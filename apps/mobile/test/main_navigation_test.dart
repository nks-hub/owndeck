import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/calendar.dart';
import 'package:nextclouddeck/features/settings.dart';
import 'package:nextclouddeck/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _PreferenceStore implements AppPreferenceStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _Vault implements CredentialVault {
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

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (ready()) return;
  }
  expect(ready(), isTrue, reason: 'The board stream did not settle.');
}

/// Pumps the app shell on one signed-in account with a cached board list.
Future<DeckSession> _pumpShell(WidgetTester tester) async {
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(connectivity, (_) async => null);
  final boards = [
    for (final archived in [false, true])
      {
        'id': archived ? 2 : 1,
        'title': archived ? 'Archived board' : 'Active board',
        'color': '008080',
        'archived': archived,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true},
      },
  ];
  http.Response json(Object data, {bool ocs = false}) => http.Response(
    jsonEncode(
      ocs
          ? {
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': data,
              },
            }
          : data,
    ),
    200,
    headers: {'content-type': 'application/json'},
  );
  late DeckDatabase database;
  final session = (await tester.runAsync(() async {
    database = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
      userId: 'user',
    );
    await database.saveBoards(
      account.id,
      account.generation,
      boards.map(DeckBoard.fromJson).toList(),
      null,
    );
    return DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/cloud/user')) {
            return json({'id': 'user'}, ocs: true);
          }
          if (path.endsWith('/cloud/capabilities')) {
            return json({
              'capabilities': {
                'deck': {
                  'version': '1.18.5',
                  'apiVersions': ['1.1'],
                  'canCreateBoards': true,
                },
              },
            }, ocs: true);
          }
          if (path.endsWith('/boards')) return json(boards);
          return http.Response('', 404);
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  }))!;
  addTearDown(() async {
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });
  final preferences = AppPreferences(store: _PreferenceStore());
  await preferences.load();
  await preferences.setLanguage(AppLanguage.en);
  await preferences.setThemeMode(ThemeMode.light);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWith((ref) => preferences),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'OwnDeck',
            packageName: 'com.example.app',
            version: '1.2.3',
            buildNumber: '4',
          ),
        ),
      ],
      child: OwnDeckApp(home: BoardsScreen(session: session)),
    ),
  );
  await _until(
    tester,
    () =>
        !session.loading('boards') &&
        find.text('Active board').evaluate().isNotEmpty,
  );
  return session;
}

/// Tears the shell down inside the test body, before timer invariants run.
Future<void> _closeShell(WidgetTester tester, DeckSession session) async {
  await tester.pumpWidget(const SizedBox.shrink());
  session.dispose();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('archive filter survives Settings language and theme changes', (
    tester,
  ) async {
    final session = await _pumpShell(tester);
    try {
      expect(session.error('boards'), isNull);
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      final screen = tester.state(find.byType(BoardsScreen));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Archived'));
      await tester.pumpAndSettle();
      expect(find.text('Archived board'), findsOneWidget);
      expect(find.text('Active board'), findsNothing);
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsView), findsOneWidget);
      expect(find.byTooltip('Search cards'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<AppLanguage>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Čeština').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tmavý').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).first);
      await _until(
        tester,
        () => find.text('Archived board').evaluate().isNotEmpty,
      );
      expect(find.text('Active board'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Archivované'))
            .selected,
        isTrue,
      );
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)),
        same(navigator),
      );
      expect(tester.state(find.byType(BoardsScreen)), same(screen));
      expect(
        Theme.of(tester.element(find.byType(BoardsScreen))).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await _closeShell(tester, session);
    }
  });
  testWidgets('My tasks keep the calendar view across tab switches', (
    tester,
  ) async {
    final session = await _pumpShell(tester);
    try {
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarView), findsNothing);
      await tester.tap(find.text('Calendar'));
      await _until(
        tester,
        () =>
            find.byType(CalendarView).evaluate().isNotEmpty &&
            find
                .byWidgetPredicate((widget) => widget is ProgressIndicator)
                .evaluate()
                .isEmpty,
      );
      expect(find.byType(CalendarView), findsOneWidget);
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .selected,
        {true},
      );
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
            .selected,
        {false},
      );
      expect(tester.takeException(), isNull);
    } finally {
      await _closeShell(tester, session);
    }
  });
}
