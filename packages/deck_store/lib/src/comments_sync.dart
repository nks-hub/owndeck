part of 'sync.dart';

extension _CommentSync on DeckSync {
  Future<bool> _sendComment(PendingWrite write) async {
    var mutationStarted = false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final userId = await client.currentUserId();
      await database.saveUserIdentity(account, userId);
      if (proposal['actorId'] != userId) {
        await database.markWrite(
          account,
          _owner,
          write.id,
          'blocked',
          error: 'identity_mismatch',
        );
        return true;
      }
      final path = [
        'apps',
        'deck',
        'api',
        'v1.0',
        'cards',
        '${write.cardId}',
        'comments',
      ];
      if (write.kind != 'createComment') {
        DeckComment? current;
        await for (final page in client.commentPages(write.cardId!)) {
          if (_closed || !await database.acquireLease(account, _owner)) {
            await database.markWrite(account, _owner, write.id, 'queued');
            return false;
          }
          current = page
              .where((comment) => comment.id == proposal['commentId'])
              .firstOrNull;
          if (current != null) break;
        }
        if (current == null) {
          if (write.kind == 'deleteComment') {
            await database.confirmComment(account, _owner, write, null);
          } else {
            await database.markWrite(
              account,
              _owner,
              write.id,
              'conflict',
              error: 'comment_missing',
            );
          }
          return true;
        }
        if (current.actorType != 'users' || current.actorId != userId) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: 'permission_denied',
          );
          return true;
        }
        final base = object(jsonDecode(write.base!));
        if (current.message != base['message'] &&
            (write.kind == 'deleteComment' ||
                current.message != proposal['message'])) {
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
        path.add('${current.id}');
      }
      if (_closed || !await database.acquireLease(account, _owner)) {
        await database.markWrite(account, _owner, write.id, 'queued');
        return false;
      }
      mutationStarted = true;
      final result = await client.ocs(
        write.kind == 'createComment'
            ? 'POST'
            : write.kind == 'updateComment'
            ? 'PUT'
            : 'DELETE',
        path,
        body: write.kind == 'deleteComment'
            ? null
            : {
                'message': proposal['message'],
                if (write.kind == 'createComment')
                  'parentId': proposal['parentId'] ?? 0,
              },
      );
      final comment = write.kind == 'deleteComment'
          ? null
          : DeckComment.fromJson(object(result.data));
      if (comment != null &&
          (comment.actorId != userId || comment.cardId != write.cardId)) {
        throw const FormatException('invalid_comment_identity');
      }
      await database.confirmComment(account, _owner, write, comment);
      return true;
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
      if (error.message != 'identity_mismatch') rethrow;
      await database.markWrite(
        account,
        _owner,
        write.id,
        'blocked',
        error: 'identity_mismatch',
      );
      return false;
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
}
