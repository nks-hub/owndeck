import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
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
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pendingDecision)),
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
  final _position = TextEditingController(text: '0');
  String? _error;
  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final maximum = widget.stacks
        .firstWhere((s) => s.id == _destination)
        .cards
        .where((c) => activeBoardCard(c) && c.id != widget.card.id)
        .length;
    return AlertDialog(
      title: Text(text.moveCard),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      _error = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _position,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: text.position,
                  helperText: text.boardMovePositionHint(maximum),
                  helperMaxLines: 3,
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_position.text);
            if (value == null || value < 0 || value > maximum) {
              setState(() => _error = text.invalidBoardMovePosition(maximum));
              return;
            }
            Navigator.pop(
              context,
              BoardDropPosition(_destination, index: value),
            );
          },
          child: Text(text.moveCard),
        ),
      ],
    );
  }
}
