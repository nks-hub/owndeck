import 'dart:convert';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/board_card_tile.dart';
import 'package:nextclouddeck/features/board_drag.dart';
import 'package:nextclouddeck/features/board_layout.dart';
import 'package:nextclouddeck/features/board_moves.dart';
import 'board_test_support.dart';

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

  testWidgets(
    'layout choices restore per account and board without changing the three destinations',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      final store = MemoryBoardPreferences();
      try {
        await tester.pumpWidget(
          boardTestApp(
            BoardScreen(session: fixture.session, board: fixture.board),
            preferences: AppPreferences(store: store),
          ),
        );
        await settleBoard(tester);
        await tester.tap(
          find.byKey(const ValueKey(('board-view', BoardViewMode.list))),
        );
        await settleBoard(tester);
        expect(
          tester.widget<BoardLayout>(find.byType(BoardLayout)).mode,
          BoardViewMode.list,
        );
        await tester.pumpWidget(const SizedBox());
        final restored = AppPreferences(store: store);
        await tester.pumpWidget(
          boardTestApp(
            BoardScreen(session: fixture.session, board: fixture.board),
            preferences: restored,
          ),
        );
        await settleBoard(tester);
        expect(
          tester.widget<BoardLayout>(find.byType(BoardLayout)).mode,
          BoardViewMode.list,
        );
        expect(
          restored.boardViewMode('another-account', 1),
          BoardViewMode.columns,
        );
        expect(
          restored.boardViewMode(fixture.account.id, 2),
          BoardViewMode.columns,
        );
        await tester.pumpWidget(
          boardTestApp(
            BoardsScreen(session: fixture.session),
            preferences: restored,
          ),
        );
        await settleBoard(tester);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(find.text('Settings'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    '1000 cards stay lazy in wide columns and list; phone shows one column',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => BoardFixture.create(counts: List.filled(10, 100)),
      ))!;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final columns = [
        for (final stack in fixture.stacks) BoardColumnView(stack, false),
      ];
      Widget layout(BoardViewMode mode) => boardTestApp(
        Scaffold(
          body: BoardLayout(
            session: fixture.session,
            board: fixture.board,
            columns: columns,
            archivedView: false,
            mode: mode,
          ),
        ),
      );
      try {
        await tester.pumpWidget(layout(BoardViewMode.columns));
        await tester.pump();
        expect(find.text('Column 1 (100)'), findsOneWidget);
        expect(find.text('Column 2 (100)'), findsOneWidget);
        expect(find.byType(BoardCardTile).evaluate().length, lessThan(80));
        final tile = tester.widget<BoardCardTile>(boardTile(100));
        final pointer = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey(('drag-card', 100)))),
        );
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        final target = tester.getCenter(boardTile(1100));
        for (var i = 0; i < 8; i++) {
          await pointer.moveTo(target + Offset(0, i.toDouble()));
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(
          identical(tester.widget<BoardCardTile>(boardTile(100)), tile),
          isTrue,
        );
        await pointer.cancel();
        await tester.pump();
        await tester.pumpWidget(layout(BoardViewMode.list));
        await tester.pump();
        expect(find.byType(BoardCardTile).evaluate().length, lessThan(30));
        tester.view.physicalSize = const Size(390, 700);
        await tester.pumpWidget(layout(BoardViewMode.columns));
        await tester.pumpAndSettle();
        expect(boardTile(100).hitTestable(), findsOneWidget);
        expect(boardTile(1100).hitTestable(), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'cross-column drop queues the real move and keeps the card after offline failure',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await tester.pumpWidget(
          boardTestApp(
            BoardScreen(session: fixture.session, board: fixture.board),
            preferences: AppPreferences(store: MemoryBoardPreferences()),
          ),
        );
        await settleBoard(tester);
        final end = find.byKey(
          boardDropKey(
            fixture.account.id,
            fixture.account.generation,
            1,
            11,
            null,
          ),
        );
        await dragBoardCard(tester, 100, tester.getCenter(end));
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(writes.single.kind, 'moveCard');
        expect(jsonDecode(writes.single.proposal), {'stackId': 11, 'order': 0});
        expect(
          jsonDecode(writes.single.base!)['description'],
          'Description 100',
        );
        final stacks = await boardModel(
          tester,
          fixture.db.stackView(fixture.account.id, 1),
        );
        expect(stacks.singleWhere((s) => s.id == 10).cards.map((c) => c.id), [
          101,
          102,
        ]);
        expect(stacks.singleWhere((s) => s.id == 11).cards.single.id, 100);
        expect(boardTile(100), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'same-column drop uses the final active index with archived cards excluded',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => BoardFixture.create(archivedLeading: true),
      ))!;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 700);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      try {
        await tester.pumpWidget(
          boardTestApp(
            BoardScreen(session: fixture.session, board: fixture.board),
            preferences: AppPreferences(store: MemoryBoardPreferences()),
          ),
        );
        await settleBoard(tester);
        expect(find.text('Archived card'), findsNothing);
        await dragBoardCard(
          tester,
          100,
          tester.getRect(boardTile(102)).topCenter + const Offset(0, 8),
        );
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(jsonDecode(writes.single.proposal), {'stackId': 10, 'order': 1});
        final stacks = await boardModel(
          tester,
          fixture.db.stackView(fixture.account.id, 1),
        );
        expect(stacks.first.cards.where(activeBoardCard).map((c) => c.id), [
          101,
          100,
          102,
        ]);
        expect(
          stacks.first.cards.singleWhere((c) => c.id == 99).archived,
          isTrue,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets('move menu uses a named anchor at 200 percent text', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.pumpWidget(
        boardTestApp(
          BoardScreen(session: fixture.session, board: fixture.board),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
          scale: 2,
        ),
      );
      await settleBoard(tester);
      final menu = find.descendant(
        of: boardTile(100),
        matching: find.byType(PopupMenuButton<String>),
      );
      await tester.ensureVisible(menu);
      await tester.pumpAndSettle();
      expect(menu.hitTestable(), findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move card'));
      await settleBoard(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        findsNothing,
      );
      final placement = find.byKey(const ValueKey(('placement', 10, 'end')));
      await tester.ensureVisible(placement);
      await tester.tap(placement);
      await tester.pumpAndSettle();
      await tester.tap(find.text('After a card').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Move card'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Move card'));
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(jsonDecode(writes.single.proposal), {'stackId': 10, 'order': 1});
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('read-only and archive modes have no drag handles or move menu', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(editable: false, archivedLeading: true),
    ))!;
    try {
      await tester.pumpWidget(
        boardTestApp(
          BoardScreen(session: fixture.session, board: fixture.board),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
        ),
      );
      await settleBoard(tester);
      expect(find.byType(LongPressDraggable<BoardCardDrag>), findsNothing);
      await tester.tap(find.byTooltip('Board actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archived cards'));
      await settleBoard(tester);
      expect(find.text('Archived card'), findsOneWidget);
      expect(find.byType(LongPressDraggable<BoardCardDrag>), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BoardCardTile),
          matching: find.byType(PopupMenuButton<String>),
        ),
        findsNothing,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets(
    'queue rejects foreign account or generation without adding writes',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await tester.runAsync(() async {
          for (final drag in [
            BoardCardDrag(
              accountId: 'another-account',
              generation: fixture.account.generation,
              boardId: 1,
              stackId: 10,
              cardId: 100,
            ),
            BoardCardDrag(
              accountId: fixture.account.id,
              generation: fixture.account.generation + 1,
              boardId: 1,
              stackId: 10,
              cardId: 100,
            ),
            BoardCardDrag(
              accountId: fixture.account.id,
              generation: fixture.account.generation,
              boardId: 2,
              stackId: 10,
              cardId: 100,
            ),
          ]) {
            await expectLater(
              queueBoardCardMove(
                fixture.session,
                fixture.board,
                drag,
                const BoardDropPosition(11),
              ),
              throwsStateError,
            );
          }
          expect(await fixture.db.writesFor(fixture.account.id), isEmpty);
        });
      } finally {
        await boardModel(tester, fixture.close());
      }
    },
  );
}
