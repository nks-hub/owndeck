import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_bulk.dart';
import 'package:nextclouddeck/features/board_view.dart';
import 'package:nextclouddeck/features/card_move_dialog.dart';

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

  Future<List<int>> column(BoardFixture fixture, int stackId) async {
    final stacks = await fixture.db.stackView(fixture.account.id, 1);
    return [
      for (final card
          in stacks.firstWhere((stack) => stack.id == stackId).cards)
        card.id,
    ];
  }

  CardMoveDestination destination(
    BoardFixture fixture, {
    required bool before,
    int? anchor,
  }) => CardMoveDestination(
    board: fixture.board,
    stack: fixture.stacks.last,
    before: before,
    anchorCardId: anchor,
  );

  test('selection toggles, refreshes and keeps only retained ids', () {
    final first = DeckCard.fromJson({
      'id': 1,
      'stackId': 1,
      'title': 'A',
      'description': '',
      'order': 0,
      'type': 'plain',
      'owner': 'user',
    });
    final second = DeckCard.fromJson({
      'id': 2,
      'stackId': 1,
      'title': 'B',
      'description': '',
      'order': 0,
      'type': 'plain',
      'owner': 'user',
    });
    final selection = BoardSelection()
      ..toggle(first)
      ..toggle(second);
    expect(selection.length, 2);
    selection.refresh([second]);
    expect(selection.cards.map((card) => card.id), [2]);
    selection.toggle(second);
    expect(selection.active, isFalse);
  });

  testWidgets(
    'partial failure is reported per card and does not stop the rest',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => BoardFixture.create(counts: [2]),
      ))!;
      try {
        final good = fixture.stacks.first.cards.first;
        final archived = DeckCard.fromJson({
          ...good.raw,
          'id': 101,
          'archived': true,
        });
        final outcomes = await boardModel(
          tester,
          archiveEach(fixture.session, fixture.board, [archived, good]),
        );
        expect(outcomes.map((o) => o.status), [
          BulkStatus.failed,
          BulkStatus.queued,
        ]);
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(writes.map((w) => w.kind), ['archiveCard']);
        expect(writes.single.cardId, 100);
      } finally {
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets('read-only board blocks every card and queues nothing', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [2], editable: false),
    ))!;
    try {
      final cards = fixture.stacks.first.cards;
      final archive = await boardModel(
        tester,
        archiveEach(fixture.session, fixture.board, cards),
      );
      final move = await boardModel(
        tester,
        moveEach(
          fixture.session,
          fixture.board,
          cards,
          destination(fixture, before: false),
        ),
      );
      expect(
        [...archive, ...move].map((o) => o.status),
        everyElement(BulkStatus.blocked),
      );
      expect(
        await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
        isEmpty,
      );
    } finally {
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('bulk move keeps the picked order for every placement', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3, 2]),
    ))!;
    try {
      final picked = fixture.stacks.first.cards.take(2).toList();
      var outcomes = await boardModel(
        tester,
        moveEach(
          fixture.session,
          fixture.board,
          picked,
          destination(fixture, before: true),
        ),
      );
      expect(outcomes.map((o) => o.card.id), [100, 101]);
      expect(outcomes.map((o) => o.status), everyElement(BulkStatus.queued));
      expect(await boardModel(tester, column(fixture, 11)), [
        100,
        101,
        1100,
        1101,
      ]);
      final next = (await boardModel(
        tester,
        fixture.db.stackView(fixture.account.id, 1),
      )).first.cards;
      outcomes = await boardModel(
        tester,
        moveEach(
          fixture.session,
          fixture.board,
          next,
          destination(fixture, before: false),
        ),
      );
      expect(outcomes.map((o) => o.status), everyElement(BulkStatus.queued));
      expect(await boardModel(tester, column(fixture, 11)), [
        100,
        101,
        1100,
        1101,
        102,
      ]);
    } finally {
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('menu selects cards, archives them and queues one write each', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3]),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
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
      await tester.tap(
        find.descendant(
          of: boardTile(100),
          matching: find.byTooltip('Card actions'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select card'));
      await settleBoard(tester);
      expect(find.text('Selected: 1'), findsOneWidget);
      await tester.tap(
        find.descendant(of: boardTile(101), matching: find.byType(Checkbox)),
      );
      await settleBoard(tester);
      expect(find.text('Selected: 2'), findsOneWidget);
      expect(
        tester
            .getSize(
              find.descendant(
                of: boardTile(101),
                matching: find.byType(Checkbox),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byTooltip('Archive selected cards'));
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(writes.map((w) => w.kind), ['archiveCard', 'archiveCard']);
      expect(writes.map((w) => w.cardId).toSet(), {100, 101});
      expect(find.text('Selected: 2'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('archived cards can be selected and restored, but not moved', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [2], archivedLeading: true),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
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
      await tester.tap(find.byTooltip('Board actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archived cards'));
      await settleBoard(tester);
      await tester.tap(
        find.descendant(
          of: boardTile(99),
          matching: find.byTooltip('Card actions'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Move card'), findsNothing);
      await tester.tap(find.text('Select card'));
      await settleBoard(tester);
      expect(find.text('Selected: 1'), findsOneWidget);
      expect(find.byTooltip('Move selected cards'), findsNothing);
      await tester.tap(find.byTooltip('Restore selected cards from archive'));
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(writes.map((w) => w.kind), ['unarchiveCard']);
      expect(writes.single.cardId, 99);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('select all picks every shown card and respects the filter', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3, 2]),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
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
      // Matches card 101 in the first column and card 1101 in the second.
      await tester.enterText(find.byType(TextField).first, '101');
      await settleBoard(tester);
      await tester.tap(
        find.descendant(
          of: boardTile(101),
          matching: find.byTooltip('Card actions'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select card'));
      await settleBoard(tester);
      await tester.tap(find.byTooltip('Select all shown cards'));
      await settleBoard(tester);
      expect(find.text('Selected: 2'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('failed cards stay selected and can be retried from the result', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3]),
    ))!;
    try {
      final cards = fixture.stacks.first.cards;
      final selection = BoardSelection()
        ..toggle(cards[0])
        ..toggle(cards[1])
        ..toggle(cards[2]);
      final calls = <List<int>>[];
      late BuildContext context;
      await tester.pumpWidget(
        boardTestApp(
          Scaffold(
            body: Builder(
              builder: (c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      Future<List<BulkOutcome>> action(List<DeckCard> picked) async {
        calls.add([for (final card in picked) card.id]);
        return [
          for (final card in picked)
            BulkOutcome(
              card,
              calls.length == 1
                  ? switch (card.id) {
                      100 => BulkStatus.queued,
                      101 => BulkStatus.failed,
                      _ => BulkStatus.blocked,
                    }
                  : BulkStatus.queued,
              calls.length == 1 && card.id != 100
                  ? StateError(
                      card.id == 101 ? 'card_unavailable' : 'permission_denied',
                    )
                  : null,
            ),
        ];
      }

      final done = runBulkAction(context, selection, action);
      await settleBoard(tester);
      expect(find.text('Result per card'), findsOneWidget);
      expect(
        find.text('Saved on this device: 1, failed: 1, no permission: 1.'),
        findsOneWidget,
      );
      expect(find.text('No permission, nothing changed'), findsOneWidget);
      expect(selection.cards.map((card) => card.id), [101, 102]);
      await tester.tap(find.text('Retry failed (1)'));
      await settleBoard(tester);
      await boardModel(tester, done);
      expect(calls, [
        [100, 101, 102],
        [101],
      ]);
      expect(selection.cards.map((card) => card.id), [102]);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('result dialog fits 200% text with 48dp buttons', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cards = [
      for (var id = 1; id <= 4; id++)
        DeckCard.fromJson({
          'id': id,
          'stackId': 1,
          'title': 'Card with a rather long title number $id',
          'description': '',
          'order': 0,
          'type': 'plain',
          'owner': 'user',
        }),
    ];
    await tester.pumpWidget(
      boardTestApp(
        BulkResultDialog(
          outcomes: [
            for (final card in cards)
              BulkOutcome(
                card,
                BulkStatus.failed,
                StateError('card_unavailable'),
              ),
          ],
        ),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.widgetWithText(FilledButton, 'Retry failed (4)'))
          .height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('a running bulk action shows progress and blocks a second run', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [2]),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1000);
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
      await tester.tap(
        find.descendant(
          of: boardTile(100),
          matching: find.byTooltip('Card actions'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select card'));
      await settleBoard(tester);
      await tester.tap(find.byTooltip('Select all shown cards'));
      await settleBoard(tester);
      await tester.tap(find.byTooltip('Archive selected cards'));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.archive_outlined),
            )
            .onPressed,
        isNull,
      );
      await settleBoard(tester);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(writes.map((w) => w.kind), ['archiveCard', 'archiveCard']);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });
}
