import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_preferences.dart';
import '../data/session.dart';
import '../core/telemetry_bootstrap.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'board_view.dart';
import 'board_presence.dart';
import 'calendar.dart';
import 'card_pane.dart';
import 'desktop_platform.dart';
import 'desktop_shortcuts.dart';
import 'drafts.dart';
import 'pending.dart';
import 'sync_notice.dart';
import 'structure_editor.dart';
import 'sync_state.dart';
import 'search.dart';
import 'notifications.dart';
import 'settings.dart';
import 'quick_add_card.dart';
import 'state_message.dart';

export 'board_view.dart' show BoardScreen;

class BoardsScreen extends ConsumerStatefulWidget {
  const BoardsScreen({super.key, required this.session});
  final DeckSession session;
  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  int _filter = 0;
  int _destination = 0;
  bool _calendar = false;
  bool _calendarVisited = false;
  final _visited = <int>{0};
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  final _pane = CardPaneController();
  DeckBoard? _selectedBoard;
  late Stream<List<DeckBoard>> _boards;
  late Stream<List<PendingWrite>> _writes;

  void _bind() {
    _boards = widget.session.watchBoards();
    _writes = widget.session.database.watchWrites(widget.session.account.id);
    scheduleMicrotask(widget.session.refreshBoards);
    unawaited(_reopenLastBoard(widget.session));
  }

  /// Reopens the board this account viewed last, once per account binding.
  Future<void> _reopenLastBoard(DeckSession session) async {
    final preferences = ref.read(appPreferencesProvider);
    final last = await preferences.lastBoard(session.account.id);
    if (last == null) return;
    final boards = await session.database.boardView(session.account.id);
    final board = boards.where((b) => b.id == last.boardId).firstOrNull;
    if (!mounted || widget.session != session) return;
    if (board == null || board.deletedAt != 0 || !board.permissions.read) {
      if (board == null && boards.isNotEmpty) {
        unawaited(preferences.forgetLastBoard(session.account.id));
      }
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _open(
      '/board',
      BoardScreen(
        session: session,
        board: board,
        initialStackId: last.stackId,
      ),
    );
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
      _pane.close();
      _selectedBoard = null;
      _filter = 0;
      _destination = 0;
      _calendar = _calendarVisited = false;
      _visited
        ..clear()
        ..add(0);
      _bind();
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    _pane.dispose();
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

  bool _wide(BuildContext context) =>
      isDesktopPlatform && MediaQuery.sizeOf(context).width >= cardPaneMinWidth;

  /// Boards on the left, the chosen board in the middle (wide desktop window).
  Widget _wideBoards(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final board = _selectedBoard;
    return Row(
      children: [
        SizedBox(width: 320, child: _boardList(context)),
        const VerticalDivider(width: 1),
        Expanded(
          child: board == null
              ? Center(child: Text(text.boards))
              : BoardScreen(
                  key: ValueKey((widget.session, board.id)),
                  session: widget.session,
                  board: board,
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    final wide = _wide(context);
    final server = Uri.tryParse(session.account.server)?.host ?? '';
    final screen = MediaQuery.sizeOf(context);
    final compactHeight =
        screen.height - MediaQuery.viewInsetsOf(context).bottom < 500;
    return DesktopShortcuts(
      onNew: _destination == 2 || wide && _selectedBoard != null
          ? null
          : () => showQuickAddCard(context, session),
      onSearch: _destination == 0 ? _searchFocus.requestFocus : null,
      onEscape: _pane.close,
      child: Scaffold(
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
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
                  CardSearchScreen(
                    session: session,
                    mineOnly: _destination == 1,
                  ),
                ),
              ),
            StreamBuilder<List<PendingWrite>>(
              stream: _writes,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                final message = snapshot.hasError
                    ? text.localReadError
                    : !snapshot.hasData
                    ? text.syncing
                    : count == 0
                    ? text.noPending
                    : text.pendingChanges;
                return Tooltip(
                  message: message,
                  excludeFromSemantics: true,
                  child: IconButton(
                    onPressed: () =>
                        _open('/sync', PendingScreen(session: session)),
                    icon: Semantics(
                      label: count > 0
                          ? '$message\n${MaterialLocalizations.of(context).formatDecimal(count)}'
                          : message,
                      excludeSemantics: true,
                      child: Badge.count(
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
        floatingActionButton:
            _destination == 2 ||
                compactHeight ||
                (wide && _destination == 0 && _selectedBoard != null)
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
        body: CardPaneHost(
          controller: _pane,
          child: IndexedStack(
            index: _destination,
            children: [
              BoardPresence(
                session: session,
                active: _destination == 0,
                child: wide ? _wideBoards(context) : _boardList(context),
              ),
              if (_visited.contains(1))
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: false,
                            icon: const Icon(Icons.view_list_outlined),
                            label: Text(text.taskListView),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(text.taskCalendarView),
                          ),
                        ],
                        selected: {_calendar},
                        onSelectionChanged: (value) => setState(() {
                          _calendar = value.first;
                          _calendarVisited |= _calendar;
                        }),
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _calendar ? 1 : 0,
                        children: [
                          CardSearchView(
                            key: ValueKey((
                              'my-tasks',
                              session.account.id,
                              session.account.generation,
                            )),
                            session: session,
                            fixedMineOnly: true,
                            active: _destination == 1 && !_calendar,
                          ),
                          if (_calendarVisited)
                            CalendarView(
                              key: ValueKey((
                                'calendar',
                                session.account.id,
                                session.account.generation,
                              )),
                              session: session,
                              active: _destination == 1 && _calendar,
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),
              if (_visited.contains(2))
                SettingsView(session: session)
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
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
            return Center(child: StateMessage(message: text.localReadError));
          }
          final savedBoards = snapshot.data ?? <DeckBoard>[];
          final filtering = _query.text.trim().isNotEmpty || _filter != 0;
          final emptyLoading = savedBoards.isEmpty && session.loading('boards');
          final emptyUnavailable =
              savedBoards.isEmpty && session.error('boards') != null;
          final boards = savedBoards
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
                          focusNode: _searchFocus,
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
                    hasData: savedBoards.isNotEmpty,
                  ),
                ),
                if (!snapshot.hasData || emptyLoading)
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
                                  emptyUnavailable
                                      ? text.noSavedContent
                                      : filtering || savedBoards.isNotEmpty
                                      ? text.noMatchingBoards
                                      : text.noBoards,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (!emptyUnavailable &&
                                    !filtering &&
                                    savedBoards.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(text.noBoardsHint),
                                ],
                                const SizedBox(height: 16),
                                if (filtering)
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
                                ? Text(
                                    syncStateLabel(
                                      board.raw['syncState'],
                                      text,
                                    ),
                                  )
                                : board.permissions.edit
                                ? null
                                : Text(text.readOnly),
                            trailing: BoardActions(
                              session: session,
                              board: board,
                            ),
                            selected:
                                _wide(context) &&
                                _selectedBoard?.id == board.id,
                            onTap: board.deletedAt != 0
                                ? null
                                : _wide(context)
                                ? () => setState(() => _selectedBoard = board)
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
