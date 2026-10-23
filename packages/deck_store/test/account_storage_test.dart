import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late DeckDatabase database;
  late MemoryVault vault;
  late AccountRepository accounts;
  setUp(() {
    database = DeckDatabase(NativeDatabase.memory());
    vault = MemoryVault();
    accounts = AccountRepository(database, vault);
  });
  tearDown(() => database.close());

  test('same remote board id remains isolated between accounts', () async {
    final first = await accounts.add(credentials('first'));
    final second = await accounts.add(credentials('second'));
    await database.saveBoards(first.id, first.generation, [
      board(7, 'First board'),
    ], 'a');
    await database.saveBoards(second.id, second.generation, [
      board(7, 'Second board'),
    ], 'b');
    expect(
      (await database.watchBoards(first.id).first).single.title,
      'First board',
    );
    expect(
      (await database.watchBoards(second.id).first).single.title,
      'Second board',
    );
    expect(vault.values.values, everyElement('test-password'));
    expect(first.toJson().values, isNot(contains('test-password')));
  });

  test('reauthentication preserves data and rejects an old response', () async {
    final original = await accounts.add(credentials('user'));
    await database.saveBoards(original.id, original.generation, [
      board(1, 'Saved'),
    ], null);
    final updated = await accounts.add(
      credentials('user', 'replacement-password'),
    );
    expect(updated.id, original.id);
    expect(updated.generation, original.generation + 1);
    expect(vault.values.containsKey(original.credentialRef), isFalse);
    await database.saveBoards(original.id, original.generation, [
      board(1, 'Stale'),
    ], null);
    expect(
      (await database.watchBoards(updated.id).first).single.title,
      'Saved',
    );
  });

  test(
    'removal cascades cached data and a late response cannot recreate it',
    () async {
      final account = await accounts.add(credentials('user'));
      await database.saveBoards(account.id, account.generation, [
        board(1, 'Saved'),
      ], 'etag');
      await accounts.remove(account.id);
      await database.saveBoards(account.id, account.generation, [
        board(1, 'Late'),
      ], 'new');
      expect(await database.watchBoards(account.id).first, isEmpty);
      expect(await database.checkpoint(account.id, 'boards'), isNull);
      expect(vault.values, isEmpty);
    },
  );

  test(
    'failed vault deletion keeps a tombstone for startup recovery',
    () async {
      final account = await accounts.add(credentials('user'));
      vault.failDelete = true;
      await expectLater(accounts.remove(account.id), throwsStateError);
      expect((await database.account(account.id))!.state, 'deleting');
      expect(await database.accepts(account.id, account.generation), isFalse);
      vault.failDelete = false;
      await accounts.recover();
      expect(await database.account(account.id), isNull);
      expect(vault.values, isEmpty);
    },
  );

  test(
    'missing credentials require reauthentication without losing cached data',
    () async {
      final account = await accounts.add(credentials('user'));
      await database.saveBoards(account.id, account.generation, [
        board(1, 'Saved'),
      ], null);
      vault.values.clear();
      await accounts.recover();
      expect((await database.account(account.id))!.state, 'reauthRequired');
      expect(
        (await database.watchBoards(account.id).first).single.title,
        'Saved',
      );
    },
  );

  test('invalid child ownership rolls the complete snapshot back', () async {
    final account = await accounts.add(credentials('user'));
    final stacks = [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 99,
        'title': 'Invalid',
        'order': 0,
        'cards': [],
      }),
    ];
    await expectLater(
      database.saveStacks(account.id, account.generation, 1, stacks, 'etag'),
      throwsFormatException,
    );
    expect(await database.watchStacks(account.id, 1).first, isEmpty);
    expect(await database.checkpoint(account.id, 'board:1'), isNull);
  });
}
