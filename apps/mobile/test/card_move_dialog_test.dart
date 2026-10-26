import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/board_moves.dart';
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

  Future<DeckBoard> addTarget(BoardFixture fixture, {bool edit = true}) async {
    final target = DeckBoard.fromJson({
      ...fixture.board.raw,
      'id': 2,
      'title': 'Destination',
      'permissions': {
        'PERMISSION_READ': true,
        'PERMISSION_EDIT': edit,
        'PERMISSION_MANAGE': false,
      },
      'labels': <Object?>[],
    });
    await fixture.db.saveBoards(
      fixture.account.id,
      fixture.account.generation,
      [fixture.board, target],
      null,
    );
    await fixture.db.saveStacks(
      fixture.account.id,
      fixture.account.generation,
      2,
      [
        DeckStack.fromJson({
          'id': 20,
          'boardId': 2,
          'title': 'Delivery',
          'order': 0,
          'cards': <Object?>[],
        }),
      ],
      null,
    );
    return target;
  }

  Future<void> openMove(
    WidgetTester tester,
    BoardFixture fixture, {
    VoidCallback? onTransferred,
  }) async {
    await tester.pumpWidget(
      boardTestApp(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showBoardCardMove(
                context,
                fixture.session,
                fixture.board,
                fixture.stacks.first.cards.first,
                onTransferred: onTransferred,
              ),
              child: const Text('Open move'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open move'));
    await settleBoard(tester);
  }

  Future<void> selectTarget(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<(String, int?)>(('move-board', 1))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Destination').last);
    await settleBoard(tester);
  }

  testWidgets('offline transfer keeps its identity and named destination', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    try {
      await boardModel(tester, addTarget(fixture));
      var transferred = false;
      await openMove(tester, fixture, onTransferred: () => transferred = true);
      await selectTarget(tester);
      expect(find.text('Delivery'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Move card'));
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(writes.single.kind, 'cardTransfer');
      expect(writes.single.cardId, 100);
      expect(
        jsonDecode(writes.single.proposal),
        containsPair('destinationBoardId', 2),
      );
      expect(
        jsonDecode(writes.single.proposal),
        containsPair('destinationStackId', 20),
      );
      expect(jsonDecode(writes.single.proposal), containsPair('before', false));
      expect(transferred, isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('read-only destination is absent from the move choices', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    try {
      await boardModel(tester, addTarget(fixture, edit: false));
      await openMove(tester, fixture);
      await tester.tap(
        find.byKey(const ValueKey<(String, int?)>(('move-board', 1))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Destination'), findsNothing);
      expect(
        await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
        isEmpty,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets(
    'lost target permission does not queue a transfer or leave detail',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await boardModel(tester, addTarget(fixture));
        var transferred = false;
        await openMove(
          tester,
          fixture,
          onTransferred: () => transferred = true,
        );
        await selectTarget(tester);
        await boardModel(tester, addTarget(fixture, edit: false));
        await tester.tap(find.widgetWithText(FilledButton, 'Move card'));
        await settleBoard(tester);
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
        expect(transferred, isFalse);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets('refresh cannot replace a removed explicit target column', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    try {
      await boardModel(tester, addTarget(fixture));
      await openMove(tester, fixture);
      await selectTarget(tester);
      await boardModel(
        tester,
        fixture.db.saveStacks(
          fixture.account.id,
          fixture.account.generation,
          2,
          [
            DeckStack.fromJson({
              'id': 21,
              'boardId': 2,
              'title': 'Other column',
              'order': 0,
              'cards': <Object?>[],
            }),
          ],
          null,
        ),
      );
      await tester.tap(find.byTooltip('Refresh'));
      await settleBoard(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Move card'),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(CardMoveDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('refresh keeps a missing relative anchor unselected', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    try {
      await openMove(tester, fixture);
      await tester.tap(
        find.byKey(
          const ValueKey<(String, int, int?, String)>((
            'move-placement',
            1,
            10,
            'end',
          )),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('After a card').last);
      await tester.pumpAndSettle();
      await boardModel(
        tester,
        fixture.db.saveStacks(
          fixture.account.id,
          fixture.account.generation,
          1,
          [
            DeckStack.fromJson({
              ...fixture.stacks.first.raw,
              'cards': [fixture.stacks.first.cards.first.raw],
            }),
          ],
          null,
        ),
      );
      await tester.tap(find.byTooltip('Refresh'));
      await settleBoard(tester);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Move card'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('After a card'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets(
    'move warns by label name when the destination cannot create it',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await boardModel(tester, addTarget(fixture));
        await boardModel(
          tester,
          fixture.db.saveStacks(
            fixture.account.id,
            fixture.account.generation,
            1,
            [
              DeckStack.fromJson({
                ...fixture.stacks.first.raw,
                'cards': [
                  {
                    ...fixture.stacks.first.cards.first.raw,
                    'labels': [
                      {'id': 8, 'title': 'Planning', 'color': 'ff0000'},
                    ],
                  },
                ],
              }),
            ],
            null,
          ),
        );
        await openMove(tester, fixture);
        await selectTarget(tester);
        expect(find.textContaining('Planning'), findsOneWidget);
        expect(find.textContaining('ff0000'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );
}
