import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';

import 'session.dart';

Future<void> setCardCompleted(
  DeckSession session,
  int boardId,
  DeckCard card,
  bool completed,
) async {
  final database = session.database;
  final account = session.account;
  var resolvedBoardId = boardId;
  final changed = await database.transaction<bool>(() async {
    if (!await database.accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    resolvedBoardId =
        await database.resolveId(account.id, boardId, 'createBoard') ?? boardId;
    final board = (await database.boardView(
      account.id,
    )).where((value) => value.id == resolvedBoardId).firstOrNull;
    if (board == null ||
        !board.permissions.edit ||
        board.archived ||
        board.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    final cardId =
        await database.resolveId(account.id, card.id, 'createCard') ?? card.id;
    final current = (await database.stackView(account.id, resolvedBoardId))
        .expand((stack) => stack.cards)
        .where((value) => value.id == cardId)
        .firstOrNull;
    if (current == null ||
        current.archived ||
        (current.raw['deletedAt'] ?? 0) != 0) {
      throw StateError('card_unavailable');
    }
    if (!current.raw.containsKey('done')) {
      throw StateError('unsupported_operation');
    }
    if ((current.raw['done'] != null) == completed) return false;
    await database.saveCardDraft(account, resolvedBoardId, current.stackId, {
      'done': completed ? DateTime.now().toUtc().toIso8601String() : null,
    }, original: current);
    return true;
  });
  if (changed) unawaited(session.refreshStacks(resolvedBoardId));
}
