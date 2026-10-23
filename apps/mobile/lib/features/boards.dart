import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'sync_notice.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
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
        title: Text(text.boards),
        actions: [
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
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) => StreamBuilder<List<DeckBoard>>(
          stream: _boards,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(child: Text(text.storageError));
            final boards = (snapshot.data ?? [])
                .where((b) => !b.archived && b.deletedAt == 0)
                .toList();
            return Column(
              children: [
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
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: boards.isEmpty ? 1 : boards.length,
                            itemBuilder: (context, index) {
                              if (boards.isEmpty)
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
                                subtitle: board.permissions.edit
                                    ? null
                                    : Text(text.readOnly),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
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
  late final Stream<List<DeckStack>> _stacks = widget.session.watchStacks(
    widget.board.id,
  );
  Future<void> _refresh() => widget.session.refreshStacks(widget.board.id);
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.board.title),
        actions: [
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
            if (snapshot.hasError)
              return Center(child: Text(text.storageError));
            final stacks = snapshot.data ?? [];
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
                                      text:
                                          '${stack.title} (${stack.cards.length})',
                                    ),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    for (final stack in stacks)
                                      RefreshIndicator(
                                        onRefresh: _refresh,
                                        child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(16),
                                          itemCount: stack.cards.isEmpty
                                              ? 1
                                              : stack.cards.length,
                                          itemBuilder: (context, index) {
                                            if (stack.cards.isEmpty)
                                              return Padding(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                child: Text(text.emptyStack),
                                              );
                                            final card = stack.cards[index];
                                            return Card(
                                              key: ValueKey(card.id),
                                              child: ListTile(
                                                title: Text(card.title),
                                                subtitle:
                                                    card.description.isEmpty
                                                    ? null
                                                    : Text(
                                                        card.description,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                onTap: () => Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    settings:
                                                        const RouteSettings(
                                                          name: '/card',
                                                        ),
                                                    builder: (_) => Scaffold(
                                                      appBar: AppBar(
                                                        title: Text(card.title),
                                                      ),
                                                      body: SingleChildScrollView(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              24,
                                                            ),
                                                        child: SelectableText(
                                                          card
                                                                  .description
                                                                  .isEmpty
                                                              ? text.noDescription
                                                              : card.description,
                                                        ),
                                                      ),
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
