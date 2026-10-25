part of 'database.dart';

bool _olderCardSnapshot(DeckCard card, StoredCard? previous) {
  if (previous == null) return false;
  final old = object(jsonDecode(previous.payload))['lastModified'];
  final fresh = card.raw['lastModified'];
  return old is int && fresh is int && old > fresh;
}

extension _ObservedCardLocations on DeckDatabase {
  Future<bool> _storeObservedCard(
    String accountId,
    int boardId,
    DeckCard card,
    StoredCard? previous,
  ) async {
    await into(storedCards).insertOnConflictUpdate(
      StoredCardsCompanion.insert(
        accountId: accountId,
        remoteId: card.id,
        boardId: boardId,
        stackId: card.stackId,
        position: card.order,
        payload: jsonEncode(card.raw),
      ),
    );
    if (previous == null ||
        previous.boardId == boardId && previous.stackId == card.stackId) {
      return false;
    }
    await (update(storedAttachments)..where(
          (row) => row.accountId.equals(accountId) & row.cardId.equals(card.id),
        ))
        .write(StoredAttachmentsCompanion(boardId: Value(boardId)));
    for (final write in await writesFor(accountId)) {
      if (write.cardId == null ||
          !{'queued', 'conflict', 'blocked'}.contains(write.state)) {
        continue;
      }
      final id =
          await resolveId(accountId, write.cardId!, 'createCard') ??
          write.cardId;
      if (id != card.id) continue;
      // Comment and attachment bases are not card snapshots.
      final cardWrite =
          !attachmentKinds.contains(write.kind) &&
          !write.kind.endsWith('Comment');
      await (update(
        pendingWrites,
      )..where((row) => row.id.equals(write.id))).write(
        PendingWritesCompanion(
          boardId: Value(boardId),
          stackId: Value(card.stackId),
          state: Value(cardWrite ? 'conflict' : 'blocked'),
          error: Value(cardWrite ? 'concurrent_edit' : 'card_moved'),
          remote: cardWrite
              ? Value(jsonEncode(card.raw))
              : const Value.absent(),
        ),
      );
    }
    return true;
  }
}
