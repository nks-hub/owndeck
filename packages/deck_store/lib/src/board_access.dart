part of 'database.dart';

extension BoardAccessStore on DeckDatabase {
  Future<bool> hasCachedCard(String accountId, int boardId, int cardId) async {
    final query = selectOnly(storedCards)
      ..addColumns([storedCards.remoteId])
      ..where(
        storedCards.accountId.equals(accountId) &
            storedCards.boardId.equals(boardId) &
            storedCards.remoteId.equals(cardId) &
            _presentCardSnapshot,
      );
    return await query.getSingleOrNull() != null;
  }

  Future<Set<(int, int)>> cachedCardScopes(String accountId) async {
    final query = selectOnly(storedCards)
      ..addColumns([storedCards.boardId, storedCards.remoteId])
      ..where(storedCards.accountId.equals(accountId) & _presentCardSnapshot);
    return {
      for (final row in await query.get())
        (row.read(storedCards.boardId)!, row.read(storedCards.remoteId)!),
    };
  }

  Future<bool> revokeBoardAccess(
    StoredAccount account,
    int boardId, {
    String reason = 'permission_denied',
  }) => transaction(() async {
    if (boardId <= 0 || !await accepts(account.id, account.generation)) {
      return false;
    }
    final writes = await writesFor(account.id);
    for (final write in writes) {
      final proposal = object(jsonDecode(write.proposal));
      final parents = <int>{write.boardId};
      for (final key in ['destinationBoardId', 'dependentBoardId']) {
        if (proposal[key] is int) parents.add(proposal[key] as int);
      }
      var affected = false;
      for (final parent in parents) {
        if ((await resolveId(account.id, parent, 'createBoard') ?? parent) ==
            boardId) {
          affected = true;
          break;
        }
      }
      if (!affected) continue;
      // Accepted receipts must never become a repeatable blocked operation.
      if (write.state == 'applied') continue;
      await (update(pendingWrites)..where((w) => w.id.equals(write.id))).write(
        PendingWritesCompanion(
          state: Value(
            {'sending', 'uncertain'}.contains(write.state)
                ? 'uncertain'
                : 'blocked',
          ),
          error: Value(reason),
          remote: const Value(null),
        ),
      );
    }
    // An orphaned comment has no cached parent establishing its board scope.
    await customUpdate(
      '''DELETE FROM stored_comments WHERE account_id = ? AND (
        card_id IN (SELECT remote_id FROM stored_cards
          WHERE account_id = ? AND board_id = ?)
        OR card_id IN (SELECT card_id FROM stored_attachments
          WHERE account_id = ? AND board_id = ?)
        OR NOT EXISTS (SELECT 1 FROM stored_cards c
          WHERE c.account_id = stored_comments.account_id
          AND c.remote_id = stored_comments.card_id))''',
      variables: [
        Variable(account.id),
        Variable(account.id),
        Variable(boardId),
        Variable(account.id),
        Variable(boardId),
      ],
      updates: {storedComments},
    );
    await (delete(storedAttachments)..where(
          (a) => a.accountId.equals(account.id) & a.boardId.equals(boardId),
        ))
        .go();
    await (delete(storedCards)..where(
          (c) => c.accountId.equals(account.id) & c.boardId.equals(boardId),
        ))
        .go();
    await (delete(storedStacks)..where(
          (s) => s.accountId.equals(account.id) & s.boardId.equals(boardId),
        ))
        .go();
    await (delete(storedBoards)..where(
          (b) => b.accountId.equals(account.id) & b.remoteId.equals(boardId),
        ))
        .go();
    await invalidateMutation(account.id, boardId);
    return true;
  });
}
