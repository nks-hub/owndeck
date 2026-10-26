import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/session.dart';
import '../data/card_edits.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'board_bulk.dart';
import 'board_drag.dart';
import 'board_moves.dart';
import 'card_actions.dart';
import 'card_pane.dart';
import 'card_summary.dart';
import 'desktop_platform.dart';
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
  late final _focus = _CardFocusNode(onKeyEvent: _arrow);
  VoidCallback? _open;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Arrow keys move the focus to the neighbouring card instead of a control.
  KeyEventResult _arrow(FocusNode node, KeyEvent event) {
    if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
        node.hasPrimaryFocus) {
      if (event is KeyDownEvent) _open?.call();
      return KeyEventResult.handled;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      _ => null,
    };
    if (direction == null || !node.hasPrimaryFocus) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final neighbour = _neighbourCard(node, direction);
    if (neighbour != null) {
      neighbour.requestFocus();
      final target = neighbour.context;
      if (target != null) unawaited(Scrollable.ensureVisible(target));
    }
    return KeyEventResult.handled;
  }

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
    final session = widget.session;
    final board = widget.board;
    final card = widget.card;
    switch (action) {
      case 'move':
        unawaited(showBoardCardMove(context, session, board, card));
      case 'labels':
        unawaited(chooseCardLabels(context, session, board, card));
      case 'archive':
        unawaited(
          runCardAction(
            context,
            session,
            board.id,
            card,
            card.archived ? 'unarchiveCard' : 'archiveCard',
            {},
          ),
        );
      case 'delete':
        unawaited(deleteCardWithConfirmation(context, session, board.id, card));
      case 'select':
        selection?.toggle(card);
      default:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/sync'),
            builder: (_) => PendingScreen(session: session),
          ),
        );
    }
  }

  List<PopupMenuEntry<String>> _menuItems(
    AppLocalizations text, {
    required bool editable,
    required bool hasPending,
    required bool selectable,
    bool full = false,
  }) => [
    if (editable) PopupMenuItem(value: 'move', child: Text(text.moveCard)),
    if (full && editable && !widget.card.archived)
      PopupMenuItem(value: 'labels', child: Text(text.labels)),
    if (full && editable && !widget.card.archived)
      PopupMenuItem(value: 'archive', child: Text(text.archive))
    else if (full && selectable && widget.card.archived)
      PopupMenuItem(value: 'archive', child: Text(text.unarchive)),
    if (full && editable)
      PopupMenuItem(value: 'delete', child: Text(text.deleteCard)),
    if (selectable)
      PopupMenuItem(value: 'select', child: Text(text.selectCard)),
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

  /// Right click: the complete action list at the pointer.
  Future<void> _openContextMenu(
    Offset at,
    AppLocalizations text,
    BoardSelection? selection, {
    required bool editable,
    required bool hasPending,
  }) async {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final items = _menuItems(
      text,
      editable: editable,
      hasPending: hasPending,
      selectable: selection != null,
      full: true,
    );
    if (items.isEmpty) return;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        at & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: items,
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
    final pane = CardPaneScope.maybeOf(context)?.open;
    final shownInPane =
        pane != null && pane.board.id == board.id && pane.card.id == card.id;
    final content = GestureDetector(
      onSecondaryTapDown: (details) => unawaited(
        _openContextMenu(
          details.globalPosition,
          text,
          selection,
          editable: editable,
          hasPending: hasPending,
        ),
      ),
      child: Card(
        color: selected || shownInPane
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
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
            onOpen: _open = selecting
                ? () => selection.toggle(card)
                : () => openCard(context, session, board, card),
            focusNode: _focus,
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
      ),
    );
    if (!editable || selecting) return content;
    Widget draggable(Widget child, {required bool mouse}) => _CardDraggable(
      key: mouse == isDesktopPlatform ? ValueKey(('drag-card', card.id)) : null,
      mouse: mouse,
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
      child: child,
    );
    final touch = draggable(
      Semantics(hint: text.reorderCard, child: content),
      mouse: false,
    );
    return isDesktopPlatform ? draggable(touch, mouse: true) : touch;
  }
}

/// Mouse pointers drag immediately; every other pointer keeps the long press.
class _CardDraggable extends Draggable<BoardCardDrag> {
  const _CardDraggable({
    super.key,
    required this.mouse,
    required super.child,
    required super.feedback,
    super.data,
    super.maxSimultaneousDrags,
    super.dragAnchorStrategy,
    super.onDragStarted,
    super.onDragCompleted,
    super.onDraggableCanceled,
    super.childWhenDragging,
  });
  final bool mouse;

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => mouse
      ? (ImmediateMultiDragGestureRecognizer(
          supportedDevices: const {PointerDeviceKind.mouse},
        )..onStart = onStart)
      : (DelayedMultiDragGestureRecognizer(delay: kLongPressTimeout)
          ..onStart = (position) {
            final drag = onStart(position);
            if (drag != null) HapticFeedback.selectionClick();
            return drag;
          });
}

class _CardFocusNode extends FocusNode {
  _CardFocusNode({super.onKeyEvent}) : super(debugLabel: 'board-card');
}

/// The built card nearest to [from] in [direction]; same-column cards win over
/// cards in other columns.
FocusNode? _neighbourCard(FocusNode from, TraversalDirection direction) {
  final here = from.rect;
  FocusNode? best;
  double bestScore = double.infinity;
  final scope = from.enclosingScope;
  if (scope == null) return null;
  for (final node in scope.descendants.whereType<_CardFocusNode>()) {
    if (node == from || !node.canRequestFocus || node.context == null) {
      continue;
    }
    final rect = node.rect;
    final double primary;
    final double cross;
    switch (direction) {
      case TraversalDirection.down:
        if (rect.top <= here.top + 1 ||
            rect.left >= here.right ||
            rect.right <= here.left) {
          continue;
        }
        primary = rect.top - here.top;
        cross = (rect.left - here.left).abs();
      case TraversalDirection.up:
        if (rect.top >= here.top - 1 ||
            rect.left >= here.right ||
            rect.right <= here.left) {
          continue;
        }
        primary = here.top - rect.top;
        cross = (rect.left - here.left).abs();
      case TraversalDirection.right:
        if (rect.left < here.right - 1) {
          continue;
        }
        primary = rect.left - here.right;
        cross = (rect.top - here.top).abs();
      case TraversalDirection.left:
        if (rect.right > here.left + 1) {
          continue;
        }
        primary = here.left - rect.right;
        cross = (rect.top - here.top).abs();
    }
    final score = primary * 1000 + cross;
    if (score < bestScore) {
      bestScore = score;
      best = node;
    }
  }
  return best;
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
