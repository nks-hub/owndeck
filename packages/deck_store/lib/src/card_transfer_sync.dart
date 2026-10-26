part of 'sync.dart';

final class _TransferTargetUnavailable implements Exception {
  const _TransferTargetUnavailable(this.boardId, this.reason);
  final int boardId;
  final String reason;
}

extension _CardTransferSync on DeckSync {
  Future<({DeckBoard board, DeckStack stack, List<DeckStack> stacks})>
  _readTransferTarget(int boardId, int stackId, {DeckBoard? knownBoard}) async {
    late DeckBoard board;
    if (knownBoard?.id == boardId) {
      board = knownBoard!;
    } else {
      try {
        board = DeckBoard.fromJson(
          object((await client.rest('GET', ['boards', '$boardId'])).data),
        );
      } on DeckException catch (error) {
        if (error.status == 403 || error.status == 404) {
          throw _TransferTargetUnavailable(boardId, error.code);
        }
        rethrow;
      }
    }
    if (board.id != boardId) throw const FormatException('board_mismatch');
    if (!board.permissions.read) {
      throw _TransferTargetUnavailable(boardId, 'permission_denied');
    }
    if (!board.permissions.edit || board.archived || board.deletedAt != 0) {
      throw const DeckException('permission_denied', status: 403);
    }
    if (board.raw['externalId'] != null) {
      throw StateError('unsupported_operation');
    }
    final stacks = await client.doneStackState(boardId);
    final stack = stacks
        .where((s) => s.id == stackId && (s.raw['deletedAt'] ?? 0) == 0)
        .firstOrNull;
    if (stack == null) throw StateError('invalid_destination');
    return (board: board, stack: stack, stacks: stacks);
  }

