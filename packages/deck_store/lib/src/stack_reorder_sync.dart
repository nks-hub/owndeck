part of 'sync.dart';

extension _StackReorderSync on DeckSync {
  Future<bool> _sendStackReorder(PendingWrite write) async {
    var started = false;
    var mutationStarted = false;
    var readingBoard = false;
    try {
      readingBoard = true;
      final board = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '${write.boardId}'])).data),
      );
      if (board.id != write.boardId) {
        throw const FormatException('invalid_board_identity');
      }
      if (!board.permissions.read) {
        throw const DeckException('permission_denied', status: 403);
      }
      readingBoard = false;
      if (!board.permissions.manage || board.archived || board.deletedAt != 0) {
        throw const DeckException('permission_denied', status: 403);
      }
      final stacks = await client.stacks(write.boardId);
      final ids = <int>{};
      for (final stack in stacks) {
        if (stack.boardId != write.boardId ||
            stack.id <= 0 ||
            !ids.add(stack.id)) {
          throw const FormatException('invalid_stack_identity');
        }
      }
      final ordered =
          stacks.where((s) => (s.raw['deletedAt'] ?? 0) == 0).toList()..sort(
            (a, b) => a.order == b.order
                ? a.id.compareTo(b.id)
                : a.order.compareTo(b.order),
          );
      final previous = ordered.indexWhere((s) => s.id == write.stackId);
      if (previous < 0) throw StateError('invalid_destination');
      final siblings = ordered
          .where((s) => s.id != write.stackId)
          .map((s) => s.id)
          .toList();
      final proposal = object(jsonDecode(write.proposal));
      final order = stackReorderIndex(siblings, proposal);
      if (_closed || !await database.acquireLease(account, _owner)) {
        return false;
      }
      started = await _start(write.id);
      if (!started) return true;
      if (proposal.containsKey('legacyOrder') && write.base != null) {
        final original = object(jsonDecode(write.base!))['order'];
        final current = ordered[previous];
        if (original is int &&
            current.order != original &&
            current.order != order) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'conflict',
            error: 'concurrent_edit',
            remote: current.raw,
          );
          return true;
        }
      }
      if (previous != order ||
          ordered.asMap().entries.any(
            (entry) => entry.value.order != entry.key,
          )) {
        mutationStarted = true;
        await client.reorderStack(write.boardId, write.stackId, order);
      }
      final receipt = {
        'boardId': write.boardId,
        'stackId': write.stackId,
        'order': order,
      };
      await database.markApplied(account, _owner, write, receipt);
      return _finishStackReorder(
        write.copyWith(remote: Value(jsonEncode(receipt))),
      );
    } on DeckException catch (error) {
      if (readingBoard && (error.status == 403 || error.status == 404)) {
        await database.revokeBoardAccess(
          account,
          write.boardId,
          reason: error.code,
        );
        return true;
      }
      final retry = _shouldRetry(error, mutationStarted);
      if (!started && retry) rethrow;
      if (!started) {
        started = await _start(write.id);
      }
      if (started) {
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
      }
      if (retry) rethrow;
      return !error.uncertain;
    } on StateError catch (error) {
      if (!started) {
        started = await _start(write.id);
      }
      if (started) {
        await database.markWrite(
          account,
          _owner,
          write.id,
          'blocked',
          error: error.message == 'invalid_position'
              ? 'invalid_position'
              : 'invalid_destination',
        );
      }
      return true;
    } on FormatException {
      if (!started) {
        started = await _start(write.id);
      }
      if (started) {
        await database.markWrite(
          account,
          _owner,
          write.id,
          mutationStarted ? 'uncertain' : 'blocked',
          error: 'invalid_response',
        );
      }
      return false;
    }
  }

  Future<bool> _finishStackReorder(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    var epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    var readingBoard = false;
    try {
      readingBoard = true;
      final board = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '${write.boardId}'])).data),
      );
      if (board.id != write.boardId) {
        throw const FormatException('invalid_board_identity');
      }
      if (!board.permissions.read || board.deletedAt != 0) {
        throw const DeckException('permission_denied', status: 403);
      }
      readingBoard = false;
      final stacks = await client.doneStackState(write.boardId);
      return database.confirmStackReorder(
        account,
        _owner,
        write,
        stacks,
        epoch,
      );
    } on DeckException catch (error) {
      if (!readingBoard || error.status != 403 && error.status != 404) {
        return false;
      }
      if (!await database.revokeBoardAccess(
        account,
        write.boardId,
        reason: error.code,
      )) {
        return false;
      }
      epoch = (await database.account(account.id))?.contentEpoch;
      if (epoch == null) return false;
      return database.confirmStackReorder(account, _owner, write, null, epoch);
    } on FormatException {
      return false;
    }
  }
}
