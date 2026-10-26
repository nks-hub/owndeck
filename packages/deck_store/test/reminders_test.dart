import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

Object _mine(String user) => {
  'participant': {'uid': user},
  'type': 0,
};

JsonObject _card(
  int id, {
  String? due = '2030-05-01T10:00:00+00:00',
  Object? done,
  bool archived = false,
  List<Object?>? assigned,
}) => {
  ...cardJson(id: id),
  'title': 'Card $id',
  'duedate': due,
  'done': done,
  'archived': archived,
  'deletedAt': 0,
  'assignedUsers': assigned ?? [_mine('canonical-user')],
};

void main() {
  late DeckDatabase database;
  late AccountRepository accounts;
  late StoredAccount account;

  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    accounts = AccountRepository(database, MemoryVault());
    account = await accounts.add(
      credentials('login-alias'),
      userId: 'canonical-user',
    );
  });
  tearDown(() => database.close());

  Future<void> seed(StoredAccount target, List<JsonObject> cards) async {
    await database.saveBoards(target.id, target.generation, [
      board(1, 'Project', edit: true),
    ], null);
    await database.saveStacks(target.id, target.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Planning',
        'order': 0,
        'cards': cards,
      }),
    ], null);
  }

  test('only open assigned cards with a due date become reminders', () async {
    await seed(account, [
      _card(1),
      _card(2, due: null),
      _card(3, done: '2030-01-01T00:00:00+00:00'),
      _card(4, archived: true),
      _card(5, assigned: [_mine('somebody-else')]),
    ]);
    final reminders = await database.dueReminders();
    expect(reminders.map((r) => r.cardId), [1]);
    expect(reminders.single.accountId, account.id);
    expect(reminders.single.boardTitle, 'Project');
    expect(reminders.single.due, DateTime.utc(2030, 5, 1, 10));
  });

  test('completing a card offline removes its reminder at once', () async {
    await seed(account, [_card(1)]);
    final card = DeckCard.fromJson(_card(1));
    await database.saveCardDraft(account, 1, 2, {
      'done': '2030-01-01T00:00:00+00:00',
    }, original: card);
    expect(await database.dueReminders(), isEmpty);
  });

  test('changing the due date offline moves its reminder at once', () async {
    await seed(account, [_card(1)]);
    final card = DeckCard.fromJson(_card(1));
    await database.saveCardDraft(account, 1, 2, {
      'duedate': '2030-07-01T10:00:00+00:00',
    }, original: card);
    expect(
      (await database.dueReminders()).single.due,
      DateTime.utc(2030, 7, 1, 10),
    );
  });

  test('a removed account no longer has reminders', () async {
    final other = await accounts.add(credentials('other'), userId: 'other');
    await seed(account, [_card(1)]);
    await database.saveBoards(other.id, other.generation, [
      board(1, 'Other'),
    ], null);
    await database.saveStacks(other.id, other.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Planning',
        'order': 0,
        'cards': [
          _card(7, assigned: [_mine('other')]),
        ],
      }),
    ], null);
    expect((await database.dueReminders()).map((r) => r.cardId), [1, 7]);
    await accounts.remove(other.id);
    expect((await database.dueReminders()).map((r) => r.cardId), [1]);
  });

  test('the stream emits again when a due date changes', () async {
    await seed(account, [_card(1)]);
    final emissions = <DateTime>[];
    final sub = database.watchDueReminders().listen(
      (list) => emissions.add(list.single.due),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await seed(account, [_card(1, due: '2030-06-01T10:00:00+00:00')]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emissions.first, DateTime.utc(2030, 5, 1, 10));
    expect(emissions.last, DateTime.utc(2030, 6, 1, 10));
  });
}
