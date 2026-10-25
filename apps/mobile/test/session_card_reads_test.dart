import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/attachment_files.dart';
import 'package:nextclouddeck/data/card_reads.dart';
import 'package:nextclouddeck/data/session.dart';

final class _Vault implements CredentialVault {
  final _values = <String, String>{};
  @override
  Future<String?> read(String reference) async => _values[reference];
  @override
  Future<void> write(String reference, String password) async {
    _values[reference] = password;
  }

  @override
  Future<void> delete(String reference) async => _values.remove(reference);
  @override
  Future<Set<String>> references() async => _values.keys.toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late StoredAccount account;
  late Directory directory;
  late AttachmentFiles files;
  late File cachedFile;
  DeckSession? session;
  final board = DeckBoard.fromJson({
    'id': 1,
    'title': 'Board',
    'color': '008080',
    'archived': false,
    'deletedAt': 0,
    'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
  });
  final stack = DeckStack.fromJson({
    'id': 2,
    'boardId': 1,
    'title': 'Column',
    'order': 0,
    'cards': [
      for (final id in [8, 9])
        {
          'id': id,
          'stackId': 2,
          'title': 'Task $id',
          'description': '',
          'order': 0,
        },
    ],
  });
  final attachment = DeckAttachment.fromJson({
    'id': 7,
    'type': 'file',
    'cardId': 8,
    'data': 'report.txt',
    'lastModified': 10,
    'deletedAt': 0,
  });

  http.Response json(Object value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    directory = await Directory.systemTemp.createTemp('owndeck-read-card-');
    files = AttachmentFiles(directory);
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    await database.saveBoards(account.id, account.generation, [board], null);
    await database.saveStacks(account.id, account.generation, 1, [stack], null);
    await database.saveAttachments(account, 1, 8, [attachment], 0);
    cachedFile = await files.cache(account.id, 1, attachment, [1, 2, 3]);
    await database.saveEditorDraft(account, 'draft', 1, 2, {
      'description': 'My local text',
    }, stack.cards.first);
  });
  tearDown(() async {
    session?.dispose();
    session = null;
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
    await directory.delete(recursive: true);
  });

  DeckSession connect(http.Client client, {Future<void> Function()? on401}) =>
      session = DeckSession(
        database,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'test-password',
          transport: client,
        ),
        files: () async => files,
        onAuthenticationRequired: on401,
      );

  for (final status in [403, 404]) {
    test(
      'opening card clears revoked board $status and files, keeps own draft',
      () async {
        var requests = 0;
        final active = connect(
          MockClient((request) async {
            requests++;
            expect(request.url.path, endsWith('/boards/1'));
            return http.Response('', status);
          }),
        );
        await expectLater(
          active.openRemoteCard(1, 8, stackId: 2),
          throwsA(
            isA<DeckException>().having((e) => e.status, 'status', status),
          ),
        );
        expect(requests, 1);
        expect(await database.boardView(account.id), isEmpty);
        expect(await database.stackView(account.id, 1), isEmpty);
        expect(await database.attachmentsFor(account.id, 8), isEmpty);
        expect(await cachedFile.exists(), isFalse);
        expect(
          (await database.editorDraft(account.id, 'draft'))!.payload,
          contains('My local text'),
        );
      },
    );

    test('card $status does not revoke its readable board', () async {
      var boardReads = 0;
      final active = connect(
        MockClient((request) async {
          if (request.url.path.endsWith('/boards/1')) {
            boardReads++;
            return json(board.raw);
          }
          if (request.url.path.endsWith('/stacks/2')) return json(stack.raw);
          expect(request.url.path, endsWith('/cards/8'));
          return http.Response('', status);
        }),
      );
      await expectLater(
        active.openRemoteCard(1, 8, stackId: 2),
        throwsA(isA<DeckException>().having((e) => e.status, 'status', status)),
      );
      expect(boardReads, 1);
      expect(await database.boardView(account.id), hasLength(1));
      expect(
        (await database.stackView(
          account.id,
          1,
        )).single.cards.any((card) => card.id == 9),
        isTrue,
      );
    });
  }

  test('board payload with no READ clears cached content', () async {
    final active = connect(
      MockClient(
        (_) async => json({
          ...board.raw,
          'permissions': {'PERMISSION_READ': false},
        }),
      ),
    );
    await expectLater(
      active.openRemoteCard(1, 8, stackId: 2),
      throwsA(isA<DeckException>()),
    );
    expect(await database.boardView(account.id), isEmpty);
    expect(await cachedFile.exists(), isFalse);
  });

  test('401 invokes reauthentication once and keeps offline data', () async {
    var requests = 0;
    final active = connect(
      MockClient((_) async => http.Response('', 401)),
      on401: () async {
        requests++;
      },
    );
    await expectLater(
      active.openRemoteCard(1, 8, stackId: 2),
      throwsA(isA<DeckException>()),
    );
    expect(requests, 1);
    expect(await database.boardView(account.id), hasLength(1));
    expect(await cachedFile.exists(), isTrue);
  });

  test('transient board error keeps offline data', () async {
    final active = connect(MockClient((_) async => http.Response('', 503)));
    await expectLater(
      active.openRemoteCard(1, 8, stackId: 2),
      throwsA(isA<DeckException>()),
    );
    expect(await database.boardView(account.id), hasLength(1));
    expect(await cachedFile.exists(), isTrue);
  });
}
