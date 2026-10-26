import 'dart:async';

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

  void _menuAction(String action, BoardSelection? selection) {
    if (action == 'move') {
      showBoardCardMove(context, widget.session, widget.board, widget.card);
    } else if (action == 'select') {
      selection?.toggle(widget.card);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/sync'),
          builder: (_) => PendingScreen(session: widget.session),
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _menuItems(
    AppLocalizations text, {
    required bool editable,
    required bool hasPending,
    required bool selectable,
  }) => [
    if (editable) PopupMenuItem(value: 'move', child: Text(text.moveCard)),
    if (selectable) PopupMenuItem(value: 'select', child: Text(text.selectCard)),
    if (hasPending)
      PopupMenuItem(value: 'pending', child: Text(text.pendingChanges)),
  ];

  Future<void> _openMenu(
    BuildContext buttonContext,
    AppLocalizations text,
    BoardSelection? selection, {
    required bool editable,
    required bool hasPending,
  }) async {
    final button = buttonContext.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(buttonContext).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: buttonContext,
      position: RelativeRect.fromRect(
        button.localToGlobal(Offset.zero, ancestor: overlay) & button.size,
        Offset.zero & overlay.size,
      ),
      items: _menuItems(
        text,
        editable: editable,
        hasPending: hasPending,
        selectable: selection != null,
      ),
    );
    if (action != null && mounted) _menuAction(action, selection);
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
      // Only the colour band needs rounded clipping; skipping it saves a clip per card.
      clipBehavior: card.rgbColor == null ? Clip.none : Clip.antiAlias,
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
              ? CardMenuButton(
                  label: text.cardActions,
                  onOpen: (buttonContext) => unawaited(
                    _openMenu(
                      buttonContext,
                      text,
                      selection,
                      editable: editable,
                      hasPending: hasPending,
                    ),
                  ),
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

/// A 48 dp "more" button that opens the card menu without a per-card
/// [PopupMenuButton], whose IconButton and Tooltip are costly to build while
/// scrolling.
class CardMenuButton extends StatelessWidget {
  const CardMenuButton({super.key, required this.label, required this.onOpen});
  final String label;
  final ValueChanged<BuildContext> onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: () => onOpen(context),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onOpen(context),
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: Icon(
            Icons.more_horiz,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ),
  );
}
