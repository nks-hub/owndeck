part of 'database.dart';

bool _localTransferBoard(DeckBoard board) =>
    board.permissions.read &&
    board.permissions.edit &&
    !board.archived &&
    board.deletedAt == 0 &&
    board.raw['externalId'] == null;

PendingWrite? _acceptedCardTransfer(
  List<PendingWrite> writes,
  int cardId, {
  int? boardId,
  int? stackId,
  int? missingBoardId,
}) {
  for (final write in writes) {
    if (write.kind != 'cardTransfer' ||
        write.state != 'applied' ||
        write.remote == null) {
      continue;
    }
    final receipt = object(jsonDecode(write.remote!));
    if (receipt['phase'] != 'transfer' || receipt['cardId'] != cardId) continue;
    if (missingBoardId != null &&
        receipt['sourceBoardId'] == missingBoardId &&
        receipt['boardId'] != missingBoardId) {
      return write;
    }
    if (boardId != null &&
        receipt['boardId'] == boardId &&
        receipt['stackId'] == stackId) {
      return write;
    }
  }
  return null;
}

extension CardTransfers on DeckDatabase {
  Future<DeckCard> _cardAfterPendingTransfer(
    StoredAccount account,
    int boardId,
    DeckCard card,
    String kind,
    JsonObject proposal,
  ) async {
    final id = await resolveId(account.id, card.id, 'createCard') ?? card.id;
    for (final write in await writesFor(account.id)) {
      if (write.kind != 'cardTransfer' || write.cardId == null) continue;
      final moving =
          await resolveId(account.id, write.cardId!, 'createCard') ??
          write.cardId;
      if (moving != id) continue;
      if ({'blocked', 'conflict', 'uncertain'}.contains(write.state)) {
        throw StateError('pending_decision');
      }
      final projected = (await stackView(
        account.id,
        boardId,
      )).expand((s) => s.cards).where((c) => c.id == id).firstOrNull;
      if (projected == null) throw StateError('card_moved');
      if ({'assignLabel', 'removeLabel'}.contains(kind)) {
        final parent =
            await resolveId(account.id, boardId, 'createBoard') ?? boardId;
        final board = (await boardView(
          account.id,
        )).where((b) => b.id == parent).first;
        final labelId =
            await resolveId(
              account.id,
              intField(proposal, 'labelId'),
              'createLabel',
            ) ??
            proposal['labelId'];
        if (!(board.raw['labels'] as List? ?? []).whereType<JsonObject>().any(
          (l) => l['id'] == labelId,
        )) {
          throw StateError('pending_decision');
        }
      }
      return projected;
    }
    return card;
  }

