part of 'sync.dart';

extension _BoardMetadataSync on DeckSync {
  Future<bool> _sendBoardMetadata(PendingWrite write) async {
    var started = false;
    var mutationStarted = false;
    try {
      final epoch = (await database.account(account.id))?.contentEpoch;
      if (epoch == null) return false;
      final board = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '${write.boardId}'])).data),
      );
      await database.saveBoard(account, board, epoch);
      if (_closed || !await database.acquireLease(account, _owner)) {
        return false;
      }
      started = await database.startWrite(account, _owner, write.id);
      if (!started) return true;
      final acl = write.kind.endsWith('Acl');
      final allowed =
          board.deletedAt == 0 &&
          (acl
              ? write.kind == 'deleteAcl'
                    ? board.permissions.manage
                    : board.permissions.share
              : board.permissions.manage && !board.archived);
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
      final proposal = object(jsonDecode(write.proposal));
      final items = objects(board.raw[acl ? 'acl' : 'labels'] ?? <Object?>[]);
      JsonObject? current;
      final target = proposal[acl ? 'aclId' : 'labelId'];
      if (!write.kind.startsWith('create')) {
        current = items.where((item) => item['id'] == target).firstOrNull;
        if (current == null) {
          if (write.kind.startsWith('delete')) {
            await database.markApplied(account, _owner, write, {
              'id': target,
              'boardId': board.id,
            });
            await database.confirmBoardMetadata(account, _owner, write, board);
          } else {
            await database.markWrite(
              account,
              _owner,
              write.id,
              'conflict',
              error: 'item_missing',
            );
          }
          return true;
        }
      } else if (write.kind == 'createAcl') {
        final duplicate = items.any((item) {
          final participant = item['participant'];
          final id = participant is JsonObject
              ? participant['uid'] ?? participant['id']
              : participant;
          return item['type'] == proposal['type'] &&
              id == proposal['participant'];
        });
        if (duplicate) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: 'already_shared',
          );
          return true;
        }
      }
      final fields = acl
          ? ['permissionEdit', 'permissionShare', 'permissionManage']
          : ['title', 'color'];
      if (acl && write.kind != 'deleteAcl') {
        final grantable = {
          'permissionEdit': board.permissions.edit || board.permissions.manage,
          'permissionShare':
              board.permissions.share || board.permissions.manage,
          'permissionManage': board.permissions.manage,
        };
        if (fields.any(
          (field) =>
              proposal.containsKey(field) &&
              !grantable[field]! &&
              proposal[field] != (current?[field] ?? false),
        )) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: 'permission_denied',
          );
          return true;
        }
      }
      if (current != null && write.base != null) {
        final original = object(jsonDecode(write.base!));
        final conflict = fields
            .where(
              (field) =>
                  write.kind.startsWith('delete') ||
                  proposal.containsKey(field),
            )
            .any(
              (field) =>
                  current![field] != original[field] &&
                  (write.kind.startsWith('delete') ||
                      current[field] != proposal[field]),
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
      final path = [
        'boards',
        '${write.boardId}',
        acl ? 'acl' : 'labels',
        if (!write.kind.startsWith('create')) '$target',
      ];
      final body = write.kind.startsWith('delete')
          ? null
          : <String, Object?>{
              for (final field in fields)
                field: proposal.containsKey(field)
                    ? proposal[field]
                    : current?[field],
              if (write.kind == 'createAcl') ...{
                'type': proposal['type'],
                'participant': proposal['participant'],
              },
            };
      mutationStarted = true;
      final response = await client.rest(
        write.kind.startsWith('create')
            ? 'POST'
            : write.kind.startsWith('delete')
            ? 'DELETE'
            : 'PUT',
        path,
        body: body,
      );
      final id = write.kind.startsWith('delete')
          ? target
          : intField(object(response.data), 'id');
      await database.markApplied(account, _owner, write, {
        'id': id,
        'boardId': board.id,
      });
      return _finishBoardMetadata(write);
    } on DeckException catch (error) {
      if (!started) {
        if (error.status != 403 && error.status != 404) rethrow;
        started = await database.startWrite(account, _owner, write.id);
      }
      final retry = error.status == 401 || error.status == 429;
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
        started = await database.startWrite(account, _owner, write.id);
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

  Future<bool> _finishBoardMetadata(PendingWrite write) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    try {
      final board = DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '${write.boardId}'])).data),
      );
      await database.confirmBoardMetadata(account, _owner, write, board);
      return true;
    } on DeckException catch (error) {
      if (error.status == 403 || error.status == 404) {
        await database.confirmBoardMetadata(account, _owner, write, null);
        return true;
      }
      return false;
    } on FormatException {
      return false;
    }
  }
}
