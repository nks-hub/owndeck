import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'board_test_support.dart';

int _selectedColumn(WidgetTester tester) =>
    DefaultTabController.of(tester.element(find.byType(TabBarView))).index;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  test('last board is stored per account and damaged values are ignored', () async {
    final store = MemoryBoardPreferences();
    final first = AppPreferences(store: store);
    await first.rememberLastBoard('a', 5, stackId: 7);
    await first.rememberLastBoard('b', 6);
    await first.rememberLastBoard('a', 5);
    final restarted = AppPreferences(store: store);
    expect(await restarted.lastBoard('a'), (boardId: 5, stackId: 7));
    expect(await restarted.lastBoard('b'), (boardId: 6, stackId: null));
    expect(await restarted.lastBoard('c'), isNull);

    await restarted.forgetLastBoard('a');
    expect(await AppPreferences(store: store).lastBoard('a'), isNull);

    final damaged = MemoryBoardPreferences();
    await AppPreferences(store: damaged).rememberLastBoard('a', 5);
    damaged.values[damaged.values.keys.single] = '{broken';
    expect(await AppPreferences(store: damaged).lastBoard('a'), isNull);
  });

  testWidgets('restart reopens the last board on its last column and a column '
      'change is remembered', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    final store = MemoryBoardPreferences();
    try {
      await tester.runAsync(
        () => AppPreferences(
          store: store,
        ).rememberLastBoard(fixture.account.id, 1, stackId: 11),
      );
      await tester.pumpWidget(
        boardTestApp(
          BoardsScreen(session: fixture.session),
          preferences: AppPreferences(store: store),
        ),
      );
      await settleBoard(tester);
      expect(find.byType(BoardScreen), findsOneWidget);
      expect(_selectedColumn(tester), 1);

      await tester.tap(find.text('Column 1 (3)'));
      await settleBoard(tester);
      expect(_selectedColumn(tester), 0);
      await settleBoard(tester);
      await settleBoard(tester);
      final saved = await tester.runAsync(
        () => AppPreferences(store: store).lastBoard(fixture.account.id),
      );
      expect(saved, (boardId: 1, stackId: 10));
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('switching accounts opens that account\'s last board', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final first = (await tester.runAsync(() => BoardFixture.create()))!;
    final second = (await tester.runAsync(
      () => BoardFixture.create(counts: [1, 1, 1]),
    ))!;
    final store = MemoryBoardPreferences();
    final session = ValueNotifier<DeckSession>(first.session);
    try {
      await tester.runAsync(() async {
        final seed = AppPreferences(store: store);
        await seed.rememberLastBoard(first.account.id, 1, stackId: 10);
        await seed.rememberLastBoard(second.account.id, 1, stackId: 12);
      });
      await tester.pumpWidget(
        boardTestApp(
          ValueListenableBuilder<DeckSession>(
            valueListenable: session,
            builder: (_, value, _) => BoardsScreen(session: value),
          ),
          preferences: AppPreferences(store: store),
        ),
      );
      await settleBoard(tester);
      expect(find.byType(BoardScreen), findsOneWidget);
      expect(_selectedColumn(tester), 0);

      Navigator.of(tester.element(find.byType(BoardScreen))).pop();
      await tester.pump(const Duration(seconds: 1));
      await settleBoard(tester);
      expect(find.byType(BoardScreen), findsNothing);
      session.value = second.session;
      await settleBoard(tester);
      expect(find.byType(BoardScreen), findsOneWidget);
      expect(_selectedColumn(tester), 2);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, first.close());
      await boardModel(tester, second.close());
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
