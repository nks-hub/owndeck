import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_drag.dart';
import 'board_moves.dart';
import 'card_detail.dart';
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
    final handle = Tooltip(
      message: text.reorderCard,
      triggerMode: TooltipTriggerMode.tap,
      child: SizedBox(
        key: ValueKey(('drag-card', card.id)),
        width: 48,
        height: 48,
        child: Icon(Icons.drag_handle, semanticLabel: text.reorderCard),
      ),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/card'),
            builder: (_) =>
                CardScreen(session: session, board: board, card: card),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: card.rgbColor == null
              ? null
              : BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      width: 4,
                      color: Color(0xff000000 | card.rgbColor!),
                    ),
                  ),
                ),
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (card.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    card.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (card.raw['syncState'] != null)
                    IconButton(
                      tooltip: text.pendingChanges,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: '/sync'),
                          builder: (_) => PendingScreen(session: session),
                        ),
                      ),
                    ),
                  if (editable) ...[
                    PopupMenuButton<String>(
                      tooltip: text.cardActions,
                      onSelected: (_) =>
                          showBoardCardMove(context, session, board, card),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'move',
                          child: Text(text.moveCard),
                        ),
                      ],
                    ),
                    LongPressDraggable<BoardCardDrag>(
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          child: SizedBox(
                            width: 240,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                card.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: .35, child: handle),
                      child: handle,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
