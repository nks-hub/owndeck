import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../core/app_preferences.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_card_tile.dart';
import 'board_drag.dart';
import 'board_moves.dart';
import 'card_column.dart';

final class BoardColumnView {
  BoardColumnView(this.stack, bool archived)
    : cards = stack.cards
          .where(
            (card) =>
                card.archived == archived && (card.raw['deletedAt'] ?? 0) == 0,
          )
          .toList(growable: false);
  final DeckStack stack;
  final List<DeckCard> cards;
}

class BoardLayout extends StatefulWidget {
  const BoardLayout({
    super.key,
    required this.session,
    required this.board,
    required this.columns,
    required this.archivedView,
    required this.mode,
  });
  final DeckSession session;
  final DeckBoard board;
  final List<BoardColumnView> columns;
  final bool archivedView;
  final BoardViewMode mode;
  @override
  State<BoardLayout> createState() => _BoardLayoutState();
}

class _BoardLayoutState extends State<BoardLayout> {
  final _activity = BoardDragActivity();
  List<_BoardListRow>? _rows;
  Map<Key, int> _rowIndices = {};
  @override
  void didUpdateWidget(covariant BoardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.columns, widget.columns)) _rows = null;
  }

  @override
  void dispose() {
    _activity.dispose();
    super.dispose();
  }

  bool _editable(BoardColumnView column) =>
      widget.board.permissions.edit &&
      !widget.board.archived &&
      !widget.archivedView &&
      (column.stack.raw['deletedAt'] ?? 0) == 0;
  void _drop(BoardCardDrag drag, BoardDropPosition position) => unawaited(
    moveBoardCard(context, widget.session, widget.board, drag, position),
  );

  Widget _column(BoardColumnView column, {bool parentDropSurface = false}) =>
      CardColumn(
        key: ValueKey(('column', column.stack.id)),
        session: widget.session,
        board: widget.board,
        stack: column.stack,
        cards: column.cards,
        archivedView: widget.archivedView,
        activity: _activity,
        parentDropSurface: parentDropSurface,
      );

  Widget _surface(
    Widget child,
    ValueChanged<Offset> pointer,
    VoidCallback stop,
  ) => BoardDropSurface(
    accountId: widget.session.account.id,
    generation: widget.session.account.generation,
    boardId: widget.board.id,
    enabled:
        widget.board.permissions.edit &&
        !widget.board.archived &&
        !widget.archivedView,
    onDrop: _drop,
    onPointer: pointer,
    onExit: stop,
    child: child,
  );

  Widget _heading(BoardColumnView column) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(
      children: [
        if (column.stack.isDoneColumn)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.check_circle_outline,
              semanticLabel: AppLocalizations.of(context)!.doneColumn,
            ),
          ),
        Expanded(
          child: Text(
            '${column.stack.title} (${column.cards.length})',
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.mode == BoardViewMode.list) return _list();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return _mobileColumns();
        final width = ((constraints.maxWidth - 32) / 2)
            .clamp(280.0, 360.0)
            .toDouble();
        return BoardDragScrollRegion(
          activity: _activity,
          axis: Axis.horizontal,
          builder: (context, scroll, pointer, stop) => _surface(
            ListView.builder(
              key: const ValueKey('board-wide-columns'),
              controller: scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.columns.length,
              itemExtent: width + 8,
              findChildIndexCallback: (key) {
                if (key is! ValueKey<int>) return null;
                final index = widget.columns.indexWhere(
                  (column) => column.stack.id == key.value,
                );
                return index < 0 ? null : index;
              },
              itemBuilder: (context, index) {
                final column = widget.columns[index];
                return Padding(
                  key: ValueKey<int>(column.stack.id),
                  padding: const EdgeInsets.only(right: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _heading(column),
                        Expanded(
                          child: _column(column, parentDropSurface: true),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            pointer,
            stop,
          ),
        );
      },
    );
  }

  Widget _mobileColumns() => DefaultTabController(
    key: ValueKey(widget.columns.map((c) => c.stack.id).join(',')),
    length: widget.columns.length,
    child: Builder(
      builder: (context) => Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              for (var index = 0; index < widget.columns.length; index++)
                _ColumnTab(
                  key: ValueKey(widget.columns[index].stack.id),
                  column: widget.columns[index],
                  enabled: _editable(widget.columns[index]),
                  accountId: widget.session.account.id,
                  generation: widget.session.account.generation,
                  boardId: widget.board.id,
                  onDrop: _drop,
                  onHover: () =>
                      DefaultTabController.of(context).animateTo(index),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [for (final column in widget.columns) _column(column)],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _list() {
    if (_rows == null) {
      _rows = [
        for (final column in widget.columns) ...[
          _BoardListRow(column, header: true),
          for (final card in column.cards) _BoardListRow(column, card: card),
          _BoardListRow(column),
        ],
      ];
      _rowIndices = {
        for (var i = 0; i < _rows!.length; i++) _rowKey(_rows![i]): i,
      };
    }
    return BoardDragScrollRegion(
      activity: _activity,
      builder: (context, scroll, pointer, stop) => _surface(
        RefreshIndicator(
          onRefresh: () => widget.session.refreshStacks(widget.board.id),
          child: ListView.builder(
            key: PageStorageKey((
              'board-list',
              widget.session.account.id,
              widget.board.id,
              widget.archivedView,
            )),
            controller: scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: _rows!.length,
            findChildIndexCallback: (key) => _rowIndices[key],
            itemBuilder: (context, index) {
              final row = _rows![index];
              if (row.header) {
                return KeyedSubtree(
                  key: _rowKey(row),
                  child: _heading(row.column),
                );
              }
              final card = row.card;
              return BoardCardDropTarget(
                key: _rowKey(row),
                stackId: row.column.stack.id,
                cardId: card?.id,
                enabled: _editable(row.column),
                child: card == null
                    ? BoardColumnFooter(
                        session: widget.session,
                        board: widget.board,
                        stack: row.column.stack,
                        empty: row.column.cards.isEmpty,
                        editable: _editable(row.column),
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
                        editable: _editable(row.column),
                        activity: _activity,
                      ),
              );
            },
          ),
        ),
        pointer,
        stop,
      ),
    );
  }

  Key _rowKey(_BoardListRow row) => row.header
      ? ValueKey(('stack-heading', row.column.stack.id))
      : boardDropKey(
          widget.session.account.id,
          widget.session.account.generation,
          widget.board.id,
          row.column.stack.id,
          row.card?.id,
        );
}

final class _BoardListRow {
  const _BoardListRow(this.column, {this.card, this.header = false});
  final BoardColumnView column;
  final DeckCard? card;
  final bool header;
}

class _ColumnTab extends StatefulWidget {
  const _ColumnTab({
    super.key,
    required this.column,
    required this.accountId,
    required this.generation,
    required this.boardId,
    required this.enabled,
    required this.onDrop,
    required this.onHover,
  });
  final BoardColumnView column;
  final String accountId;
  final int generation;
  final int boardId;
  final bool enabled;
  final BoardDropHandler onDrop;
  final VoidCallback onHover;
  @override
  State<_ColumnTab> createState() => _ColumnTabState();
}

class _ColumnTabState extends State<_ColumnTab> {
  Timer? _hover;
  bool _accepts(BoardCardDrag data) =>
      widget.enabled &&
      data.accountId == widget.accountId &&
      data.generation == widget.generation &&
      data.boardId == widget.boardId;
  @override
  void dispose() {
    _hover?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DragTarget<BoardCardDrag>(
    onWillAcceptWithDetails: (details) {
      if (!_accepts(details.data)) return false;
      _hover?.cancel();
      _hover = Timer(const Duration(milliseconds: 350), () {
        if (mounted) widget.onHover();
      });
      return true;
    },
    onLeave: (_) => _hover?.cancel(),
    onAcceptWithDetails: (details) {
      _hover?.cancel();
      if (_accepts(details.data)) {
        widget.onDrop(details.data, BoardDropPosition(widget.column.stack.id));
      }
    },
    builder: (context, candidates, _) => DecoratedBox(
      decoration: BoxDecoration(
        border: candidates.isEmpty
            ? null
            : Border(
                bottom: BorderSide(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
      ),
      child: Tab(
        icon: widget.column.stack.isDoneColumn
            ? Icon(
                Icons.check_circle_outline,
                semanticLabel: AppLocalizations.of(context)!.doneColumn,
              )
            : null,
        text: '${widget.column.stack.title} (${widget.column.cards.length})',
      ),
    ),
  );
}
