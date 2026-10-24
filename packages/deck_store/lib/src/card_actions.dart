part of 'database.dart';

extension CardActions on DeckDatabase {
  Future<void> queueCardAction(
    StoredAccount account,
    int boardId,
    DeckCard card,
    String kind,
    JsonObject proposal,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    if (!{
      'moveCard',
      'archiveCard',
      'unarchiveCard',
      'deleteCard',
      'assignLabel',
      'removeLabel',
      'assignUser',
      'unassignUser',
      'cloneCard',
      'addCardLink',
      'removeCardLink',
    }.contains(kind)) {
      throw ArgumentError('invalid_operation');
    }
    final resolved =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((b) => b.id == resolved).firstOrNull;
    if (board == null ||
        (kind == 'cloneCard'
            ? !board.permissions.read
            : !board.permissions.edit || board.archived) ||
        board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    if (card.archived &&
        !{'unarchiveCard', 'deleteCard', 'cloneCard'}.contains(kind)) {
      throw StateError('card_archived');
    }
    if ((card.raw['deletedAt'] ?? 0) != 0) throw StateError('card_unavailable');
    if (kind == 'cloneCard' ||
        kind == 'addCardLink' ||
        kind == 'removeCardLink') {
      final clone = kind == 'cloneCard';
      final targetBoardId = intField(
        proposal,
        clone ? 'destinationBoardId' : 'dependentBoardId',
      );
      final targetStackId = intField(
        proposal,
        clone ? 'destinationStackId' : 'dependentStackId',
      );
      final resolvedTarget =
          await resolveId(account.id, targetBoardId, 'createBoard') ??
          targetBoardId;
      final targetBoard = (await boardView(
        account.id,
      )).where((b) => b.id == resolvedTarget).firstOrNull;
      if (targetBoard == null ||
          !targetBoard.permissions.read ||
          targetBoard.deletedAt != 0 ||
          clone && (!targetBoard.permissions.edit || targetBoard.archived)) {
        throw StateError('permission_denied');
      }
      final resolvedStack =
          await resolveId(account.id, targetStackId, 'createStack') ??
          targetStackId;
      final targetStack = (await stackView(
        account.id,
        targetBoardId,
      )).where((s) => s.id == resolvedStack).firstOrNull;
      if (targetStack == null) throw StateError('invalid_destination');
      if (!clone) {
        final targetId = intField(proposal, 'dependentCardId');
        final resolvedCard =
            await resolveId(account.id, targetId, 'createCard') ?? targetId;
        final sourceId =
            await resolveId(account.id, card.id, 'createCard') ?? card.id;
        if (resolvedCard == sourceId ||
            !targetStack.cards.any(
              (card) =>
                  card.id == resolvedCard && (card.raw['deletedAt'] ?? 0) == 0,
            )) {
          throw StateError('invalid_card_link');
        }
      }
    }
    if (kind == 'moveCard') {
      final targetId = intField(proposal, 'stackId');
      final target = (await stackView(
        account.id,
        boardId,
      )).where((s) => s.id == targetId).firstOrNull;
      if (target == null || intField(proposal, 'order') < 0) {
        throw StateError('invalid_destination');
      }
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
      if (earlier.sequence >= write.sequence || earlier.cardId == null) {
        continue;
      }
      final earlierId =
          await resolveId(write.accountId, earlier.cardId!, 'createCard') ??
          earlier.cardId;
      if (earlierId == id) return true;
    }
    return false;
  }

  Future<bool> confirmClonedCard(
    StoredAccount account,
    String owner,
    PendingWrite write,
    int boardId,
    DeckCard card,
  ) => transaction(() async {
    if (!await ownsLease(account, owner)) return false;
    final row =
        await (select(storedBoards)..where(
              (b) =>
                  b.accountId.equals(account.id) & b.remoteId.equals(boardId),
            ))
            .getSingleOrNull();
    if (row == null) return false;
    final board = DeckBoard.fromJson(object(jsonDecode(row.payload)));
    if (!board.permissions.read || board.deletedAt != 0) return false;
    await confirmCard(account, owner, write.copyWith(boardId: boardId), card);
    return (await (select(
          pendingWrites,
        )..where((w) => w.id.equals(write.id))).getSingle()).state ==
        'confirmed';
  });

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
