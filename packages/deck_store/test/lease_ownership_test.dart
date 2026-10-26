import 'dart:io';

import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const _background = '${DeckDatabase.backgroundOwnerPrefix}run';

void main() {
  late Directory dir;
  late File file;
  late String accountId;

  Future<void> lease(DeckDatabase db, String owner, Duration ttl) => db
      .into(db.syncLeases)
      .insertOnConflictUpdate(
        SyncLeasesCompanion.insert(
          accountId: accountId,
          owner: owner,
          expires: DateTime.now().toUtc().add(ttl),
        ),
      );

  Future<List<String>> owners(DeckDatabase db) async => [
    for (final l in await db.select(db.syncLeases).get()) l.owner,
  ];

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('owndeck_lease_owner');
    file = File('${dir.path}/deck.sqlite');
    final first = DeckDatabase(NativeDatabase(file));
    accountId = (await AccountRepository(
      first,
      MemoryVault(),
    ).add(credentials('user'), userId: 'uid-1')).id;
    await first.close();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test(
    'a foreground open keeps the live lease of a background sender',
    () async {
      final seed = DeckDatabase(NativeDatabase(file));
      await lease(seed, _background, const Duration(minutes: 1));
      await seed.close();
      final db = DeckDatabase(NativeDatabase(file));
      addTearDown(db.close);
      expect(await owners(db), [_background]);
      final account = (await db.accounts()).single;
      expect(await db.acquireLease(account, 'foreground'), isFalse);
    },
  );

  test('a foreground open clears dead and expired background leases', () async {
    final seed = DeckDatabase(NativeDatabase(file));
    await lease(seed, 'dead-foreground', const Duration(minutes: 1));
    await seed.close();
    var db = DeckDatabase(NativeDatabase(file));
    expect(await owners(db), isEmpty);
    await lease(db, _background, const Duration(minutes: -1));
    await db.close();
    db = DeckDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect(await owners(db), isEmpty);
  });

  test('a background open never clears the foreground lease', () async {
    final seed = DeckDatabase(NativeDatabase(file));
    await lease(seed, 'foreground', const Duration(minutes: 1));
    await seed.close();
    final db = DeckDatabase(NativeDatabase(file), background: true);
    addTearDown(db.close);
    expect(await owners(db), ['foreground']);
    final account = (await db.accounts()).single;
    expect(await db.acquireLease(account, _background), isFalse);
  });

  test('the last successful sync is stored per account', () async {
    final db = DeckDatabase(NativeDatabase(file));
    addTearDown(db.close);
    expect((await db.watchSyncStatus().first).single.lastSyncedAt, isNull);
    await db.markSynced(accountId);
    final status = (await db.watchSyncStatus().first).single;
    expect(status.account.id, accountId);
    expect(
      DateTime.now().toUtc().difference(status.lastSyncedAt!.toUtc()).inSeconds,
      lessThan(5),
    );
  });
}
