import 'dart:async';

import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

class PausingVault implements CredentialVault {
  final values = <String, String>{};
  final written = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<String?> read(String reference) async => values[reference];
  @override
  Future<void> write(String reference, String password) async {
    values[reference] = password;
    written.complete();
    await resume.future;
  }

  @override
  Future<void> delete(String reference) async => values.remove(reference);
  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

void main() {
  late DeckDatabase database;
  setUp(() => database = DeckDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'cancelling while saving credentials leaves no account or secret',
    () async {
      final vault = PausingVault();
      final repository = AccountRepository(database, vault);
      var allowed = true;
      final result = repository.add(
        credentials('user'),
        canCommit: () => allowed,
      );
      final rejected = expectLater(result, throwsStateError);
      await vault.written.future;
      allowed = false;
      vault.resume.complete();
      await rejected;
      expect(await database.accounts(), isEmpty);
      expect(vault.values, isEmpty);
    },
  );

  test('changed or missing pin cannot replace a trusted account', () async {
    final vault = MemoryVault();
    final repository = AccountRepository(database, vault);
    final first = await repository.add(
      credentials('user'),
      certificateFingerprint: 'a' * 64,
    );
    for (final pin in [null, 'b' * 64]) {
      await expectLater(
        repository.add(
          credentials('user', 'new-password'),
          certificateFingerprint: pin,
        ),
        throwsStateError,
      );
      expect(
        (await database.account(first.id))!.credentialRef,
        first.credentialRef,
      );
      expect(vault.values.values, ['test-password']);
    }
    final renewed = await repository.add(
      credentials('user', 'new-password'),
      certificateFingerprint: 'a' * 64,
    );
    expect(renewed.id, first.id);
    expect(renewed.certificateFingerprint, 'a' * 64);
    expect(vault.values.values, ['new-password']);
  });
}
