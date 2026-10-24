import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late DeckDatabase database;
  late AccountRepository accounts;
  late StoredAccount account;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    accounts = AccountRepository(database, MemoryVault());
    account = await accounts.add(credentials('user'));
  });
  tearDown(() => database.close());

  DeckCardContext result(int id) => DeckCardContext(
    board: board(1, 'Board', edit: true),
    stack: DeckStack.fromJson({
      'id': 2,
      'boardId': 1,
      'title': 'Stack',
      'order': 0,
      'cards': [],
    }),
    card: DeckCard.fromJson(cardJson(id: id)),
  );

  test(
    'single-card reads preserve other cached cards and pending changes',
    () async {
      expect(await database.saveReadCard(account, result(8), 0), isTrue);
      await database.saveCardDraft(account, 1, 2, {
        'title': 'Local edit',
      }, original: result(8).card);
      expect(await database.saveReadCard(account, result(9), 0), isTrue);
      final cards = (await database.stackView(account.id, 1)).single.cards;
      expect(cards.map((card) => card.id).toSet(), {8, 9});
      expect(cards.singleWhere((card) => card.id == 8).title, 'Local edit');
    },
  );

  test('removed accounts and changed epochs reject a late read', () async {
    await database.invalidateMutation(account.id, 1);
    expect(await database.saveReadCard(account, result(8), 0), isFalse);
    await accounts.remove(account.id);
    expect(await database.saveReadCard(account, result(9), 1), isFalse);
    expect(await database.boardView(account.id), isEmpty);
  });
}
