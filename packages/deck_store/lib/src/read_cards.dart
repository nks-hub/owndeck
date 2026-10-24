import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:drift/drift.dart';

import 'database.dart';

extension DeckReadCards on DeckDatabase {
  Future<bool> saveReadCard(
    StoredAccount account,
    DeckCardContext result,
    int epoch,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation) ||
        (await this.account(account.id))?.contentEpoch != epoch) {
      return false;
    }
    final board = result.board;
    final stack = result.stack;
    final card = result.card;
    if (!board.permissions.read ||
        board.deletedAt != 0 ||
        stack.boardId != board.id ||
        card.stackId != stack.id ||
        (stack.raw['deletedAt'] ?? 0) != 0 ||
        (card.raw['deletedAt'] ?? 0) != 0) {
      throw StateError('card_unavailable');
    }
    final previous =
        await (select(storedCards)..where(
              (row) =>
                  row.accountId.equals(account.id) &
                  row.remoteId.equals(card.id),
            ))
            .getSingleOrNull();
    if (previous != null) {
      final old = object(jsonDecode(previous.payload))['lastModified'];
      final fresh = card.raw['lastModified'];
      if (old is int && fresh is int && old > fresh) return false;
    }
    await into(storedBoards).insertOnConflictUpdate(
      StoredBoardsCompanion.insert(
        accountId: account.id,
        remoteId: board.id,
        payload: jsonEncode(board.raw),
      ),
    );
    await into(storedStacks).insertOnConflictUpdate(
      StoredStacksCompanion.insert(
        accountId: account.id,
        remoteId: stack.id,
        boardId: board.id,
        position: stack.order,
        payload: jsonEncode({...stack.raw, 'cards': <Object?>[]}),
      ),
    );
    await into(storedCards).insertOnConflictUpdate(
      StoredCardsCompanion.insert(
        accountId: account.id,
        remoteId: card.id,
        boardId: board.id,
        stackId: stack.id,
        position: card.order,
        payload: jsonEncode(card.raw),
      ),
    );
    return true;
  });
}
