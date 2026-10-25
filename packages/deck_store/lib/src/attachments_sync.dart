part of 'sync.dart';

extension _AttachmentSync on DeckSync {
  Future<bool> _sendAttachment(PendingWrite write) async {
    var mutationStarted = false;
    try {
      final proposal = object(jsonDecode(write.proposal));
      final card = DeckCard.fromJson(
        object(
          (await client.rest('GET', [
            'boards',
            '${write.boardId}',
            'stacks',
            '${write.stackId}',
            'cards',
            '${write.cardId}',
          ])).data,
        ),
      );
      if (card.id != write.cardId ||
          card.stackId != write.stackId ||
          card.raw['archived'] == true ||
          (card.raw['deletedAt'] as int? ?? 0) != 0) {
        await database.markWrite(
          account,
          _owner,
          write.id,
          'blocked',
          error: 'card_unavailable',
        );
        return true;
      }
      AttachmentUploadSource? source;
      DeckAttachment? current;
      if (write.kind == 'uploadAttachment') {
        final read = readUpload;
        if (read == null) throw StateError('attachment_storage_unavailable');
        source = await read(stringField(proposal, 'uploadId'));
      } else if (write.kind != 'linkAttachment') {
        final items = await client.attachments(
          write.boardId,
          write.stackId,
          write.cardId!,
        );
        current = items
            .where(
              (item) =>
                  item.id == proposal['attachmentId'] &&
                  item.type == proposal['type'],
            )
            .firstOrNull;
        final done = write.kind == 'deleteAttachment'
            ? current == null || current.deletedAt != 0
            : current != null && current.deletedAt == 0;
        if (done) {
          await database.markApplied(account, _owner, write, {
            'attachmentId': proposal['attachmentId'],
            'type': proposal['type'],
          });
          return _finishAttachment(
            write.copyWith(
              remote: Value(
                jsonEncode({
                  'attachmentId': proposal['attachmentId'],
                  'type': proposal['type'],
                }),
              ),
            ),
            items: items,
          );
        }
        if (current == null) {
          await database.markWrite(
            account,
            _owner,
            write.id,
            'blocked',
            error: 'attachment_missing',
          );
          return true;
        }
        final base = DeckAttachment.fromJson(object(jsonDecode(write.base!)));
        if (base.name != current.name || base.modified != current.modified) {
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
      if (_closed) {
        await database.markWrite(account, _owner, write.id, 'queued');
        return false;
      }
      if (!await database.acquireLease(account, _owner)) {
        return false;
      }
      mutationStarted = true;
      final JsonObject receipt;
      if (write.kind == 'uploadAttachment') {
        final item = await client.uploadAttachment(
          write.boardId,
          write.stackId,
          write.cardId!,
          filename: source!.filename,
          mime: source.mime,
          length: source.length,
          bytes: source.bytes,
          cancelled: _cancelled.future,
        );
        receipt = {'attachmentId': item.id, 'type': item.type};
      } else if (write.kind == 'linkAttachment') {
        final id = await client.attachCloudFile(
          write.cardId!,
          (proposal['segments'] as List).cast<String>(),
        );
        receipt = {'attachmentId': id, 'type': 'file'};
      } else {
        if (write.kind == 'deleteAttachment') {
          await client.removeAttachment(write.boardId, write.stackId, current!);
        } else {
          await client.restoreAttachment(
            write.boardId,
            write.stackId,
            current!,
          );
        }
        receipt = {'attachmentId': current.id, 'type': current.type};
      }
      await database.markApplied(account, _owner, write, receipt);
      await _finishAttachment(
        write.copyWith(remote: Value(jsonEncode(receipt))),
      );
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
    } on FormatException {
      await database.markWrite(
        account,
        _owner,
        write.id,
        mutationStarted ? 'uncertain' : 'blocked',
        error: 'invalid_response',
      );
      return false;
    } on IOException {
      await database.markWrite(
        account,
        _owner,
        write.id,
        mutationStarted ? 'uncertain' : 'blocked',
        error: 'attachment_storage_unavailable',
      );
      return false;
    } on StateError {
      await database.markWrite(
        account,
        _owner,
        write.id,
        mutationStarted ? 'uncertain' : 'blocked',
        error: 'attachment_storage_unavailable',
      );
      return false;
    } on ArgumentError {
      await database.markWrite(
        account,
        _owner,
        write.id,
        'blocked',
        error: 'invalid_attachment',
      );
      return false;
    }
  }

  Future<bool> _finishAttachment(
    PendingWrite write, {
    List<DeckAttachment>? items,
  }) async {
    if (_closed || !await database.acquireLease(account, _owner)) return false;
    var epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return false;
    try {
      final receipt = object(jsonDecode(write.remote!));
      if (intField(receipt, 'attachmentId') <= 0 ||
          !{'file', 'deck_file'}.contains(receipt['type'])) {
        return false;
      }
      final context = await _readAppliedCard(
        write.boardId,
        write.stackId,
        write.cardId!,
      );
      final result =
          items != null &&
              context.stack.id == write.stackId &&
              context.board.id == write.boardId
          ? items
          : await client.attachments(
              context.board.id,
              context.stack.id,
              context.card.id,
            );
      // A complete read-back may show a later removal by another client.
      return database.confirmAttachments(
        account,
        _owner,
        write,
        result,
        context,
        epoch,
      );
    } on _AppliedCardUnavailable catch (error) {
      if (error.boardId != null) {
        if (!await database.revokeBoardAccess(
          account,
          error.boardId!,
          reason: error.code,
        )) {
          return false;
        }
        epoch = (await database.account(account.id))?.contentEpoch;
        if (epoch == null) return false;
      }
      return database.confirmAttachmentUnavailable(
        account,
        _owner,
        write,
        epoch,
        error.code,
      );
    } on DeckException {
      // Accepted writes retry only their read-back, never the upload or share.
      return false;
    } on FormatException {
      return false;
    }
  }
}
