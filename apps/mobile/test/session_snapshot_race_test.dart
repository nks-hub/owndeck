import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';

final class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late StoredAccount account;
  DeckSession? session;
  JsonObject board(int id) => {
    'id': id,
    'title': 'Board',
    'color': '008080',
    'deletedAt': 0,
    'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
  };
  JsonObject stack(int boardId, {bool card = false}) => {
    'id': boardId + 1,
    'boardId': boardId,
    'title': 'Column',
    'order': 0,
    'cards': [
      if (card)
        {
          'id': 8,
          'stackId': boardId + 1,
          'title': 'Task',
          'description': 'Text',
          'order': 0,
          'lastModified': 10,
        },
    ],
  };
  http.Response json(Object? data) => http.Response(
    jsonEncode(data),
    200,
    headers: {'content-type': 'application/json'},
  );
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson(board(1)),
      DeckBoard.fromJson(board(3)),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stack(1, card: true)),
    ], null);
    await database.saveStacks(account.id, account.generation, 3, [
      DeckStack.fromJson(stack(3)),
    ], null);
  });
  tearDown(() async {
    session?.dispose();
    session = null;
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });
  DeckSession connect(Future<http.Response> Function(http.Request) request) =>
      session = DeckSession(
        database,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'test-password',
          transport: MockClient(request),
        ),
      );

  test(
    'destination refresh recovers from a concurrent empty source snapshot',
    () async {
      final reached = Completer<void>();
      final release = Completer<void>();
      var reads = 0;
      final active = connect((request) async {
        final path = request.url.path;
        if (path.endsWith('/boards/1')) return json(board(1));
        if (path.endsWith('/boards/3')) return json(board(3));
        if (path.endsWith('/archived')) return json([]);
        if (path.endsWith('/boards/1/stacks')) return json([stack(1)]);
        if (path.endsWith('/boards/3/stacks')) {
          reads++;
          if (reads == 1) {
            reached.complete();
            await release.future;
          }
          return json([stack(3, card: true)]);
        }
        throw StateError('unexpected_request');
      });
      final destination = active.refreshStacks(3);
      await reached.future;
      await active.refreshStacks(1);
      release.complete();
      await destination;
      expect(reads, 2);
      expect(active.error('board:3'), isNull);
      await database.saveStacks(
        account.id,
        account.generation,
        1,
        [DeckStack.fromJson(stack(1, card: true))],
        null,
        contentEpoch: 0,
      );
      expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
      expect(
        (await database.stackView(account.id, 3)).single.cards.single.id,
        8,
      );
    },
  );

  test(
    'repeated invalidations report an error instead of silently accepting stale data',
    () async {
      var reads = 0;
      final active = connect((request) async {
        if (request.url.path.endsWith('/boards/3')) return json(board(3));
        if (request.url.path.endsWith('/archived')) return json([]);
        reads++;
        await database.invalidateMutation(account.id, 3);
        return json([stack(3, card: true)]);
      });
      await active.refreshStacks(3);
      expect(reads, 3);
      expect(active.error('board:3'), isA<StateError>());
      expect((await database.stackView(account.id, 3)).single.cards, isEmpty);
    },
  );

  test(
    'board-list refresh retries after a concurrent content invalidation',
    () async {
      var reads = 0;
      final active = connect((request) async {
        if (request.url.path.endsWith('/cloud/user')) {
          return json({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': {'id': 'user'},
            },
          });
        }
        if (request.url.path.endsWith('/capabilities')) {
          return json({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': {
                'capabilities': {
                  'deck': {
                    'version': '1.19.1',
                    'apiVersions': ['1.1'],
                    'canCreateBoards': true,
                  },
                },
              },
            },
          });
        }
        expect(request.url.path, endsWith('/boards'));
        reads++;
        if (reads == 1) await database.invalidateMutation(account.id, 1);
        return json([board(1), board(3)]);
      });
      await active.refreshBoards();
      expect(reads, 2);
      expect(active.error('boards'), isNull);
      expect(await database.boardView(account.id), hasLength(2));
    },
  );
}
