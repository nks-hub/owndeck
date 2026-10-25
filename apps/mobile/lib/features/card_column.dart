import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_card_tile.dart';
import 'board_drag.dart';
import 'board_moves.dart';
import 'quick_add_card.dart';
import 'structure_editor.dart';

class CardColumn extends StatefulWidget {
  const CardColumn({
    super.key,
    required this.session,
    required this.board,
    required this.stack,
    required this.archivedView,
    this.cards,
    this.activity,
    this.parentDropSurface = false,
    this.filtered = false,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckStack stack;
  final bool archivedView;
  final List<DeckCard>? cards;
  final BoardDragActivity? activity;
  final bool parentDropSurface;
  final bool filtered;
  @override
  State<CardColumn> createState() => _CardColumnState();
}

class _CardColumnState extends State<CardColumn> {
  final _ownActivity = BoardDragActivity();
  List<DeckCard>? _indexedCards;
  Object? _indexScope;
  Map<Key, int> _indices = {};
  @override
  void dispose() {
    _ownActivity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards ?? widget.stack.cards;
    final activity = widget.activity ?? _ownActivity;
    final editable =
        widget.board.permissions.edit &&
        !widget.board.archived &&
        !widget.archivedView &&
        (widget.stack.raw['deletedAt'] ?? 0) == 0;
    final scope = (
      widget.session.account.id,
      widget.session.account.generation,
      widget.board.id,
      widget.stack.id,
    );
    Key keyFor(int? id) => boardDropKey(
      widget.session.account.id,
      widget.session.account.generation,
      widget.board.id,
      widget.stack.id,
      id,
    );
    if (!identical(_indexedCards, cards) || _indexScope != scope) {
      _indexedCards = cards;
      _indexScope = scope;
      _indices = {
        for (var i = 0; i < cards.length; i++) keyFor(cards[i].id): i,
        keyFor(null): cards.length,
      };
    }
    void drop(BoardCardDrag drag, BoardDropPosition position) => unawaited(
      moveBoardCard(context, widget.session, widget.board, drag, position),
    );
    final list = BoardDragScrollRegion(
      activity: activity,
      builder: (context, scroll, pointer, stop) {
        final content = RefreshIndicator(
          onRefresh: () => widget.session.refreshStacks(widget.board.id),
          child: ListView.builder(
            key: PageStorageKey((
              'column',
              widget.session.account.id,
              widget.board.id,
              widget.stack.id,
              widget.archivedView,
            )),
            controller: scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: cards.length + 1,
            findChildIndexCallback: (key) => _indices[key],
            itemBuilder: (context, index) {
              final card = index < cards.length ? cards[index] : null;
              return BoardCardDropTarget(
                key: keyFor(card?.id),
                stackId: widget.stack.id,
                cardId: card?.id,
                enabled: editable,
                onPointer: widget.parentDropSurface ? pointer : null,
                onExit: widget.parentDropSurface ? stop : null,
                child: card == null
                    ? BoardColumnFooter(
                        session: widget.session,
                        board: widget.board,
                        stack: widget.stack,
                        empty: cards.isEmpty,
                        editable: editable,
                        filtered: widget.filtered,
                      )
                    : BoardCardTile(
                        key: ValueKey((
                          'board-card',
                          widget.session.account.id,
                          widget.session.account.generation,
                          widget.board.id,
                          card.id,
                        )),
                        session: widget.session,
                        board: widget.board,
                        card: card,
                        editable: editable,
                        activity: activity,
                      ),
              );
            },
          ),
        );
        if (widget.parentDropSurface) return content;
        return BoardDropSurface(
          accountId: widget.session.account.id,
          generation: widget.session.account.generation,
          boardId: widget.board.id,
          enabled: editable,
          onDrop: drop,
          onPointer: pointer,
          onExit: stop,
          child: content,
        );
      },
    );
    final text = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (editable || widget.board.permissions.manage)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (editable)
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: ValueKey(('column-add-card', widget.stack.id)),
                        icon: const Icon(Icons.add),
                        label: Text(text.addCard),
                        onPressed: () => showQuickAddCard(
                          context,
                          widget.session,
                          board: widget.board,
                          stackId: widget.stack.id,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (widget.board.permissions.manage && !widget.board.archived)
                  StackActions(
                    session: widget.session,
                    board: widget.board,
                    stack: widget.stack,
                  ),
              ],
            ),
          ),
        Expanded(child: list),
      ],
    );
  }
}

class BoardColumnFooter extends StatelessWidget {
  const BoardColumnFooter({
    super.key,
    required this.session,
    required this.board,
    required this.stack,
    required this.empty,
    required this.editable,
    this.filtered = false,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckStack stack;
  final bool empty;
  final bool editable;
  final bool filtered;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          if (stack.raw['syncState'] != null) Text(text.pendingChanges),
          if (empty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                filtered ? text.boardNoMatchingCards : text.emptyStack,
              ),
            ),
          if (editable)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(text.dropCardHere),
            ),
        ],
      ),
    );
  }
}