  Future<void> queueCardTransfer(
    StoredAccount account,
    int sourceBoardId,
    DeckCard card, {
    required int destinationBoardId,
    required int destinationStackId,
    int? anchorCardId,
    bool before = false,
  }) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    final sourceId =
        await resolveId(account.id, sourceBoardId, 'createBoard') ??
        sourceBoardId;
    final destinationId =
        await resolveId(account.id, destinationBoardId, 'createBoard') ??
        destinationBoardId;
    if (sourceId == destinationId) throw StateError('invalid_destination');
    final boards = await boardView(account.id);
    final source = boards.where((b) => b.id == sourceId).firstOrNull;
    final destination = boards.where((b) => b.id == destinationId).firstOrNull;
    if (source == null ||
        destination == null ||
        !_localTransferBoard(source) ||
        !_localTransferBoard(destination)) {
      throw StateError('permission_denied');
    }
    final cardId =
        await resolveId(account.id, card.id, 'createCard') ?? card.id;
    for (final write in await writesFor(account.id)) {
      if (write.kind != 'cardTransfer' || write.cardId == null) continue;
      final existing =
          await resolveId(account.id, write.cardId!, 'createCard') ??
          write.cardId;
      if (existing == cardId) throw StateError('pending_decision');
    }
    final current = (await stackView(
      account.id,
      sourceBoardId,
    )).expand((s) => s.cards).where((c) => c.id == cardId).firstOrNull;
    if (current == null ||
        current.archived ||
        (current.raw['deletedAt'] ?? 0) != 0) {
      throw StateError('card_unavailable');
    }
    final targetId =
        await resolveId(account.id, destinationStackId, 'createStack') ??
        destinationStackId;
    final target = (await stackView(
      account.id,
      destinationBoardId,
    )).where((s) => s.id == targetId).firstOrNull;
    if (target == null || (target.raw['deletedAt'] ?? 0) != 0) {
      throw StateError('invalid_destination');
    }
    final anchor = anchorCardId == null
        ? null
        : await resolveId(account.id, anchorCardId, 'createCard') ??
              anchorCardId;
    if (anchor == cardId ||
        anchor != null &&
            !target.cards.any(
              (c) =>
                  c.id == anchor &&
                  !c.archived &&
                  (c.raw['deletedAt'] ?? 0) == 0,
            )) {
      throw StateError('invalid_destination');
    }
    for (final write in await writesFor(account.id)) {
      if (write.kind != 'deleteStack') continue;
      final deleting =
          await resolveId(account.id, write.stackId, 'createStack') ??
          write.stackId;
      if (deleting == targetId) throw StateError('pending_decision');
    }
    await into(pendingWrites).insert(
      PendingWritesCompanion.insert(
        id: const Uuid().v4(),
        accountId: account.id,
        kind: 'cardTransfer',
        boardId: sourceBoardId,
        stackId: current.stackId,
        cardId: Value(current.id),
        proposal: jsonEncode({
          'phase': 'transfer',
          'title': current.title,
          'destinationBoardId': destinationBoardId,
          'destinationStackId': destinationStackId,
          'anchorCardId': anchorCardId,
          'before': before,
        }),
        base: Value(jsonEncode(current.raw)),
      ),
    );
  });

  Future<bool> refuseCardTransfer(
    StoredAccount account,
    String owner,
    PendingWrite write,
    String reason, {
    int? deniedBoardId,
  }) => transaction(() async {
    if (!await ownsLease(account, owner)) return false;
    final current =
        await (select(pendingWrites)..where(
              (row) =>
                  row.id.equals(write.id) & row.accountId.equals(account.id),
            ))
            .getSingleOrNull();
    if (current?.state != 'sending' || current?.kind != 'cardTransfer') {
      return false;
    }
    if (deniedBoardId != null) {
      await revokeBoardAccess(account, deniedBoardId, reason: reason);
    }
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        state: const Value('blocked'),
        error: Value(reason),
      ),
    );
    return true;
  });

  Future<void> _rebindTransferFollowers(
    StoredAccount account,
    PendingWrite transfer,
    DeckCardContext context,
    JsonObject receipt,
  ) async {
    final sourceBoard = intField(receipt, 'sourceBoardId');
    var nextStack = context.stack.id;
    final labels = (context.board.raw['labels'] as List? ?? [])
        .whereType<JsonObject>()
        .toList();
    for (final later in await writesFor(account.id)) {
      if (later.sequence <= transfer.sequence ||
          later.cardId == null ||
          !{'queued', 'blocked', 'conflict'}.contains(later.state)) {
        continue;
      }
      if (later.state != 'queued' &&
          !{
            'not_found',
            'card_moved',
            'concurrent_edit',
            'permission_denied',
          }.contains(later.error)) {
        continue;
      }
      final id =
          await resolveId(account.id, later.cardId!, 'createCard') ??
          later.cardId;
      if (id != context.card.id) continue;
      if (later.kind == 'cardTransfer') break;
      final previousBoard =
          await resolveId(account.id, later.boardId, 'createBoard') ??
          later.boardId;
      if (previousBoard != sourceBoard && previousBoard != context.board.id) {
        continue;
      }
      final proposal = object(jsonDecode(later.proposal));
      var blocked = false;
      int? nextPosition;
      if (later.kind == 'moveCard') {
        final target = intField(proposal, 'stackId');
        final resolved =
            await resolveId(account.id, target, 'createStack') ?? target;
        final row =
            await (select(storedStacks)..where(
                  (s) =>
                      s.accountId.equals(account.id) &
                      s.remoteId.equals(resolved),
                ))
                .getSingleOrNull();
        final creator = resolved >= 0
            ? null
            : await (select(pendingWrites)..where(
                    (w) =>
                        w.accountId.equals(account.id) &
                        w.sequence.equals(-resolved) &
                        w.kind.equals('createStack'),
                  ))
                  .getSingleOrNull();
        final localBoard = creator == null
            ? null
            : await resolveId(account.id, creator.boardId, 'createBoard') ??
                  creator.boardId;
        if (row == null
            ? creator == null ||
                  creator.state == 'discarded' ||
                  localBoard != context.board.id
            : row.boardId != context.board.id) {
          blocked = true;
        } else {
          nextPosition = resolved;
        }
      }
      if ({'assignLabel', 'removeLabel'}.contains(later.kind) &&
          previousBoard != context.board.id) {
        final original = later.base == null
            ? <String, Object?>{}
            : object(jsonDecode(later.base!));
        final sourceLabels = (original['labels'] as List? ?? [])
            .whereType<JsonObject>();
        final label = proposal['label'] is JsonObject
            ? object(proposal['label'])
            : sourceLabels
                  .where((l) => l['id'] == proposal['labelId'])
                  .firstOrNull;
        final mapped = label == null
            ? null
            : labels.where((l) => l['title'] == label['title']).firstOrNull;
        if (mapped == null) {
          blocked = true;
        } else {
          proposal['labelId'] = mapped['id'];
          if (proposal.containsKey('label')) proposal['label'] = mapped;
        }
      }
      await (update(
        pendingWrites,
      )..where((row) => row.id.equals(later.id))).write(
        PendingWritesCompanion(
          boardId: Value(context.board.id),
          stackId: Value(nextStack),
          cardId: Value(context.card.id),
          proposal: Value(jsonEncode(proposal)),
          state: Value(blocked ? 'blocked' : 'queued'),
          error: Value(blocked ? 'invalid_destination' : null),
        ),
      );
      if (nextPosition != null) nextStack = nextPosition;
    }
    await _relocateCardDrafts(
      account.id,
      context.card.id,
      context.board.id,
      nextStack,
    );
  }

  Future<bool> prepareCardTransferPosition(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckCardContext context,
    int epoch,
  ) => transaction(() async {
    final current = await _ownedAppliedWrite(account, owner, write, epoch);
    if (current?.kind != 'cardTransfer') return false;
    final receipt = object(jsonDecode(current!.remote!));
    final proposal = object(jsonDecode(write.proposal));
    if (receipt['phase'] != 'transfer' ||
        receipt['cardId'] != context.card.id ||
        receipt['boardId'] != proposal['destinationBoardId'] ||
        receipt['stackId'] != proposal['destinationStackId']) {
      return false;
    }
    final ready =
        context.board.id == receipt['boardId'] &&
        context.stack.id == receipt['stackId'] &&
        !context.card.archived;
    if (!await saveReadCard(account, context, epoch)) return false;
    if (ready) {
      await _rebindTransferFollowers(account, current, context, receipt);
    }
    final error = ready
        ? null
        : context.card.archived
        ? 'card_archived'
        : context.board.id == receipt['boardId']
        ? 'concurrent_edit'
        : 'card_moved';
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        boardId: Value(intField(receipt, 'boardId')),
        stackId: Value(intField(receipt, 'stackId')),
        cardId: Value(context.card.id),
        base: Value(jsonEncode(context.card.raw)),
        proposal: Value(
          jsonEncode({
            ...proposal,
            'phase': 'position',
            'transferReceipt': receipt,
          }),
        ),
        state: Value(
          ready
              ? 'queued'
              : error == 'concurrent_edit'
              ? 'conflict'
              : 'blocked',
        ),
        error: Value(error),
        remote: Value(jsonEncode(ready ? receipt : context.card.raw)),
      ),
    );
    await invalidateMutation(account.id, intField(receipt, 'sourceBoardId'));
    await invalidateMutation(account.id, intField(receipt, 'boardId'));
    return true;
  });

  Future<bool> blockAcceptedCardTransfer(
    StoredAccount account,
    String owner,
    PendingWrite write,
    int epoch,
    String reason, {
    int? deniedBoardId,
  }) => transaction(() async {
    final current = await _ownedAppliedWrite(account, owner, write, epoch);
    if (current?.kind != 'cardTransfer') return false;
    final receipt = object(jsonDecode(current!.remote!));
    if (receipt['phase'] != 'transfer') return false;
    if (deniedBoardId != null) {
      if (!await revokeBoardAccess(account, deniedBoardId, reason: reason)) {
        return false;
      }
      epoch = (await this.account(account.id))!.contentEpoch;
    }
    if (!await confirmAppliedUnavailable(
      account,
      owner,
      write,
      epoch,
      reason,
    )) {
      return false;
    }
    final proposal = object(jsonDecode(write.proposal));
    final cardId = intField(receipt, 'cardId');
    final boardId = intField(receipt, 'boardId');
    final stackId = intField(receipt, 'stackId');
    await _relocateCardDrafts(account.id, cardId, boardId, stackId);
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        boardId: Value(boardId),
        stackId: Value(stackId),
        cardId: Value(cardId),
        proposal: Value(
          jsonEncode({
            ...proposal,
            'phase': 'position',
            'transferReceipt': receipt,
          }),
        ),
        base: Value(jsonEncode(receipt['acceptedCard'])),
        remote: Value(jsonEncode(receipt)),
        state: const Value('blocked'),
        error: Value(reason),
      ),
    );
    await invalidateMutation(account.id, intField(receipt, 'sourceBoardId'));
    return true;
  });

  Future<bool> confirmCardTransfer(
    StoredAccount account,
    String owner,
    PendingWrite write,
    DeckCardContext context,
    List<DeckStack> stacks,
    int epoch,
  ) => transaction(() async {
    final current = await _ownedAppliedWrite(account, owner, write, epoch);
    if (current?.kind != 'cardTransfer') return false;
    final receipt = object(jsonDecode(current!.remote!));
    final proposal = object(jsonDecode(write.proposal));
    if (receipt['phase'] != 'position' ||
        receipt['cardId'] != context.card.id ||
        proposal['phase'] != 'position' ||
        proposal['transferReceipt'] is! JsonObject) {
      return false;
    }
    if (!await saveReadCard(account, context, epoch)) return false;
    final savedEpoch = (await this.account(account.id))!.contentEpoch;
    if (!await saveStacks(
      account.id,
      account.generation,
      context.board.id,
      stacks,
      null,
      contentEpoch: savedEpoch,
    )) {
      return false;
    }
    if (context.board.id == proposal['destinationBoardId'] &&
        context.stack.id == proposal['destinationStackId']) {
      await _rebindTransferFollowers(
        account,
        current,
        context,
        object(proposal['transferReceipt']),
      );
    }
    await (update(
      pendingWrites,
    )..where((row) => row.id.equals(write.id))).write(
      PendingWritesCompanion(
        boardId: Value(context.board.id),
        stackId: Value(context.stack.id),
        state: const Value('confirmed'),
        error: const Value(null),
        remote: Value(
          jsonEncode({
            ...context.card.raw,
            'transferReceipt': proposal['transferReceipt'],
            'positionReceipt': receipt,
          }),
        ),
      ),
    );
    await invalidateMutation(account.id, context.board.id);
    return true;
  });
}