  Future<bool> _sendCardTransfer(
    PendingWrite write,
    DeckBoard sourceBoard,
  ) async {
    var mutationStarted = false;
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final positioning = proposal['phase'] == 'position';
      if (!positioning && proposal['phase'] != 'transfer') {
        throw const FormatException('invalid_transfer_phase');
      }
      final capabilities = await client.capabilities();
      await database.saveCapabilities(account, capabilities);
      final current = await _readCurrentCardContext(
        write.boardId,
        write.stackId,
        write.cardId!,
        knownBoard: sourceBoard,
      );
      final targetBoardId = intField(proposal, 'destinationBoardId');
      final targetStackId = intField(proposal, 'destinationStackId');
      if (positioning && current.board.id != targetBoardId) {
        await database.saveReadCard(account, current, epoch);
        await database.markWrite(
          account,
          _owner,
          write.id,
          'blocked',
          error: 'card_moved',
          remote: current.card.raw,
        );
        return true;
      }
      if (!positioning &&
          current.board.id == targetBoardId &&
          current.stack.id == targetStackId) {
        // A retried transfer the server already applied: only positioning is left.
        final receipt = <String, Object?>{
          'phase': 'transfer',
          'sourceBoardId': write.boardId,
          'sourceStackId': write.stackId,
          'boardId': targetBoardId,
          'stackId': targetStackId,
          'cardId': current.card.id,
          'acceptedCard': current.card.raw,
          'beforeCard': current.card.raw,
        };
        await database.markApplied(account, _owner, write, receipt);
        return _finishCardTransfer(
          write.copyWith(remote: Value(jsonEncode(receipt))),
        );
      }
      final expectedLocation =
          current.board.id == write.boardId &&
          current.stack.id == write.stackId;
      final confirmedDestination =
          positioning &&
          current.board.id == targetBoardId &&
          current.stack.id == targetStackId;
      if (!expectedLocation && !confirmedDestination) {
        final saved = await database.flagMovedCardWrite(
          account,
          _owner,
          write,
          current,
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
      if (!current.board.permissions.edit ||
          current.board.archived ||
          current.card.archived) {
        throw StateError(
          current.card.archived ? 'card_archived' : 'permission_denied',
        );
      }
      if (current.board.raw['externalId'] != null) {
        throw StateError('unsupported_operation');
      }
      if (!positioning && current.board.id == targetBoardId) {
        throw StateError('invalid_destination');
      }
      final target = await _readTransferTarget(
        targetBoardId,
        targetStackId,
        knownBoard: positioning ? current.board : null,
      );
      final siblings = cardPositionCandidates(
        target.stack,
        excluding: current.card.id,
      );
      final order = cardPositionIndex(
        siblings.map((c) => c.id).toList(),
        proposal,
      );
      if (!positioning) {
        if (target.stacks.any(
          (s) => s.cards.any((c) => c.id == current.card.id),
        )) {
          throw StateError('card_moved');
        }
        final appendOrder = siblings.fold<int>(
          0,
          (next, card) => card.order >= next ? card.order + 1 : next,
        );
        final done = target.stack.isDoneColumn
            ? DateTime.now().toUtc().toIso8601String()
            : current.stack.isDoneColumn
            ? null
            : current.card.raw['done'];
        final request = CardUpdateRequest.transfer(
          current.card,
          destinationBoardId: target.board.id,
          destinationStackId: target.stack.id,
          order: appendOrder,
          done: done,
        );
        if (_closed || !await database.acquireLease(account, _owner)) {
          await database.markWrite(account, _owner, write.id, 'queued');
          return false;
        }
        mutationStarted = true;
        final accepted = await client.updateCardSafely(request);
        final receipt = <String, Object?>{
          'phase': 'transfer',
          'sourceBoardId': current.board.id,
          'sourceStackId': current.stack.id,
          'boardId': target.board.id,
          'stackId': target.stack.id,
          'cardId': accepted.id,
          'acceptedCard': accepted.raw,
          'beforeCard': current.card.raw,
        };
        await database.markApplied(account, _owner, write, receipt);
        return _finishCardTransfer(
          write.copyWith(remote: Value(jsonEncode(receipt))),
        );
      }
      final transfer = object(proposal['transferReceipt']);
      final accepted = DeckCard.fromJson(object(transfer['acceptedCard']));
      if (accepted.id != current.card.id ||
          transfer['boardId'] != targetBoardId ||
          transfer['stackId'] != targetStackId) {
        throw const FormatException('invalid_transfer_receipt');
      }
      final latest = _cardInBoardSnapshot(
        target.board,
        current.card.id,
        target.stacks,
      );
      if (latest == null) throw StateError('card_moved');
      final latestStack = latest.stack;
      final latestCard = latest.card;
      if (latestCard.archived || (latestCard.raw['deletedAt'] ?? 0) != 0) {
        throw StateError('card_unavailable');
      }
      if (latestStack.id != write.stackId && latestStack.id != targetStackId) {
        final saved = await database.flagMovedCardWrite(
          account,
          _owner,
          write,
          DeckCardContext(
            board: target.board,
            stack: latestStack,
            card: latestCard,
          ),
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
      final all = cardPositionCandidates(target.stack);
      final currentOrder = all.indexWhere((c) => c.id == latestCard.id);
      final unchanged =
          latestStack.id == targetStackId &&
          currentOrder == order &&
          all.asMap().entries.every((entry) => entry.key == entry.value.order);
      if (_closed || !await database.acquireLease(account, _owner)) {
        await database.markWrite(account, _owner, write.id, 'queued');
        return false;
      }
      if (!unchanged) {
        mutationStarted = true;
        await client.reorderCard(
          targetBoardId,
          targetStackId,
          current.card.id,
          order,
        );
      }
      final receipt = <String, Object?>{
        'phase': 'position',
        'sourceBoardId': transfer['sourceBoardId'],
        'sourceStackId': transfer['sourceStackId'],
        'boardId': targetBoardId,
        'stackId': targetStackId,
        'cardId': current.card.id,
        'acceptedCard': transfer['acceptedCard'],
        'order': order,
        'positionAlreadySatisfied': unchanged,
      };
      await database.markApplied(account, _owner, write, receipt);
      return _finishCardTransfer(
        write.copyWith(remote: Value(jsonEncode(receipt))),
      );
    } on _TransferTargetUnavailable catch (error) {
      return database.refuseCardTransfer(
        account,
        _owner,
        write,
        error.reason,
        deniedBoardId: error.boardId,
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
        'card_moved',
        'card_unavailable',
        'card_archived',
        'permission_denied',
        'unsupported_operation',
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

  Future<bool> _finishCardTransfer(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    final receipt = object(jsonDecode(write.remote!));
    try {
      final context = await _readCurrentCardContext(
        intField(receipt, 'boardId'),
        intField(receipt, 'stackId'),
        intField(receipt, 'cardId'),
      );
      if (receipt['phase'] == 'transfer') {
        return database.prepareCardTransferPosition(
          account,
          _owner,
          write,
          context,
          epoch,
        );
      }
      if (receipt['phase'] != 'position') {
        throw const FormatException('invalid_transfer_phase');
      }
      final stacks = await client.doneStackState(context.board.id);
      final latest = _cardInBoardSnapshot(
        context.board,
        context.card.id,
        stacks,
      );
      if (latest == null) return false;
      return database.confirmCardTransfer(
        account,
        _owner,
        write,
        latest,
        stacks,
        epoch,
      );
    } on _CardContextUnavailable catch (error) {
      if (receipt['phase'] == 'transfer') {
        return database.blockAcceptedCardTransfer(
          account,
          _owner,
          write,
          epoch,
          error.code,
          deniedBoardId: error.boardId,
        );
      }
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
