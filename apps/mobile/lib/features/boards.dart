import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/telemetry_bootstrap.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'board_view.dart';
import 'drafts.dart';
import 'pending.dart';
import 'sync_notice.dart';
import 'structure_editor.dart';
import 'search.dart';
import 'notifications.dart';
import 'settings.dart';
import 'quick_add_card.dart';

export 'board_view.dart' show BoardScreen;

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  int _filter = 0;
  int _destination = 0;
  final _visited = <int>{0};
  final _query = TextEditingController();
  late Stream<List<DeckBoard>> _boards;
  late Stream<List<PendingWrite>> _writes;

  void _bind() {
    _boards = widget.session.watchBoards();
    _writes = widget.session.database.watchWrites(widget.session.account.id);
    scheduleMicrotask(widget.session.refreshBoards);
  }

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant BoardsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _query.clear();
      _filter = 0;
      _destination = 0;
      _visited
        ..clear()
        ..add(0);
      _bind();
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _open(String route, Widget screen) => unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: route),
        builder: (_) => screen,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    final server = Uri.tryParse(session.account.server)?.host ?? '';
    final screen = MediaQuery.sizeOf(context);
    final compactHeight =
        screen.height - MediaQuery.viewInsetsOf(context).bottom < 500;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(32) + 32,
        title: Tooltip(
          message: text.accounts,
          child: InkWell(
            onTap: () => _open('/accounts', const AccountsScreen()),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(switch (_destination) {
                    0 => text.boards,
                    1 => text.myTasks,
                    _ => text.settings,
                  }),
                  Text(
                    '${session.account.loginName} · $server',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (_destination != 2 && compactHeight)
            if (screen.width >= 600)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: FilledButton.icon(
                  onPressed: () => showQuickAddCard(context, session),
                  icon: const Icon(Icons.add),
                  label: Text(text.addCard),
                ),
              )
            else
              IconButton.filled(
                onPressed: () => showQuickAddCard(context, session),
                tooltip: text.addCard,
                icon: const Icon(Icons.add),
              ),
          if (_destination != 2)
            IconButton(
              tooltip: text.searchCards,
              icon: const Icon(Icons.search),
              onPressed: () => _open(
                '/search',
                CardSearchScreen(session: session, mineOnly: _destination == 1),
              ),
            ),
          StreamBuilder<List<PendingWrite>>(
            stream: _writes,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return IconButton(
                tooltip: snapshot.hasError
                    ? text.storageError
                    : !snapshot.hasData
                    ? text.syncing
                    : count == 0
                    ? text.noPending
                    : text.pendingChanges,
                onPressed: () =>
                    _open('/sync', PendingScreen(session: session)),
                icon: Badge.count(
                  count: count,
                  isLabelVisible: count > 0,
                  child: Icon(
                    snapshot.hasError
                        ? Icons.sync_problem_outlined
                        : !snapshot.hasData
                        ? Icons.cloud_outlined
                        : count == 0
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_sync_outlined,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'accounts':
                  _open('/accounts', const AccountsScreen());
                case 'notifications':
                  _open(
                    '/notifications',
                    NotificationsScreen(session: session),
                  );
                case 'drafts':
                  _open('/drafts', DraftsScreen(session: session));
                case 'new-board':
                  unawaited(editStructure(context, session));
                case 'refresh':
                  unawaited(session.refreshBoards());
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'accounts', child: Text(text.accounts)),
              PopupMenuItem(
                value: 'notifications',
                child: Text(text.deckNotifications),
              ),
              PopupMenuItem(value: 'drafts', child: Text(text.drafts)),
              if (session.capabilities?.canCreateBoards == true)
                PopupMenuItem(value: 'new-board', child: Text(text.addBoard)),
              PopupMenuItem(value: 'refresh', child: Text(text.refresh)),
            ],
          ),
        ],
      ),
      floatingActionButton: _destination == 2 || compactHeight
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showQuickAddCard(context, session),
              icon: const Icon(Icons.add),
              label: Text(text.addCard),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _destination,
        onDestinationSelected: (value) {
          setState(() {
            _destination = value;
            _visited.add(value);
          });
          telemetry.screen(switch (value) {
            0 => '/boards',
            1 => '/my-tasks',
            _ => '/settings',
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.view_kanban_outlined),
            label: text.boards,
          ),
          NavigationDestination(
            icon: const Icon(Icons.checklist),
            label: text.myTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: text.settings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _destination,
        children: [
          _boardList(context),
          if (_visited.contains(1))
            CardSearchView(
              key: ValueKey((
                'my-tasks',
                session.account.id,
                session.account.generation,
              )),
              session: session,
              fixedMineOnly: true,
              active: _destination == 1,
            )
          else
            const SizedBox.shrink(),
          if (_visited.contains(2))
            SettingsView(session: session)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _boardList(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => StreamBuilder<List<DeckBoard>>(
        stream: _boards,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(text.storageError));
          }
          final boards = (snapshot.data ?? [])
              .where(
                (b) => b.title.toLowerCase().contains(
                  _query.text.trim().toLowerCase(),
                ),
              )
              .where(
                (b) => _filter == 2
                    ? b.deletedAt != 0
                    : b.deletedAt == 0 && b.archived == (_filter == 1),
              )
              .toList();
          return RefreshIndicator(
            onRefresh: session.refreshBoards,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      children: [
                        TextField(
                          controller: _query,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: text.boardSearchHint,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: text.clearFilters,
                                    onPressed: () => setState(_query.clear),
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              for (final entry in <int, String>{
                                0: text.activeBoards,
                                1: text.archivedBoards,
                                2: text.deletedBoards,
                              }.entries)
                                ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _filter == entry.key,
                                  onSelected: (_) =>
                                      setState(() => _filter = entry.key),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SyncNotice(
                    session: session,
                    scope: 'boards',
                    retry: session.refreshBoards,
                    hasData: boards.isNotEmpty,
                  ),
                ),
                if (!snapshot.hasData)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 88),
                    sliver: SliverList.builder(
                      itemCount: boards.isEmpty ? 1 : boards.length,
                      itemBuilder: (context, index) {
                        if (boards.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(
                                  text.noBoards,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _query.text.isNotEmpty || _filter != 0
                                      ? text.noMatchingBoards
                                      : text.noBoardsHint,
                                ),
                                const SizedBox(height: 16),
                                if (_query.text.isNotEmpty || _filter != 0)
                                  OutlinedButton(
                                    onPressed: () => setState(() {
                                      _query.clear();
                                      _filter = 0;
                                    }),
                                    child: Text(text.clearFilters),
                                  )
                                else if (session
                                        .capabilities
                                        ?.canCreateBoards ==
                                    true)
                                  FilledButton.icon(
                                    onPressed: () =>
                                        editStructure(context, session),
                                    icon: const Icon(Icons.add),
                                    label: Text(text.addBoard),
                                  ),
                              ],
                            ),
                          );
                        }
                        final board = boards[index];
                        final color = int.tryParse(
                          board.color.replaceFirst('#', ''),
                          radix: 16,
                        );
                        return Card(
                          child: ListTile(
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
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
