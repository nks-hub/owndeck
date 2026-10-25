part of 'database.dart';

extension DeckReadCards on DeckDatabase {
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
