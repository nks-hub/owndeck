import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/background_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String reference) async => values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      values[reference] = password;
  @override
  Future<void> delete(String reference) async => values.remove(reference);
  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

http.Response _json(Object? value, {bool ocs = false}) => http.Response(
  jsonEncode(
    ocs
        ? {
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': value,
            },
          }
        : value,
  ),
  200,
  headers: {'content-type': 'application/json'},
);

const _board = {
  'id': 1,
  'title': 'Board',
  'color': '008080',
  'archived': false,
  'deletedAt': 0,
  'permissions': {
    'PERMISSION_READ': true,
    'PERMISSION_EDIT': true,
    'PERMISSION_MANAGE': false,
  },
};

const _card = {
  'id': 8,
  'stackId': 2,
  'title': 'Card',
  'description': '',
  'order': 0,
  'type': 'plain',
  'owner': 'user',
  'archived': false,
  'deletedAt': 0,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late _Vault vault;
  late StoredAccount account;
  late List<String> requests;

  Future<http.Response> server(http.Request request) async {
    final path = request.url.path;
    requests.add('${request.method} $path');
    if (path.endsWith('/cloud/user')) return _json({'id': 'user'}, ocs: true);
    if (path.endsWith('/cloud/capabilities')) {
      return _json({
        'capabilities': {
          'deck': {
            'version': '1.19.1',
            'apiVersions': ['1.1'],
          },
        },
      }, ocs: true);
    }
    if (request.method == 'POST' && path.endsWith('/comments')) {
      return _json({
        'id': 10,
        'objectId': 8,
        'message': 'Hello',
        'actorId': 'user',
        'actorType': 'users',
        'creationDateTime': '2030-01-01T00:00:00Z',
      }, ocs: true);
    }
    if (path.endsWith('/comments')) return _json([], ocs: true);
    if (path.endsWith('/boards')) return _json([_board]);
    if (path.endsWith('/boards/1')) return _json(_board);
    if (path.endsWith('/stacks/archived')) return _json([]);
    if (path.endsWith('/boards/1/stacks')) {
      return _json([
        {
          'id': 2,
          'boardId': 1,
          'title': 'Column',
          'order': 0,
          'cards': [_card],
        },
      ]);
    }
    return http.Response('', 404);
  }

  Future<bool> run({Future<bool> Function()? allowed}) => runBackgroundSync(
    database: database,
    vault: vault,
    transport: (_) => MockClient(server),
    files: () async => throw StateError('no files'),
    allowed: allowed ?? () async => true,
  );

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    requests = [];
    vault = _Vault();
    database = DeckDatabase(NativeDatabase.memory(), background: true);
    account = await AccountRepository(database, vault).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
      userId: 'user',
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson(_board),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [_card],
      }),
    ], null);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
    await database.close();
  });

  test('defaults are 15 minutes on any network', () async {
    final preferences = await BackgroundSyncPreferences.load();
    expect(preferences.minutes, 15);
    expect(preferences.wifiOnly, isFalse);
    expect(BackgroundSyncPreferences.intervals, [0, 15, 60, 360]);
  });

  test('a damaged stored value falls back to the defaults', () async {
    await SharedPreferencesAsync().setString('backgroundSync', '{"minutes":7}');
    expect((await BackgroundSyncPreferences.load()).minutes, 15);
  });

  test('the stored choice is read back', () async {
    await const BackgroundSyncPreferences(minutes: 360, wifiOnly: true).save();
    final preferences = await BackgroundSyncPreferences.load();
    expect(preferences.minutes, 360);
    expect(preferences.wifiOnly, isTrue);
  });

  test('a run sends queued changes and refreshes the cache', () async {
    await database.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    expect(await run(), isTrue);
    expect(
      requests.where((r) => r.startsWith('POST') && r.endsWith('/comments')),
      hasLength(1),
    );
    expect(requests.where((r) => r.endsWith('/boards/1/stacks')), isNotEmpty);
    expect(await database.select(database.syncLeases).get(), isEmpty);
  });

  test('an uncertain write is never sent again by a background run', () async {
    await database.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Lost',
    });
    final write = (await database.writesFor(account.id)).single;
    await (database.update(
      database.pendingWrites,
    )..where((w) => w.id.equals(write.id))).write(
      const PendingWritesCompanion(
        state: Value('uncertain'),
        error: Value('interrupted_write'),
      ),
    );
    expect(await run(), isTrue);
    expect(requests.where((r) => r.startsWith('POST')), isEmpty);
    expect((await database.writesFor(account.id)).single.state, 'uncertain');
  });

  test('nothing is requested while background sync is not allowed', () async {
    await database.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    expect(await run(allowed: () async => false), isTrue);
    expect(requests, isEmpty);
    expect((await database.writesFor(account.id)).single.state, 'queued');
  });

  test('turning the setting off stops the real gate', () async {
    await const BackgroundSyncPreferences(minutes: 0).save();
    expect(await backgroundSyncAllowed(), isFalse);
    await const BackgroundSyncPreferences(minutes: 60).save();
    expect(await backgroundSyncAllowed(), isTrue);
  });

  test('a run does not send while the app holds the lease', () async {
    await database.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    expect(await database.acquireLease(account, 'foreground'), isTrue);
    expect(await run(), isTrue);
    expect(requests.where((r) => r.startsWith('POST')), isEmpty);
    expect((await database.writesFor(account.id)).single.state, 'queued');
    final lease = await database.select(database.syncLeases).getSingle();
    expect(lease.owner, 'foreground');
  });

  test('a run takes a background lease owner and releases it', () async {
    await database.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    final owners = <String>[];
    final watch = database
        .select(database.syncLeases)
        .watch()
        .listen((rows) => owners.addAll(rows.map((r) => r.owner)));
    await run();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await watch.cancel();
    expect(
      owners,
      everyElement(startsWith(DeckDatabase.backgroundOwnerPrefix)),
    );
    expect(owners, isNotEmpty);
    expect(await database.select(database.syncLeases).get(), isEmpty);
  });
}
