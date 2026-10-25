import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_drag.dart';
import 'package:nextclouddeck/features/board_filters.dart';
import 'package:nextclouddeck/features/board_layout.dart';
import 'package:nextclouddeck/features/board_view.dart';
import 'package:nextclouddeck/features/card_summary.dart';

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

  DeckCard task({Object? due, Object? done, List<Object?>? assigned}) =>
      DeckCard.fromJson({
        'id': 1,
        'stackId': 10,
        'order': 0,
        'title': 'Prepare release',
        'description': 'Check the mobile package',
        'duedate': due,
        'done': done,
        'labels': [
          {'id': 7, 'title': 'Review', 'color': '008080'},
        ],
        'assignedUsers':
            assigned ??
            [
              {
                'type': 0,
                'participant': {'uid': 'editor', 'displayname': 'Editor'},
              },
            ],
      });

  test('board filters intersect query, member, label and calendar date', () {
    final now = DateTime(2030, 1, 15, 12);
    final card = task(due: DateTime(2030, 1, 15, 14).toIso8601String());
    const selected = BoardCardFilter(
      query: 'release mobile',
      memberId: 'editor',
      labelId: 7,
      due: BoardDueFilter.today,
      completion: BoardCompletionFilter.open,
    );
    expect(selected.matches(card, now: now), isTrue);
    expect(selected.withQuery('different').matches(card, now: now), isFalse);
    expect(const BoardCardFilter(memberId: '').matches(card), isFalse);
    expect(
      const BoardCardFilter(memberId: '').matches(task(assigned: [])),
      isTrue,
    );
    expect(
      const BoardCardFilter(due: BoardDueFilter.overdue).matches(
        task(
          due: DateTime(2030, 1, 14).toIso8601String(),
          done: '2030-01-14T12:00:00Z',
        ),
        now: now,
      ),
      isFalse,
    );
    expect(
      const BoardCardFilter(
        due: BoardDueFilter.upcoming,
      ).matches(task(due: DateTime(2030, 1, 16).toIso8601String()), now: now),
      isTrue,
    );
    expect(
      const BoardCardFilter(due: BoardDueFilter.noDate).matches(task()),
      isTrue,
    );
  });

  testWidgets(
    'card summary exposes working metadata without inventing counts',
    (tester) async {
      final card = DeckCard.fromJson({
        ...task(due: '2030-01-15T12:00:00Z', done: '2030-01-15T11:00:00Z').raw,
        'commentsCount': 3,
        'attachmentCount': 2,
        'syncState': 'queued',
      });
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          boardTestApp(
            Scaffold(
              body: Card(child: CardSummary(card: card)),
            ),
          ),
        );
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('Prepare release'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Assignees: Editor')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(RegExp('Comments: 3')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Attachments: 2')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Completed:')), findsOneWidget);
        expect(find.text('Queued'), findsOneWidget);
        await tester.pumpWidget(
          boardTestApp(
            Scaffold(
              body: Card(child: CardSummary(card: task())),
            ),
          ),
        );
        expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
        expect(find.byIcon(Icons.attach_file), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('filtered drag resolves its anchor in the complete column', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3]),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.runAsync(
        () => fixture.db.saveStacks(
          fixture.account.id,
          fixture.account.generation,
          1,
          [
            DeckStack.fromJson({
              ...fixture.stacks.first.raw,
              'cards': [
                for (final card in fixture.stacks.first.cards)
                  {
                    ...card.raw,
                    'title': card.id == 101 ? 'Hidden' : 'Shown ${card.id}',
                  },
              ],
            }),
          ],
          null,
        ),
      );
      await tester.pumpWidget(
        boardTestApp(
          BoardScreen(session: fixture.session, board: fixture.board),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
        ),
      );
      await settleBoard(tester);
      await tester.enterText(
        find.byKey(const ValueKey('board-card-search')),
        'Shown',
      );
      await settleBoard(tester);
      expect(boardTile(101), findsNothing);
      expect(
        tester
            .widget<BoardLayout>(find.byType(BoardLayout))
            .columns
            .first
            .cards
            .length,
        2,
      );
      final target = find.byKey(
        boardDropKey(
          fixture.account.id,
          fixture.account.generation,
          1,
          10,
          102,
        ),
      );
      await dragBoardCard(
        tester,
        100,
        tester.getBottomRight(target) - const Offset(20, 8),
      );
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(jsonDecode(writes.single.proposal), {'stackId': 10, 'order': 2});
      final stacks = await boardModel(
        tester,
        fixture.db.stackView(fixture.account.id, 1),
      );
      expect(stacks.first.cards.map((card) => card.id), [101, 102, 100]);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets(
    'board stays usable at large text in landscape and clears no-match filters',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => BoardFixture.create(counts: [2]),
      ))!;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 360);
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
        expect(find.byKey(const ValueKey('board-add-card')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.enterText(
          find.byKey(const ValueKey('board-card-search')),
          'missing',
        );
        await settleBoard(tester);
        expect(find.text('No cards match these filters.'), findsWidgets);
        final clear = find.widgetWithText(TextButton, 'Clear filters');
        await tester.ensureVisible(clear);
        await tester.tap(clear);
        await settleBoard(tester);
        expect(find.text('No cards match these filters.'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );
}
