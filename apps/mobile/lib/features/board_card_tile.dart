import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../data/card_edits.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'board_bulk.dart';
import 'board_drag.dart';
import 'board_moves.dart';
import 'card_detail.dart';
import 'card_summary.dart';
import 'pending.dart';

class BoardCardTile extends StatefulWidget {
  const BoardCardTile({
    super.key,
    required this.session,
    required this.board,
    required this.card,
    required this.editable,
    required this.activity,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckCard card;
  final bool editable;
  final BoardDragActivity activity;

  @override
  State<BoardCardTile> createState() => _BoardCardTileState();
}

class _BoardCardTileState extends State<BoardCardTile> {
  bool _savingDone = false;

  Future<void> _setDone(bool completed) async {
    if (_savingDone) return;
    final session = widget.session;
    setState(() => _savingDone = true);
    try {
      await setCardCompleted(session, widget.board.id, widget.card, completed);
    } catch (error) {
      if (mounted && widget.session == session) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localWriteErrorMessage(error, AppLocalizations.of(context)!),
            ),
          ),
        );
      }
    } finally {
      if (mounted && widget.session == session) {
        setState(() => _savingDone = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    final board = widget.board;
    final card = widget.card;
    final editable = widget.editable;
    final activity = widget.activity;
    final drag = BoardCardDrag(
      accountId: session.account.id,
      generation: session.account.generation,
      boardId: board.id,
      stackId: card.stackId,
      cardId: card.id,
    );
    final hasPending = card.raw['syncState'] != null;
    // Archived cards cannot be dragged or moved, but can still be restored.
    final selectable =
        editable ||
        (card.archived && board.permissions.edit && !board.archived);
    final selection = selectable ? BoardSelectionScope.maybeOf(context) : null;
    final selecting = selection != null && selection.active;
    final selected = selecting && selection.contains(card);
    final content = Card(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      semanticContainer: false,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: card.rgbColor == null
              ? null
              : Border(
                  top: BorderSide(
                    width: 6,
                    color: Color(0xff000000 | card.rgbColor!),
                  ),
                ),
        ),
        child: CardSummary(
          card: card,
          onCompletedChanged:
              editable && card.raw.containsKey('done') && !_savingDone
              ? _setDone
              : null,
          changingCompletion: _savingDone,
          onOpen: selecting
              ? () => selection.toggle(card)
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    settings: const RouteSettings(name: '/card'),
                    builder: (_) =>
                        CardScreen(session: session, board: board, card: card),
                  ),
                ),
          trailing: selecting
              ? Checkbox(
                  value: selected,
                  semanticLabel: text.selectCard,
                  onChanged: (_) => selection.toggle(card),
                )
              : editable || hasPending || selection != null
              ? PopupMenuButton<String>(
                  tooltip: text.cardActions,
                  icon: Icon(
                    Icons.more_horiz,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (action) {
                    if (action == 'move') {
                      showBoardCardMove(context, session, board, card);
                    } else if (action == 'select') {
                      selection?.toggle(card);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: '/sync'),
                          builder: (_) => PendingScreen(session: session),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    if (editable)
                      PopupMenuItem(value: 'move', child: Text(text.moveCard)),
                    if (selection != null)
                      PopupMenuItem(
                        value: 'select',
                        child: Text(text.selectCard),
                      ),
                    if (hasPending)
                      PopupMenuItem(
                        value: 'pending',
                        child: Text(text.pendingChanges),
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
    if (!editable || selecting) return content;
    return LongPressDraggable<BoardCardDrag>(
      key: ValueKey(('drag-card', card.id)),
      data: drag,
      maxSimultaneousDrags: _savingDone ? 0 : 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => activity.start(drag),
      onDragCompleted: activity.stop,
      onDraggableCanceled: (_, _) => activity.stop(),
      feedback: Transform.translate(
        offset: const Offset(-120, -24),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: SizedBox(
            width: 260,
            child: CardSummary(card: card, showDescription: false),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: content),
      child: Semantics(hint: text.reorderCard, child: content),
    );
  }
}
