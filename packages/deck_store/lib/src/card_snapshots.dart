part of 'database.dart';

const _missingCardPrefix = '{"_snapshotMissing":true,';
// Availability queries can skip tombstones without decoding every card body.
final _presentCardSnapshot = CustomExpression<bool>(
  "payload NOT GLOB '$_missingCardPrefix*'",
);

bool _missingCardSnapshot(StoredCard card) =>
    card.payload.startsWith(_missingCardPrefix);

bool _olderCardSnapshot(DeckCard card, StoredCard? previous) {
  if (previous == null) return false;
  final old = object(jsonDecode(previous.payload))['lastModified'];
  final fresh = card.raw['lastModified'];
  return old is int && fresh is int && old > fresh;
}

extension _ObservedCardLocations on DeckDatabase {
  Future<bool> _retainMissingCardIdentities(
    String accountId,
    Iterable<StoredCard> missing,
  ) async {
    final changed = <int>{};
    for (final card in missing) {
      if (!_missingCardSnapshot(card)) changed.add(card.remoteId);
      final raw = object(jsonDecode(card.payload));
      await into(storedCards).insertOnConflictUpdate(
        StoredCardsCompanion.insert(
          accountId: accountId,
          remoteId: card.remoteId,
          boardId: card.boardId,
          stackId: card.stackId,
          position: card.position,
          payload: jsonEncode({
            '_snapshotMissing': true,
            'id': card.remoteId,
            'stackId': card.stackId,
            if (raw['lastModified'] is int) 'lastModified': raw['lastModified'],
          }),
        ),
      );
    }
    if (changed.isEmpty) return false;
    for (final write in await writesFor(accountId)) {
      if (write.state != 'queued' || write.cardId == null) continue;
      final id =
          await resolveId(accountId, write.cardId!, 'createCard') ??
          write.cardId;
      if (!changed.contains(id)) continue;
      await (update(
        pendingWrites,
      )..where((row) => row.id.equals(write.id))).write(
        const PendingWritesCompanion(
          state: Value('blocked'),
          error: Value('not_found'),
        ),
      );
    }
    return true;
  }

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
        !_missingCardSnapshot(previous) &&
            previous.boardId == boardId &&
            previous.stackId == card.stackId) {
      return false;
    }
    await (update(storedAttachments)..where(
          (row) => row.accountId.equals(accountId) & row.cardId.equals(card.id),
        ))
        .write(StoredAttachmentsCompanion(boardId: Value(boardId)));
    final drafts =
        await (select(editorDrafts)..where(
              (row) => row.accountId.equals(accountId) & row.cardId.isNotNull(),
            ))
            .get();
    for (final draft in drafts) {
      final id =
          await resolveId(accountId, draft.cardId!, 'createCard') ??
          draft.cardId;
      if (id != card.id) continue;
      final original = draft.base == null
          ? null
          : object(jsonDecode(draft.base!));
      final resolveBase =
          draft.kind == 'card' && draft.cardId! < 0 && original != null;
      await (update(editorDrafts)..where(
            (row) =>
                row.accountId.equals(accountId) &
                row.draftKey.equals(draft.draftKey),
          ))
          .write(
            EditorDraftsCompanion(
              boardId: Value(boardId),
              stackId: Value(card.stackId),
              cardId: Value(card.id),
              base: resolveBase
                  ? Value(jsonEncode({...original, 'id': card.id}))
                  : const Value.absent(),
            ),
          );
    }
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
