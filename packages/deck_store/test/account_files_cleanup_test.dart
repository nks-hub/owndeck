import 'dart:async';
import 'dart:io';

import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late DeckDatabase database;
  late MemoryVault vault;
  setUp(() {
    database = DeckDatabase(NativeDatabase.memory());
    vault = MemoryVault();
  });
  tearDown(() => database.close());

  test(
    'failed file cleanup keeps a tombstone and credentials until recovery succeeds',
    () async {
      var unavailable = true;
      final calls = <String>[];
      Future<void> clear(String id) async {
        calls.add(id);
        final account = (await database.account(id))!;
        expect(account.state, 'deleting');
        expect(vault.values[account.credentialRef], 'test-password');
        if (unavailable) throw const FileSystemException('storage_unavailable');
      }

      final repository = AccountRepository(database, vault, clearFiles: clear);
      final account = await repository.add(credentials('user'));
      await database.saveBoards(account.id, account.generation, [
        board(1, 'Board'),
      ], null);
      await expectLater(
        repository.remove(account.id),
        throwsA(isA<FileSystemException>()),
      );
      final tombstone = (await database.account(account.id))!;
      expect(tombstone.state, 'deleting');
      expect(tombstone.generation, account.generation + 1);
      expect(await database.accepts(account.id, account.generation), isFalse);
      expect(vault.values[account.credentialRef], 'test-password');

      final restarted = AccountRepository(database, vault, clearFiles: clear);
      await expectLater(
        restarted.recover(),
        throwsA(isA<FileSystemException>()),
      );
      expect(vault.values[account.credentialRef], 'test-password');
      unavailable = false;
      await restarted.recover();
      expect(calls, [account.id, account.id, account.id]);
      expect(await database.account(account.id), isNull);
      expect(vault.values, isEmpty);
      expect(await database.watchBoards(account.id).first, isEmpty);
    },
  );

  test(
    'account access stops before asynchronous file cleanup and credential deletion',
    () async {
      final started = Completer<void>();
      final removed = Completer<void>();
      var clears = 0;
      final repository = AccountRepository(
        database,
        vault,
        clearFiles: (_) {
          clears++;
          started.complete();
          return removed.future;
        },
      );
      final account = await repository.add(credentials('user'));
      final removing = repository.remove(account.id);
      await started.future;
      expect(await database.accepts(account.id, account.generation), isFalse);
      expect((await database.account(account.id))!.state, 'deleting');
      expect(vault.values[account.credentialRef], 'test-password');
      removed.complete();
      await removing;
      expect(await database.account(account.id), isNull);
      expect(vault.values, isEmpty);
      await repository.recover();
      expect(clears, 1);
    },
  );
}
