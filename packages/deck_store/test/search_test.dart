import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

DeckBoard testBoard(
  int id, {
  String title = 'Project',
  bool read = true,
  bool archived = false,
  int deletedAt = 0,
}) => DeckBoard.fromJson({
  ...board(id, title, edit: true).raw,
  'archived': archived,
  'deletedAt': deletedAt,
  'permissions': {'PERMISSION_READ': read, 'PERMISSION_EDIT': true},
});

JsonObject testCard(
  int id, {
  String title = 'Task',
  String? due,
  Object? done,
  bool archived = false,
  int deletedAt = 0,
  List<Object?> assigned = const [],
}) => {
  ...cardJson(id: id),
  'title': title,
  'duedate': due,
  'done': done,
  'archived': archived,
  'deletedAt': deletedAt,
  'assignedUsers': assigned,
};

Object assigned(String user, {int type = 0}) => {
  'participant': {'uid': user},
  'type': type,
};

void main() {
  late DeckDatabase database;
  late MemoryVault vault;
  late AccountRepository accounts;
  late StoredAccount account;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    vault = MemoryVault();
    accounts = AccountRepository(database, vault);
    account = await accounts.add(
      credentials('login-alias'),
      userId: 'canonical-user',
    );
  });
  tearDown(() => database.close());

  Future<void> seed(
    StoredAccount target,
    DeckBoard board,
    List<JsonObject> cards,
  ) async {
    await database.saveBoards(target.id, target.generation, [board], null);
    await database.saveStacks(target.id, target.generation, board.id, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': board.id,
        'title': 'Planning',
        'order': 0,
        'cards': cards,
      }),
    ], null);
  }

  Future<List<int>> ids(CardSearchOptions options, {DateTime? now}) async =>
      (await database.searchCards(
        account.id,
        options,
        now: now,
      )).hits.map((hit) => hit.card.id).toList();

  test(
    'matching uses only the requested account and treats SQL wildcard characters literally',
    () async {
      await seed(account, testBoard(1), [
        testCard(8, title: 'Budget 50%_done'),
      ]);
      final other = await accounts.add(credentials('other'), userId: 'other');
      await seed(other, testBoard(1), [testCard(8, title: 'Foreign secret')]);
      expect(await ids(const CardSearchOptions(query: 'foreign')), isEmpty);
      expect(await ids(const CardSearchOptions(query: '%_')), [8]);
      expect(await ids(const CardSearchOptions(query: '%missing')), isEmpty);
      expect(
        (await database.searchCards(
          other.id,
          const CardSearchOptions(),
        )).hits.single.card.title,
        'Foreign secret',
      );
    },
  );

  test(
    'archive and completion are explicit filters while deleted and inaccessible data stay hidden',
    () async {
      await seed(account, testBoard(1), [
        testCard(1),
        testCard(2, archived: true),
        testCard(3, done: '2026-10-24T09:00:00Z'),
        testCard(4, deletedAt: 1),
      ]);
      expect(await ids(const CardSearchOptions()), [1]);
      expect(await ids(const CardSearchOptions(includeArchived: true)), [1, 2]);
      expect(
        await ids(
          const CardSearchOptions(
            includeArchived: true,
            includeCompleted: true,
          ),
        ),
        [1, 2, 3],
      );
      await database.saveBoards(account.id, account.generation, [
        testBoard(1, archived: true),
      ], null);
      expect(await ids(const CardSearchOptions()), isEmpty);
      expect(await ids(const CardSearchOptions(includeArchived: true)), [1, 2]);
      await database.saveBoards(account.id, account.generation, [
        testBoard(1, read: false),
      ], null);
      expect(
        await ids(
          const CardSearchOptions(
            includeArchived: true,
            includeCompleted: true,
          ),
        ),
        isEmpty,
      );
      await database.saveBoards(account.id, account.generation, [
        testBoard(1, deletedAt: 1),
      ], null);
      expect(
        await ids(
          const CardSearchOptions(
            includeArchived: true,
            includeCompleted: true,
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'my tasks matches canonical user assignment, not login alias, owner or a group with the same id',
    () async {
      await seed(account, testBoard(1), [
        testCard(1, assigned: [assigned('canonical-user')]),
        testCard(2, assigned: [assigned('login-alias')]),
        {...testCard(3), 'owner': 'canonical-user'},
        testCard(4, assigned: [assigned('canonical-user', type: 1)]),
        testCard(
          5,
          assigned: [
            {
              'participant': {'primaryKey': 'canonical-user'},
              'type': 0,
            },
          ],
        ),
        testCard(
          6,
          assigned: [
            {'participant': 'canonical-user', 'type': 0},
          ],
        ),
      ]);
      expect(await ids(const CardSearchOptions(mineOnly: true)), [1, 5, 6]);
    },
  );

  test(
    'missing canonical identity does not fall back to the login name',
    () async {
      final unknown = await accounts.add(credentials('unverified'));
      await seed(unknown, testBoard(1), [
        testCard(8, assigned: [assigned('unverified')]),
      ]);
      final result = await database.searchCards(
        unknown.id,
        const CardSearchOptions(mineOnly: true),
      );
      expect(result.identityKnown, isFalse);
      expect(result.hits, isEmpty);
    },
  );

  test(
    'date filters use local calendar boundaries and the exact overdue instant',
    () async {
      final day = DateTime(2026, 10, 25);
      final next = DateTime(2026, 10, 26);
      final now = DateTime(2026, 10, 25, 12);
      String stamp(DateTime time) => time.toUtc().toIso8601String();
      await seed(account, testBoard(1), [
        testCard(1, due: stamp(day.subtract(const Duration(minutes: 1)))),
        testCard(2, due: stamp(day)),
        testCard(3, due: stamp(now)),
        testCard(4, due: stamp(next.subtract(const Duration(minutes: 1)))),
        testCard(5, due: stamp(next)),
        testCard(6),
      ]);
      expect(
        await ids(const CardSearchOptions(due: CardDueFilter.today), now: now),
        [2, 3, 4],
      );
      expect(
        await ids(
          const CardSearchOptions(due: CardDueFilter.overdue),
          now: now,
        ),
        [1, 2],
      );
      expect(
        await ids(const CardSearchOptions(due: CardDueFilter.noDate), now: now),
        [6],
      );
    },
  );

  test(
    'pending edits and new cards are searchable without waiting for upload',
    () async {
      final original = testCard(8, title: 'Original');
      await seed(account, testBoard(1), [original]);
      await database.saveCardDraft(account, 1, 2, {
        'title': 'Changed',
      }, original: DeckCard.fromJson(original));
      await database.saveCardDraft(account, 1, 2, {'title': 'Offline task'});
      expect(await ids(const CardSearchOptions(query: 'original')), isEmpty);
      expect(await ids(const CardSearchOptions(query: 'changed')), [8]);
      final pending = await database.searchCards(
        account.id,
        const CardSearchOptions(query: 'offline'),
      );
      expect(pending.hits.single.card.id, isNegative);
      expect(pending.hits.single.card.raw['syncState'], 'queued');
    },
  );

  test('discarding a pending deletion returns the card to search', () async {
    final original = testCard(8);
    await seed(account, testBoard(1), [original]);
    await database.queueCardAction(
      account,
      1,
      DeckCard.fromJson(original),
      'deleteCard',
      {},
    );
    expect(
      await ids(
        const CardSearchOptions(includeArchived: true, includeCompleted: true),
      ),
      isEmpty,
    );
    final pending = (await database.writesFor(account.id)).single;
    await database.decideWrite(account.id, pending.id, discard: true);
    expect(await ids(const CardSearchOptions()), [8]);
  });

  test('an account removal updates an already visible search stream', () async {
    await seed(account, testBoard(1), [testCard(8)]);
    final stream = StreamIterator(
      database.watchCardSearch(account.id, const CardSearchOptions()),
    );
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.hits.single.card.id, 8);
    await accounts.remove(account.id);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.accountAvailable, isFalse);
    expect(stream.current.hits, isEmpty);
    await stream.cancel();
  });

  test(
    'a deleting account does not expose cached results while vault cleanup is retried',
    () async {
      await seed(account, testBoard(1), [testCard(8)]);
      vault.failDelete = true;
      await expectLater(accounts.remove(account.id), throwsStateError);
      expect(
        (await database.searchCards(
          account.id,
          const CardSearchOptions(),
        )).hits,
        isEmpty,
      );
    },
  );
}
