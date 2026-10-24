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
      final base = write.base == null
          ? <String, Object?>{}
          : object(jsonDecode(write.base!));
      final conflict =
          write.kind == 'moveCard' && current.stackId != write.stackId ||
          write.kind == 'deleteCard' &&
              [
                'title',
                'description',
                'stackId',
                'duedate',
                'archived',
                'lastModified',
              ].any((key) => current.raw[key] != base[key]);
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
      if (_closed || !await database.acquireLease(account, _owner))
        return false;
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
      };
      if (write.kind == 'deleteCard' &&
          intField(object(receipt['deleted']), 'deletedAt') <= 0)
        throw const FormatException('deletion_not_confirmed');
      await database.markApplied(account, _owner, write, receipt);
      return _finishApplied(write.copyWith(remote: Value(jsonEncode(receipt))));
    } on DeckException catch (error) {
      final retry =
          !mutationStarted &&
              {'transport_failed', 'timeout'}.contains(error.code) ||
          error.status == 401 ||
          error.status == 429;
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
    try {
      final receipt = object(jsonDecode(write.remote!));
      final result =
          receipt['deleted'] ??
          (await client.rest('GET', [
            'boards',
            '${intField(receipt, 'boardId')}',
            'stacks',
            '${intField(receipt, 'stackId')}',
            'cards',
            '${intField(receipt, 'cardId')}',
          ])).data;
      final card = DeckCard.fromJson(object(result));
      await database.confirmCard(account, _owner, write, card);
      return true;
    } on DeckException {
      // The mutation already succeeded. Only its read-back can be retried.
      return false;
    } on FormatException {
      return false;
    }
  }
}
