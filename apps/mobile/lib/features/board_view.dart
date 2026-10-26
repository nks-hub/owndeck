import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_preferences.dart';
import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_bulk.dart';
import 'board_layout.dart';
import 'board_moves.dart';
import 'board_presence.dart';
import 'card_pane.dart';
import 'desktop_shortcuts.dart';
import 'board_filters.dart';
import 'quick_add_card.dart';
import 'state_message.dart';
import 'structure_editor.dart';
import 'sync_notice.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({
    super.key,
    required this.session,
    required this.board,
    this.initialStackId,
  });
  final DeckSession session;
  final DeckBoard board;

  /// Column to show first on narrow screens, restored from the last visit.
  final int? initialStackId;
  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  late DeckBoard _board;
  final _selection = BoardSelection();
  bool _unavailable = false;
  bool _showArchived = false;
  bool _bulkBusy = false;
  StreamSubscription<DeckBoard?>? _boardChanges;
  late Stream<List<DeckStack>> _stacks;
  List<DeckStack>? _input;
  late int? _stackId = widget.initialStackId;
  List<BoardColumnView> _columns = [];
  bool? _filteredArchive;
  int _binding = 0;
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  BoardCardFilter _filter = const BoardCardFilter();
  BoardCardFilter? _appliedFilter;
  Timer? _filterClock;

  Future<void> _refresh() => widget.session.refreshStacks(widget.board.id);
  @override
  void initState() {
    super.initState();
    _bind();
    _filterClock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted &&
          _filter.due != BoardDueFilter.any &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.of(context)?.isCurrent != false) {
        setState(() => _appliedFilter = null);
      }
    });
  }

  void _bind() {
    final binding = ++_binding;
    final session = widget.session;
    _board = widget.board;
    _unavailable = false;
    _input = null;
    _columns = [];
    _stacks = session.watchStacks(widget.board.id);
    final preferences = ref.read(appPreferencesProvider);
    unawaited(preferences.loadBoardViewMode(session.account.id, _board.id));
    if (_board.id > 0) {
      unawaited(preferences.rememberLastBoard(session.account.id, _board.id));
    }
    unawaited(_restoreFilter(binding));
    _boardChanges = session.database
        .watchBoard(session.account.id, widget.board.id)
        .listen(
          (board) {
            if (!mounted || binding != _binding) return;
            if (board != null && board.id != _board.id) {
              if (_board.id < 0 && board.id > 0) {
                unawaited(
                  preferences.setBoardViewMode(
                    session.account.id,
                    board.id,
                    preferences.boardViewMode(session.account.id, _board.id),
                  ),
                );
              } else {
                unawaited(
                  preferences.loadBoardViewMode(session.account.id, board.id),
                );
              }
            }
            setState(() {
              _unavailable = board == null || !board.permissions.read;
              if (board != null) _board = board;
            });
          },
          onError: (Object _) {
            if (mounted && binding == _binding) {
              setState(() => _unavailable = true);
            }
          },
        );
  }

  @override
  void didUpdateWidget(covariant BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.board.id != widget.board.id) {
      unawaited(_boardChanges?.cancel());
      _showArchived = false;
      _stackId = widget.initialStackId;
      _selection.clear();
      _filter = const BoardCardFilter();
      _query.clear();
      _bind();
    }
  }

  @override
  void dispose() {
    _binding++;
    _filterClock?.cancel();
    _query.dispose();
    _searchFocus.dispose();
    _selection.dispose();
    unawaited(_boardChanges?.cancel());
    super.dispose();
  }

  List<BoardColumnView> _visible(List<DeckStack>? stacks) {
    if (!identical(_input, stacks) ||
        _filteredArchive != _showArchived ||
        !identical(_appliedFilter, _filter)) {
      _input = stacks;
      _filteredArchive = _showArchived;
      _appliedFilter = _filter;
      _columns = [
        for (final stack in stacks ?? <DeckStack>[])
          BoardColumnView(stack, _showArchived, filter: _filter),
      ];
    }
    return _columns;
  }

  void _setFilter(BoardCardFilter value) {
    setState(() {
      _filter = value;
      if (_query.text != value.query) _query.text = value.query;
    });
    unawaited(
      ref
          .read(appPreferencesProvider)
          .setBoardFilter(widget.session.account.id, _board.id, value.encode()),
    );
  }

  Future<void> _restoreFilter(int binding) async {
    final saved = await ref
        .read(appPreferencesProvider)
        .loadBoardFilter(widget.session.account.id, _board.id);
    if (!mounted || binding != _binding || _filter.active || saved == null) {
      return;
    }
    final value = BoardCardFilter.decode(saved);
    setState(() {
      _filter = value;
      _query.text = value.query;
    });
  }

  Future<void> _chooseFilters() async {
    final value = await showBoardFilters(
      context,
      filter: _filter,
      board: _board,
      stacks: _input ?? const [],
    );
    if (value != null && mounted) _setFilter(value);
  }

  /// Runs one bulk action at a time; the actions stay disabled meanwhile.
  Future<void> _guardBulk(Future<void> Function() run) async {
    if (_bulkBusy) return;
    setState(() => _bulkBusy = true);
    try {
      await run();
    } finally {
      if (mounted) setState(() => _bulkBusy = false);
    }
  }

  Future<void> _bulkMove() => _guardBulk(_runBulkMove);

  Future<void> _bulkArchive() => _guardBulk(_runBulkArchive);

  Future<void> _runBulkMove() async {
    final text = AppLocalizations.of(context)!;
    try {
      _selection.refresh(_input?.expand((stack) => stack.cards) ?? const []);
      if (!_selection.active) return;
      final move = await chooseBoardCardMove(
        context,
        widget.session,
        _board,
        _selection.cards,
      );
      if (move == null || !mounted) return;
      await runBulkAction(
        context,
        _selection,
        (cards) => moveEach(widget.session, _board, cards, move),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage(error, text))));
      }
    }
  }

  Future<void> _runBulkArchive() async {
    _selection.refresh(_input?.expand((stack) => stack.cards) ?? const []);
    if (!_selection.active) return;
    await runBulkAction(
      context,
      _selection,
      (cards) =>
          archiveEach(widget.session, _board, cards, archive: !_showArchived),
    );
  }

  void _selectAllVisible() => _selection.addAll(
    _columns
        .where((column) => (column.stack.raw['deletedAt'] ?? 0) == 0)
        .expand((column) => column.cards),
  );

  @override
  Widget build(BuildContext context) => BoardSelectionScope(
    selection: _selection,
    child: ListenableBuilder(
      listenable: _selection,
      builder: (context, _) => PopScope(
        canPop: !_selection.active,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _selection.clear();
        },
        child: BoardPresence(
          session: widget.session,
          boardId: _board.id,
          child: _content(context),
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    final preferences = ref.watch(appPreferencesProvider);
    final mode = preferences.boardViewMode(session.account.id, _board.id);
    if (_unavailable || _board.deletedAt != 0) {
      return Scaffold(
        appBar: AppBar(title: Text(_board.title)),
        body: Center(child: Text(text.permissionError)),
      );
    }
    final canCreate =
        _board.permissions.edit && !_board.archived && !_showArchived;
    return DesktopShortcuts(
      onNew: canCreate
          ? () => showQuickAddCard(context, session, board: _board)
          : null,
      onSearch: () {
        _searchFocus.requestFocus();
        _query.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _query.text.length,
        );
      },
      onEscape: () {
        if (_selection.active) {
          _selection.clear();
        } else {
          CardPaneScope.maybeOf(context)?.close();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _selection.active
              ? IconButton(
                  tooltip: text.cancelSelection,
                  icon: const Icon(Icons.close),
                  onPressed: _bulkBusy ? null : _selection.clear,
                )
              : null,
          bottom: _bulkBusy
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(4),
                  child: LinearProgressIndicator(),
                )
              : null,
          title: Text(
            _selection.active
                ? text.selectedCardsCount(_selection.length)
                : _board.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_selection.active) ...[
              IconButton(
                tooltip: text.selectAllVisibleCards,
                icon: const Icon(Icons.select_all),
                onPressed: _bulkBusy ? null : _selectAllVisible,
              ),
              if (!_showArchived)
                IconButton(
                  tooltip: text.moveSelectedCards,
                  icon: const Icon(Icons.drive_file_move_outlined),
                  onPressed: _bulkBusy ? null : _bulkMove,
                ),
              IconButton(
                tooltip: _showArchived
                    ? text.unarchiveSelectedCards
                    : text.archiveSelectedCards,
                icon: Icon(
                  _showArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                onPressed: _bulkBusy ? null : _bulkArchive,
              ),
            ] else ...[
              for (final value in BoardViewMode.values)
                if (value != mode)
                  IconButton(
                    key: ValueKey(('board-view', value)),
                    tooltip: value == BoardViewMode.columns
                        ? text.boardColumns
                        : text.boardList,
                    icon: Icon(
                      value == BoardViewMode.columns
                          ? Icons.view_kanban_outlined
                          : Icons.view_list_outlined,
                    ),
                    onPressed: () => unawaited(
                      preferences.setBoardViewMode(
                        session.account.id,
                        _board.id,
                        value,
                      ),
                    ),
                  ),
              BoardActions(
                session: session,
                board: _board,
                extraItems: [
                  PopupMenuItem(
                    value: 'toggle-archived-cards',
                    child: Text(
                      _showArchived ? text.activeCards : text.archivedCards,
                    ),
                  ),
                  if (_board.permissions.manage && !_board.archived)
                    PopupMenuItem(
                      value: 'add-column',
                      child: Text(text.addStack),
                    ),
                  PopupMenuItem(
                    value: 'refresh-board',
                    child: Text(text.refresh),
                  ),
                  const PopupMenuDivider(),
                ],
                onExtraAction: (action) {
                  switch (action) {
                    case 'toggle-archived-cards':
                      _selection.clear();
                      setState(() => _showArchived = !_showArchived);
                    case 'add-column':
                      unawaited(
                        editStructure(
                          context,
                          session,
                          board: _board,
                          column: true,
                        ),
                      );
                    case 'refresh-board':
                      unawaited(_refresh());
                  }
                },
              ),
            ],
          ],
        ),
        bottomNavigationBar: canCreate
            ? SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const ValueKey('board-add-card'),
                  icon: const Icon(Icons.add),
                  label: Text(text.addCard),
                  onPressed: () =>
                      showQuickAddCard(context, session, board: _board),
                ),
              )
            : null,
        body: ListenableBuilder(
          listenable: session,
          builder: (context, _) => StreamBuilder<List<DeckStack>>(
            key: ValueKey((
              session.account.id,
              session.account.generation,
              widget.board.id,
            )),
            stream: _stacks,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: StateMessage(
                    message: text.localReadError,
                    actionLabel: text.retry,
                    onAction: () => setState(() {
                      _input = null;
                      _stacks = session.watchStacks(widget.board.id);
                    }),
                  ),
                );
              }
              final columns = _visible(snapshot.data);
              final scope = 'board:${widget.board.id}';
              final emptyLoading = columns.isEmpty && session.loading(scope);
              final emptyUnavailable =
                  columns.isEmpty && session.error(scope) != null;
              return LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * .5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SyncNotice(
                              session: session,
                              scope: scope,
                              retry: _refresh,
                              hasData: columns.isNotEmpty,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      key: const ValueKey('board-card-search'),
                                      controller: _query,
                                      focusNode: _searchFocus,
                                      textInputAction: TextInputAction.search,
                                      onChanged: (value) =>
                                          _setFilter(_filter.withQuery(value)),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: text.searchCards,
                                        prefixIcon: const Icon(Icons.search),
                                        suffixIcon: _query.text.isEmpty
                                            ? null
                                            : IconButton(
                                                tooltip: text.clearSearch,
                                                icon: const Icon(Icons.close),
                                                onPressed: () => _setFilter(
                                                  _filter.withQuery(''),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: text.filterCards,
                                    onPressed: _chooseFilters,
                                    icon: Badge(
                                      isLabelVisible: _filter.active,
                                      label: Text('${_filter.count}'),
                                      child: const Icon(Icons.tune),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_showArchived || _filter.active)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (_showArchived)
                                        Text(text.archivedCards),
                                      if (_filter.active)
                                        TextButton.icon(
                                          onPressed: () => _setFilter(
                                            const BoardCardFilter(),
                                          ),
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          label: Text(text.clearFilters),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            if (preferences.persistenceError)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  children: [
                                    Text(text.preferenceStorageError),
                                    TextButton(
                                      onPressed: () => unawaited(
                                        preferences.retryPersistence(),
                                      ),
                                      child: Text(text.retry),
                                    ),
                                  ],
                                ),
                              ),
                            if (_filter.active &&
                                columns.isNotEmpty &&
                                columns.every((column) => column.cards.isEmpty))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Text(text.boardNoMatchingCards),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: !snapshot.hasData || emptyLoading
                          ? const Center(child: CircularProgressIndicator())
                          : columns.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      emptyUnavailable
                                          ? text.noSavedContent
                                          : text.noStacks,
                                    ),
                                    if (_board.permissions.manage &&
                                        !_board.archived)
                                      TextButton.icon(
                                        onPressed: () => editStructure(
                                          context,
                                          session,
                                          board: _board,
                                          column: true,
                                        ),
                                        icon: const Icon(Icons.add),
                                        label: Text(text.addStack),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : BoardLayout(
                              key: ValueKey((
                                session.account.id,
                                session.account.generation,
                                _board.id,
                              )),
                              session: session,
                              board: _board,
                              columns: columns,
                              archivedView: _showArchived,
                              mode: mode,
                              initialStackId: _stackId,
                              onColumnChanged: (id) {
                                _stackId = id;
                                if (_board.id > 0) {
                                  unawaited(
                                    ref
                                        .read(appPreferencesProvider)
                                        .rememberLastBoard(
                                          session.account.id,
                                          _board.id,
                                          stackId: id,
                                        ),
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
