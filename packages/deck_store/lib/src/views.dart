part of 'database.dart';

extension DeckViews on DeckDatabase {
  Future<int?> resolveId(String accountId, int id, String creationKind) async {
    if (id >= 0) return id;
    final write =
        await (select(pendingWrites)..where(
              (w) =>
                  w.accountId.equals(accountId) &
                  w.sequence.equals(-id) &
                  w.kind.equals(creationKind),
            ))
            .getSingleOrNull();
    if (write?.state != 'confirmed' || write?.remote == null) return null;
    return intField(object(jsonDecode(write!.remote!)), 'id');
  }

  Future<PendingWrite?> resolveWrite(PendingWrite write) async {
    if (write.kind == 'createBoard') return write;
    final boardId = await resolveId(
      write.accountId,
      write.boardId,
      'createBoard',
    );
    if (boardId == null) return null;
    if (write.kind.endsWith('Board') || write.kind == 'createStack')
      return write.copyWith(boardId: boardId);
    final stackId = await resolveId(
      write.accountId,
      write.stackId,
      'createStack',
    );
    if (stackId == null) return null;
    return write.copyWith(boardId: boardId, stackId: stackId);
  }

  Future<bool> dependencyUnavailable(PendingWrite write) async {
    final parents = [
      if (write.kind != 'createBoard' && write.boardId < 0) -write.boardId,
      if (!write.kind.endsWith('Board') &&
          write.kind != 'createStack' &&
          write.stackId < 0)
        -write.stackId,
    ];
    for (final sequence in parents) {
      final parent =
          await (select(pendingWrites)..where(
                (w) =>
                    w.accountId.equals(write.accountId) &
                    w.sequence.equals(sequence),
              ))
              .getSingleOrNull();
      if (parent == null || parent.state == 'discarded') return true;
    }
    return false;
  }

  Stream<List<QueryRow>> _viewChanges(String accountId) => customSelect(
    'SELECT id FROM stored_accounts WHERE id = ?',
    variables: [Variable(accountId)],
    readsFrom: {
      storedAccounts,
      storedBoards,
      storedStacks,
      storedCards,
      pendingWrites,
    },
  ).watch();

  Stream<List<DeckBoard>> watchBoards(String accountId) =>
      _viewChanges(accountId).asyncMap((_) => boardView(accountId));

  Stream<DeckBoard?> watchBoard(String accountId, int id) =>
      _viewChanges(accountId).asyncMap((_) async {
        final resolved = await resolveId(accountId, id, 'createBoard') ?? id;
        return (await boardView(
          accountId,
        )).where((b) => b.id == resolved).firstOrNull;
      });

  Future<List<DeckBoard>> boardView(String accountId) async {
    final rows = await (select(
      storedBoards,
    )..where((b) => b.accountId.equals(accountId))).get();
    final boards = {
      for (final row in rows) row.remoteId: object(jsonDecode(row.payload)),
    };
    for (final write in await writesFor(accountId)) {
      final data = object(jsonDecode(write.proposal));
      if (write.kind == 'createBoard') {
        boards[-write.sequence] = {
          ...data,
          'id': -write.sequence,
          'archived': false,
          'deletedAt': 0,
          'permissions': {
            'PERMISSION_READ': true,
            'PERMISSION_EDIT': true,
            'PERMISSION_MANAGE': true,
            'PERMISSION_SHARE': true,
          },
          'syncState': write.state,
        };
      } else if (write.kind == 'updateBoard' || write.kind == 'deleteBoard') {
        final id =
            await resolveId(accountId, write.boardId, 'createBoard') ??
            write.boardId;
        final base = boards[id];
        if (base != null)
          boards[id] = {...base, ...data, 'syncState': write.state};
      }
    }
    return boards.values.map(DeckBoard.fromJson).toList();
  }

  Stream<List<DeckStack>> watchStacks(String accountId, int boardId) =>
      _viewChanges(accountId).asyncMap((_) => stackView(accountId, boardId));

  Future<List<DeckStack>> stackView(
    String accountId,
    int requestedBoard,
  ) async {
    final boardId =
        await resolveId(accountId, requestedBoard, 'createBoard') ??
        requestedBoard;
    final rows =
        await (select(storedStacks)..where(
              (s) => s.accountId.equals(accountId) & s.boardId.equals(boardId),
            ))
            .get();
    final stacks = {
      for (final row in rows)
        row.remoteId: <String, Object?>{
          ...object(jsonDecode(row.payload)),
          'cards': <JsonObject>[],
        },
    };
    final cards =
        await (select(storedCards)
              ..where(
                (c) =>
                    c.accountId.equals(accountId) & c.boardId.equals(boardId),
              )
              ..orderBy([
                (c) => OrderingTerm.asc(c.position),
                (c) => OrderingTerm.asc(c.remoteId),
              ]))
            .get();
    for (final card in cards) {
      final stack = stacks[card.stackId];
      if (stack != null)
        (stack['cards'] as List<JsonObject>).add(
          object(jsonDecode(card.payload)),
        );
    }
    for (final write in await writesFor(accountId)) {
      final parent =
          await resolveId(accountId, write.boardId, 'createBoard') ??
          write.boardId;
      if (parent != boardId) continue;
      final data = object(jsonDecode(write.proposal));
      if (write.kind == 'createStack') {
        stacks[-write.sequence] = {
          ...data,
          'id': -write.sequence,
          'boardId': boardId,
          'cards': <JsonObject>[],
          'syncState': write.state,
        };
        continue;
      }
      final stackId =
          await resolveId(accountId, write.stackId, 'createStack') ??
          write.stackId;
      if (write.kind == 'updateStack' && stacks[stackId] != null) {
        stacks[stackId] = {
          ...stacks[stackId]!,
          ...data,
          'syncState': write.state,
        };
        continue;
      }
      if (write.kind == 'deleteStack') {
        if (stacks[stackId] != null)
          stacks[stackId] = {...stacks[stackId]!, 'syncState': write.state};
        continue;
      }
      final stack = stacks[stackId];
      if (stack == null) continue;
      final entries = stack['cards'] as List<JsonObject>;
      if (write.kind == 'createCard') {
        entries.add({
          ...data,
          'id': -write.sequence,
          'stackId': stackId,
          'syncState': write.state,
        });
      } else if (write.kind == 'updateCard') {
        final index = entries.indexWhere((c) => c['id'] == write.cardId);
        final original = index < 0
            ? object(jsonDecode(write.base!))
            : entries[index];
        final projected = {...original, ...data, 'syncState': write.state};
        if (index < 0) {
          entries.add(projected);
        } else {
          entries[index] = projected;
        }
      }
    }
    return stacks.values.map(DeckStack.fromJson).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
