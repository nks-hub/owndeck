part of 'database.dart';

int _intentSequence(PendingWrite write) {
  if (write.kind == 'stackReorder') {
    final source = object(jsonDecode(write.proposal))['orderAfter'];
    if (source is int && source > 0 && source < write.sequence) return source;
  }
  return write.sequence;
}

int _compareWriteIntents(PendingWrite first, PendingWrite second) {
  final order = _intentSequence(first).compareTo(_intentSequence(second));
  return order == 0 ? first.sequence.compareTo(second.sequence) : order;
}

extension DeckWrites on DeckDatabase {
  Future<void> deferSync(StoredAccount account, DateTime? until) =>
      transaction(() async {
        if (until == null || !await accepts(account.id, account.generation)) {
          return;
        }
        final rounded = DateTime.fromMillisecondsSinceEpoch(
          ((until.microsecondsSinceEpoch + 999999) ~/ 1000000) * 1000,
          isUtc: true,
        );
        final current = await this.account(account.id);
        if (current?.syncNotBefore != null &&
            !rounded.isAfter(current!.syncNotBefore!)) {
          return;
        }
        await (update(storedAccounts)..where((a) => a.id.equals(account.id)))
            .write(StoredAccountsCompanion(syncNotBefore: Value(rounded)));
      });
  Future<List<PendingWrite>> writesFor(String accountId, {int? boardId}) async {
    final writes =
        await (select(pendingWrites)
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
    return writes..sort(_compareWriteIntents);
  }

  Stream<List<PendingWrite>> watchWrites(String accountId) =>
      (select(pendingWrites)
            ..where(
              (w) =>
                  w.accountId.equals(accountId) &
                  w.state.isNotIn(['confirmed', 'discarded']),
            )
            ..orderBy([(w) => OrderingTerm.asc(w.sequence)]))
          .watch()
          .map(
            (writes) =>
                List<PendingWrite>.of(writes)..sort(_compareWriteIntents),
          );

  Future<String> saveCardDraft(
    StoredAccount account,
    int boardId,
    int stackId,
    JsonObject changes, {
    DeckCard? original,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    var resolved = original;
    if (original != null && original.id < 0) {
      final creation =
          await (select(pendingWrites)..where(
                (w) =>
                    w.accountId.equals(account.id) &
                    w.sequence.equals(-original.id),
              ))
              .getSingleOrNull();
      if (creation?.state == 'confirmed' && creation?.remote != null) {
        resolved = DeckCard.fromJson(object(jsonDecode(creation!.remote!)));
        stackId = resolved.stackId;
      }
    }
    final source = resolved;
    final resolvedBoardId =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((b) => b.id == resolvedBoardId).firstOrNull;
    if (board == null ||
        !board.permissions.edit ||
        board.archived ||
        board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    final existing = (await writesFor(account.id))
        .where(
          (w) =>
              source != null &&
              (source.id < 0
                  ? w.sequence == -source.id
                  : w.cardId == source.id),
        )
        .firstOrNull;
    if (existing != null) {
      if (existing.state != 'queued' ||
          !{'createCard', 'updateCard'}.contains(existing.kind)) {
        throw StateError('pending_decision');
      }
      final merged = {...object(jsonDecode(existing.proposal)), ...changes};
      await (update(pendingWrites)..where((w) => w.id.equals(existing.id)))
          .write(PendingWritesCompanion(proposal: Value(jsonEncode(merged))));
      return existing.id;
    }
    if (source != null && source.id < 0) throw StateError('draft_not_found');
    final id = const Uuid().v4();
    final proposal = source == null
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
        kind: source == null ? 'createCard' : 'updateCard',
        boardId: boardId,
        stackId: stackId,
        cardId: Value(source?.id),
        proposal: jsonEncode(proposal),
        base: Value(source == null ? null : jsonEncode(source.raw)),
      ),
    );
    return id;
  });

  Future<bool> acquireLease(StoredAccount account, String owner) => transaction(
    () async {
      if (!await accepts(account.id, account.generation)) return false;
      final lease = await (select(
        syncLeases,
      )..where((l) => l.accountId.equals(account.id))).getSingleOrNull();
      final now = DateTime.now().toUtc();
      if (lease != null && lease.owner != owner && lease.expires.isAfter(now)) {
        return false;
      }
      await into(syncLeases).insertOnConflictUpdate(
        SyncLeasesCompanion.insert(
          accountId: account.id,
          owner: owner,
          expires: now.add(const Duration(minutes: 2)),
        ),
      );
      return true;
    },
  );

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

  Future<bool> confirmCard(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckCard card, {
    int? contentEpoch,
  }) => transaction(() async {
    if (card.id <= 0 ||
        card.stackId <= 0 ||
        write.boardId <= 0 ||
        !await ownsLease(account, owner) ||
        contentEpoch != null &&
            (await this.account(account.id))?.contentEpoch != contentEpoch) {
      return false;
    }
    final current =
        await (select(pendingWrites)..where(
              (w) => w.accountId.equals(account.id) & w.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (current == null || !{'sending', 'applied'}.contains(current.state)) {
      return false;
    }
    final boardRow =
        await (select(storedBoards)..where(
              (board) =>
                  board.accountId.equals(account.id) &
                  board.remoteId.equals(write.boardId),
            ))
            .getSingleOrNull();
    if (boardRow == null) return false;
    final board = DeckBoard.fromJson(object(jsonDecode(boardRow.payload)));
    if (!board.permissions.read || board.deletedAt != 0) return false;
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
    await invalidateMutation(account.id, write.boardId);
    return true;
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
    if (write == null ||
        write.state == 'sending' ||
        write.state == 'confirmed') {
      throw StateError('write_unavailable');
    }
    if (write.state == 'applied' && !discard) {
      throw StateError('already_applied');
    }
    await (update(pendingWrites)..where((w) => w.id.equals(id))).write(
      PendingWritesCompanion(
        state: Value(discard ? 'discarded' : 'queued'),
        error: const Value(null),
        base: acceptRemoteBase && write.remote != null
            ? Value(write.remote)
            : const Value.absent(),
        stackId:
            acceptRemoteBase &&
                write.remote != null &&
                object(jsonDecode(write.remote!)).containsKey('stackId') &&
                !write.kind.endsWith('Board') &&
                !write.kind.endsWith('Stack')
            ? Value(intField(object(jsonDecode(write.remote!)), 'stackId'))
            : const Value.absent(),
      ),
    );
  });
}
