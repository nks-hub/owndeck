import 'dart:async';
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

DeckAttachment attachment(int modified) => DeckAttachment.fromJson({
  'id': 7,
  'cardId': 8,
  'type': 'file',
  'data': 'report.txt',
  'lastModified': modified,
  'deletedAt': 0,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late Directory root;
  late AttachmentFiles files;
  late DeckDatabase database;
  late AccountRepository accounts;
  late StoredAccount account;
  DeckSession? session;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    root = await Directory.systemTemp.createTemp('owndeck-session-files-test-');
    files = AttachmentFiles(root);
    database = DeckDatabase(NativeDatabase.memory());
    accounts = AccountRepository(
      database,
      _Vault(),
      clearFiles: files.removeAccount,
    );
    account = await accounts.add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        'id': 1,
        'title': 'Board',
        'color': '008080',
        'archived': false,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
      }),
    ], null);
  });
  tearDown(() async {
    session?.dispose();
    session = null;
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
    if (await root.exists()) await root.delete(recursive: true);
  });

  DeckSession connect(http.Client transport) => session = DeckSession(
    database,
    account,
    DeckClient(
      base: ServerBase.parse(account.server),
      loginName: account.loginName,
      appPassword: 'test-password',
      transport: transport,
    ),
    files: () async => files,
  );

  test(
    'a stale attachment GET cannot prune a newer locally confirmed file',
    () async {
      final requested = Completer<void>();
      final response = Completer<http.Response>();
      final active = connect(
        MockClient((request) {
          expect(
            request.url.path,
            endsWith('/boards/1/stacks/2/cards/8/attachments'),
          );
          requested.complete();
          return response.future;
        }),
      );
      await database.saveAttachments(account, 1, 8, [attachment(10)], 0);
      await files.cache(account.id, 1, attachment(10), [1]);
      final refresh = active.refreshAttachments(1, 2, 8);
      await requested.future;
      await database.invalidateMutation(account.id, 1);
      final epoch = (await database.account(account.id))!.contentEpoch;
      await database.saveAttachments(account, 1, 8, [attachment(11)], epoch);
      await files.cache(account.id, 1, attachment(11), [2]);
      response.complete(
        http.Response(
          jsonEncode([attachment(10).raw]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await refresh;
      expect(active.error('attachments:8'), isNull);
      expect(
        (await database.attachmentsFor(account.id, 8)).single.modified,
        11,
      );
      expect(
        await (await files.cached(
          account.id,
          1,
          attachment(11),
        ))!.readAsBytes(),
        [2],
      );
      expect(await files.cached(account.id, 1, attachment(10)), isNull);
    },
  );

  test('a late download cannot recreate files after account removal', () async {
    final requested = Completer<void>();
    final response = Completer<http.Response>();
    final active = connect(
      MockClient((_) {
        requested.complete();
        return response.future;
      }),
    );
    await files.cache(account.id, 1, attachment(10), [1]);
    final download = active.downloadAttachment(1, 2, attachment(10));
    final rejected = expectLater(download, throwsStateError);
    await requested.future;
    await accounts.remove(account.id);
    response.complete(http.Response.bytes([2], 200));
    await rejected;
    expect(await Directory('${root.path}/${account.id}').exists(), isFalse);
  });

  test('a network failure can use an explicitly marked cached copy', () async {
    final active = connect(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await files.cache(account.id, 1, attachment(10), [1, 2]);
    final downloaded = await active.downloadAttachment(1, 2, attachment(10));
    expect(downloaded.offline, isTrue);
    expect(await downloaded.file.readAsBytes(), [1, 2]);
  });

  test(
    'a server permission denial removes the cached copy instead of using it',
    () async {
      final active = connect(MockClient((_) async => http.Response('', 403)));
      await files.cache(account.id, 1, attachment(10), [1, 2]);
      await expectLater(
        active.downloadAttachment(1, 2, attachment(10)),
        throwsA(
          isA<DeckException>().having((error) => error.status, 'status', 403),
        ),
      );
      expect(await files.cached(account.id, 1, attachment(10)), isNull);
    },
  );
}
