part of 'database.dart';

extension CommentStore on DeckDatabase {
  Stream<List<DeckComment>> watchComments(String accountId, int cardId) =>
      customSelect(
        'SELECT id FROM stored_accounts WHERE id = ?',
        variables: [Variable(accountId)],
        readsFrom: {storedAccounts, storedComments, pendingWrites},
      ).watch().asyncMap((_) async {
        final resolved =
            await resolveId(accountId, cardId, 'createCard') ?? cardId;
        final rows =
            await (select(storedComments)..where(
                  (c) =>
                      c.accountId.equals(accountId) & c.cardId.equals(resolved),
                ))
                .get();
        final comments = {
          for (final row in rows) row.remoteId: object(jsonDecode(row.payload)),
        };
        for (final write in (await writesFor(
          accountId,
        )).where((w) => w.kind.endsWith('Comment'))) {
          final target =
              await resolveId(accountId, write.cardId!, 'createCard') ??
              write.cardId;
          if (target != resolved) continue;
          final proposal = object(jsonDecode(write.proposal));
          if (write.kind == 'createComment') {
            comments[-write.sequence] = {
              'id': -write.sequence,
              'objectId': resolved,
              'message': proposal['message'],
              'actorId': proposal['actorId'],
              'actorType': 'users',
              'actorDisplayName': proposal['actorId'],
              'creationDateTime': proposal['createdAt'],
              'syncState': write.state,
              if (proposal['replyTo'] != null) 'replyTo': proposal['replyTo'],
            };
          } else {
            final id =
                await resolveId(
                  accountId,
                  intField(proposal, 'commentId'),
                  'createComment',
                ) ??
                proposal['commentId'];
            final original =
                comments[id] ??
                (write.base == null ? null : object(jsonDecode(write.base!)));
            if (original != null) {
              comments[id as int] = {
                ...original,
                'id': id,
                'syncState': write.state,
                if (write.kind == 'updateComment')
                  'message': proposal['message'],
              };
            }
          }
        }
        return comments.values.map(DeckComment.fromJson).toList()
          ..sort((a, b) => b.created.compareTo(a.created));
      });

  Future<void> saveComments(
    StoredAccount account,
    int cardId,
    List<DeckComment> comments,
    int epoch,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation) ||
        (await this.account(account.id))?.contentEpoch != epoch) {
      return;
    }
    await (delete(storedComments)..where(
          (c) => c.accountId.equals(account.id) & c.cardId.equals(cardId),
        ))
        .go();
    for (final comment in comments) {
      if (comment.cardId != cardId) {
        throw const FormatException('comment_card_mismatch');
      }
      await into(storedComments).insertOnConflictUpdate(
        StoredCommentsCompanion.insert(
          accountId: account.id,
          cardId: cardId,
          remoteId: comment.id,
          payload: jsonEncode(comment.raw),
        ),
      );
    }
  });

  Future<void> queueComment(
    StoredAccount account,
    int boardId,
    int stackId,
    int cardId,
    String kind,
    JsonObject proposal, {
    DeckComment? original,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    if (!{'createComment', 'updateComment', 'deleteComment'}.contains(kind)) {
      throw ArgumentError('invalid_operation');
    }
    final current = (await this.account(account.id))!;
    if (current.userId == null) throw StateError('identity_unavailable');
    final resolved =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((b) => b.id == resolved).firstOrNull;
    if (board == null || !board.permissions.read || board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    if (kind != 'createComment' &&
        (original == null ||
            original.actorId != current.userId ||
            original.actorType != 'users')) {
      throw StateError('permission_denied');
    }
    if (kind != 'deleteComment') {
      final message = stringField(proposal, 'message');
      if (message.trim().isEmpty ||
          message.runes.length > deckCommentMaxLength) {
        throw const FormatException('invalid_comment_length');
      }
    }
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        kind: kind,
        boardId: boardId,
        stackId: stackId,
        cardId: Value(cardId),
        proposal: jsonEncode({
          ...proposal,
          'actorId': current.userId,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          if (original != null) 'commentId': original.id,
        }),
        base: Value(original == null ? null : jsonEncode(original.raw)),
      ),
    );
  });

  Future<void> confirmComment(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckComment? result,
  ) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    final pending =
        await (select(pendingWrites)..where(
              (w) => w.accountId.equals(account.id) & w.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (pending?.state != 'sending') return;
    final id =
        result?.id ?? intField(object(jsonDecode(write.proposal)), 'commentId');
    if (result == null) {
      await (delete(storedComments)..where(
            (c) => c.accountId.equals(account.id) & c.remoteId.equals(id),
          ))
          .go();
    } else {
      if (result.cardId != write.cardId) {
        throw const FormatException('comment_card_mismatch');
      }
      await into(storedComments).insertOnConflictUpdate(
        StoredCommentsCompanion.insert(
          accountId: account.id,
          cardId: result.cardId,
          remoteId: id,
          payload: jsonEncode(result.raw),
        ),
      );
    }
    await (update(pendingWrites)..where((w) => w.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('confirmed'),
        remote: Value(jsonEncode(result?.raw ?? {'id': id, 'deleted': true})),
        error: const Value(null),
      ),
    );
    await invalidateMutation(account.id, write.boardId);
  });

  Future<void> saveCommentDraft(
    StoredAccount account,
    String key,
    int boardId,
    int stackId,
    int cardId,
    String message, {
    DeckComment? original,
    DeckComment? replyTo,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    await into(editorDrafts).insertOnConflictUpdate(
      EditorDraftsCompanion.insert(
        accountId: account.id,
        draftKey: key,
        kind: const Value('comment'),
        boardId: boardId,
        stackId: stackId,
        cardId: Value(cardId),
        payload: jsonEncode({
          'title': '',
          'description': message,
          if (replyTo != null) 'replyTo': replyTo.raw,
        }),
        base: Value(original == null ? null : jsonEncode(original.raw)),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  });

  Future<void> publishCommentDraft(
    StoredAccount account,
    String key,
    int boardId,
    int stackId,
    int cardId,
    String message, {
    DeckComment? original,
    DeckComment? replyTo,
  }) => transaction(() async {
    await queueComment(
      account,
      boardId,
      stackId,
      cardId,
      original == null ? 'createComment' : 'updateComment',
      {
        'message': message,
        'parentId': replyTo?.id ?? 0,
        if (replyTo != null) 'replyTo': replyTo.raw,
      },
      original: original,
    );
    await deleteEditorDraft(account.id, key);
  });
}
