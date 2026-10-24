import 'package:deck_protocol/deck_protocol.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';

abstract interface class CredentialVault {
  Future<String?> read(String reference);
  Future<void> write(String reference, String password);
  Future<void> delete(String reference);
  Future<Set<String>> references();
}

final class AccountRepository {
  AccountRepository(this.database, this.vault, {this.clearFiles});
  final DeckDatabase database;
  final CredentialVault vault;
  final Future<void> Function(String accountId)? clearFiles;
  Future<void> _tail = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    // The caller receives each error; a failed operation must not poison the queue.
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<StoredAccount> add(
    LoginCredentials credentials, {
    String? userId,
    String? certificateFingerprint,
    bool Function()? canCommit,
  }) => _serialize(() async {
    void ensureCommit() {
      if (canCommit?.call() == false) throw StateError('onboarding_cancelled');
    }

    ensureCommit();
    final existing =
        await (database.select(database.storedAccounts)..where(
              (a) =>
                  a.server.equals(credentials.server.uri.toString()) &
                  a.loginName.equals(credentials.loginName),
            ))
            .getSingleOrNull();
    if (existing?.state == 'deleting') throw StateError('account_deleting');
    if (userId != null &&
        existing?.userId != null &&
        existing!.userId != userId) {
      throw StateError('identity_mismatch');
    }
    if (existing?.certificateFingerprint != null &&
        existing!.certificateFingerprint != certificateFingerprint) {
      throw StateError('certificate_changed');
    }
    final id = existing?.id ?? const Uuid().v4();
    final reference = 'owndeck.account.${const Uuid().v4()}';
    // A new reference keeps the old account usable until the database commits.
    ensureCommit();
    try {
      await vault.write(reference, credentials.appPassword);
      await database.transaction(() async {
        ensureCommit();
        await database
            .update(database.storedAccounts)
            .write(const StoredAccountsCompanion(selected: Value(false)));
        await database
            .into(database.storedAccounts)
            .insertOnConflictUpdate(
              StoredAccountsCompanion.insert(
                id: id,
                server: credentials.server.uri.toString(),
                loginName: credentials.loginName,
                userId: userId == null ? const Value.absent() : Value(userId),
                credentialRef: reference,
                certificateFingerprint: Value(certificateFingerprint),
                generation: Value((existing?.generation ?? 0) + 1),
                state: const Value('active'),
                selected: const Value(true),
              ),
            );
        ensureCommit();
      });
    } catch (_) {
      try {
        await vault.delete(reference);
      } catch (_) {
        /* A locked vault is repaired by startup orphan recovery. */
      }
      rethrow;
    }
    // Orphaned references after a failed transaction or cleanup are removed by recover.
    if (existing != null) await vault.delete(existing.credentialRef);
    return (await database.account(id))!;
  });

  Future<void> select(String id) => _serialize(
    () => database.transaction(() async {
      final target = await database.account(id);
      if (target == null || target.state == 'deleting') {
        throw StateError('account_unavailable');
      }
      await database
          .update(database.storedAccounts)
          .write(const StoredAccountsCompanion(selected: Value(false)));
      await (database.update(database.storedAccounts)
            ..where((a) => a.id.equals(id)))
          .write(const StoredAccountsCompanion(selected: Value(true)));
    }),
  );

  Future<void> remove(String id) => _serialize(() async {
    final current = await database.account(id);
    if (current == null) return;
    await (database.update(
      database.storedAccounts,
    )..where((a) => a.id.equals(id))).write(
      StoredAccountsCompanion(
        state: const Value('deleting'),
        generation: Value(current.generation + 1),
      ),
    );
    await clearFiles?.call(id);
    await vault.delete(current.credentialRef);
    await (database.delete(
      database.storedAccounts,
    )..where((a) => a.id.equals(id))).go();
  });

  Future<void> recover() => _serialize(() async {
    for (final account in await database.accounts()) {
      if (account.state == 'deleting') {
        await clearFiles?.call(account.id);
        await vault.delete(account.credentialRef);
        await (database.delete(
          database.storedAccounts,
        )..where((a) => a.id.equals(account.id))).go();
      } else if (await vault.read(account.credentialRef) == null) {
        await (database.update(
          database.storedAccounts,
        )..where((a) => a.id.equals(account.id))).write(
          const StoredAccountsCompanion(state: Value('reauthRequired')),
        );
      }
    }
    final keep = (await database.accounts())
        .map((a) => a.credentialRef)
        .toSet();
    for (final reference in await vault.references()) {
      if (reference.startsWith('owndeck.account.') &&
          !keep.contains(reference)) {
        await vault.delete(reference);
      }
    }
  });
}
