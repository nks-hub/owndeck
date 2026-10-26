import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/card_activity.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

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

Map<String, Object?> _activity(int id, String subject) => {
  'activity_id': id,
  'datetime': '2026-10-24T12:00:00+00:00',
  'subject': subject,
  'user': 'alice',
  'object_type': 'deck_card',
  'object_id': 3,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late DeckSession session;
  late http.Response Function(http.Request) reply;
  final queries = <Map<String, String>>[];

  setUp(() async {
    queries.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'login-alias',
        appPassword: 'test-password',
      ),
      userId: 'canonical-user',
    );
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          queries.add(request.url.queryParameters);
          return reply(request);
        }),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  http.Response ocs(Object? data) => http.Response(
    jsonEncode({
      'ocs': {
        'meta': {'status': 'ok', 'statuscode': 200},
        'data': data,
      },
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CardActivity(session: session, cardId: 3),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  testWidgets('shows server entries with time and loads older ones', (
    tester,
  ) async {
    reply = (request) => ocs(
      request.url.queryParameters.containsKey('since')
          ? [_activity(10, 'You created the card')]
          : List.generate(
              30,
              (i) => _activity(100 - i, i == 0 ? 'You moved the card' : 'Edit $i'),
            ),
    );
    await pump(tester);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('You moved the card'), findsOneWidget);
    expect(queries.single['object_type'], 'deck_card');
    expect(queries.single['object_id'], '3');
    await tester.ensureVisible(find.text('Load older'));
    await tester.tap(find.text('Load older'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
    expect(queries.last['since'], '71');
    expect(find.text('You created the card'), findsOneWidget);
    expect(find.text('Load older'), findsNothing);
  });

  testWidgets('offline says so and invents no entries', (tester) async {
    reply = (_) => throw http.ClientException('offline');
    await pump(tester);
    expect(find.textContaining('not stored on this device'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
