import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_detail.dart';
import 'card_editor.dart';
import 'pending.dart';
import 'structure_editor.dart';

class CardColumn extends StatelessWidget {
  const CardColumn({
    super.key,
    required this.session,
    required this.board,
    required this.stack,
    required this.archivedView,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckStack stack;
  final bool archivedView;

  Future<void> _reorder(
    BuildContext context,
    int oldIndex,
    int newIndex,
  ) async {
    if (!board.permissions.edit || board.archived || archivedView) return;
    if (newIndex > oldIndex) newIndex--;
    if (newIndex == oldIndex) return;
    final text = AppLocalizations.of(context)!;
    try {
      await session.database.queueCardAction(
        session.account,
        board.id,
        stack.cards[oldIndex],
        'moveCard',
        {'stackId': stack.id, 'order': newIndex},
      );
      unawaited(session.refreshStacks(board.id));
    } catch (_) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.pendingDecision)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final editable = board.permissions.edit && !board.archived && !archivedView;
    return RefreshIndicator(
      onRefresh: () => session.refreshStacks(board.id),
      child: ReorderableListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        buildDefaultDragHandles: false,
        itemCount: stack.cards.length,
        onReorder: (oldIndex, newIndex) =>
            _reorder(context, oldIndex, newIndex),
        footer: Column(
          children: [
            if (stack.raw['syncState'] != null) Text(text.pendingChanges),
            if (board.permissions.manage && !board.archived)
              StackActions(session: session, board: board, stack: stack),
            if (stack.cards.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(text.emptyStack),
              ),
            if (editable)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(text.addCard),
                  onPressed: () =>
                      editCard(context, session, board.id, stack.id),
                ),
              ),
          ],
        ),
        itemBuilder: (context, index) {
          final card = stack.cards[index];
          return Card(
            key: ValueKey(card.id),
            child: ListTile(
              title: Text(card.title),
              subtitle: card.description.isEmpty
                  ? null
                  : Text(
                      card.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
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
                  if (editable)
                    ReorderableDelayedDragStartListener(
                      index: index,
                      child: Tooltip(
                        message: text.reorderCard,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.drag_handle,
                            semanticLabel: text.reorderCard,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/card'),
                  builder: (_) =>
                      CardScreen(session: session, board: board, card: card),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
