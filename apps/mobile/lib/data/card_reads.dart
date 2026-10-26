import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';

import 'session.dart';

extension SessionCardReads on DeckSession {
  Future<DeckCardContext> openRemoteCard(
    int boardId,
    int cardId, {
    int? stackId,
  }) async {
    final epoch = (await database.account(account.id))?.contentEpoch;
    if (epoch == null) throw StateError('account_unavailable');
    final result = await readCardContext(boardId, cardId, stackId: stackId);
    if (!await database.saveReadCard(account, result, epoch)) {
      throw StateError('stale_response');
    }
    return result;
  }

  /// Loads cards of readable boards that were never saved on this device.
  Future<void> loadUncachedBoards() async {
    final boards = await database.boardView(account.id);
    for (final board in boards) {
      if (!board.permissions.read || board.deletedAt != 0 || board.archived) {
        continue;
      }
      if (await database.checkpoint(account.id, 'board:${board.id}') == null) {
        await refreshStacks(board.id);
      }
    }
  }
}
