import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/telemetry_bootstrap.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'board_view.dart';

export 'board_view.dart' show BoardScreen;
import 'pending.dart';
import 'sync_notice.dart';
import 'structure_editor.dart';
import 'search.dart';
import 'notifications.dart';
import 'settings.dart';

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
        title: Text(switch (_destination) {
          0 => text.boards,
          1 => text.myTasks,
          _ => text.settings,
        }),
        actions: _destination == 2
            ? []
            : [
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
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'refresh') {
                      unawaited(session.refreshBoards());
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/notifications'),
                        builder: (_) => NotificationsScreen(session: session),
                      ),
                    );
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'refresh', child: Text(text.refresh)),
                    PopupMenuItem(
                      value: 'notifications',
                      child: Text(text.deckNotifications),
                    ),
                  ],
                ),
              ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _destination,
        onDestinationSelected: (value) {
          setState(() => _destination = value);
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
      body: _destination == 2
          ? SettingsView(session: session)
          : _destination == 1
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
