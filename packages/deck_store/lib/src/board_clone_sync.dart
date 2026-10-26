part of 'sync.dart';

extension _BoardCloneSync on DeckSync {
  Future<bool> _sendBoardClone(PendingWrite write) async {
    var started = false;
    var mutationStarted = false;
    var readingSource = false;
    try {
      final options = BoardCloneOptions.fromJson(
        object(jsonDecode(write.proposal)),
      );
      final capabilities = await client.capabilities();
      await database.saveCapabilities(account, capabilities);
      if (!capabilities.supportsBoardCloning || !capabilities.canCreateBoards) {
        if (await _start(write.id)) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: capabilities.supportsBoardCloning
                ? 'permission_denied'
                : 'unsupported_operation',
          );
        }
        return true;
      }
      readingSource = true;
      final source = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '${write.boardId}'])).data),
      );
      if (source.id != write.boardId) {
        throw const FormatException('board_mismatch');
      }
      if (!source.permissions.read || source.deletedAt != 0) {
        throw const DeckException('permission_denied', status: 403);
      }
      readingSource = false;
      if (_closed || !await database.acquireLease(account, _owner)) {
        return false;
      }
      started = await _start(write.id);
      if (!started) return true;
      mutationStarted = true;
      final created = await client.cloneBoard(write.boardId, options);
      final receipt = <String, Object?>{'createdBoard': created.raw};
      await database.markApplied(account, _owner, write, receipt);
      return _finishClonedBoard(
        write.copyWith(remote: Value(jsonEncode(receipt))),
      );
    } on DeckException catch (error) {
      if (readingSource && (error.status == 403 || error.status == 404)) {
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

  Future<bool> _finishClonedBoard(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    try {
      final receipt = object(jsonDecode(write.remote!));
      final created = DeckBoard.fromJson(object(receipt['createdBoard']));
      final current = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '${created.id}'])).data),
      );
      return database.confirmBoardClone(account, _owner, write, current, epoch);
    } on DeckException catch (error) {
      if (error.status == 403 || error.status == 404) {
        return database.confirmBoardClone(account, _owner, write, null, epoch);
      }
      return false;
    } on FormatException {
      return false;
    }
  }
}
