import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/pending.dart';

import 'board_test_support.dart';

const _moved = 'The card has moved. Its position is still being confirmed.';
const _retry =
    'Check the card on the server before sending the remaining change again.';

Future<void> _using(
  WidgetTester tester,
  String state,
  Future<void> Function(BoardFixture fixture, PendingWrite write) run, {
  bool accepted = true,
  bool awaitingTransferReadback = false,
}) async {
  final fixture = (await tester.runAsync(
    () => BoardFixture.create(counts: [1]),
  ))!;
  final write = (await tester.runAsync(() async {
    await fixture.db.deferSync(
      fixture.account,
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    final destination = DeckBoard.fromJson({
      ...fixture.board.raw,
      'id': 2,
      'title': 'Destination board',
    });
    final card = fixture.stacks.first.cards.first;
    final transferred = DeckCard.fromJson({...card.raw, 'stackId': 20});
    await fixture.db.saveBoards(
      fixture.account.id,
      fixture.account.generation,
      [fixture.board, destination],
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
          'title': 'Ready',
          'order': 0,
          'cards': [if (accepted) transferred.raw],
        }),
      ],
      null,
    );
    final receipt = {
      'phase': 'transfer',
      'sourceBoardId': 1,
      'sourceStackId': 10,
      'boardId': 2,
      'stackId': 20,
      'cardId': 100,
      'acceptedCard': transferred.raw,
      'beforeCard': card.raw,
    };
    await fixture.db
        .into(fixture.db.pendingWrites)
        .insert(
          PendingWritesCompanion.insert(
            id: 'transfer-write',
            accountId: fixture.account.id,
            kind: 'cardTransfer',
            boardId: accepted && !awaitingTransferReadback ? 2 : 1,
            stackId: accepted && !awaitingTransferReadback ? 20 : 10,
            cardId: const Value(100),
            state: Value(state),
            error: Value(state == 'blocked' ? 'permission_denied' : null),
            proposal: jsonEncode({
              'phase': accepted && !awaitingTransferReadback
                  ? 'position'
                  : 'transfer',
              'title': card.title,
              'destinationBoardId': 2,
              'destinationStackId': 20,
              'anchorCardId': null,
              'before': false,
              if (accepted && !awaitingTransferReadback)
                'transferReceipt': receipt,
            }),
            base: Value(jsonEncode(accepted ? transferred.raw : card.raw)),
            remote: Value(
              accepted
                  ? jsonEncode(
                      awaitingTransferReadback ? receipt : transferred.raw,
                    )
                  : null,
            ),
          ),
        );
    return (await fixture.db.writesFor(fixture.account.id)).single;
  }))!;
  try {
    await tester.pumpWidget(
      boardTestApp(PendingScreen(session: fixture.session)),
    );
    await settleBoard(tester);
    await run(fixture, write);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await settleBoard(tester);
    await tester.runAsync(fixture.close);
  }
}

void _noInternalData() {
  for (final value in [
    'cardTransfer',
    'transferReceipt',
    'destinationBoardId',
    'destinationStackId',
    'sourceStackId',
    'anchorCardId',
  ]) {
    expect(find.textContaining(value), findsNothing);
  }
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ),
  );
  await settleBoard(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
  });

  testWidgets(
    'queued transfer shows destination names without claiming it moved',
    (tester) async {
      await _using(tester, 'queued', (fixture, write) async {
        expect(find.text('Move card'), findsOneWidget);
        expect(find.textContaining('Destination board'), findsOneWidget);
        expect(find.textContaining('Ready'), findsOneWidget);
        expect(find.text(_moved), findsNothing);
        _noInternalData();
      }, accepted: false);
    },
  );

  for (final state in ['blocked', 'uncertain', 'conflict']) {
    testWidgets(
      '$state positioning retry preserves accepted transfer and phase',
      (tester) async {
        await _using(tester, state, (fixture, write) async {
          expect(find.text('Move card'), findsOneWidget);
          expect(find.text(_moved), findsOneWidget);
          expect(find.textContaining('Ready'), findsOneWidget);
          _noInternalData();
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Retry'),
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
          await tester.pumpAndSettle();
          expect(find.text(_retry), findsOneWidget);
          await _confirm(tester);
          final updated = await boardModel(
            tester,
            fixture.db.writesFor(fixture.account.id),
          );
          expect(updated.single.state, 'queued');
          expect(updated.single.proposal, write.proposal);
          final proposal = jsonDecode(updated.single.proposal) as Map;
          expect(proposal['phase'], 'position');
          expect(proposal['transferReceipt'], isA<Map>());
          expect(updated.single.boardId, 2);
        });
      },
    );
  }

  testWidgets(
    'accepted transfer awaiting readback is already described as moved',
    (tester) async {
      await _using(tester, 'applied', (fixture, write) async {
        expect(find.text(_moved), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
        _noInternalData();
      }, awaitingTransferReadback: true);
    },
  );

  testWidgets(
    'discarding remaining positioning keeps the card in its destination',
    (tester) async {
      await _using(tester, 'blocked', (fixture, write) async {
        await tester.ensureVisible(
          find.widgetWithText(TextButton, 'Discard local change'),
        );
        await tester.tap(
          find.widgetWithText(TextButton, 'Discard local change'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Only this local change will be discarded. Nothing will be changed on the server.',
          ),
          findsOneWidget,
        );
        await _confirm(tester);
        final row = await boardModel(
          tester,
          (fixture.db.select(
            fixture.db.pendingWrites,
          )..where((row) => row.id.equals(write.id))).getSingle(),
        );
        expect(row.state, 'discarded');
        expect(row.proposal, write.proposal);
        final card = await boardModel(
          tester,
          fixture.db.watchCard(fixture.account.id, 2, 100).first,
        );
        expect(card!.stackId, 20);
      });
    },
  );
}
