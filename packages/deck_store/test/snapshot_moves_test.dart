import 'dart:convert';
import 'dart:io';

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
    int? modified = 10,
  }) => DeckStack.fromJson({
    'id': stackId,
    'boardId': boardId,
    'title': 'Column',
    'order': 0,
    'cards': [
      if (cardId != null)
        {
          ...cardJson(id: cardId),
          'stackId': stackId,
          'lastModified': ?modified,
        },
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

  for (final modified in <int?>[10, null]) {
    test('empty source keeps move identity with timestamp $modified', () async {
      final old = snapshot(1, 2, cardId: 8, modified: modified);
      await save(1, old, 0);
      await database.saveCardDraft(account, 1, 2, {
        'description': 'My text',
      }, original: old.cards.single);
      await database.saveEditorDraft(account, 'moving-draft', 1, 2, {
        'description': 'My draft text',
      }, old.cards.single);
      await database.saveAttachments(account, 1, 8, [
        DeckAttachment.fromJson({
          'id': 7,
          'cardId': 8,
          'type': 'file',
          'data': 'report.txt',
          'lastModified': 10,
        }),
      ], 0);
      await save(1, snapshot(1, 2), 0);
      await save(3, snapshot(3, 4, cardId: 8, modified: modified), 0);
      // A caller must recover a snapshot rejected by a concurrent invalidation.
      if ((await database.stackView(account.id, 3)).single.cards.isEmpty) {
        await save(
          3,
          snapshot(3, 4, cardId: 8, modified: modified),
          (await database.account(account.id))!.contentEpoch,
        );
      }
      await save(1, old, 0);
      expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
      expect(
        (await database.stackView(account.id, 3)).single.cards.single.id,
        8,
      );
      final pending = (await database.writesFor(account.id)).single;
      expect(pending.boardId, 3);
      expect(pending.stackId, 4);
      expect(pending.state, 'conflict');
      final draft = (await database.editorDraft(account.id, 'moving-draft'))!;
      expect(draft.boardId, 3);
      expect(draft.stackId, 4);
      expect(jsonDecode(draft.payload)['description'], 'My draft text');
      expect(jsonDecode(draft.base!)['stackId'], 2);
      expect(jsonDecode(pending.proposal)['description'], 'My text');
      expect(
        (await database.select(database.storedAttachments).get())
            .single
            .boardId,
        3,
      );
    });

    test(
      'empty source rejects its old in-flight snapshot with timestamp $modified',
      () async {
        final old = snapshot(1, 2, cardId: 8, modified: modified);
        await save(1, old, 0);
        await save(1, snapshot(1, 2), 0);
        await save(1, old, 0);
        expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
        expect(await database.hasCachedCard(account.id, 1, 8), isFalse);
        expect(await database.cachedCardScopes(account.id), isEmpty);
      },
    );
  }

  test(
    'missing identity survives reopening the database without the card body',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'owndeck-snapshot-locations-',
      );
      final file = File('${folder.path}/cards.sqlite');
      var store = DeckDatabase(NativeDatabase(file));
      try {
        final savedAccount = await AccountRepository(
          store,
          MemoryVault(),
        ).add(credentials('user'));
        await store.saveBoards(savedAccount.id, savedAccount.generation, [
          board(1, 'Source', edit: true),
          board(3, 'Destination', edit: true),
        ], null);
        final old = snapshot(1, 2, cardId: 8);
        await store.saveStacks(savedAccount.id, savedAccount.generation, 1, [
          old,
        ], null);
        await store.saveCardDraft(savedAccount, 1, 2, {
          'description': 'Own text',
        }, original: old.cards.single);
        await store.saveStacks(
          savedAccount.id,
          savedAccount.generation,
          1,
          [snapshot(1, 2)],
          null,
          contentEpoch: 0,
        );
        final identity = (await store.select(store.storedCards).get()).single;
        expect(jsonDecode(identity.payload), {
          '_snapshotMissing': true,
          'id': 8,
          'stackId': 2,
          'lastModified': 10,
        });
        await store.close();
        store = DeckDatabase(NativeDatabase(file));
        final restored = (await store.account(savedAccount.id))!;
        await store.saveStacks(
          restored.id,
          restored.generation,
          3,
          [snapshot(3, 4, cardId: 8)],
          null,
          contentEpoch: restored.contentEpoch,
        );
        final pending = (await store.writesFor(restored.id)).single;
        expect(pending.boardId, 3);
        expect(pending.stackId, 4);
        expect(jsonDecode(pending.proposal)['description'], 'Own text');
        expect(
          (await store.stackView(restored.id, 3)).single.cards.single.id,
          8,
        );
      } finally {
        await store.close();
        await folder.delete(recursive: true);
      }
    },
  );

  test(
    'a moved draft created before server acknowledgement keeps the new destination',
    () async {
      final id = await database.saveCardDraft(account, 1, 2, {
        'title': 'New card',
      });
      final write = (await database.writesFor(account.id)).single;
      final local = DeckCard.fromJson(cardJson(id: -write.sequence));
      await database.saveEditorDraft(account, 'local-draft', 1, 2, {
        'description': 'Draft after creation',
      }, local);
      await database.acquireLease(account, 'creator');
      await database.startWrite(account, 'creator', id);
      await database.confirmCard(
        account,
        'creator',
        write,
        DeckCard.fromJson(cardJson(id: 18)),
      );
      await database.releaseLease(account.id, 'creator');
      await save(
        1,
        snapshot(1, 2),
        (await database.account(account.id))!.contentEpoch,
      );
      await save(
        3,
        snapshot(3, 4, cardId: 18),
        (await database.account(account.id))!.contentEpoch,
      );
      final draft = (await database.editorDraft(account.id, 'local-draft'))!;
      expect(draft.cardId, 18);
      expect(draft.boardId, 3);
      expect(draft.stackId, 4);
      await database.publishEditorDraft(
        account,
        draft.draftKey,
        draft.boardId,
        draft.stackId,
        {'description': 'Draft after creation'},
        DeckCard.fromJson(object(jsonDecode(draft.base!))),
      );
      final queued = (await database.writesFor(account.id)).single;
      expect(queued.cardId, 18);
      expect(queued.boardId, 3);
      expect(queued.stackId, 4);
      expect(
        jsonDecode(queued.proposal)['description'],
        'Draft after creation',
      );
    },
  );

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

  test(
    'an applied edit does not project a moved card back into its old stack',
    () async {
      final original = snapshot(1, 2, cardId: 8).cards.single;
      final id = await database.saveCardDraft(account, 1, 2, {
        'description': 'Accepted edit',
      }, original: original);
      await database.acquireLease(account, 'sender');
      await database.startWrite(account, 'sender', id);
      final write = (await database.writesFor(account.id)).single;
      await database.markApplied(account, 'sender', write, {
        'boardId': 1,
        'stackId': 2,
        'cardId': 8,
        'acceptedCard': {...original.raw, 'description': 'Accepted edit'},
      });
      await database.releaseLease(account.id, 'sender');
      await save(3, snapshot(3, 4, cardId: 8, modified: 11), 0);
      expect((await database.stackView(account.id, 1)).single.cards, isEmpty);
      expect((await database.writesFor(account.id)).single.state, 'applied');
    },
  );
}
