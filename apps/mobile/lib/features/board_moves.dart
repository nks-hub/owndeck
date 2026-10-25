import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'board_drag.dart';

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
  final stacks = await session.database.stackView(session.account.id, board.id);
  final move = resolveBoardDrop(stacks, drag, position);
  if (move == null) return;
  await session.database.queueCardAction(
    session.account,
    board.id,
    move.card,
    'moveCard',
    {'stackId': position.stackId, 'order': move.order},
  );
  unawaited(session.refreshStacks(board.id));
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
  DeckCard card,
) async {
  final text = AppLocalizations.of(context)!;
  List<DeckStack> stacks;
  try {
    stacks = (await session.database.stackView(
      session.account.id,
      board.id,
    )).where((s) => (s.raw['deletedAt'] ?? 0) == 0).toList();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text.storageError)));
    }
    return;
  }
  if (!context.mounted ||
      stacks.isEmpty ||
      !board.permissions.edit ||
      board.archived ||
      !activeBoardCard(card)) {
    return;
  }

  final move = await showDialog<BoardDropPosition>(
    context: context,
    builder: (_) => _BoardMoveDialog(stacks: stacks, card: card),
  );
  if (move != null && context.mounted) {
    await moveBoardCard(
      context,
      session,
      board,
      BoardCardDrag(
        accountId: session.account.id,
        generation: session.account.generation,
        boardId: board.id,
        stackId: card.stackId,
        cardId: card.id,
      ),
      move,
    );
  }
}

class _BoardMoveDialog extends StatefulWidget {
  const _BoardMoveDialog({required this.stacks, required this.card});
  final List<DeckStack> stacks;
  final DeckCard card;
  @override
  State<_BoardMoveDialog> createState() => _BoardMoveDialogState();
}

class _BoardMoveDialogState extends State<_BoardMoveDialog> {
  late int _destination = widget.stacks.any((s) => s.id == widget.card.stackId)
      ? widget.card.stackId
      : widget.stacks.first.id;
  String _placement = 'end';
  int? _anchor;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final cards = widget.stacks
        .firstWhere((s) => s.id == _destination)
        .cards
        .where((c) => activeBoardCard(c) && c.id != widget.card.id)
        .toList();
    final relative = _placement == 'before' || _placement == 'after';
    return AlertDialog(
      scrollable: true,
      title: Text(text.moveCard),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.card.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _destination,
              isExpanded: true,
              decoration: InputDecoration(labelText: text.destinationColumn),
              items: [
                for (final stack in widget.stacks)
                  DropdownMenuItem(
                    value: stack.id,
                    child: Text(stack.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _destination = value;
                    _anchor = null;
                    _placement = 'end';
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(('placement', _destination, _placement)),
              initialValue: _placement,
              isExpanded: true,
              decoration: InputDecoration(labelText: text.position),
              items: [
                DropdownMenuItem(value: 'start', child: Text(text.moveToTop)),
                DropdownMenuItem(value: 'end', child: Text(text.moveToBottom)),
                if (cards.isNotEmpty) ...[
                  DropdownMenuItem(
                    value: 'before',
                    child: Text(text.moveBefore),
                  ),
                  DropdownMenuItem(value: 'after', child: Text(text.moveAfter)),
                ],
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _placement = value;
                    _anchor ??= cards.firstOrNull?.id;
                  });
                }
              },
            ),
            if (relative) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey(('anchor', _destination, _anchor)),
                initialValue: _anchor,
                isExpanded: true,
                decoration: InputDecoration(labelText: text.moveRelativeCard),
                items: [
                  for (final card in cards)
                    DropdownMenuItem(
                      value: card.id,
                      child: Text(card.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) => setState(() => _anchor = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: relative && _anchor == null
              ? null
              : () => Navigator.pop(
                  context,
                  BoardDropPosition(
                    _destination,
                    index: _placement == 'start' ? 0 : null,
                    anchorId: relative ? _anchor : null,
                    after: _placement == 'after',
                  ),
                ),
          child: Text(text.moveCard),
        ),
      ],
    );
  }
}
