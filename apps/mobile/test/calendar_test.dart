import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/calendar.dart';
import 'package:nextclouddeck/features/card_detail.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late StoredAccount account;
  late DeckSession session;
  final now = DateTime.now();

  String at(int day, [int hour = 12]) =>
      DateTime(now.year, now.month, day, hour).toUtc().toIso8601String();

  Map<String, Object?> card(int id, String title, Map<String, Object?> extra) =>
      {
        'id': id,
        'stackId': 2,
        'title': title,
        'description': '',
        'type': 'plain',
        'owner': 'u',
        'order': id,
        'archived': false,
        'done': null,
        'assignedUsers': [
          {
            'type': 0,
            'participant': {'uid': 'canonical-user'},
          },
        ],
        ...extra,
      };

  Future<void> seed() async {
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
          card(1, 'Starts card', {'startdate': at(10)}),
          card(2, 'Due card', {'duedate': at(12)}),
          card(3, 'Done card', {'duedate': at(14), 'done': at(13)}),
          card(4, 'Quick done', {'done': at(16)}),
        ],
      }),
    ], null);
  }

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(database, _Vault()).add(
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
        transport: MockClient((_) async => throw StateError('offline')),
      ),
    );
    await seed();
  });
  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Widget app({double textScale = 1}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: CalendarView(session: session)),
  );

  Future<void> pickDay(WidgetTester tester, int day) async {
    await tester.ensureVisible(find.byKey(ValueKey('calendar-day:$day')));
    await tester.tap(find.byKey(ValueKey('calendar-day:$day')));
    await tester.pumpAndSettle();
  }

  testWidgets('start, due and completed dates are told apart', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await pickDay(tester, 10);
    expect(find.text('Starts card'), findsOneWidget);
    expect(find.textContaining('Start date · '), findsOneWidget);
    expect(find.byIcon(Icons.event_outlined), findsWidgets);

    await pickDay(tester, 12);
    expect(find.text('Due card'), findsOneWidget);
    expect(find.textContaining('Due date · '), findsOneWidget);

    await pickDay(tester, 13);
    expect(find.text('Done card'), findsOneWidget);
    expect(find.textContaining('Completed · '), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'0 start, 0 due, 1 completed')),
      findsWidgets,
    );

    await pickDay(tester, 14);
    expect(find.text('Done card'), findsNothing);

    await pickDay(tester, 16);
    expect(find.text('Quick done'), findsOneWidget);
    expect(find.textContaining('Completed · '), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'1 start, 0 due, 0 completed')),
      findsOneWidget,
    );

    await pickDay(tester, 20);
    expect(find.text('Nothing on this day.'), findsOneWidget);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('says so when some boards have no saved cards', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-incomplete')), findsNothing);
    await tester.runAsync(() => database.saveBoards(account.id, account.generation, [
      for (final id in [1, 5])
        DeckBoard.fromJson({
          'id': id,
          'title': 'Board $id',
          'color': '008080',
          'archived': false,
          'deletedAt': 0,
          'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
        }),
    ], null));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-incomplete')), findsOneWidget);
    expect(find.textContaining('Cards of 1 board'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('tapping an entry opens that card in this account', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await pickDay(tester, 12);
    await tester.tap(find.text('Due card'));
    await tester.pumpAndSettle();
    final screen = tester.widget<CardScreen>(find.byType(CardScreen));
    expect(screen.session, session);
    expect(screen.card.id, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('month grid and agenda fit double-size text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(textScale: 2));
    await tester.pumpAndSettle();
    await pickDay(tester, 10);
    expect(find.text('Starts card'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('day cells keep 48 dp touch targets at 360 dp width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final size = tester.getSize(find.byKey(const ValueKey('calendar-day:10')));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('a card can be completed from the agenda', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await pickDay(tester, 12);
    await tester.tap(find.byType(Checkbox));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    final writes = (await tester.runAsync(
      () => database.writesFor(account.id),
    ))!;
    expect(writes.length, 1);
    expect(find.byType(CardScreen), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  test('a completed card sits on its completion day, not its due day', () {
    final hit = CardSearchHit(
      board: DeckBoard.fromJson({'id': 1, 'title': 'B', 'color': '008080', 'archived': false, 'deletedAt': 0, 'permissions': {'PERMISSION_READ': true}}),
      stack: DeckStack.fromJson({'id': 2, 'boardId': 1, 'title': 'S', 'order': 0, 'cards': []}),
      card: DeckCard.fromJson({
        'id': 3,
        'stackId': 2,
        'title': 'C',
        'description': '',
        'type': 'plain',
        'owner': 'u',
        'order': 1,
        'archived': false,
        'done': '2030-05-04T10:00:00+00:00',
        'duedate': '2030-05-09T10:00:00+00:00',
      }),
    );
    final done = DateTime.parse('2030-05-04T10:00:00+00:00').toLocal();
    final days = calendarEntries([hit]);
    expect(days.length, 1);
    expect(
      days[DateTime(done.year, done.month, done.day)]!.single.kind,
      CalendarKind.done,
    );
  });

  test('entries are grouped by local day', () {
    final hit = CardSearchHit(
      board: DeckBoard.fromJson({'id': 1, 'title': 'B', 'color': '008080', 'archived': false, 'deletedAt': 0, 'permissions': {'PERMISSION_READ': true}}),
      stack: DeckStack.fromJson({'id': 2, 'boardId': 1, 'title': 'S', 'order': 0, 'cards': []}),
      card: DeckCard.fromJson({
        'id': 3,
        'stackId': 2,
        'title': 'C',
        'description': '',
        'type': 'plain',
        'owner': 'u',
        'order': 1,
        'archived': false,
        'done': null,
        'startdate': '2030-05-01T23:30:00+00:00',
        'duedate': '2030-05-03T00:10:00+00:00',
      }),
    );
    final days = calendarEntries([hit]);
    final start = DateTime.parse('2030-05-01T23:30:00+00:00').toLocal();
    final due = DateTime.parse('2030-05-03T00:10:00+00:00').toLocal();
    expect(
      days[DateTime(start.year, start.month, start.day)]!.single.kind,
      CalendarKind.start,
    );
    expect(
      days[DateTime(due.year, due.month, due.day)]!.single.kind,
      CalendarKind.due,
    );
  });
}
