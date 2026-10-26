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
  if (position.anchorId == null &&
      position.index != null &&
      position.index != 0 &&
      target.id == source.id &&
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

Future<DeckBoard> _editableSource(DeckSession session, DeckBoard board) async {
  final database = session.database;
  final accountId = session.account.id;
  final sourceId =
      await database.resolveId(accountId, board.id, 'createBoard') ?? board.id;
  final source = (await database.boardView(accountId))
      .where(
        (value) =>
            value.id == sourceId &&
            value.permissions.read &&
            value.permissions.edit &&
            !value.archived &&
            value.deletedAt == 0 &&
            value.raw['externalId'] == null,
      )
      .firstOrNull;
  if (source == null) throw StateError('permission_denied');
  return source;
}

Future<DeckCard> _currentCard(
  DeckSession session,
  int boardId,
  DeckCard card,
) async {
  final database = session.database;
  final cardId =
      await database.resolveId(session.account.id, card.id, 'createCard') ??
      card.id;
  final current = (await database.stackView(session.account.id, boardId))
      .where((stack) => (stack.raw['deletedAt'] ?? 0) == 0)
      .expand((stack) => stack.cards)
      .where((value) => value.id == cardId && activeBoardCard(value))
      .firstOrNull;
  if (current == null) throw StateError('card_unavailable');
  return current;
}

/// Lets the user pick a destination for [cards]; returns null when cancelled.
Future<CardMoveDestination?> chooseBoardCardMove(
  BuildContext context,
  DeckSession session,
  DeckBoard board,
  List<DeckCard> cards,
) async {
  final database = session.database;
  final account = session.account;
  final source = await _editableSource(session, board);
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
  final stacks = (await database.stackView(
    account.id,
    source.id,
  )).where((stack) => (stack.raw['deletedAt'] ?? 0) == 0).toList();
  final current = <DeckCard>[
    for (final card in cards) await _currentCard(session, source.id, card),
  ];
  if (!context.mounted) return null;
  return showDialog<CardMoveDestination>(
    context: context,
    builder: (_) => CardMoveDialog(
      session: session,
      source: source,
      card: current.first,
      moreCards: current.skip(1).toList(),
      boards: boards,
      stacks: stacks,
    ),
  );
}

/// Queues one card into [move] through the same outbox path as a single move.
Future<void> queueCardMoveTo(
  DeckSession session,
  DeckBoard board,
  DeckCard card,
  CardMoveDestination move, {
  VoidCallback? onTransferred,
}) async {
  final database = session.database;
  final account = session.account;
  final source = await _editableSource(session, board);
  final current = await _currentCard(session, source.id, card);
  final targetId =
      await database.resolveId(account.id, move.board.id, 'createBoard') ??
      move.board.id;
  if (source.id == targetId) {
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
      source.id,
      current,
      destinationBoardId: targetId,
      destinationStackId: move.stack.id,
      anchorCardId: move.anchorCardId,
      before: move.before,
    );
    onTransferred?.call();
    unawaited(session.refreshStacks(source.id));
    unawaited(session.refreshStacks(targetId));
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
  try {
    final move = await chooseBoardCardMove(context, session, board, [card]);
    if (move == null || !context.mounted) return;
    await queueCardMoveTo(
      session,
      board,
      card,
      move,
      onTransferred: onTransferred,
    );
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
