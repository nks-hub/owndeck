import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_drag.dart';
import 'board_moves.dart';
import 'card_detail.dart';
import 'card_summary.dart';
import 'pending.dart';

class BoardCardTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final drag = BoardCardDrag(
      accountId: session.account.id,
      generation: session.account.generation,
      boardId: board.id,
      stackId: card.stackId,
      cardId: card.id,
    );
    final hasPending = card.raw['syncState'] != null;
    final content = Card(
      semanticContainer: false,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: card.rgbColor == null
              ? null
              : Border(
                  left: BorderSide(
                    width: 4,
                    color: Color(0xff000000 | card.rgbColor!),
                  ),
                ),
        ),
        child: CardSummary(
          card: card,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/card'),
              builder: (_) =>
                  CardScreen(session: session, board: board, card: card),
            ),
          ),
          trailing: editable || hasPending
              ? PopupMenuButton<String>(
                  tooltip: text.cardActions,
                  onSelected: (action) {
                    if (action == 'move') {
                      showBoardCardMove(context, session, board, card);
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
    if (!editable) return content;
    return LongPressDraggable<BoardCardDrag>(
      key: ValueKey(('drag-card', card.id)),
      data: drag,
      maxSimultaneousDrags: 1,
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
