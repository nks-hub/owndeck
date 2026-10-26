import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/board_drag.dart';
import 'package:nextclouddeck/features/board_layout.dart';
import 'package:nextclouddeck/features/board_moves.dart';
import 'package:nextclouddeck/features/card_column.dart';

import 'board_test_support.dart';

void _size(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

({BoardCardDropTarget anchor, Rect rect})? _at(
  WidgetTester tester,
  Offset point,
) {
  for (final element in find.byType(BoardCardDropTarget).evaluate()) {
    final anchor = element.widget as BoardCardDropTarget;
    final render = element.renderObject;
    if (anchor.cardId == null || render is! RenderBox) continue;
    final rect = render.localToGlobal(Offset.zero) & render.size;
    if (rect.contains(point)) return (anchor: anchor, rect: rect);
  }
  return null;
}

Widget _canvas(BoardFixture fixture) => boardTestApp(
  Scaffold(
    body: BoardLayout(
      session: fixture.session,
      board: fixture.board,
      columns: [
        for (final stack in fixture.stacks) BoardColumnView(stack, false),
      ],
      archivedView: false,
      mode: BoardViewMode.columns,
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null),
  );

  for (final horizontal in [false, true]) {
    testWidgets(
      'stationary pointer drops on the visible card after ${horizontal ? 'horizontal' : 'vertical'} auto-scroll',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => BoardFixture.create(
            counts: horizontal ? List.filled(10, 20) : [40, 0],
          ),
        ))!;
        _size(tester, const Size(900, 500));
        try {
          await tester.pumpWidget(_canvas(fixture));
          await tester.pump();
          final pointer = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey(('drag-card', 100)))),
          );
          await tester.pump(
            kLongPressTimeout + const Duration(milliseconds: 100),
          );
          final point = horizontal
              ? const Offset(888, 180)
              : const Offset(180, 482);
          await pointer.moveTo(point);
          for (var frame = 0; frame < 100; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          for (
            var frame = 0;
            frame < 20 && _at(tester, point) == null;
            frame++
          ) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          final target = _at(tester, point);
          expect(target, isNotNull);
          if (horizontal) {
            expect(target!.anchor.stackId, greaterThan(12));
          } else {
            expect(target!.anchor.cardId, greaterThan(104));
          }
          final targetCards = fixture.stacks
              .firstWhere((s) => s.id == target.anchor.stackId)
              .cards
              .where((c) => activeBoardCard(c) && c.id != 100)
              .toList();
          final expectedOrder =
              targetCards.indexWhere((c) => c.id == target.anchor.cardId) +
              (point.dy >= target.rect.center.dy ? 1 : 0);
          await pointer.up();
          await settleBoard(tester);
          final writes = await boardModel(
            tester,
            fixture.db.writesFor(fixture.account.id),
          );
          expect(jsonDecode(writes.single.proposal), {
            'stackId': target.anchor.stackId,
            'order': expectedOrder,
            'anchorCardId': target.anchor.cardId,
            'before': point.dy < target.rect.center.dy,
          });
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await boardModel(tester, fixture.close());
        }
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  }

  testWidgets(
    'a cached card behind the fixed column heading is not a drop target',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => BoardFixture.create(counts: [40, 0]),
      ))!;
      _size(tester, const Size(900, 500));
      try {
        await tester.pumpWidget(_canvas(fixture));
        await tester.pump();
        final column = find.byWidgetPredicate(
          (w) => w is CardColumn && w.stack.id == 10,
        );
        final scrollable = find
            .descendant(of: column, matching: find.byType(Scrollable))
            .first;
        tester.state<ScrollableState>(scrollable).position.jumpTo(150);
        await tester.pump();
        final point = tester.getCenter(
          find.byKey(const ValueKey(('column-add-card', 10))),
        );
        expect(
          _at(tester, point),
          isNotNull,
          reason: 'The regression requires a cached row beneath the heading.',
        );
        final pointer = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey(('drag-card', 102)))),
        );
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await pointer.moveTo(point);
        await tester.pump();
        await pointer.up();
        await settleBoard(tester);
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'mobile tab hover switches columns and accepts the drop',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      _size(tester, const Size(390, 800));
      try {
        await tester.pumpWidget(
          boardTestApp(
            BoardScreen(session: fixture.session, board: fixture.board),
            preferences: AppPreferences(store: MemoryBoardPreferences()),
          ),
        );
        await settleBoard(tester);
        final pointer = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey(('drag-card', 100)))),
        );
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await pointer.moveTo(tester.getCenter(find.text('Column 2 (0)')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        final destination = find.byKey(
          boardDropKey(
            fixture.account.id,
            fixture.account.generation,
            1,
            11,
            null,
          ),
        );
        expect(destination, findsOneWidget);
        expect(
          DefaultTabController.of(tester.element(find.byType(TabBar))).index,
          1,
        );
        expect(
          const Rect.fromLTWH(
            0,
            0,
            390,
            800,
          ).contains(tester.getCenter(destination)),
          isTrue,
        );
        await pointer.moveTo(tester.getCenter(destination));
        await tester.pump();
        await pointer.up();
        await settleBoard(tester);
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(jsonDecode(writes.single.proposal), {
          'stackId': 11,
          'order': 0,
          'anchorCardId': null,
          'before': false,
        });
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets(
    'permission revoked during a drag prevents a queued move',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      _size(tester, const Size(900, 700));
      try {
        await tester.pumpWidget(
          boardTestApp(
            BoardScreen(session: fixture.session, board: fixture.board),
            preferences: AppPreferences(store: MemoryBoardPreferences()),
          ),
        );
        await settleBoard(tester);
        final pointer = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey(('drag-card', 100)))),
        );
        await tester.pump(
          kLongPressTimeout + const Duration(milliseconds: 100),
        );
        await boardModel(
          tester,
          fixture.db.saveBoards(
            fixture.account.id,
            fixture.account.generation,
            [
              DeckBoard.fromJson({
                ...fixture.board.raw,
                'permissions': {'PERMISSION_READ': true},
              }),
            ],
            null,
          ),
        );
        await settleBoard(tester);
        final destination = find.byKey(
          boardDropKey(
            fixture.account.id,
            fixture.account.generation,
            1,
            11,
            null,
          ),
        );
        await pointer.moveTo(tester.getCenter(destination));
        await tester.pump();
        await pointer.up();
        await settleBoard(tester);
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
        expect(find.byType(LongPressDraggable<BoardCardDrag>), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
