part of 'database.dart';

extension DeckWrites on DeckDatabase {
  Future<List<PendingWrite>> writesFor(String accountId, {int? boardId}) =>
      (select(pendingWrites)
            ..where(
              (w) =>
                  w.accountId.equals(accountId) &
                  w.state.isNotIn(['confirmed', 'discarded']) &
                  (boardId == null
                      ? const Constant(true)
                      : w.boardId.equals(boardId)),
            )
            ..orderBy([(w) => OrderingTerm.asc(w.sequence)]))
          .get();

  Stream<List<PendingWrite>> watchWrites(String accountId) =>
      (select(pendingWrites)
            ..where(
              (w) =>
                  w.accountId.equals(accountId) &
                  w.state.isNotIn(['confirmed', 'discarded']),
            )
            ..orderBy([(w) => OrderingTerm.asc(w.sequence)]))
          .watch();

  Future<String> saveCardDraft(
    StoredAccount account,
    int boardId,
    int stackId,
    JsonObject changes, {
    DeckCard? original,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation))
      throw StateError('account_unavailable');
    final board =
        await (select(storedBoards)..where(
              (b) =>
                  b.accountId.equals(account.id) & b.remoteId.equals(boardId),
            ))
            .getSingleOrNull();
    if (board == null ||
        !DeckBoard.fromJson(
          object(jsonDecode(board.payload)),
        ).permissions.edit) {
      throw StateError('permission_denied');
    }
    final existing = (await writesFor(account.id, boardId: boardId))
        .where(
          (w) =>
              original != null &&
              (original.id < 0
                  ? w.sequence == -original.id
                  : w.cardId == original.id),
        )
        .firstOrNull;
    if (existing != null) {
      if (existing.state != 'queued') throw StateError('pending_decision');
      final merged = {...object(jsonDecode(existing.proposal)), ...changes};
      await (update(pendingWrites)..where((w) => w.id.equals(existing.id)))
          .write(PendingWritesCompanion(proposal: Value(jsonEncode(merged))));
      return existing.id;
    }
    if (original != null && original.id < 0)
      throw StateError('draft_not_found');
    final id = const Uuid().v4();
    final proposal = original == null
        ? <String, Object?>{
            'title': '',
            'description': '',
            'type': 'plain',
            'order': 999,
            'owner': account.loginName,
            'archived': false,
            'duedate': null,
            ...changes,
          }
        : changes;
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: id,
        accountId: account.id,
        kind: original == null ? 'createCard' : 'updateCard',
        boardId: boardId,
        stackId: stackId,
        cardId: Value(original?.id),
        proposal: jsonEncode(proposal),
        base: Value(original == null ? null : jsonEncode(original.raw)),
      ),
    );
    return id;
  });

  Future<bool> acquireLease(StoredAccount account, String owner) =>
      transaction(() async {
        if (!await accepts(account.id, account.generation)) return false;
        final lease = await (select(
          syncLeases,
        )..where((l) => l.accountId.equals(account.id))).getSingleOrNull();
        final now = DateTime.now().toUtc();
        if (lease != null && lease.owner != owner && lease.expires.isAfter(now))
          return false;
        await into(syncLeases).insertOnConflictUpdate(
          SyncLeasesCompanion.insert(
            accountId: account.id,
            owner: owner,
            expires: now.add(const Duration(minutes: 2)),
          ),
        );
        return true;
      });

  Future<bool> ownsLease(StoredAccount account, String owner) async {
    if (!await accepts(account.id, account.generation)) return false;
    final lease =
        await (select(syncLeases)..where(
              (l) => l.accountId.equals(account.id) & l.owner.equals(owner),
            ))
            .getSingleOrNull();
    return lease != null && lease.expires.isAfter(DateTime.now().toUtc());
  }

  Future<void> releaseLease(String accountId, String owner) async {
    await (delete(syncLeases)
          ..where((l) => l.accountId.equals(accountId) & l.owner.equals(owner)))
        .go();
  }

  Future<void> recoverWrites(StoredAccount account, String owner) =>
      transaction(() async {
        if (!await ownsLease(account, owner)) return;
        await (update(pendingWrites)..where(
              (w) => w.accountId.equals(account.id) & w.state.equals('sending'),
            ))
            .write(
              const PendingWritesCompanion(
                state: Value('uncertain'),
                error: Value('interrupted_write'),
              ),
            );
      });

  Future<bool> startWrite(StoredAccount account, String owner, String id) =>
      transaction(() async {
        if (!await ownsLease(account, owner)) return false;
        return await (update(pendingWrites)..where(
                  (w) =>
                      w.accountId.equals(account.id) &
                      w.id.equals(id) &
                      w.state.equals('queued'),
                ))
                .write(
                  const PendingWritesCompanion(
                    state: Value('sending'),
                    error: Value(null),
                  ),
                ) ==
            1;
      });

  Future<void> markWrite(
    StoredAccount account,
    String owner,
    String id,
    String state, {
    String? error,
    JsonObject? remote,
  }) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    await (update(pendingWrites)..where(
          (w) =>
              w.accountId.equals(account.id) &
              w.id.equals(id) &
              w.state.equals('sending'),
        ))
        .write(
          PendingWritesCompanion(
            state: Value(state),
            error: Value(error),
            remote: Value(remote == null ? null : jsonEncode(remote)),
          ),
        );
  });

  Future<void> confirmCard(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckCard card,
  ) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    final current =
        await (select(pendingWrites)..where(
              (w) => w.accountId.equals(account.id) & w.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (current?.state != 'sending') return;
    await into(storedCards).insertOnConflictUpdate(
      StoredCardsCompanion.insert(
        accountId: account.id,
        remoteId: card.id,
        boardId: write.boardId,
        stackId: card.stackId,
        position: card.order,
        payload: jsonEncode(card.raw),
      ),
    );
    await (update(pendingWrites)..where((w) => w.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('confirmed'),
        remote: Value(jsonEncode(card.raw)),
        error: const Value(null),
      ),
    );
    final currentAccount = (await this.account(account.id))!;
    await (update(storedAccounts)..where((a) => a.id.equals(account.id))).write(
      StoredAccountsCompanion(
        contentEpoch: Value(currentAccount.contentEpoch + 1),
      ),
    );
    await (delete(syncCheckpoints)..where(
          (c) =>
              c.accountId.equals(account.id) &
              (c.scope.equals('boards') |
                  c.scope.equals('board:${write.boardId}')),
        ))
        .go();
  });

  Future<void> decideWrite(
    String accountId,
    String id, {
    required bool discard,
    bool acceptRemoteBase = false,
  }) => transaction(() async {
    final write =
        await (select(pendingWrites)
              ..where((w) => w.accountId.equals(accountId) & w.id.equals(id)))
            .getSingleOrNull();
    if (write == null || write.state == 'sending' || write.state == 'confirmed')
      throw StateError('write_unavailable');
    await (update(pendingWrites)..where((w) => w.id.equals(id))).write(
      PendingWritesCompanion(
        state: Value(discard ? 'discarded' : 'queued'),
        error: const Value(null),
        base: acceptRemoteBase && write.remote != null
            ? Value(write.remote)
            : const Value.absent(),
        stackId: acceptRemoteBase && write.remote != null
            ? Value(intField(object(jsonDecode(write.remote!)), 'stackId'))
            : const Value.absent(),
      ),
    );
  });
}
