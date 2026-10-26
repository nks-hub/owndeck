import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/search.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

class _Vault implements CredentialVault {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  // A Monday, so the weekend card is still "This week".
  final now = DateTime(2026, 10, 19, 12);
  final dues = <String, String?>{
    'Later card': '2026-11-20T10:00:00',
    'None card': null,
    'Week card': '2026-10-23T10:00:00',
    'Overdue card': '2026-10-17T10:00:00',
    'Tomorrow card': '2026-10-20T10:00:00',
    'Today card': '2026-10-19T18:00:00',
  };
  late DeckDatabase database;
  late DeckSession session;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
      userId: 'user',
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        'id': 1,
        'title': 'Project',
        'color': '008080',
        'archived': false,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
      }),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Planning',
        'order': 0,
        'cards': [
          for (final (i, entry) in dues.entries.indexed)
            {
              'id': i + 1,
              'stackId': 2,
              'title': entry.key,
              'description': '',
              'type': 'plain',
              'owner': 'user',
              'order': i,
              'archived': false,
              'done': null,
              if (entry.value != null) 'duedate': entry.value,
              'assignedUsers': [
                {
                  'type': 0,
                  'participant': {'uid': 'user'},
                },
              ],
            },
        ],
      }),
    ], null);
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'user',
        appPassword: 'test-password',
        transport: MockClient((_) async => throw StateError('offline')),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  test('groups follow calendar days, with the week ending on Sunday', () {
    expect(dueGroupOf(null, now), DueGroup.none);
    expect(dueGroupOf(DateTime(2026, 10, 19, 11), now), DueGroup.overdue);
    expect(dueGroupOf(DateTime(2026, 10, 19, 23, 59), now), DueGroup.today);
    expect(dueGroupOf(DateTime(2026, 10, 20), now), DueGroup.tomorrow);
    expect(dueGroupOf(DateTime(2026, 10, 25, 23), now), DueGroup.thisWeek);
    expect(dueGroupOf(DateTime(2026, 10, 26), now), DueGroup.later);
    // Sunday: tomorrow is already next week.
    final sunday = DateTime(2026, 10, 25, 9);
    expect(dueGroupOf(DateTime(2026, 10, 26, 9), sunday), DueGroup.tomorrow);
    expect(dueGroupOf(DateTime(2026, 10, 27, 9), sunday), DueGroup.later);
  });

  testWidgets('My tasks shows a header for every due group in order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CardSearchView(
            session: session,
            fixedMineOnly: true,
            clock: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    const order = [
      'Overdue',
      'Overdue card',
      'Today',
      'Today card',
      'Tomorrow',
      'Tomorrow card',
      'This week',
      'Week card',
      'Later',
      'Later card',
      'No due date',
      'None card',
    ];
    // Overdue and Today also exist as filter chips above the list.
    double top(String label) => tester
        .getTopLeft(
          find.byWidgetPredicate((w) => w is Text && w.data == label).last,
        )
        .dy;
    for (var i = 1; i < order.length; i++) {
      expect(
        top(order[i]),
        greaterThan(top(order[i - 1])),
        reason: '${order[i]} after ${order[i - 1]}',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
