part of 'sync.dart';

extension _CardActionSync on DeckSync {
  Future<bool> _sendCardAction(PendingWrite write) async {
    var mutationStarted = false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final path = [
        'boards',
        '${write.boardId}',
        'stacks',
        '${write.stackId}',
        'cards',
        '${write.cardId}',
      ];
      final current = DeckCard.fromJson(
        object((await client.rest('GET', path)).data),
      );
      if (current.id != write.cardId) {
        throw const FormatException('invalid_card_identity');
      }
      final base = write.base == null
          ? <String, Object?>{}
          : object(jsonDecode(write.base!));
      final conflict =
          write.kind == 'moveCard' && current.stackId != write.stackId ||
          {'deleteCard', 'cloneCard'}.contains(write.kind) &&
              [
                    'title',
                    'description',
                    'stackId',
                    'duedate',
                    'archived',
                    'lastModified',
                    if (write.kind == 'cloneCard') ...[
                      'labels',
                      'assignedUsers',
                    ],
                  ]
                  .where(base.containsKey)
                  .any(
                    (key) =>
                        jsonEncode(current.raw[key]) !=
                        jsonEncode(
                          key == 'stackId' ? write.stackId : base[key],
                        ),
                  );
      if (conflict) {
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
      path[3] = '${current.stackId}';
      if (write.kind == 'cloneCard') {
        final boardId = intField(proposal, 'destinationBoardId');
        final stackId = intField(proposal, 'destinationStackId');
        final targetBoard = DeckBoard.fromJson(
          object((await client.rest('GET', ['boards', '$boardId'])).data),
        );
        final targetStack = object(
          (await client.rest('GET', [
            'boards',
            '$boardId',
            'stacks',
            '$stackId',
          ])).data,
        );
        if (!targetBoard.permissions.read ||
            !targetBoard.permissions.edit ||
            targetBoard.archived ||
            targetBoard.deletedAt != 0 ||
            (targetStack['deletedAt'] ?? 0) != 0 ||
            targetBoard.id != boardId ||
            intField(targetStack, 'boardId') != boardId ||
            intField(targetStack, 'id') != stackId) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: 'permission_denied',
          );
          return true;
        }
        if (!await database.acquireLease(account, _owner) || _closed) {
          await database.markWrite(account, _owner, write.id, 'queued');
          return false;
        }
        mutationStarted = true;
        final copied = await client.cloneCard(current.id, stackId);
        final receipt = {
          'boardId': boardId,
          'stackId': stackId,
          'cardId': copied.id,
        };
        await database.markApplied(account, _owner, write, receipt);
        return _finishApplied(
          write.copyWith(remote: Value(jsonEncode(receipt))),
        );
      }
      var method = 'PUT';
      JsonObject? body;
      switch (write.kind) {
        case 'moveCard':
          // Deck binds stackId from the route before the body: use the destination in both.
          path[3] = '${intField(proposal, 'stackId')}';
          path.add('reorder');
          body = {'stackId': proposal['stackId'], 'order': proposal['order']};
        case 'archiveCard':
          path.add('archive');
        case 'unarchiveCard':
          path.add('unarchive');
        case 'deleteCard':
          method = 'DELETE';
        case 'assignLabel':
        case 'removeLabel':
          path.add(write.kind);
          body = {'labelId': intField(proposal, 'labelId')};
        case 'assignUser':
        case 'unassignUser':
          path.add(write.kind);
          body = {
            'userId': stringField(proposal, 'userId'),
            'type': proposal['type'] ?? 0,
          };
        case 'addCardLink':
        case 'removeCardLink':
          final targetId = intField(proposal, 'dependentCardId');
          if (targetId == current.id) {
            throw const FormatException('invalid_card_link');
          }
          final target = DeckCard.fromJson(
            object(
              (await client.rest('GET', [
                'boards',
                '${intField(proposal, 'dependentBoardId')}',
                'stacks',
                '${intField(proposal, 'dependentStackId')}',
                'cards',
                '$targetId',
              ])).data,
            ),
          );
          if (target.id != targetId ||
              target.stackId != proposal['dependentStackId'] ||
              (target.raw['deletedAt'] ?? 0) != 0) {
            throw const FormatException('invalid_card_link');
          }
          method = write.kind == 'addCardLink' ? 'POST' : 'DELETE';
          path.addAll(['dependentCards', '$targetId']);
        default:
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
      final response = await client.rest(method, path, body: body);
      final receipt = <String, Object?>{
        'boardId': write.boardId,
        'cardId': current.id,
        'stackId': write.kind == 'moveCard'
            ? proposal['stackId']
            : current.stackId,
        if (write.kind == 'deleteCard')
          'deleted': {...current.raw, ...object(response.data)},
        if (write.kind == 'addCardLink' || write.kind == 'removeCardLink') ...{
          'dependentCardId': proposal['dependentCardId'],
          'linked': write.kind == 'addCardLink',
        },
      };
      if (write.kind == 'deleteCard' &&
          intField(object(receipt['deleted']), 'deletedAt') <= 0) {
        throw const FormatException('deletion_not_confirmed');
      }
      await database.markApplied(account, _owner, write, receipt);
      return _finishApplied(write.copyWith(remote: Value(jsonEncode(receipt))));
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

  Future<bool> _finishApplied(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    try {
      final receipt = object(jsonDecode(write.remote!));
      if (receipt['deleted'] != null) {
        final card = DeckCard.fromJson(object(receipt['deleted']));
        if (card.id != receipt['cardId'] || card.id <= 0) return false;
        return await _finishUnavailableCard(write, epoch, 'not_found');
      }
      final context = await _readCurrentCardContext(
        intField(receipt, 'boardId'),
        intField(receipt, 'stackId'),
        intField(receipt, 'cardId'),
      );
      return await database.confirmReconciledCard(
        account,
        _owner,
        write,
        context,
        epoch,
      );
    } on _CardContextUnavailable catch (error) {
      return _finishUnavailableCard(
        write,
        epoch,
        error.code,
        boardId: error.boardId,
      );
    } on DeckException {
      // The mutation already succeeded. Only its read-back can be retried.
      return false;
    } on FormatException {
      return false;
    }
  }

  Future<bool> _finishUnavailableCard(
    PendingWrite write,
    int epoch,
    String error, {
    int? boardId,
  }) async {
    if (boardId != null) {
      if (!await database.revokeBoardAccess(account, boardId, reason: error)) {
        return false;
      }
      final current = await database.account(account.id);
      if (current == null) return false;
      epoch = current.contentEpoch;
    }
    return database.confirmAppliedUnavailable(
      account,
      _owner,
      write,
      epoch,
      error,
    );
  }
}
