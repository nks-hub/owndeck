part of 'database.dart';

extension _TransferProjection on DeckDatabase {
  Future<bool> _transferDestinationExists(
    String accountId,
    int boardId,
    int stackId,
  ) async {
    final board = (await boardView(
      accountId,
    )).where((b) => b.id == boardId).firstOrNull;
    if (board == null || !board.permissions.read || board.deletedAt != 0) {
      return false;
    }
    if (stackId < 0) {
      final creator =
          await (select(pendingWrites)..where(
                (row) =>
                    row.accountId.equals(accountId) &
                    row.sequence.equals(-stackId) &
                    row.kind.equals('createStack'),
              ))
              .getSingleOrNull();
      if (creator == null || creator.state == 'discarded') return false;
      return (await resolveId(accountId, creator.boardId, 'createBoard') ??
              creator.boardId) ==
          boardId;
    }
    final row =
        await (select(storedStacks)..where(
              (row) =>
                  row.accountId.equals(accountId) &
                  row.remoteId.equals(stackId) &
                  row.boardId.equals(boardId),
            ))
            .getSingleOrNull();
    return row != null &&
        (object(jsonDecode(row.payload))['deletedAt'] ?? 0) == 0;
  }

  Future<void> _projectCardTransfer(
    String accountId,
    int boardId,
    Map<int, JsonObject> stacks,
    PendingWrite write,
  ) async {
    if (write.cardId == null) return;
    final cardId =
        await resolveId(accountId, write.cardId!, 'createCard') ??
        write.cardId!;
    final proposal = object(jsonDecode(write.proposal));
    final source =
        await resolveId(accountId, write.boardId, 'createBoard') ??
        write.boardId;
    final target =
        await resolveId(
          accountId,
          intField(proposal, 'destinationBoardId'),
          'createBoard',
        ) ??
        intField(proposal, 'destinationBoardId');
    final targetStack =
        await resolveId(
          accountId,
          intField(proposal, 'destinationStackId'),
          'createStack',
        ) ??
        intField(proposal, 'destinationStackId');
    if ({'blocked', 'conflict', 'uncertain'}.contains(write.state) ||
        !await _transferDestinationExists(accountId, target, targetStack)) {
      for (final stack in stacks.values) {
        final cards = stack['cards']! as List<JsonObject>;
        final index = cards.indexWhere((c) => c['id'] == cardId);
        if (index >= 0) {
          cards[index] = {
            ...cards[index],
            'syncState': write.state,
            'transferPhase': proposal['phase'],
          };
        }
      }
      return;
    }
    if (source != boardId && target != boardId) return;
    JsonObject? value;
    if (write.state == 'applied' && write.remote != null) {
      final receipt = object(jsonDecode(write.remote!));
      if (receipt['acceptedCard'] is JsonObject) {
        value = object(receipt['acceptedCard']);
      }
    }
    final cached =
        await (select(storedCards)..where(
              (row) =>
                  row.accountId.equals(accountId) & row.remoteId.equals(cardId),
            ))
            .getSingleOrNull();
    if (value == null && cached != null && !_missingCardSnapshot(cached)) {
      value = object(jsonDecode(cached.payload));
    }
    value ??= write.base == null ? null : object(jsonDecode(write.base!));
    if (value == null) return;
    for (final earlier in await writesFor(accountId)) {
      if (earlier.sequence >= write.sequence ||
          earlier.kind != 'updateCard' ||
          earlier.cardId == null) {
        continue;
      }
      final id =
          await resolveId(accountId, earlier.cardId!, 'createCard') ??
          earlier.cardId;
      if (id == cardId) {
        value = {...value!, ...object(jsonDecode(earlier.proposal))};
      }
    }
    for (final stack in stacks.values) {
      final cards = stack['cards']! as List<JsonObject>;
      cards.removeWhere((c) => c['id'] == cardId);
      _renumberActiveCards(cards);
    }
    if (target != boardId || stacks[targetStack] == null) return;
    final cards = stacks[targetStack]!['cards']! as List<JsonObject>;
    final active = cards.where(_activeCard).toList();
    final anchor = proposal['anchorCardId'];
    if (anchor is int) {
      proposal['anchorCardId'] =
          await resolveId(accountId, anchor, 'createCard') ?? anchor;
    }
    var order = active.length;
    try {
      order = cardPositionIndex(
        active.map((c) => intField(c, 'id')).toList(),
        proposal,
      );
    } on StateError {
      // Preserve the card while an unavailable anchor awaits a user decision.
    }
    final position = order == active.length
        ? cards.length
        : cards.indexOf(active[order]);
    final board = (await boardView(
      accountId,
    )).where((b) => b.id == boardId).first;
    final targetLabels = (board.raw['labels'] as List? ?? [])
        .whereType<JsonObject>();
    final sourceLabels = (value!['labels'] as List? ?? [])
        .whereType<JsonObject>();
    final labels = <JsonObject>[];
    for (final label in sourceLabels) {
      final mapped = targetLabels
          .where((item) => item['title'] == label['title'])
          .firstOrNull;
      if (mapped != null) {
        labels.add(mapped);
      } else if (board.permissions.manage) {
        labels.add(label);
      }
    }
    cards.insert(position, {
      ...value,
      'id': cardId,
      'stackId': targetStack,
      'labels': labels,
      'syncState': write.state,
      'transferPhase': proposal['phase'],
    });
    _renumberActiveCards(cards);
  }
}
