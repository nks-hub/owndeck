part of 'session.dart';

final class DownloadedAttachment {
  const DownloadedAttachment(this.file, {this.offline = false});
  final File file;
  final bool offline;
}

extension SessionAttachments on DeckSession {
  Future<void> _cleanAttachmentFiles() async {
    final files = await _attachmentFiles();
    if (_disposed || !await database.accepts(account.id, account.generation)) {
      return;
    }
    final boards = await database.boardView(account.id);
    await files.pruneBoards(account.id, {
      for (final board in boards)
        if (board.permissions.read && board.deletedAt == 0) board.id,
    });
    await _cleanUploads(files);
  }

  Future<AttachmentFiles> _attachmentFiles() {
    if (_disposed || _files == null) throw StateError('account_unavailable');
    return _files();
  }

  Future<void> _checkAttachmentBoard(int boardId) async {
    if (_disposed || !await database.accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    final board = (await database.boardView(
      account.id,
    )).where((board) => board.id == boardId).firstOrNull;
    if (board == null || !board.permissions.read || board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
  }

  Future<void> _cleanUploads(AttachmentFiles files) => files.pruneUploads(
    account.id,
    () async => {
      for (final write in await database.writesFor(account.id))
        if (write.kind == 'uploadAttachment')
          stringField(object(jsonDecode(write.proposal)), 'uploadId'),
    },
  );

  Future<void> uploadAttachment(
    int boardId,
    int stackId,
    int cardId, {
    required String name,
    required String mime,
    required Stream<List<int>> bytes,
  }) async {
    final files = await _attachmentFiles();
    final staged = await files.stage(account.id, name, mime, bytes);
    var queued = false;
    try {
      if (_disposed) throw StateError('account_unavailable');
      await database.queueAttachment(
        account,
        boardId,
        stackId,
        cardId,
        'uploadAttachment',
        {
          'uploadId': staged.id,
          'name': staged.name,
          'mime': staged.mime,
          'length': staged.length,
        },
      );
      queued = true;
    } finally {
      files.releaseStage(account.id, staged.id);
      if (!queued) await files.discardUpload(account.id, staged.id);
    }
    unawaited(refreshAttachments(boardId, stackId, cardId));
  }

  Future<void> linkAttachment(
    int boardId,
    int stackId,
    int cardId,
    CloudFile file,
  ) async {
    if (_disposed) throw StateError('account_unavailable');
    if (file.directory || !file.readable || !file.shareable) {
      throw StateError('permission_denied');
    }
    await database.queueAttachment(
      account,
      boardId,
      stackId,
      cardId,
      'linkAttachment',
      {'segments': file.segments, 'name': file.name},
    );
    unawaited(refreshAttachments(boardId, stackId, cardId));
  }

  Future<void> changeAttachment(
    int boardId,
    int stackId,
    DeckAttachment attachment, {
    required bool restore,
  }) async {
    if (_disposed) throw StateError('account_unavailable');
    await database.queueAttachment(
      account,
      boardId,
      stackId,
      attachment.cardId,
      restore ? 'restoreAttachment' : 'deleteAttachment',
      {},
      original: attachment,
    );
    unawaited(refreshAttachments(boardId, stackId, attachment.cardId));
  }

  Future<void> refreshAttachments(
    int boardId,
    int stackId,
    int cardId,
  ) => _refresh('attachments:$cardId', () async {
    await sync.run();
    final board = await database.resolveId(account.id, boardId, 'createBoard');
    final stack = await database.resolveId(account.id, stackId, 'createStack');
    final card = await database.resolveId(account.id, cardId, 'createCard');
    if (_disposed || board == null || stack == null || card == null) return;
    await _checkAttachmentBoard(board);
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) return;
    final items = await client.attachments(board, stack, card);
    if (_disposed) return;
    await database.saveAttachments(account, board, card, items, epoch);
    await _checkAttachmentBoard(board);
    final files = await _attachmentFiles();
    await files.pruneCard(account.id, board, card, items);
  });

  Future<List<CloudFile>> cloudFiles(List<String> path) async {
    if (_disposed) throw StateError('account_unavailable');
    final uid = await client.currentUserId();
    await database.saveUserIdentity(account, uid);
    if (_disposed || !await database.accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    final files = await client.files(uid, path);
    if (_disposed) throw StateError('account_unavailable');
    return files;
  }

  Future<DownloadedAttachment> downloadAttachment(
    int boardId,
    int stackId,
    DeckAttachment attachment,
  ) async {
    await _checkAttachmentBoard(boardId);
    final files = await _attachmentFiles();
    try {
      final bytes = await client.downloadAttachment(
        boardId,
        stackId,
        attachment,
      );
      await _checkAttachmentBoard(boardId);
      return DownloadedAttachment(
        await files.cache(account.id, boardId, attachment, bytes),
      );
    } on DeckException catch (error) {
      if ({401, 403, 404}.contains(error.status)) {
        await files.forgetCached(account.id, boardId, attachment);
      }
      if (!{'transport_failed', 'timeout'}.contains(error.code)) rethrow;
      await _checkAttachmentBoard(boardId);
      final cached = await files.cached(account.id, boardId, attachment);
      if (cached == null) rethrow;
      return DownloadedAttachment(cached, offline: true);
    }
  }
}
