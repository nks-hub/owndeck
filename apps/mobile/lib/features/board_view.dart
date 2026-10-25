import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_preferences.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_layout.dart';
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

  Future<void> _refresh() => widget.session.refreshStacks(widget.board.id);
  @override
  void initState() {
    super.initState();
    _bind();
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
      _bind();
    }
  }

  @override
  void dispose() {
    _binding++;
    unawaited(_boardChanges?.cancel());
    widget.session.closeBoard(widget.board.id);
    super.dispose();
  }

  List<BoardColumnView> _visible(List<DeckStack>? stacks) {
    if (!identical(_input, stacks) || _filteredArchive != _showArchived) {
      _input = stacks;
      _filteredArchive = _showArchived;
      _columns = [
        for (final stack in stacks ?? <DeckStack>[])
          BoardColumnView(stack, _showArchived),
      ];
    }
    return _columns;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_board.title),
        actions: [
          IconButton(
            tooltip: _showArchived ? text.activeCards : text.archivedCards,
            icon: Icon(
              _showArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
          if (_board.permissions.manage && !_board.archived)
            IconButton(
              tooltip: text.addStack,
              icon: const Icon(Icons.add),
              onPressed: () =>
                  editStructure(context, session, board: _board, column: true),
            ),
          BoardActions(session: session, board: _board),
          IconButton(
            onPressed: _refresh,
            tooltip: text.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Semantics(
              label: text.boardView,
              child: Wrap(
                spacing: 8,
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
                ],
              ),
            ),
          ),
          if (preferences.persistenceError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(text.preferenceStorageError),
                  TextButton(
                    onPressed: () => unawaited(preferences.retryPersistence()),
                    child: Text(text.retry),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListenableBuilder(
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
                  return Column(
                    children: [
                      SyncNotice(
                        session: session,
                        scope: 'board:${widget.board.id}',
                        retry: _refresh,
                        hasData: columns.isNotEmpty,
                      ),
                      Expanded(
                        child: !snapshot.hasData
                            ? const Center(child: CircularProgressIndicator())
                            : columns.isEmpty
                            ? Center(child: Text(text.noStacks))
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
