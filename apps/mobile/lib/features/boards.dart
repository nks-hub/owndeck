import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'card_column.dart';
import 'pending.dart';
import 'sync_notice.dart';
import 'structure_editor.dart';
import 'search.dart';
import 'notifications.dart';
import 'package:deck_store/deck_store.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  int _filter = 0;
  int _destination = 0;
  late final Stream<List<DeckBoard>> _boards = widget.session.watchBoards();
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(widget.session.refreshBoards);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: Text(_destination == 0 ? text.boards : text.myTasks),
        actions: [
          IconButton(
            tooltip: text.deckNotifications,
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/notifications'),
                builder: (_) => NotificationsScreen(session: session),
              ),
            ),
          ),
          IconButton(
            tooltip: text.searchCards,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/search'),
                builder: (_) => CardSearchScreen(
                  session: session,
                  mineOnly: _destination == 1,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: text.pendingChanges,
            icon: const Icon(Icons.sync_problem_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/sync'),
                builder: (_) => PendingScreen(session: session),
              ),
            ),
          ),
          IconButton(
            tooltip: text.accounts,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/accounts'),
                builder: (_) => const AccountsScreen(),
              ),
            ),
          ),
          IconButton(
            onPressed: session.refreshBoards,
            tooltip: text.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _destination,
        onDestinationSelected: (value) => setState(() => _destination = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.view_kanban_outlined),
            label: text.boards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist),
            label: text.myTasks,
          ),
        ],
      ),
      body: _destination == 1
          ? CardSearchView(
              key: const ValueKey('my-tasks'),
              session: session,
              fixedMineOnly: true,
            )
          : ListenableBuilder(
              listenable: session,
              builder: (context, _) => StreamBuilder<List<DeckBoard>>(
                stream: _boards,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(text.storageError));
                  }
                  final boards = (snapshot.data ?? [])
                      .where(
                        (b) => _filter == 2
                            ? b.deletedAt != 0
                            : b.deletedAt == 0 && b.archived == (_filter == 1),
                      )
                      .toList();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(text.activeBoards),
                              selected: _filter == 0,
                              onSelected: (_) => setState(() => _filter = 0),
                            ),
                            ChoiceChip(
                              label: Text(text.archivedBoards),
                              selected: _filter == 1,
                              onSelected: (_) => setState(() => _filter = 1),
                            ),
                            ChoiceChip(
                              label: Text(text.deletedBoards),
                              selected: _filter == 2,
                              onSelected: (_) => setState(() => _filter = 2),
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(text.addBoard),
                              onPressed:
                                  session.capabilities?.canCreateBoards == true
                                  ? () => editStructure(context, session)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      SyncNotice(
                        session: session,
                        scope: 'boards',
                        retry: session.refreshBoards,
                        hasData: boards.isNotEmpty,
                      ),
                      Expanded(
                        child: !snapshot.hasData
                            ? const Center(child: CircularProgressIndicator())
                            : RefreshIndicator(
                                onRefresh: session.refreshBoards,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: boards.isEmpty ? 1 : boards.length,
                                  itemBuilder: (context, index) {
                                    if (boards.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          children: [
                                            Text(
                                              text.noBoards,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(text.noBoardsHint),
                                          ],
                                        ),
                                      );
                                    }
                                    final board = boards[index];
                                    final color = int.tryParse(
                                      board.color.replaceFirst('#', ''),
                                      radix: 16,
                                    );
                                    return ListTile(
                                      key: ValueKey(board.id),
                                      leading: Icon(
                                        Icons.view_kanban_outlined,
                                        color: color == null
                                            ? null
                                            : Color(0xff000000 | color),
                                      ),
                                      title: Text(board.title),
                                      subtitle: board.raw['syncState'] != null
                                          ? Text(text.pendingChanges)
                                          : board.permissions.edit
                                          ? null
                                          : Text(text.readOnly),
                                      trailing: BoardActions(
                                        session: session,
                                        board: board,
                                      ),
                                      onTap: board.deletedAt != 0
                                          ? null
                                          : () => Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                settings: const RouteSettings(
                                                  name: '/board',
                                                ),
                                                builder: (_) => BoardScreen(
                                                  session: session,
                                                  board: board,
                                                ),
                                              ),
                                            ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.session, required this.board});
  final DeckSession session;
  final DeckBoard board;
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late DeckBoard _board = widget.board;
  bool _unavailable = false;
  bool _showArchived = false;
  StreamSubscription<DeckBoard?>? _boardChanges;
  late final Stream<List<DeckStack>> _stacks = widget.session.watchStacks(
    widget.board.id,
  );
  Future<void> _refresh() => widget.session.refreshStacks(widget.board.id);
  @override
  void initState() {
    super.initState();
    _boardChanges = widget.session.database
        .watchBoard(widget.session.account.id, widget.board.id)
        .listen(
          (board) {
            if (mounted) {
              setState(() {
                _unavailable = board == null || !board.permissions.read;
                if (board != null) _board = board;
              });
            }
          },
          onError: (Object _) {
            if (mounted) setState(() => _unavailable = true);
          },
        );
    scheduleMicrotask(() {
      if (mounted) widget.session.openBoard(widget.board.id);
    });
  }

  @override
  void dispose() {
    unawaited(_boardChanges?.cancel());
    widget.session.closeBoard(widget.board.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
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
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => StreamBuilder<List<DeckStack>>(
          stream: _stacks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(text.storageError));
            }
            final stacks = (snapshot.data ?? <DeckStack>[])
                .map(
                  (stack) => DeckStack.fromJson({
                    ...stack.raw,
                    'cards': stack.cards
                        .where(
                          (card) =>
                              card.archived == _showArchived &&
                              (card.raw['deletedAt'] ?? 0) == 0,
                        )
                        .map((card) => card.raw)
                        .toList(),
                  }),
                )
                .toList();
            return Column(
              children: [
                SyncNotice(
                  session: session,
                  scope: 'board:${widget.board.id}',
                  retry: _refresh,
                  hasData: stacks.isNotEmpty,
                ),
                Expanded(
                  child: !snapshot.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : stacks.isEmpty
                      ? Center(child: Text(text.noStacks))
                      : DefaultTabController(
                          length: stacks.length,
                          child: Column(
                            children: [
                              TabBar(
                                isScrollable: true,
                                tabs: [
                                  for (final stack in stacks)
                                    Tab(
                                      icon: stack.isDoneColumn
                                          ? Icon(
                                              Icons.check_circle_outline,
                                              semanticLabel: text.doneColumn,
                                            )
                                          : null,
                                      text:
                                          '${stack.title} (${stack.cards.length})',
                                    ),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    for (final stack in stacks)
                                      CardColumn(
                                        session: session,
                                        board: _board,
                                        stack: stack,
                                        archivedView: _showArchived,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
