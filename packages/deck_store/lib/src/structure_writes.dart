part of 'database.dart';

extension StructureWrites on DeckDatabase {
  Future<void> saveCapabilities(
    StoredAccount account,
    DeckCapabilities capabilities,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation)) return;
    await (update(storedAccounts)..where((a) => a.id.equals(account.id))).write(
      StoredAccountsCompanion(
        capabilities: Value(
          jsonEncode({
            'deck': {
              'version': capabilities.version,
              'apiVersions': [capabilities.apiVersion],
              'canCreateBoards': capabilities.canCreateBoards,
            },
          }),
        ),
      ),
    );
  });

  Future<int> queueStructure(
    StoredAccount account,
    String kind,
    JsonObject proposal, {
    int boardId = 0,
    int stackId = 0,
    JsonObject? base,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation))
      throw StateError('account_unavailable');
    if (!{
      'createBoard',
      'updateBoard',
      'deleteBoard',
      'restoreBoard',
      'createStack',
      'updateStack',
      'deleteStack',
    }.contains(kind))
      throw ArgumentError('invalid_operation');
    if (kind == 'createBoard') {
      final current = (await this.account(account.id))!;
      if (current.capabilities == null ||
          !DeckCapabilities.fromJson(
            object(jsonDecode(current.capabilities!)),
          ).canCreateBoards)
        throw StateError('permission_denied');
    } else {
      final resolved =
          await resolveId(account.id, boardId, 'createBoard') ?? boardId;
      final board = (await boardView(
        account.id,
      )).where((b) => b.id == resolved).firstOrNull;
      if (board == null ||
          !board.permissions.manage ||
          board.deletedAt != 0 && kind != 'restoreBoard' ||
          board.archived && !{'updateBoard', 'restoreBoard'}.contains(kind))
        throw StateError('permission_denied');
    }
    final entityId = kind.endsWith('Board') ? boardId : stackId;
    if (!kind.startsWith('create')) {
      final creation = entityId < 0
          ? await (select(pendingWrites)..where(
                  (w) =>
                      w.accountId.equals(account.id) &
                      w.sequence.equals(-entityId),
                ))
                .getSingleOrNull()
          : null;
      if (creation != null && creation.state != 'confirmed') {
        if (creation.state != 'queued' || kind.startsWith('delete'))
          throw StateError('pending_decision');
        await (update(
          pendingWrites,
        )..where((w) => w.id.equals(creation.id))).write(
          PendingWritesCompanion(
            proposal: Value(
              jsonEncode({
                ...object(jsonDecode(creation.proposal)),
                ...proposal,
              }),
            ),
          ),
        );
        return entityId;
      }
      final existing = (await writesFor(account.id))
          .where(
            (w) => kind.endsWith('Board')
                ? w.kind.endsWith('Board') && w.boardId == boardId
                : w.kind.endsWith('Stack') && w.stackId == stackId,
          )
          .firstOrNull;
      if (existing != null) throw StateError('pending_decision');
    }
    final sequence = await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        kind: kind,
        boardId: boardId,
        stackId: stackId,
        proposal: jsonEncode(proposal),
        base: Value(base == null ? null : jsonEncode(base)),
      ),
    );
    return kind.startsWith('create') ? -sequence : entityId;
  });

  Future<void> confirmStructure(
    StoredAccount account,
    String owner,
    PendingWrite write,
    JsonObject remote,
  ) => transaction(() async {
    if (!await ownsLease(account, owner)) return;
    final current =
        await (select(pendingWrites)..where(
              (w) => w.accountId.equals(account.id) & w.id.equals(write.id),
            ))
            .getSingleOrNull();
    if (current?.state != 'sending') return;
    final id = intField(remote, 'id');
    if (write.kind.endsWith('Board')) {
      final parsed = DeckBoard.fromJson(remote);
      await into(storedBoards).insertOnConflictUpdate(
        StoredBoardsCompanion.insert(
          accountId: account.id,
          remoteId: id,
          payload: jsonEncode(parsed.raw),
        ),
      );
    } else if (write.kind == 'deleteStack') {
      await (delete(storedStacks)..where(
            (s) => s.accountId.equals(account.id) & s.remoteId.equals(id),
          ))
          .go();
      await (delete(storedCards)..where(
            (c) => c.accountId.equals(account.id) & c.stackId.equals(id),
          ))
          .go();
    } else {
      await into(storedStacks).insertOnConflictUpdate(
        StoredStacksCompanion.insert(
          accountId: account.id,
          remoteId: id,
          boardId: write.boardId,
          position: intField(remote, 'order'),
          payload: jsonEncode({...remote, 'cards': <Object?>[]}),
        ),
      );
    }
    await (update(pendingWrites)..where((w) => w.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('confirmed'),
        remote: Value(jsonEncode(remote)),
        error: const Value(null),
      ),
    );
    await invalidateMutation(
      account.id,
      write.kind == 'createBoard' ? id : write.boardId,
    );
  });

  Future<void> invalidateMutation(String accountId, int boardId) async {
    final current = (await account(accountId))!;
    await (update(storedAccounts)..where((a) => a.id.equals(accountId))).write(
      StoredAccountsCompanion(contentEpoch: Value(current.contentEpoch + 1)),
    );
    await (delete(syncCheckpoints)..where(
          (c) =>
              c.accountId.equals(accountId) &
              (c.scope.equals('boards') | c.scope.equals('board:$boardId')),
        ))
        .go();
  }
}
