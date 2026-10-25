import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/data/card_edits.dart';
import 'package:nextclouddeck/features/board_card_tile.dart';
import 'package:nextclouddeck/features/board_drag.dart';
import 'package:nextclouddeck/features/card_detail.dart';

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

  Future<DeckCard> saveCard(BoardFixture fixture, JsonObject fields) async {
    final card = DeckCard.fromJson({
      ...fixture.stacks.first.cards.first.raw,
      ...fields,
    });
    await fixture.db.saveStacks(
      fixture.account.id,
      fixture.account.generation,
      1,
      [
        DeckStack.fromJson({
          ...fixture.stacks.first.raw,
          'cards': [card.raw],
        }),
      ],
      null,
    );
    return card;
  }

  test('completion uses the current cached card and is idempotent', () async {
    final fixture = await BoardFixture.create(counts: [1]);
    try {
      final stale = fixture.stacks.first.cards.first;
      await saveCard(fixture, {
        'done': null,
        'description': 'Changed elsewhere before this tap',
        'duedate': '2030-01-15T12:00:00Z',
      });
      await setCardCompleted(fixture.session, 1, stale, true);
      final first = (await fixture.db.writesFor(fixture.account.id)).single;
      final proposal = jsonDecode(first.proposal) as Map<String, dynamic>;
      expect(DateTime.tryParse(proposal['done'] as String), isNotNull);
      expect(
        jsonDecode(first.base!)['description'],
        'Changed elsewhere before this tap',
      );
      expect(jsonDecode(first.base!)['duedate'], '2030-01-15T12:00:00Z');
      await setCardCompleted(fixture.session, 1, stale, true);
      final writes = await fixture.db.writesFor(fixture.account.id);
      expect(writes.single.id, first.id);
      expect(writes.single.proposal, first.proposal);
    } finally {
      await fixture.close();
    }
  });

  test('completion can be cleared without changing the other fields', () async {
    final fixture = await BoardFixture.create(counts: [1]);
    try {
      final card = await saveCard(fixture, {'done': '2030-01-15T12:00:00Z'});
      await setCardCompleted(fixture.session, 1, card, false);
      final write = (await fixture.db.writesFor(fixture.account.id)).single;
      expect(jsonDecode(write.proposal), {'done': null});
      expect(jsonDecode(write.base!)['description'], card.description);
    } finally {
      await fixture.close();
    }
  });

  test(
    'completion rejects revoked rights, unsupported cards and stale accounts',
    () async {
      final fixture = await BoardFixture.create(counts: [1]);
      try {
        final card = fixture.stacks.first.cards.first;
        await expectLater(
          setCardCompleted(fixture.session, 1, card, true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'reason',
              'unsupported_operation',
            ),
          ),
        );
        await saveCard(fixture, {'done': null});
        await fixture.db.saveBoards(
          fixture.account.id,
          fixture.account.generation,
          [
            DeckBoard.fromJson({
              ...fixture.board.raw,
              'permissions': {
                'PERMISSION_READ': true,
                'PERMISSION_EDIT': false,
              },
            }),
          ],
          null,
        );
        await expectLater(
          setCardCompleted(fixture.session, 1, card, true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'reason',
              'permission_denied',
            ),
          ),
        );
        await (fixture.db.update(
          fixture.db.storedAccounts,
        )..where((row) => row.id.equals(fixture.account.id))).write(
          StoredAccountsCompanion(
            generation: Value(fixture.account.generation + 1),
          ),
        );
        await expectLater(
          setCardCompleted(fixture.session, 1, card, true),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'reason',
              'account_unavailable',
            ),
          ),
        );
        expect(await fixture.db.writesFor(fixture.account.id), isEmpty);
      } finally {
        await fixture.close();
      }
    },
  );

  testWidgets(
    'inline checkbox saves once without opening or dragging the card',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => BoardFixture.create(counts: [1]),
      ))!;
      final activity = BoardDragActivity();
      try {
        final initial = (await tester.runAsync(
          () => saveCard(fixture, {'done': null}),
        ))!;
        await tester.pumpWidget(
          boardTestApp(
            Scaffold(
              body: StreamBuilder<DeckCard?>(
                stream: fixture.db.watchCard(fixture.account.id, 1, initial.id),
                initialData: initial,
                builder: (context, snapshot) => BoardCardTile(
                  session: fixture.session,
                  board: fixture.board,
                  card: snapshot.data!,
                  editable: true,
                  activity: activity,
                ),
              ),
            ),
          ),
        );
        await settleBoard(tester);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        await tester.tap(find.byType(Checkbox));
        await settleBoard(tester);
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(writes.length, 1);
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
        expect(find.byType(CardScreen), findsNothing);
        expect(activity.value, isNull);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        activity.dispose();
        await boardModel(tester, fixture.close());
      }
    },
  );
}
