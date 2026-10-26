import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_drag.dart';
import 'package:nextclouddeck/features/board_layout.dart';
import 'package:nextclouddeck/features/board_view.dart';

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
      expect(jsonDecode(writes.single.proposal), {
        'stackId': 10,
        'order': 2,
        'anchorCardId': 102,
        'before': false,
      });
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
