part of 'sync.dart';

/// Kinds sent as creating POST requests: repeating one may duplicate the item.
const duplicateRiskKinds = {
  'createCard',
  'createBoard',
  'createStack',
  'createLabel',
  'createAcl',
  'createComment',
  'cloneCard',
  'boardClone',
  'addCardLink',
  'uploadAttachment',
  'linkAttachment',
};

/// Kinds whose effect on the server can be looked up by [DeckServerCheck].
const serverCheckKinds = {
  'createCard',
  'createComment',
  'uploadAttachment',
  'linkAttachment',
};

extension DeckServerCheck on DeckSync {
  /// Looks for the effect of an uncertain write on the server.
  ///
  /// Returns true and continues through the normal read-back when the server
  /// already holds the item; returns false when nothing matches, leaving the
  /// write uncertain so the user may send it again.
  Future<bool> checkServer(String id) async {
    await _running;
    if (_closed || !await database.acquireLease(account, _owner)) {
      throw StateError('write_unavailable');
    }
    try {
      final write = (await database.writesFor(
        account.id,
      )).where((w) => w.id == id && w.state == 'uncertain').firstOrNull;
      if (write == null) throw StateError('write_unavailable');
      final resolved = await database.resolveWrite(write);
      final sentAt = write.sentAt;
      if (resolved == null ||
          sentAt == null ||
          !serverCheckKinds.contains(write.kind)) {
        return false;
      }
      // Server clocks are in whole seconds, so compare at that resolution.
      final since = sentAt.millisecondsSinceEpoch ~/ 1000;
      final proposal = object(jsonDecode(resolved.proposal));
      return switch (write.kind) {
        'createCard' => await _checkCard(resolved, proposal, since),
        'createComment' => await _checkComment(resolved, proposal, since),
        _ => await _checkAttachment(resolved, proposal, since),
      };
    } on _CardContextUnavailable catch (error) {
      throw DeckException(error.code);
    } finally {
      await database.releaseLease(account.id, _owner);
    }
  }

  Future<bool> _checkCard(
    PendingWrite write,
    JsonObject proposal,
    int since,
  ) async {
    final stack = DeckStack.fromJson(
      object(
        (await client.rest('GET', [
          'boards',
          '${write.boardId}',
          'stacks',
          '${write.stackId}',
        ])).data,
      ),
    );
    if (stack.id != write.stackId) {
      throw const FormatException('invalid_stack_identity');
    }
    final found = stack.cards
        .where(
          (card) =>
              card.raw['title'] == proposal['title'] &&
              _createdSince(card.raw['createdAt'], since),
        )
        .toList();
    if (found.length != 1 ||
        !await database.resumeUncertain(account, _owner, write.id)) {
      return false;
    }
    final receipt = <String, Object?>{
      'boardId': write.boardId,
      'stackId': found.single.stackId,
      'cardId': found.single.id,
      'acceptedCard': found.single.raw,
    };
    await database.markApplied(account, _owner, write, receipt);
    await _finishApplied(write.copyWith(remote: Value(jsonEncode(receipt))));
    return true;
  }

  Future<bool> _checkComment(
    PendingWrite write,
    JsonObject proposal,
    int since,
  ) async {
    final userId = await client.currentUserId();
    final found = <DeckComment>[];
    await for (final page in client.commentPages(write.cardId!)) {
      found.addAll(
        page.where(
          (comment) =>
              comment.actorType == 'users' &&
              comment.actorId == userId &&
              comment.message == proposal['message'] &&
              comment.created.millisecondsSinceEpoch ~/ 1000 >= since,
        ),
      );
    }
    if (found.length != 1 ||
        !await database.resumeUncertain(account, _owner, write.id)) {
      return false;
    }
    await database.confirmComment(account, _owner, write, found.single);
    return true;
  }

  Future<bool> _checkAttachment(
    PendingWrite write,
    JsonObject proposal,
    int since,
  ) async {
    final context = await _readCurrentCardContext(
      write.boardId,
      write.stackId,
      write.cardId!,
    );
    final items = await client.attachments(
      context.board.id,
      context.stack.id,
      write.cardId!,
    );
    final upload = write.kind == 'uploadAttachment';
    final found = items
        .where(
          (item) =>
              item.deletedAt == 0 &&
              item.supported &&
              item.name == proposal['name'] &&
              (!upload || item.size == proposal['length']) &&
              _createdSince(item.raw['createdAt'], since),
        )
        .toList();
    if (found.length != 1 ||
        !await database.resumeUncertain(account, _owner, write.id)) {
      return false;
    }
    final receipt = <String, Object?>{
      'attachmentId': found.single.id,
      'type': found.single.type,
    };
    await database.markApplied(account, _owner, write, receipt);
    await _finishAttachment(
      write.copyWith(remote: Value(jsonEncode(receipt))),
      items: items,
    );
    return true;
  }
}

bool _createdSince(Object? createdAt, int since) =>
    createdAt is int && createdAt >= since;
