import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_preferences.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_layout.dart';
import 'board_filters.dart';
import 'quick_add_card.dart';
import 'structure_editor.dart';
import 'sync_notice.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key, required this.session, required this.board});
  final DeckSession session;
  final DeckBoard board;
  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  late DeckBoard _board;
  bool _unavailable = false;
  bool _showArchived = false;
  StreamSubscription<DeckBoard?>? _boardChanges;
  late Stream<List<DeckStack>> _stacks;
  List<DeckStack>? _input;
  List<BoardColumnView> _columns = [];
  bool? _filteredArchive;
  int _binding = 0;
  final _query = TextEditingController();
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
    scheduleMicrotask(() {
      if (mounted && binding == _binding) session.openBoard(widget.board.id);
    });
  }

  @override
  void didUpdateWidget(covariant BoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session ||
        oldWidget.board.id != widget.board.id) {
      unawaited(_boardChanges?.cancel());
      oldWidget.session.closeBoard(oldWidget.board.id);
      _showArchived = false;
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
    unawaited(_boardChanges?.cancel());
    widget.session.closeBoard(widget.board.id);
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

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_board.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        actions: [
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
                PopupMenuItem(value: 'add-column', child: Text(text.addStack)),
              PopupMenuItem(value: 'refresh-board', child: Text(text.refresh)),
              const PopupMenuDivider(),
            ],
            onExtraAction: (action) {
              switch (action) {
                case 'toggle-archived-cards':
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
              return Center(child: Text(text.storageError));
            }
            final columns = _visible(snapshot.data);
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
                            scope: 'board:${widget.board.id}',
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
                                    textInputAction: TextInputAction.search,
                                    onChanged: (value) =>
                                        _setFilter(_filter.withQuery(value)),
                                    decoration: InputDecoration(
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
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  for (final value in BoardViewMode.values)
                                    ChoiceChip(
                                      key: ValueKey(('board-view', value)),
                                      showCheckmark: false,
                                      avatar: Icon(
                                        value == BoardViewMode.columns
                                            ? Icons.view_kanban_outlined
                                            : Icons.view_list_outlined,
                                      ),
                                      label: Text(
                                        value == BoardViewMode.columns
                                            ? text.boardColumns
                                            : text.boardList,
                                      ),
                                      selected: mode == value,
                                      onSelected: (_) => unawaited(
                                        preferences.setBoardViewMode(
                                          session.account.id,
                                          _board.id,
                                          value,
                                        ),
                                      ),
                                    ),
                                  if (_showArchived) Text(text.archivedCards),
                                  if (_filter.active)
                                    TextButton.icon(
                                      onPressed: () =>
                                          _setFilter(const BoardCardFilter()),
                                      icon: const Icon(Icons.close, size: 18),
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
                    child: !snapshot.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : columns.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(text.noStacks),
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
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
