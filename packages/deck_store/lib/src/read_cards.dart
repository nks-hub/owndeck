part of 'database.dart';

extension DeckReadCards on DeckDatabase {
  Future<bool> blockUnavailableCardWrite(
    StoredAccount account,
    String owner,
    PendingWrite write,
    int epoch,
    String reason, {
    int? deniedBoardId,
  }) => transaction(() async {
    if (!await ownsLease(account, owner) ||
        (await this.account(account.id))?.contentEpoch != epoch ||
        write.cardId == null) {
      return false;
    }
    final current =
        await (select(pendingWrites)..where(
              (row) =>
                  row.accountId.equals(account.id) & row.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (current?.state != 'sending') return false;
    if (deniedBoardId != null) {
      await revokeBoardAccess(account, deniedBoardId, reason: reason);
    }
    final cached =
        await (select(storedCards)..where(
              (row) =>
                  row.accountId.equals(account.id) &
                  row.remoteId.equals(write.cardId!),
            ))
            .getSingleOrNull();
    if (cached != null) {
      await _retainMissingCardIdentities(account.id, [cached]);
    }
    await (delete(storedComments)..where(
          (row) =>
              row.accountId.equals(account.id) &
              row.cardId.equals(write.cardId!),
        ))
        .go();
    await (delete(storedAttachments)..where(
          (row) =>
              row.accountId.equals(account.id) &
              row.cardId.equals(write.cardId!),
        ))
        .go();
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('blocked'),
        error: Value(reason),
      ),
    );
    await invalidateMutation(account.id, cached?.boardId ?? write.boardId);
    return true;
  });

  Future<bool> flagMovedCardWrite(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckCardContext context,
    int epoch,
  ) => transaction(() async {
    if (!await ownsLease(account, owner) || context.card.id != write.cardId) {
      return false;
    }
    final pending =
        await (select(pendingWrites)..where(
              (row) =>
                  row.accountId.equals(account.id) & row.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (pending?.state != 'sending' ||
        !{'updateCard', 'cardTransfer'}.contains(pending?.kind) ||
        !await saveReadCard(account, context, epoch)) {
      return false;
    }
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        boardId: Value(context.board.id),
        stackId: Value(context.stack.id),
        cardId: Value(context.card.id),
        state: const Value('conflict'),
        error: const Value('concurrent_edit'),
        remote: Value(jsonEncode(context.card.raw)),
      ),
    );
    return true;
  });

  Future<bool> saveReadCard(
    StoredAccount account,
    DeckCardContext result,
    int epoch,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation) ||
        (await this.account(account.id))?.contentEpoch != epoch) {
      return false;
    }
    final board = result.board;
    final stack = result.stack;
    final card = result.card;
    if (!board.permissions.read ||
        board.deletedAt != 0 ||
        stack.boardId != board.id ||
        card.stackId != stack.id ||
        (stack.raw['deletedAt'] ?? 0) != 0 ||
        (card.raw['deletedAt'] ?? 0) != 0) {
      throw StateError('card_unavailable');
    }
    final previous =
        await (select(storedCards)..where(
              (row) =>
                  row.accountId.equals(account.id) &
                  row.remoteId.equals(card.id),
            ))
            .getSingleOrNull();
    if (_olderCardSnapshot(card, previous)) return false;
    await into(storedBoards).insertOnConflictUpdate(
      StoredBoardsCompanion.insert(
        accountId: account.id,
        remoteId: board.id,
        payload: jsonEncode(board.raw),
      ),
    );
    await into(storedStacks).insertOnConflictUpdate(
      StoredStacksCompanion.insert(
        accountId: account.id,
        remoteId: stack.id,
        boardId: board.id,
        position: stack.order,
        payload: jsonEncode({...stack.raw, 'cards': <Object?>[]}),
      ),
    );
    if (await _storeObservedCard(account.id, board.id, card, previous)) {
      for (final scope in {previous!.boardId, board.id}) {
        await invalidateMutation(account.id, scope);
      }
    }
    return true;
  });
}
