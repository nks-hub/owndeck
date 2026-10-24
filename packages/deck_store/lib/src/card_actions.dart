part of 'database.dart';

extension CardActions on DeckDatabase {
  Future<void> queueCardAction(
    StoredAccount account,
    int boardId,
    DeckCard card,
    String kind,
    JsonObject proposal,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation))
      throw StateError('account_unavailable');
    if (!{
      'moveCard',
      'archiveCard',
      'unarchiveCard',
      'deleteCard',
      'assignLabel',
      'removeLabel',
      'assignUser',
      'unassignUser',
    }.contains(kind))
      throw ArgumentError('invalid_operation');
    final resolved =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((b) => b.id == resolved).firstOrNull;
    if (board == null ||
        !board.permissions.edit ||
        board.archived ||
        board.deletedAt != 0)
      throw StateError('permission_denied');
    if (card.archived && !{'unarchiveCard', 'deleteCard'}.contains(kind))
      throw StateError('card_archived');
    if (kind == 'moveCard') {
      final targetId = intField(proposal, 'stackId');
      final target = (await stackView(
        account.id,
        boardId,
      )).where((s) => s.id == targetId).firstOrNull;
      if (target == null || intField(proposal, 'order') < 0)
        throw StateError('invalid_destination');
    }
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        kind: kind,
        boardId: boardId,
        stackId: card.stackId,
        cardId: Value(card.id),
        proposal: jsonEncode(proposal),
        base: Value(jsonEncode(card.raw)),
      ),
    );
  });

  Future<bool> hasEarlierCardWrite(PendingWrite write) async {
    if (write.cardId == null) return false;
    final id =
        await resolveId(write.accountId, write.cardId!, 'createCard') ??
        write.cardId;
    for (final earlier in await writesFor(write.accountId)) {
      if (earlier.sequence >= write.sequence || earlier.cardId == null)
        continue;
      final earlierId =
          await resolveId(write.accountId, earlier.cardId!, 'createCard') ??
          earlier.cardId;
      if (earlierId == id) return true;
    }
    return false;
  }

  Future<void> markApplied(
    StoredAccount account,
    String owner,
    PendingWrite write,
    JsonObject receipt,
  ) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    await (update(pendingWrites)..where(
          (w) =>
              w.accountId.equals(account.id) &
              w.id.equals(write.id) &
              w.state.equals('sending'),
        ))
        .write(
          PendingWritesCompanion(
            state: const Value('applied'),
            remote: Value(jsonEncode(receipt)),
            error: const Value(null),
          ),
        );
  });
}
