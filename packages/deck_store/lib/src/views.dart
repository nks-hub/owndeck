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
    if (write.kind.endsWith('Board') || write.kind == 'createStack') {
      return write.copyWith(boardId: boardId);
    }
    final stackId = await resolveId(
      write.accountId,
      write.stackId,
      'createStack',
    );
    if (stackId == null) return null;
    final cardId = write.cardId == null
        ? null
        : await resolveId(write.accountId, write.cardId!, 'createCard');
    if (write.cardId != null && cardId == null) return null;
    var proposal = write.proposal;
    if (write.kind == 'moveCard') {
      final data = object(jsonDecode(proposal));
      final targetId = await resolveId(
        write.accountId,
        intField(data, 'stackId'),
        'createStack',
      );
      if (targetId == null) return null;
      proposal = jsonEncode({...data, 'stackId': targetId});
    }
    if (write.kind.endsWith('Comment')) {
      final data = object(jsonDecode(proposal));
      for (final key in ['commentId', 'parentId']) {
        if (data[key] is int && (data[key] as int) < 0) {
          final targetId = await resolveId(
            write.accountId,
            data[key] as int,
            'createComment',
          );
          if (targetId == null) return null;
          data[key] = targetId;
        }
      }
      proposal = jsonEncode(data);
    }
    final metadata = object(jsonDecode(proposal));
    for (final field in const {
      'labelId': 'createLabel',
      'aclId': 'createAcl',
      'destinationBoardId': 'createBoard',
      'destinationStackId': 'createStack',
      'dependentBoardId': 'createBoard',
      'dependentStackId': 'createStack',
      'dependentCardId': 'createCard',
    }.entries) {
      if (metadata[field.key] is int && (metadata[field.key] as int) < 0) {
        final id = await resolveId(
          write.accountId,
          metadata[field.key] as int,
          field.value,
        );
        if (id == null) return null;
        metadata[field.key] = id;
      }
    }
    proposal = jsonEncode(metadata);
    return write.copyWith(
      boardId: boardId,
      stackId: stackId,
      cardId: Value(cardId),
      proposal: proposal,
    );
  }

  Future<bool> dependencyUnavailable(PendingWrite write) async {
    final data = object(jsonDecode(write.proposal));
    final parents = [
      if (write.kind != 'createBoard' && write.boardId < 0) -write.boardId,
      if (!write.kind.endsWith('Board') &&
          write.kind != 'createStack' &&
          write.stackId < 0)
        -write.stackId,
      if (write.cardId != null && write.cardId! < 0) -write.cardId!,
      for (final key in [
        'labelId',
        'aclId',
        'destinationBoardId',
        'destinationStackId',
        'dependentBoardId',
        'dependentStackId',
        'dependentCardId',
      ])
        if (data[key] is int && (data[key] as int) < 0) -(data[key] as int),
      if (write.kind.endsWith('Comment'))
        for (final key in ['commentId', 'parentId'])
          if (data[key] is int && (data[key] as int) < 0) -(data[key] as int),
      if (write.kind == 'moveCard' &&
          intField(object(jsonDecode(write.proposal)), 'stackId') < 0)
        -intField(object(jsonDecode(write.proposal)), 'stackId'),
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

  Stream<DeckCard?> watchCard(String accountId, int boardId, int cardId) =>
      _viewChanges(accountId).asyncMap((_) async {
        final resolved =
            await resolveId(accountId, cardId, 'createCard') ?? cardId;
        for (final stack in await stackView(accountId, boardId)) {
          final card = stack.cards.where((c) => c.id == resolved).firstOrNull;
          if (card != null && (card.raw['deletedAt'] ?? 0) == 0) return card;
        }
        return null;
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
        if (base != null) {
          boards[id] = {...base, ...data, 'syncState': write.state};
        }
      } else if (boardMetadataKinds.contains(write.kind)) {
        final id =
            await resolveId(accountId, write.boardId, 'createBoard') ??
            write.boardId;
        final board = boards[id];
        if (board == null) continue;
        final acl = write.kind.endsWith('Acl');
        final field = acl ? 'acl' : 'labels';
        final items = objects(board[field] ?? <Object?>[]).toList();
        if (write.kind.startsWith('create')) {
          items.add({
            ...data,
            'id': -write.sequence,
            'boardId': id,
            'syncState': write.state,
            if (acl)
              'participant': {
                'id': data['participant'],
                'uid': data['participant'],
                'displayname': data['displayName'] ?? data['participant'],
              },
          });
        } else {
          final target =
              await resolveId(
                accountId,
                intField(data, acl ? 'aclId' : 'labelId'),
                acl ? 'createAcl' : 'createLabel',
              ) ??
              data[acl ? 'aclId' : 'labelId'];
          final index = items.indexWhere((item) => item['id'] == target);
          if (index >= 0) {
            items[index] = {...items[index], ...data, 'syncState': write.state};
          }
        }
        boards[id] = {...board, field: items};
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
    if (boardId > 0) {
      final row =
          await (select(storedBoards)..where(
                (b) =>
                    b.accountId.equals(accountId) & b.remoteId.equals(boardId),
              ))
              .getSingleOrNull();
      if (row == null ||
          !DeckBoard.fromJson(
            object(jsonDecode(row.payload)),
          ).permissions.read) {
        return [];
      }
    }
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
      if (stack != null) {
        (stack['cards'] as List<JsonObject>).add(
          object(jsonDecode(card.payload)),
        );
      }
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
        if (stacks[stackId] != null) {
          stacks[stackId] = {...stacks[stackId]!, 'syncState': write.state};
        }
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
        final cardId = write.cardId == null
            ? null
            : await resolveId(accountId, write.cardId!, 'createCard') ??
                  write.cardId;
        final index = entries.indexWhere((c) => c['id'] == cardId);
        if (index < 0 &&
            {'permission_denied', 'not_found'}.contains(write.error)) {
          continue;
        }
        if (index < 0 && cardId != null) {
          final observed =
              await (select(storedCards)..where(
                    (row) =>
                        row.accountId.equals(accountId) &
                        row.remoteId.equals(cardId),
                  ))
                  .getSingleOrNull();
          if (observed != null &&
              (observed.boardId != boardId || observed.stackId != stackId)) {
            continue;
          }
        }
        final original = index < 0
            ? object(jsonDecode(write.base!))
            : entries[index];
        final projected = {...original, ...data, 'syncState': write.state};
        if (index < 0) {
          entries.add(projected);
        } else {
          entries[index] = projected;
        }
      } else if (write.cardId != null) {
        final id =
            await resolveId(accountId, write.cardId!, 'createCard') ??
            write.cardId;
        for (final sourceStack in stacks.values) {
          final sourceCards = sourceStack['cards'] as List<JsonObject>;
          final index = sourceCards.indexWhere((c) => c['id'] == id);
          if (index < 0) continue;
          final current = sourceCards[index];
          final projected = <String, Object?>{
            ...current,
            'syncState': write.state,
          };
          if (write.kind == 'moveCard') {
            final targetId =
                await resolveId(
                  accountId,
                  intField(data, 'stackId'),
                  'createStack',
                ) ??
                data['stackId'];
            final target = stacks[targetId];
            if (target != null) {
              sourceCards.removeAt(index);
              final targetCards = target['cards'] as List<JsonObject>;
              final activePositions = [
                for (var i = 0; i < targetCards.length; i++)
                  if (_activeCard(targetCards[i])) i,
              ];
              final activeOrder = intField(
                data,
                'order',
              ).clamp(0, activePositions.length);
              final position = activeOrder == activePositions.length
                  ? targetCards.length
                  : activePositions[activeOrder];
              targetCards.insert(position, {...projected, 'stackId': targetId});
              _renumberActiveCards(sourceCards);
              if (!identical(sourceCards, targetCards)) {
                _renumberActiveCards(targetCards);
              }
            }
          } else {
            if (write.kind == 'archiveCard') projected['archived'] = true;
            if (write.kind == 'unarchiveCard') projected['archived'] = false;
            if (write.kind == 'addCardLink' || write.kind == 'removeCardLink') {
              final targetId =
                  await resolveId(
                    accountId,
                    intField(data, 'dependentCardId'),
                    'createCard',
                  ) ??
                  data['dependentCardId'];
              final links = (current['dependentCards'] as List? ?? [])
                  .whereType<int>()
                  .toSet();
              if (write.kind == 'addCardLink') {
                links.add(targetId! as int);
              } else {
                links.remove(targetId);
              }
              projected['dependentCards'] = links.toList();
            }
            if (write.kind == 'assignLabel' || write.kind == 'removeLabel') {
              final labels = (current['labels'] as List? ?? [])
                  .whereType<JsonObject>()
                  .where((label) => label['id'] != data['labelId'])
                  .toList();
              if (write.kind == 'assignLabel') {
                labels.add(object(data['label']));
              }
              projected['labels'] = labels;
            }
            if (write.kind == 'assignUser' || write.kind == 'unassignUser') {
              final assigned = (current['assignedUsers'] as List? ?? [])
                  .whereType<JsonObject>()
                  .where((assignment) {
                    final participant = assignment['participant'];
                    return (participant is JsonObject
                            ? participant['uid']
                            : participant) !=
                        data['userId'];
                  })
                  .toList();
              if (write.kind == 'assignUser') {
                assigned.add({
                  'participant': data['user'],
                  'type': data['type'] ?? 0,
                });
              }
              projected['assignedUsers'] = assigned;
            }
            sourceCards[index] = projected;
          }
          break;
        }
      }
    }
    return stacks.values.map(DeckStack.fromJson).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}

bool _activeCard(JsonObject card) =>
    card['archived'] != true && (card['deletedAt'] ?? 0) == 0;

void _renumberActiveCards(List<JsonObject> cards) {
  var order = 0;
  for (var i = 0; i < cards.length; i++) {
    if (_activeCard(cards[i])) cards[i] = {...cards[i], 'order': order++};
  }
}
