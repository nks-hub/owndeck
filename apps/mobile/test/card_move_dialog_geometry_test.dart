import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/card_move_dialog.dart';

import 'board_test_support.dart';

Rect screenSemanticsRect(SemanticsNode node) {
  var transform = Matrix4.identity();
  SemanticsNode? current = node;
  while (current != null) {
    if (current.transform != null) transform = current.transform! * transform;
    current = current.parent;
  }
  return MatrixUtils.transformRect(transform, node.rect);
}

void main() {
  const channel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);
  });

  Future<void> scenario(
    WidgetTester tester,
    Size size,
    double scale,
    Future<void> Function(BoardFixture, Finder, Finder) check,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final semantics = tester.ensureSemantics();
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [1]),
    ))!;
    final target = DeckBoard.fromJson({
      ...fixture.board.raw,
      'id': 2,
      'title': 'Destination',
      'permissions': {
        'PERMISSION_READ': true,
        'PERMISSION_EDIT': true,
        'PERMISSION_MANAGE': false,
      },
      'labels': <Object?>[],
    });
    final card = DeckCard.fromJson({
      ...fixture.stacks.first.cards.first.raw,
      'labels': [
        {'id': 30, 'title': 'Source label', 'color': '008080'},
      ],
    });
    try {
      await boardModel(
        tester,
        fixture.db.saveBoards(fixture.account.id, fixture.account.generation, [
          fixture.board,
          target,
        ], null),
      );
      await boardModel(
        tester,
        fixture.db.saveStacks(
          fixture.account.id,
          fixture.account.generation,
          2,
          [
            DeckStack.fromJson({
              'id': 20,
              'boardId': 2,
              'title': 'Delivery',
              'order': 0,
              'cards': [
                {...card.raw, 'id': 200, 'stackId': 20, 'title': 'Anchor'},
              ],
            }),
          ],
          null,
        ),
      );
      await tester.pumpWidget(
        boardTestApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => CardMoveDialog(
                    session: fixture.session,
                    source: fixture.board,
                    card: card,
                    boards: [fixture.board, target],
                    stacks: fixture.stacks,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          scale: scale,
        ),
      );
      await tester.tap(find.text('Open'));
      await settleBoard(tester);
      final board = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<int> &&
            widget.key == const ValueKey<(String, int?)>(('move-board', 1)),
      );
      final submit = find.widgetWithText(FilledButton, 'Move card');
      await check(fixture, board, submit);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await boardModel(tester, fixture.close());
      semantics.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }

  Future<Finder> changeTarget(WidgetTester tester, Finder board) async {
    await tester.ensureVisible(board);
    await tester.tap(board);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Destination').last);
    await settleBoard(tester);
    return find.byKey(const ValueKey<(String, int?)>(('move-board', 2)));
  }

  testWidgets(
    'destination hints do not move the board field or action buttons',
    (tester) async {
      await scenario(tester, const Size(393, 852), 1, (
        fixture,
        board,
        submit,
      ) async {
        final beforeBoard = tester.getRect(board);
        final beforeSubmit = tester.getRect(submit);
        final beforeCancel = tester.getRect(
          find.widgetWithText(TextButton, 'Cancel'),
        );
        final selected = await changeTarget(tester, board);
        expect(find.textContaining('Source label'), findsOneWidget);
        expect(tester.getRect(selected), beforeBoard);
        expect(tester.getRect(submit), beforeSubmit);
        expect(
          tester.getRect(find.widgetWithText(TextButton, 'Cancel')),
          beforeCancel,
        );
        final node = tester.getSemantics(submit);
        final accessible = screenSemanticsRect(node);
        expect(accessible.center.dx, closeTo(beforeSubmit.center.dx, 1));
        expect(accessible.center.dy, closeTo(beforeSubmit.center.dy, 1));
        await tester.tapAt(
          screenSemanticsRect(tester.getSemantics(selected)).center,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Board').last);
        await settleBoard(tester);
        expect(
          find.byKey(const ValueKey<(String, int?)>(('move-board', 1))),
          findsOneWidget,
        );
      });
    },
  );

  for (final size in [const Size(393, 852), const Size(852, 393)]) {
    testWidgets('move actions stay reachable at 200 percent in $size', (
      tester,
    ) async {
      await scenario(tester, size, 2, (fixture, board, submit) async {
        final actions = tester.getRect(submit);
        final selected = await changeTarget(tester, board);
        expect(submit.hitTestable(), findsOneWidget);
        expect(
          find.widgetWithText(TextButton, 'Cancel').hitTestable(),
          findsOneWidget,
        );
        expect(tester.getRect(submit), actions);
        final placement = find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<String>,
        );
        await tester.ensureVisible(placement);
        await tester.tap(placement);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Before a card').last);
        await settleBoard(tester);
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.getRect(submit), actions);
        expect(
          find.byKey(
            const ValueKey<(String, int, int?, int?)>((
              'move-anchor',
              2,
              20,
              200,
            )),
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(selected);
        await tester.pumpAndSettle();
        final accessible = screenSemanticsRect(tester.getSemantics(selected));
        final visible = tester
            .getRect(selected)
            .intersect(tester.getRect(find.byType(SingleChildScrollView)));
        expect(visible.contains(accessible.center), isTrue);
        await tester.tapAt(
          screenSemanticsRect(tester.getSemantics(selected)).center,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Board').last);
        await settleBoard(tester);
        expect(
          find.byKey(const ValueKey<(String, int?)>(('move-board', 1))),
          findsOneWidget,
        );
      });
    });
  }
}
