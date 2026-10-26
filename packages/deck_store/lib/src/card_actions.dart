part of 'database.dart';

final class _StaleCardReadback implements Exception {
  const _StaleCardReadback();
}

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
    card = await _cardAfterPendingTransfer(
      account,
      boardId,
      card,
      kind,
      proposal,
    );
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
      if (targetStack == null || (targetStack.raw['deletedAt'] ?? 0) != 0) {
        throw StateError('invalid_destination');
      }
      if (clone) {
        for (final write in await writesFor(account.id)) {
          if (write.kind != 'deleteStack') continue;
          final deleting =
              await resolveId(account.id, write.stackId, 'createStack') ??
              write.stackId;
          if (deleting == resolvedStack) throw StateError('pending_decision');
        }
      }
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
      final resolvedTarget =
          await resolveId(account.id, targetId, 'createStack') ?? targetId;
      final target = (await stackView(
        account.id,
        boardId,
      )).where((s) => s.id == resolvedTarget).firstOrNull;
      if (target == null || (target.raw['deletedAt'] ?? 0) != 0) {
        throw StateError('invalid_destination');
      }
      final sourceId =
          await resolveId(account.id, card.id, 'createCard') ?? card.id;
      final position = {...proposal};
      if (position['anchorCardId'] is int) {
        final anchor = position['anchorCardId']! as int;
        position['anchorCardId'] =
            await resolveId(account.id, anchor, 'createCard') ?? anchor;
      }
      cardPositionIndex(
        cardPositionCandidates(
          target,
          excluding: sourceId,
        ).map((c) => c.id).toList(),
        position,
      );
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

  Future<bool> confirmReconciledCard(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckCardContext context,
    int epoch, {
    List<DeckStack>? boardSnapshot,
  }) async {
    try {
      return await transaction(() async {
        final current = await _ownedAppliedWrite(account, owner, write, epoch);
        if (current == null) return false;
        final receipt = object(jsonDecode(current.remote!));
        final board = context.board;
        final stack = context.stack;
        final card = context.card;
        if (card.id <= 0 ||
            stack.id <= 0 ||
            board.id <= 0 ||
            card.id != receipt['cardId'] ||
            stack.id != card.stackId ||
            stack.boardId != board.id ||
            !board.permissions.read ||
            board.deletedAt != 0 ||
            (stack.raw['deletedAt'] ?? 0) != 0 ||
            (card.raw['deletedAt'] ?? 0) != 0) {
          return false;
        }
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
        if (!await confirmCard(
          account,
          owner,
          write.copyWith(boardId: board.id),
          card,
          contentEpoch: epoch,
        )) {
          return false;
        }
        final oldBoardId = intField(receipt, 'boardId');
        if (oldBoardId != board.id) {
          await invalidateMutation(account.id, oldBoardId);
          await (update(storedAttachments)..where(
                (row) =>
                    row.accountId.equals(account.id) &
                    row.cardId.equals(card.id),
              ))
              .write(StoredAttachmentsCompanion(boardId: Value(board.id)));
        }
        for (final later in await _laterCardWrites(account, write, card.id)) {
          if (oldBoardId != board.id) {
            await (update(
              pendingWrites,
            )..where((row) => row.id.equals(later.id))).write(
              PendingWritesCompanion(
                boardId: Value(board.id),
                stackId: Value(stack.id),
                state: const Value('conflict'),
                error: const Value('concurrent_edit'),
                remote: Value(jsonEncode(card.raw)),
              ),
            );
          } else if (later.kind == 'updateCard' && later.stackId != stack.id) {
            await (update(pendingWrites)
                  ..where((row) => row.id.equals(later.id)))
                .write(PendingWritesCompanion(stackId: Value(stack.id)));
          }
        }
        if (boardSnapshot != null) {
          final currentEpoch = (await this.account(account.id))!.contentEpoch;
          if (!await saveStacks(
            account.id,
            account.generation,
            board.id,
            boardSnapshot,
            null,
            contentEpoch: currentEpoch,
          )) {
            throw const _StaleCardReadback();
          }
        }
        return true;
      });
    } on _StaleCardReadback {
      return false;
    }
  }

  Future<bool> confirmAppliedUnavailable(
    StoredAccount account,
    String owner,
    PendingWrite write,
    int epoch,
    String error,
  ) => transaction(() async {
    final current = await _ownedAppliedWrite(account, owner, write, epoch);
    if (current == null) return false;
    final receipt = object(jsonDecode(current.remote!));
    final cardId = intField(receipt, 'cardId');
    final acceptedCard = receipt['acceptedCard'];
    if (acceptedCard != null) {
      final accepted = DeckCard.fromJson(object(acceptedCard));
      if (accepted.id != cardId || accepted.stackId != receipt['stackId']) {
        return false;
      }
    } else if (current.kind == 'createCard') {
      return false;
    }
    await (delete(storedCards)..where(
          (row) =>
              row.accountId.equals(account.id) & row.remoteId.equals(cardId),
        ))
        .go();
    await (delete(storedComments)..where(
          (row) => row.accountId.equals(account.id) & row.cardId.equals(cardId),
        ))
        .go();
    await (delete(storedAttachments)..where(
          (row) => row.accountId.equals(account.id) & row.cardId.equals(cardId),
        ))
        .go();
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('confirmed'),
        error: const Value(null),
        // Dependent local creations still need the accepted server identity.
        remote: acceptedCard == null
            ? const Value.absent()
            : Value(jsonEncode(acceptedCard)),
      ),
    );
    for (final later in await _laterCardWrites(account, write, cardId)) {
      await (update(
        pendingWrites,
      )..where((row) => row.id.equals(later.id))).write(
        PendingWritesCompanion(
          state: const Value('blocked'),
          error: Value(error),
        ),
      );
    }
    await invalidateMutation(account.id, intField(receipt, 'boardId'));
    return true;
  });

  Future<PendingWrite?> _ownedAppliedWrite(
    StoredAccount account,
    String owner,
    PendingWrite write,
    int epoch,
  ) async {
    if (!await ownsLease(account, owner) ||
        (await this.account(account.id))?.contentEpoch != epoch) {
      return null;
    }
    final current =
        await (select(pendingWrites)..where(
              (row) =>
                  row.accountId.equals(account.id) & row.id.equals(write.id),
            ))
            .getSingleOrNull();
    return current?.state == 'applied' && current?.remote != null
        ? current
        : null;
  }

  Future<List<PendingWrite>> _laterCardWrites(
    StoredAccount account,
    PendingWrite write,
    int cardId,
  ) async {
    final result = <PendingWrite>[];
    for (final later in await writesFor(account.id)) {
      if (later.sequence <= write.sequence ||
          later.state != 'queued' ||
          later.cardId == null) {
        continue;
      }
      final resolved =
          await resolveId(account.id, later.cardId!, 'createCard') ??
          later.cardId;
      if (resolved == cardId) result.add(later);
    }
    return result;
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
              (w.state.equals('sending') |
                  (w.state.equals('uncertain') &
                      w.error.isIn(['permission_denied', 'not_found']))),
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
