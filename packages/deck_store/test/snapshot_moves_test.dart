import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late DeckDatabase database;
  late StoredAccount account;

  DeckStack snapshot(
    int boardId,
    int stackId, {
    int? cardId,
    int modified = 10,
  }) => DeckStack.fromJson({
    'id': stackId,
    'boardId': boardId,
    'title': 'Column',
    'order': 0,
    'cards': [
      if (cardId != null)
        {...cardJson(id: cardId), 'stackId': stackId, 'lastModified': modified},
    ],
  });

  Future<void> save(int boardId, DeckStack stack, int epoch) =>
      database.saveStacks(
        account.id,
        account.generation,
        boardId,
        [stack],
        'etag-$boardId',
        contentEpoch: epoch,
      );

  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Source', edit: true),
      board(3, 'Destination', edit: true),
    ], null);
    await save(1, snapshot(1, 2, cardId: 8), 0);
    await save(3, snapshot(3, 4), 0);
  });
  tearDown(() => database.close());

  for (final sourceFinishesFirst in [false, true]) {
    test(
      'cross-board move survives source-first=$sourceFinishesFirst',
      () async {
        final old = snapshot(1, 2, cardId: 8);
        if (sourceFinishesFirst) await save(1, old, 0);
        await save(3, snapshot(3, 4, cardId: 8, modified: 11), 0);
        if (!sourceFinishesFirst) await save(1, old, 0);

        expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
        final moved = (await database.stackView(
          account.id,
          3,
        )).single.cards.single;
        expect(moved.id, 8);
        expect(moved.stackId, 4);
        expect(moved.raw['lastModified'], 11);
        expect(
          (await database.account(account.id))!.contentEpoch,
          greaterThan(0),
        );
      },
    );
  }

  test('moved card keeps files and own text in its new board', () async {
    final original = snapshot(1, 2, cardId: 8).cards.single;
    await database.saveAttachments(account, 1, 8, [
      DeckAttachment.fromJson({
        'id': 7,
        'type': 'file',
        'cardId': 8,
        'data': 'report.txt',
        'lastModified': 10,
        'deletedAt': 0,
      }),
    ], 0);
    await database.saveCardDraft(account, 1, 2, {
      'description': 'My unsent text',
    }, original: original);
    await database.saveEditorDraft(account, 'draft', 1, 2, {
      'description': 'My editor text',
    }, original);
    await save(3, snapshot(3, 4, cardId: 8, modified: 11), 0);

    final pending = (await database.writesFor(account.id)).single;
    expect(pending.state, 'conflict');
    expect(pending.boardId, 3);
    expect(pending.stackId, 4);
    expect(jsonDecode(pending.proposal)['description'], 'My unsent text');
    expect(jsonDecode(pending.remote!)['stackId'], 4);
    expect(
      (await database.editorDraft(account.id, 'draft'))!.payload,
      contains('My editor text'),
    );
    expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
    final attachmentRow =
        (await database.select(database.storedAttachments).get()).single;
    expect(attachmentRow.boardId, 3);
    await database.revokeBoardAccess(account, 1);
    expect(await database.attachmentsFor(account.id, 8), hasLength(1));
  });

  test('late lower-version snapshot cannot move a card back', () async {
    await save(3, snapshot(3, 4, cardId: 8, modified: 11), 0);
    final epoch = (await database.account(account.id))!.contentEpoch;
    await save(1, snapshot(1, 2, cardId: 8), epoch);
    expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
    expect((await database.stackView(account.id, 3)).single.cards.single.id, 8);
  });

  test(
    'single-card read invalidates an already running board snapshot',
    () async {
      final destination = snapshot(3, 4, cardId: 8, modified: 11);
      expect(
        await database.saveReadCard(
          account,
          DeckCardContext(
            board: board(3, 'Destination', edit: true),
            stack: destination,
            card: destination.cards.single,
          ),
          0,
        ),
        isTrue,
      );
      await save(1, snapshot(1, 2, cardId: 8), 0);
      expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
      expect(
        (await database.stackView(account.id, 3)).single.cards.single.id,
        8,
      );
    },
  );

  test('same-board move also rejects the old in-flight snapshot', () async {
    await save(1, snapshot(1, 6, cardId: 8, modified: 11), 0);
    await save(1, snapshot(1, 2, cardId: 8), 0);
    final result = (await database.stackView(account.id, 1)).single;
    expect(result.id, 6);
    expect(result.cards.single.stackId, 6);
  });
}
