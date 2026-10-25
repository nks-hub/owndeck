part of 'database.dart';

extension BoardMetadata on DeckDatabase {
  Future<void> queueBoardMetadata(
    StoredAccount account,
    int boardId,
    String kind,
    JsonObject proposal, {
    JsonObject? original,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    if (!boardMetadataKinds.contains(kind)) {
      throw ArgumentError('invalid_operation');
    }
    final resolved =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((b) => b.id == resolved).firstOrNull;
    final acl = kind.endsWith('Acl');
    final canWrite =
        board != null &&
        board.deletedAt == 0 &&
        (acl
            ? kind == 'deleteAcl'
                  ? board.permissions.manage
                  : board.permissions.share
            : board.permissions.manage && !board.archived);
    if (!canWrite) throw StateError('permission_denied');
    if (acl && kind != 'deleteAcl') {
      final allowed = {
        'permissionEdit': board.permissions.edit || board.permissions.manage,
        'permissionShare': board.permissions.share || board.permissions.manage,
        'permissionManage': board.permissions.manage,
      };
      for (final key in allowed.keys) {
        if (kind == 'updateAcl' && !proposal.containsKey(key)) continue;
        final value = proposal[key];
        if (value is! bool ||
            !allowed[key]! && value != (original?[key] ?? false)) {
          throw StateError('permission_denied');
        }
      }
    }
    if (kind == 'createAcl') {
      if (!{0, 1, 6, 7}.contains(proposal['type']) ||
          stringField(proposal, 'participant').isEmpty) {
        throw const FormatException('invalid_recipient');
      }
    }
    if (!kind.startsWith('create')) {
      if (original == null) throw ArgumentError('original_required');
      final id = intField(original, 'id');
      if (id < 0) {
        final pending =
            await (select(pendingWrites)..where(
                  (w) =>
                      w.accountId.equals(account.id) & w.sequence.equals(-id),
                ))
                .getSingleOrNull();
        if (pending == null ||
            pending.kind != (acl ? 'createAcl' : 'createLabel') ||
            pending.state != 'queued' ||
            kind.startsWith('delete')) {
          throw StateError('pending_decision');
        }
        await (update(
          pendingWrites,
        )..where((w) => w.id.equals(pending.id))).write(
          PendingWritesCompanion(
            proposal: Value(
              jsonEncode({
                ...object(jsonDecode(pending.proposal)),
                ...proposal,
              }),
            ),
          ),
        );
        return;
      }
      final field = acl ? 'aclId' : 'labelId';
      final existing = (await writesFor(account.id)).any(
        (write) =>
            boardMetadataKinds.contains(write.kind) &&
            object(jsonDecode(write.proposal))[field] == id,
      );
      if (existing) throw StateError('pending_decision');
    }
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        kind: kind,
        boardId: boardId,
        stackId: 0,
        proposal: jsonEncode({
          ...proposal,
          if (original != null)
            acl ? 'aclId' : 'labelId': intField(original, 'id'),
        }),
        base: Value(original == null ? null : jsonEncode(original)),
      ),
    );
  });

  Future<void> confirmBoardMetadata(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckBoard? board, {
    int? contentEpoch,
  }) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    if (contentEpoch != null &&
        (await this.account(account.id))?.contentEpoch != contentEpoch) {
      return;
    }
    final pending =
        await (select(pendingWrites)..where(
              (w) => w.accountId.equals(account.id) & w.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (pending?.state != 'applied') return;
    if (board != null && board.permissions.read) {
      if (board.id != write.boardId) {
        throw const FormatException('board_mismatch');
      }
      await into(storedBoards).insertOnConflictUpdate(
        StoredBoardsCompanion.insert(
          accountId: account.id,
          remoteId: board.id,
          payload: jsonEncode(board.raw),
        ),
      );
      if (write.kind == 'deleteLabel' || write.kind == 'deleteAcl') {
        final proposal = object(jsonDecode(write.proposal));
        final original = write.base == null
            ? <String, Object?>{}
            : object(jsonDecode(write.base!));
        final participant = original['participant'];
        final userId = participant is JsonObject
            ? participant['uid']
            : participant;
        final cards =
            await (select(storedCards)..where(
                  (c) =>
                      c.accountId.equals(account.id) &
                      c.boardId.equals(write.boardId),
                ))
                .get();
        for (final card in cards) {
          final data = object(jsonDecode(card.payload));
          if (write.kind == 'deleteLabel') {
            data['labels'] = objects(
              data['labels'] ?? <Object?>[],
            ).where((label) => label['id'] != proposal['labelId']).toList();
          } else if (original['type'] == 0) {
            data['assignedUsers'] =
                objects(data['assignedUsers'] ?? <Object?>[]).where((
                  assignment,
                ) {
                  final user = assignment['participant'];
                  return (user is JsonObject ? user['uid'] : user) != userId;
                }).toList();
          }
          await (update(storedCards)..where(
                (c) =>
                    c.accountId.equals(account.id) &
                    c.remoteId.equals(card.remoteId),
              ))
              .write(StoredCardsCompanion(payload: Value(jsonEncode(data))));
        }
      }
    } else {
      await revokeBoardAccess(account, write.boardId);
    }
    await (update(pendingWrites)..where((w) => w.id.equals(write.id))).write(
      const PendingWritesCompanion(
        state: Value('confirmed'),
        error: Value(null),
      ),
    );
    await invalidateMutation(account.id, write.boardId);
  });
}
