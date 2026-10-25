part of 'database.dart';

extension BoardCloneStore on DeckDatabase {
  Future<void> queueBoardClone(
    StoredAccount account,
    int boardId,
    BoardCloneOptions options,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    final current = (await this.account(account.id))!;
    final capabilities = current.capabilities == null
        ? null
        : DeckCapabilities.fromJson(object(jsonDecode(current.capabilities!)));
    if (capabilities?.supportsBoardCloning != true) {
      throw StateError('unsupported_operation');
    }
    final source = (await boardView(
      account.id,
    )).where((board) => board.id == boardId).firstOrNull;
    if (boardId <= 0 ||
        source == null ||
        !source.permissions.read ||
        source.deletedAt != 0 ||
        capabilities?.canCreateBoards != true) {
      throw StateError('permission_denied');
    }
    for (final pending in await writesFor(account.id)) {
      final parent =
          await resolveId(account.id, pending.boardId, 'createBoard') ??
          pending.boardId;
      if (parent == boardId) throw StateError('pending_decision');
    }
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        // Older clients route unknown *Board kinds as updates to the source board.
        kind: 'boardClone',
        boardId: boardId,
        stackId: 0,
        proposal: jsonEncode({'title': source.title, ...options.toJson()}),
        base: Value(jsonEncode(source.raw)),
      ),
    );
  });

  Future<bool> confirmBoardClone(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckBoard? board,
    int epoch,
  ) => transaction(() async {
    if (!await ownsLease(account, owner) ||
        (await this.account(account.id))?.contentEpoch != epoch) {
      return false;
    }
    final current =
        await (select(pendingWrites)..where(
              (row) =>
                  row.accountId.equals(account.id) & row.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (current?.state != 'applied' || current?.kind != 'boardClone') {
      return false;
    }
    final receipt = object(jsonDecode(current!.remote!));
    final accepted = DeckBoard.fromJson(object(receipt['createdBoard']));
    if (accepted.id <= 0 ||
        accepted.id == write.boardId ||
        board != null && board.id != accepted.id) {
      return false;
    }
    var confirmed = accepted.raw;
    if (board != null && board.permissions.read && board.deletedAt == 0) {
      await saveBoard(account, board, epoch);
      confirmed = board.raw;
    } else {
      await revokeBoardAccess(account, accepted.id);
    }
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('confirmed'),
        error: const Value(null),
        remote: Value(jsonEncode(confirmed)),
      ),
    );
    await invalidateMutation(account.id, accepted.id);
    return true;
  });
}
