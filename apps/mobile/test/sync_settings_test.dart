import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/sync_settings.dart';

import 'test_support.dart';

final class _Vault implements CredentialVault {
  final _values = <String, String>{};
  @override
  Future<String?> read(String reference) async => _values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      _values[reference] = password;
  @override
  Future<void> delete(String reference) async => _values.remove(reference);
  @override
  Future<Set<String>> references() async => _values.keys.toSet();
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late StoredAccount account;
  late DeckSession session;
  var offline = false;

  setUp(() async {
    offline = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
      userId: 'user',
    );
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'user',
        appPassword: 'test-password',
        transport: MockClient((request) async {
          if (offline) throw const SocketException('offline');
          final path = request.url.path;
          if (path.endsWith('/cloud/user')) {
            return _json({'id': 'user'}, ocs: true);
          }
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
          if (path.endsWith('/boards')) return _json([]);
          return http.Response('', 404);
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  });
  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Widget app() => localizedTestApp(
    home: Scaffold(body: SyncSettingsTile(session: session)),
  );

  testWidgets('shows the last successful sync after Sync now', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('Not synced yet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sync-now')));
    await settle(tester);

    expect(find.text('Not synced yet'), findsNothing);
    expect(find.textContaining('Last sync: '), findsOneWidget);
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.textContaining('unavailable'), findsNothing);
  });

  testWidgets('a network error keeps the old time and says so', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.tap(find.byKey(const Key('sync-now')));
    await settle(tester);
    final before = tester.widget<Text>(find.textContaining('Last sync: ')).data;

    offline = true;
    await tester.tap(find.byKey(const Key('sync-now')));
    await settle(tester);

    expect(find.textContaining('server is unavailable'), findsOneWidget);
    expect(
      tester.widget<Text>(find.textContaining('Last sync: ')).data,
      before,
    );
    expect(find.text('Sync now'), findsOneWidget);
  });

  testWidgets('a first attempt that fails leaves the account never synced', (
    tester,
  ) async {
    offline = true;
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.tap(find.byKey(const Key('sync-now')));
    await settle(tester);
    expect(find.text('Not synced yet'), findsOneWidget);
    expect(find.textContaining('server is unavailable'), findsOneWidget);
  });
}
