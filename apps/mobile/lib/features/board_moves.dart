import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'board_drag.dart';
import 'card_move_dialog.dart';

bool activeBoardCard(DeckCard card) =>
    !card.archived && (card.raw['deletedAt'] ?? 0) == 0;

({DeckCard card, int order})? resolveBoardDrop(
  List<DeckStack> stacks,
  BoardCardDrag drag,
  BoardDropPosition position,
) {
  final source = stacks.where((s) => s.id == drag.stackId).firstOrNull;
  final target = stacks.where((s) => s.id == position.stackId).firstOrNull;
  final card = source?.cards.where((c) => c.id == drag.cardId).firstOrNull;
  if (card == null ||
      source == null ||
      target == null ||
      !activeBoardCard(card) ||
      (source.raw['deletedAt'] ?? 0) != 0 ||
      (target.raw['deletedAt'] ?? 0) != 0) {
    throw StateError('invalid_destination');
  }
  final cards = target.cards
      .where((c) => activeBoardCard(c) && c.id != card.id)
      .toList();
  var order = position.index ?? cards.length;
  if (position.anchorId != null) {
    final anchor = cards.indexWhere((c) => c.id == position.anchorId);
    if (anchor < 0) throw StateError('invalid_destination');
    order = anchor + (position.after ? 1 : 0);
  }
  if (order < 0 || order > cards.length) throw StateError('invalid_position');
  if (target.id == source.id &&
      source.cards
              .where(activeBoardCard)
              .toList()
              .indexWhere((c) => c.id == card.id) ==
          order) {
    return null;
  }
  return (card: card, order: order);
}

Future<void> queueBoardCardMove(
  DeckSession session,
  DeckBoard board,
  BoardCardDrag drag,
  BoardDropPosition position,
) async {
  if (drag.accountId != session.account.id ||
      drag.generation != session.account.generation ||
      drag.boardId != board.id ||
      !board.permissions.edit ||
      board.archived ||
      board.deletedAt != 0) {
    throw StateError('permission_denied');
  }
  final database = session.database;
  final account = session.account;
  var boardId = board.id;
  final changed = await database.transaction<bool>(() async {
    if (!await database.accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    boardId =
        await database.resolveId(account.id, board.id, 'createBoard') ??
        board.id;
    final current = (await database.boardView(
      account.id,
    )).where((value) => value.id == boardId).firstOrNull;
    if (current == null ||
        !current.permissions.edit ||
        current.archived ||
        current.deletedAt != 0) {
      throw StateError('permission_denied');
    }
    final sourceId =
        await database.resolveId(account.id, drag.stackId, 'createStack') ??
        drag.stackId;
    final targetId =
        await database.resolveId(account.id, position.stackId, 'createStack') ??
        position.stackId;
    final cardId =
        await database.resolveId(account.id, drag.cardId, 'createCard') ??
        drag.cardId;
    final anchorId = position.anchorId == null
        ? null
        : await database.resolveId(
                account.id,
                position.anchorId!,
                'createCard',
              ) ??
              position.anchorId;
    final stacks = await database.stackView(account.id, boardId);
    final move = resolveBoardDrop(
      stacks,
      BoardCardDrag(
        accountId: account.id,
        generation: account.generation,
        boardId: boardId,
        stackId: sourceId,
        cardId: cardId,
      ),
      BoardDropPosition(
        targetId,
        index: position.index,
        anchorId: anchorId,
        after: position.after,
      ),
    );
    if (move == null) return false;
    await database.queueCardAction(account, boardId, move.card, 'moveCard', {
      'stackId': targetId,
      'order': move.order,
      if (anchorId != null ||
          position.index == null ||
          position.index == 0) ...{
        'anchorCardId': anchorId,
        'before': anchorId != null ? !position.after : position.index == 0,
      },
    });
    return true;
  });
  if (changed) unawaited(session.refreshStacks(boardId));
}

Future<void> moveBoardCard(
  BuildContext context,
  DeckSession session,
  DeckBoard board,
  BoardCardDrag drag,
  BoardDropPosition position,
) async {
  try {
    await queueBoardCardMove(session, board, drag, position);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage(error, AppLocalizations.of(context)!)),
        ),
      );
    }
  }
}

Future<void> showBoardCardMove(
  BuildContext context,
  DeckSession session,
  DeckBoard board,
  DeckCard card, {
  VoidCallback? onTransferred,
}) async {
  final text = AppLocalizations.of(context)!;
  final database = session.database;
  final account = session.account;
  try {
    final sourceId =
        await database.resolveId(account.id, board.id, 'createBoard') ??
        board.id;
    final boards = (await database.boardView(account.id))
        .where(
          (value) =>
              value.permissions.read &&
              value.permissions.edit &&
              !value.archived &&
              value.deletedAt == 0 &&
              value.raw['externalId'] == null,
        )
        .toList();
    final source = boards.where((value) => value.id == sourceId).firstOrNull;
    if (source == null) throw StateError('permission_denied');
    final stacks = (await database.stackView(
      account.id,
      sourceId,
    )).where((stack) => (stack.raw['deletedAt'] ?? 0) == 0).toList();
    final cardId =
        await database.resolveId(account.id, card.id, 'createCard') ?? card.id;
    final current = stacks
        .expand((stack) => stack.cards)
        .where((value) => value.id == cardId && activeBoardCard(value))
        .firstOrNull;
    if (current == null) throw StateError('card_unavailable');
    if (!context.mounted) return;
    final move = await showDialog<CardMoveDestination>(
      context: context,
      builder: (_) => CardMoveDialog(
        session: session,
        source: source,
        card: current,
        boards: boards,
        stacks: stacks,
      ),
    );
    if (move == null || !context.mounted) return;
    final resolvedSource =
        await database.resolveId(account.id, sourceId, 'createBoard') ??
        sourceId;
    final targetId =
        await database.resolveId(account.id, move.board.id, 'createBoard') ??
        move.board.id;
    if (resolvedSource == targetId) {
      await queueBoardCardMove(
        session,
        source,
        BoardCardDrag(
          accountId: account.id,
          generation: account.generation,
          boardId: source.id,
          stackId: current.stackId,
          cardId: current.id,
        ),
        BoardDropPosition(
          move.stack.id,
          anchorId: move.anchorCardId,
          after: !move.before,
          index: move.anchorCardId == null && move.before ? 0 : null,
        ),
      );
    } else {
      await database.queueCardTransfer(
        account,
        sourceId,
        current,
        destinationBoardId: targetId,
        destinationStackId: move.stack.id,
        anchorCardId: move.anchorCardId,
        before: move.before,
      );
      if (context.mounted) onTransferred?.call();
      unawaited(session.refreshStacks(resolvedSource));
      unawaited(session.refreshStacks(targetId));
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text.savedLocally)));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage(error, text))));
    }
  }
}
