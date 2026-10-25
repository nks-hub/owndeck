part of 'database.dart';

int stackReorderIndex(List<int> siblings, JsonObject proposal) {
  final legacy = proposal['legacyOrder'];
  if (legacy != null) {
    if (legacy is! int || legacy < 0) throw StateError('invalid_position');
    return legacy.clamp(0, siblings.length);
  }
  final before = proposal['before'];
  if (before is! bool) throw StateError('invalid_position');
  final anchor = proposal['anchorStackId'];
  if (anchor == null) return before ? 0 : siblings.length;
  final index = siblings.indexOf(anchor as int);
  if (index < 0) throw StateError('invalid_destination');
  return index + (before ? 0 : 1);
}

extension StackReordering on DeckDatabase {
  // Without an anchor, before selects the start; otherwise select the end.
  Future<void> queueStackReorder(
    StoredAccount account,
    int boardId,
    int stackId, {
    int? anchorStackId,
    bool before = false,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    final resolved =
        await resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await boardView(
      account.id,
    )).where((b) => b.id == resolved).firstOrNull;
    if (board == null ||
        !board.permissions.manage ||
        board.archived ||
        board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    final target =
        await resolveId(account.id, stackId, 'createStack') ?? stackId;
    final anchor = anchorStackId == null
        ? null
        : await resolveId(account.id, anchorStackId, 'createStack') ??
              anchorStackId;
    final stacks = (await stackView(
      account.id,
      boardId,
    )).where((s) => (s.raw['deletedAt'] ?? 0) == 0).toList();
    final source = stacks.where((s) => s.id == target).firstOrNull;
    if (source == null ||
        target == anchor ||
        anchor != null && !stacks.any((s) => s.id == anchor)) {
      throw StateError('invalid_destination');
    }
    for (final write in await writesFor(account.id)) {
      if (write.kind != 'deleteStack') continue;
      final deleting =
          await resolveId(account.id, write.stackId, 'createStack') ??
          write.stackId;
      if (deleting == target || deleting == anchor) {
        throw StateError('pending_decision');
      }
    }
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        // Older clients dispatch unknown *Stack kinds as metadata updates.
        kind: 'stackReorder',
        boardId: boardId,
        stackId: stackId,
        proposal: jsonEncode({
          'title': source.title,
          'anchorStackId': anchorStackId,
          'before': before,
        }),
        base: Value(jsonEncode(source.raw)),
      ),
    );
  });

  Future<void> normalizeStackOrders(StoredAccount account, String owner) =>
      transaction(() async {
        if (!await ownsLease(account, owner)) return;
        for (final write in await writesFor(account.id)) {
          if (write.state != 'queued' ||
              !{'createStack', 'updateStack'}.contains(write.kind)) {
            continue;
          }
          final data = object(jsonDecode(write.proposal));
          if (!data.containsKey('order')) continue;
          final order = data['order'];
          if (order is! int || order < 0) {
            await (update(
              pendingWrites,
            )..where((row) => row.id.equals(write.id))).write(
              const PendingWritesCompanion(
                state: Value('blocked'),
                error: Value('invalid_position'),
              ),
            );
            continue;
          }
          data.remove('order');
          await (update(pendingWrites)..where((row) => row.id.equals(write.id)))
              .write(PendingWritesCompanion(proposal: Value(jsonEncode(data))));
          await into(pendingWrites).insert(
            PendingWritesCompanion.insert(
              id: const Uuid().v4(),
              accountId: account.id,
              kind: 'stackReorder',
              boardId: write.boardId,
              stackId: write.kind == 'createStack'
                  ? -write.sequence
                  : write.stackId,
              proposal: jsonEncode({
                'legacyOrder': order,
                'title': data['title'] ?? '',
              }),
              base: Value(write.base),
            ),
          );
        }
      });

  Future<bool> hasEarlierStackWrite(PendingWrite write) async {
    if (write.kind != 'stackReorder') return false;
    final board =
        await resolveId(write.accountId, write.boardId, 'createBoard') ??
        write.boardId;
    for (final earlier in await writesFor(write.accountId)) {
      if (earlier.sequence >= write.sequence ||
          earlier.kind != 'stackReorder' && !earlier.kind.endsWith('Stack')) {
        continue;
      }
      final other =
          await resolveId(write.accountId, earlier.boardId, 'createBoard') ??
          earlier.boardId;
      if (other == board) return true;
    }
    return false;
  }

  Future<bool> confirmStackReorder(
    StoredAccount account,
    String owner,
    PendingWrite write,
    List<DeckStack>? stacks,
    int epoch,
  ) => transaction(() async {
    final current = await _ownedAppliedWrite(account, owner, write, epoch);
    if (current?.kind != 'stackReorder') return false;
    if (stacks != null) {
      await saveStacks(
        account.id,
        account.generation,
        write.boardId,
        stacks,
        null,
        contentEpoch: epoch,
      );
    }
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      const PendingWritesCompanion(
        state: Value('confirmed'),
        error: Value(null),
      ),
    );
    await invalidateMutation(account.id, write.boardId);
    return true;
  });
}
