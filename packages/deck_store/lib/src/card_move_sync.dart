part of 'sync.dart';

extension _CardMoveSync on DeckSync {
  Future<bool> _sendCardMove(PendingWrite write, DeckBoard board) async {
    var mutationStarted = false;
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final destination = intField(proposal, 'stackId');
      final current = await _readCurrentCardContext(
        write.boardId,
        write.stackId,
        write.cardId!,
        knownBoard: board,
      );
      if (current.board.id != write.boardId ||
          current.stack.id != write.stackId &&
              current.stack.id != destination) {
        return _recordMoveConflict(write, current, epoch);
      }
      if (current.card.archived ||
          !current.board.permissions.edit ||
          current.board.archived) {
        throw StateError('card_unavailable');
      }
      final stacks = await client.doneStackState(write.boardId);
      final latest = _cardInBoardSnapshot(
        current.board,
        current.card.id,
        stacks,
      );
      if (latest == null ||
          latest.card.archived ||
          (latest.card.raw['deletedAt'] ?? 0) != 0) {
        return database.blockUnavailableCardWrite(
          account,
          _owner,
          write,
          epoch,
          'not_found',
        );
      }
      final target = stacks
          .where(
            (stack) =>
                stack.id == destination && (stack.raw['deletedAt'] ?? 0) == 0,
          )
          .firstOrNull;
      if (target == null) throw StateError('invalid_destination');
      final order = cardPositionIndex(
        cardPositionCandidates(
          target,
          excluding: latest.card.id,
        ).map((c) => c.id).toList(),
        proposal,
      );
      final atTarget = latest.stack.id == destination;
      final alreadyPlaced =
          atTarget &&
          cardPositionCandidates(
                target,
              ).indexWhere((c) => c.id == latest.card.id) ==
              order;
      if (latest.stack.id != write.stackId && !alreadyPlaced) {
        return _recordMoveConflict(write, latest, epoch);
      }
      if (_closed || !await database.acquireLease(account, _owner)) {
        await database.markWrite(account, _owner, write.id, 'queued');
        return false;
      }
      if (!alreadyPlaced) {
        mutationStarted = true;
        await client.reorderCard(
          write.boardId,
          destination,
          latest.card.id,
          order,
        );
      }
      final receipt = <String, Object?>{
        'boardId': write.boardId,
        'stackId': destination,
        'cardId': latest.card.id,
        'observedPosition': alreadyPlaced,
      };
      await database.markApplied(account, _owner, write, receipt);
      return _finishCardMove(
        write.copyWith(remote: Value(jsonEncode(receipt))),
      );
    } on _CardContextUnavailable catch (error) {
      final blocked = await database.blockUnavailableCardWrite(
        account,
        _owner,
        write,
        epoch,
        error.code,
        deniedBoardId: error.boardId,
      );
      if (!blocked) {
        await database.markWrite(
          account,
          _owner,
          write.id,
          'queued',
          error: 'stale_response',
        );
      }
      return blocked;
    } on DeckException catch (error) {
      final retry = _shouldRetry(error, mutationStarted);
      await database.markWrite(
        account,
        _owner,
        write.id,
        mutationStarted && error.uncertain
            ? 'uncertain'
            : retry
            ? 'queued'
            : 'blocked',
        error: error.code,
      );
      if (retry) rethrow;
      return !error.uncertain;
    } on StateError catch (error) {
      const known = {
        'invalid_destination',
        'invalid_position',
        'card_unavailable',
      };
      await database.markWrite(
        account,
        _owner,
        write.id,
        'blocked',
        error: known.contains(error.message)
            ? error.message
            : 'invalid_destination',
      );
      return true;
    } on FormatException {
      await database.markWrite(
        account,
        _owner,
        write.id,
        mutationStarted ? 'uncertain' : 'blocked',
        error: 'invalid_response',
      );
      return false;
    }
  }

  Future<bool> _recordMoveConflict(
    PendingWrite write,
    DeckCardContext context,
    int epoch,
  ) async {
    final saved = await database.flagMovedCardWrite(
      account,
      _owner,
      write,
      context,
      epoch,
    );
    if (!saved) {
      await database.markWrite(
        account,
        _owner,
        write.id,
        'queued',
        error: 'stale_response',
      );
    }
    return saved;
  }

  Future<bool> _finishCardMove(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    try {
      final receipt = object(jsonDecode(write.remote!));
      final context = await _readCurrentCardContext(
        intField(receipt, 'boardId'),
        intField(receipt, 'stackId'),
        intField(receipt, 'cardId'),
      );
      final stacks = await client.doneStackState(context.board.id);
      final latest = _cardInBoardSnapshot(
        context.board,
        context.card.id,
        stacks,
      );
      if (latest == null) return false;
      return database.confirmReconciledCard(
        account,
        _owner,
        write,
        latest,
        epoch,
        boardSnapshot: stacks,
      );
    } on _CardContextUnavailable catch (error) {
      return _finishUnavailableCard(
        write,
        epoch,
        error.code,
        boardId: error.boardId,
      );
    } on DeckException {
      return false;
    } on FormatException {
      return false;
    }
  }
}
