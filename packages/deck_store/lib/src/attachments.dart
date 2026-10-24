part of 'database.dart';

extension AttachmentStore on DeckDatabase {
  Future<List<DeckAttachment>> attachmentsFor(
    String accountId,
    int cardId,
  ) async =>
      (await (select(storedAttachments)..where(
                (a) => a.accountId.equals(accountId) & a.cardId.equals(cardId),
              ))
              .get())
          .map(
            (row) => DeckAttachment.fromJson(object(jsonDecode(row.payload))),
          )
          .toList();
  Future<bool> _canCacheAttachments(String accountId, int boardId) async {
    final row =
        await (select(storedBoards)..where(
              (board) =>
                  board.accountId.equals(accountId) &
                  board.remoteId.equals(boardId),
            ))
            .getSingleOrNull();
    if (row == null) return false;
    final board = DeckBoard.fromJson(object(jsonDecode(row.payload)));
    return board.permissions.read && board.deletedAt == 0;
  }

  Stream<List<DeckAttachment>> watchAttachments(String accountId, int cardId) =>
      (select(storedAttachments)..where(
            (a) => a.accountId.equals(accountId) & a.cardId.equals(cardId),
          ))
          .watch()
          .map(
            (rows) =>
                rows
                    .map(
                      (row) => DeckAttachment.fromJson(
                        object(jsonDecode(row.payload)),
                      ),
                    )
                    .toList()
                  ..sort((a, b) => b.modified.compareTo(a.modified)),
          );

  Future<void> _replaceAttachments(
    String accountId,
    int boardId,
    int cardId,
    List<DeckAttachment> attachments,
  ) async {
    await (delete(storedAttachments)..where(
          (a) => a.accountId.equals(accountId) & a.cardId.equals(cardId),
        ))
        .go();
    for (final attachment in attachments) {
      if (attachment.cardId != cardId) {
        throw const FormatException('attachment_card_mismatch');
      }
      await into(storedAttachments).insertOnConflictUpdate(
        StoredAttachmentsCompanion.insert(
          accountId: accountId,
          boardId: boardId,
          cardId: cardId,
          type: attachment.type,
          remoteId: attachment.id,
          payload: jsonEncode(attachment.raw),
        ),
      );
    }
  }

  Future<void> saveAttachments(
    StoredAccount account,
    int boardId,
    int cardId,
    List<DeckAttachment> attachments,
    int epoch,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation) ||
        (await this.account(account.id))?.contentEpoch != epoch) {
      return;
    }
    if (!await _canCacheAttachments(account.id, boardId)) return;
    await _replaceAttachments(account.id, boardId, cardId, attachments);
  });

  Future<String> queueAttachment(
    StoredAccount account,
    int boardId,
    int stackId,
    int cardId,
    String kind,
    JsonObject proposal, {
    DeckAttachment? original,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    if (!attachmentKinds.contains(kind) || cardId == 0) {
      throw ArgumentError('invalid_attachment_operation');
    }
    final resolved =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((board) => board.id == resolved).firstOrNull;
    if (board == null ||
        !board.permissions.edit ||
        board.archived ||
        board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    if (kind == 'deleteAttachment' || kind == 'restoreAttachment') {
      if (original == null ||
          !original.supported ||
          original.cardId != cardId ||
          kind == 'restoreAttachment' && !original.canRestore) {
        throw ArgumentError('invalid_attachment_identity');
      }
    } else if (kind == 'uploadAttachment') {
      if (stringField(proposal, 'uploadId').isEmpty ||
          stringField(proposal, 'name').isEmpty) {
        throw const FormatException('invalid_upload');
      }
    } else {
      final segments = proposal['segments'];
      if (segments is! List ||
          segments.isEmpty ||
          segments.any(
            (value) =>
                value is! String ||
                value.isEmpty ||
                value == '.' ||
                value == '..' ||
                value.contains('/') ||
                value.contains('\\') ||
                value.runes.any((c) => c < 32 || c == 127),
          )) {
        throw const FormatException('invalid_cloud_path');
      }
    }
    final id = const Uuid().v4();
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: id,
        accountId: account.id,
        kind: kind,
        boardId: boardId,
        stackId: stackId,
        cardId: Value(cardId),
        proposal: jsonEncode({
          ...proposal,
          if (original != null) ...{
            'type': original.type,
            'attachmentId': original.id,
            'name': original.name,
          },
        }),
        base: Value(original == null ? null : jsonEncode(original.raw)),
      ),
    );
    return id;
  });

  Future<void> confirmAttachments(
    StoredAccount account,
    String owner,
    PendingWrite write,
    List<DeckAttachment> attachments,
  ) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    final current =
        await (select(pendingWrites)..where(
              (w) => w.id.equals(write.id) & w.accountId.equals(account.id),
            ))
            .getSingleOrNull();
    if (current?.state != 'applied') return;
    if (!await _canCacheAttachments(account.id, write.boardId)) return;
    await _replaceAttachments(
      account.id,
      write.boardId,
      write.cardId!,
      attachments,
    );
    await (update(pendingWrites)..where((w) => w.id.equals(write.id))).write(
      const PendingWritesCompanion(
        state: Value('confirmed'),
        error: Value(null),
      ),
    );
    await invalidateMutation(account.id, write.boardId);
  });
}
