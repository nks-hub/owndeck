part of 'sync.dart';

extension _StructureSync on DeckSync {
  Future<bool> _sendStructure(PendingWrite write) async {
    var started = false;
    var mutationStarted = false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final isBoard = write.kind.endsWith('Board');
      JsonObject? current;
      int? appendOrder;
      bool allowed;
      if (write.kind == 'createBoard') {
        final capabilities = await client.capabilities();
        await database.saveCapabilities(account, capabilities);
        allowed = capabilities.canCreateBoards;
      } else if (write.kind == 'restoreBoard') {
        final boards = await client.boards();
        final board = boards.where((b) => b.id == write.boardId).firstOrNull;
        if (board == null) throw const DeckException('not_found', status: 404);
        current = board.raw;
        allowed = board.permissions.manage && board.deletedAt != 0;
      } else {
        final board = DeckBoard.fromJson(
          object(
            (await client.rest('GET', ['boards', '${write.boardId}'])).data,
          ),
        );
        allowed =
            board.permissions.manage &&
            board.deletedAt == 0 &&
            (!board.archived || write.kind == 'updateBoard');
        if (isBoard) {
          current = board.raw;
        } else if (write.kind == 'createStack') {
          final siblings = await client.stacks(write.boardId);
          if (siblings.any((stack) => stack.boardId != write.boardId)) {
            throw const FormatException('invalid_stack_identity');
          }
          appendOrder = siblings.fold<int>(
            0,
            (next, stack) => stack.order >= next ? stack.order + 1 : next,
          );
        } else if (write.kind != 'createStack') {
          current = object(
            (await client.rest('GET', [
              'boards',
              '${write.boardId}',
              'stacks',
              '${write.stackId}',
            ])).data,
          );
        }
      }
      if (_closed || !await database.acquireLease(account, _owner)) {
        return false;
      }
      started = await _start(write.id);
      if (!started) return true;
      if (!allowed) {
        await database.markWrite(
          account,
          _owner,
          write.id,
          'blocked',
          error: 'permission_denied',
        );
        return true;
      }
      if (write.kind == 'setDoneStack') {
        if (current?['isDoneColumn'] is! bool ||
            current?['id'] != write.stackId ||
            current?['boardId'] != write.boardId) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: 'unsupported_operation',
          );
          return true;
        }
        if (!await database.acquireLease(account, _owner) || _closed) {
          await database.markWrite(account, _owner, write.id, 'queued');
          return false;
        }
        mutationStarted = true;
        await client.setDoneStack(
          write.boardId,
          write.stackId,
          proposal['isDone']! as bool,
        );
        final receipt = {
          'boardId': write.boardId,
          'stackId': write.stackId,
          'isDone': proposal['isDone'],
        };
        await database.markApplied(account, _owner, write, receipt);
        return _finishDoneStack(
          write.copyWith(remote: Value(jsonEncode(receipt))),
        );
      }
      if (current != null && write.base != null) {
        final base = object(jsonDecode(write.base!));
        final keys = write.kind.startsWith('delete')
            ? ['lastModified']
            : proposal.keys;
        final conflict = keys.any(
          (key) =>
              current![key] != base[key] &&
              (write.kind.startsWith('delete') ||
                  current[key] != proposal[key]),
        );
        if (conflict) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'conflict',
            error: 'concurrent_edit',
            remote: current,
          );
          return true;
        }
      }
      final path = isBoard
          ? [
              'boards',
              if (write.kind != 'createBoard') '${write.boardId}',
              if (write.kind == 'restoreBoard') 'undo_delete',
            ]
          : [
              'boards',
              '${write.boardId}',
              'stacks',
              if (write.kind != 'createStack') '${write.stackId}',
            ];
      final body =
          write.kind.startsWith('delete') || write.kind == 'restoreBoard'
          ? null
          : isBoard
          ? <String, Object?>{
              'title': proposal['title'] ?? current?['title'],
              'color': proposal['color'] ?? current?['color'],
              if (write.kind == 'updateBoard')
                'archived':
                    proposal['archived'] ?? current?['archived'] ?? false,
            }
          : <String, Object?>{
              'title': proposal['title'] ?? current?['title'],
              'order': appendOrder ?? current?['order'] ?? 0,
            };
      mutationStarted = true;
      final response = await client.rest(
        write.kind.startsWith('create') || write.kind == 'restoreBoard'
            ? 'POST'
            : write.kind.startsWith('delete')
            ? 'DELETE'
            : 'PUT',
        path,
        body: body,
      );
      final remote = <String, Object?>{...?current, ...object(response.data)};
      await database.confirmStructure(account, _owner, write, remote);
      return true;
    } on DeckException catch (error) {
      if (!started) {
        if (error.status != 403 && error.status != 404) rethrow;
        started = await _start(write.id);
      }
      if (started) {
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
      }
      return !error.uncertain;
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

  Future<bool> _finishDoneStack(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    try {
      final receipt = object(jsonDecode(write.remote!));
      final stacks = await client.doneStackState(write.boardId);
      final target = stacks
          .where((stack) => stack.id == write.stackId)
          .firstOrNull;
      final isDone = receipt['isDone'];
      if (isDone is! bool ||
          target == null ||
          !target.supportsDoneColumn ||
          target.isDoneColumn != isDone) {
        return false;
      }
      if (isDone &&
          (stacks.where((stack) => stack.isDoneColumn).length != 1 ||
              target.cards.any(
                (card) =>
                    !card.archived &&
                    (card.raw['deletedAt'] ?? 0) == 0 &&
                    card.raw['done'] == null,
              ))) {
        return false;
      }
      return database.confirmDoneStack(account, _owner, write, stacks);
    } on DeckException {
      return false;
    } on FormatException {
      return false;
    }
  }
}
