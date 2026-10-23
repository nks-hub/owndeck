import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../data/accounts.dart';
import '../l10n/app_localizations.dart';
import 'login.dart';

class BoardsScreen extends ConsumerStatefulWidget {
  const BoardsScreen({super.key, required this.client});
  final DeckClient client;

  @override
  ConsumerState<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends ConsumerState<BoardsScreen> {
  late Future<List<DeckBoard>> _boards = widget.client.boards();

  Future<void> _refresh() async {
    final next = widget.client.boards();
    setState(() => _boards = next);
    try {
      await next;
    } on DeckException {
      // FutureBuilder displays this failure; the refresh indicator must settle.
    }
  }

  Future<void> _accounts() async {
    final text = AppLocalizations.of(context)!;
    final accounts = ref.read(accountsProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final account in accounts.items)
              ListTile(
                selected: accounts.selected?.id == account.id,
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(account.credentials.loginName),
                subtitle: Text(account.credentials.server.uri.toString()),
                onTap: () => Navigator.pop(context, account.id),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(text.addAccount),
              onTap: () => Navigator.pop(context, 'add'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'add') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/login'),
          builder: (_) => const LoginScreen(closeOnSuccess: true),
        ),
      );
    } else {
      try {
        await accounts.select(choice);
      } catch (_) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text.storageError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.boards),
        actions: [
          IconButton(
            onPressed: _accounts,
            tooltip: text.accounts,
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            onPressed: _refresh,
            tooltip: text.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<DeckBoard>>(
        future: _boards,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return _Problem(error: snapshot.error!, retry: _refresh);
          final boards = snapshot.requireData
              .where((b) => !b.archived && b.deletedAt == 0)
              .toList();
          if (boards.isEmpty)
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text.noBoards,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(text.noBoardsHint),
                  ],
                ),
              ),
            );
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];
                final colorValue = int.tryParse(
                  board.color.replaceFirst('#', ''),
                  radix: 16,
                );
                return ListTile(
                  key: ValueKey(board.id),
                  leading: Icon(
                    Icons.view_kanban_outlined,
                    color: colorValue == null
                        ? null
                        : Color(0xff000000 | colorValue),
                  ),
                  title: Text(board.title),
                  subtitle: board.permissions.edit ? null : Text(text.readOnly),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: '/board'),
                      builder: (_) =>
                          BoardScreen(client: widget.client, board: board),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.client, required this.board});
  final DeckClient client;
  final DeckBoard board;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late Future<List<DeckStack>> _stacks = widget.client.stacks(widget.board.id);

  void _refresh() =>
      setState(() => _stacks = widget.client.stacks(widget.board.id));

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
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
      body: FutureBuilder<List<DeckStack>>(
        future: _stacks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return _Problem(error: snapshot.error!, retry: _refresh);
          final stacks = snapshot.requireData;
          if (stacks.isEmpty) return Center(child: Text(text.noStacks));
          return DefaultTabController(
            length: stacks.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: [
                    for (final stack in stacks)
                      Tab(text: '${stack.title} (${stack.cards.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final stack in stacks)
                        stack.cards.isEmpty
                            ? Center(child: Text(text.emptyStack))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: stack.cards.length,
                                itemBuilder: (context, index) {
                                  final card = stack.cards[index];
                                  return Card(
                                    key: ValueKey(card.id),
                                    child: ListTile(
                                      title: Text(card.title),
                                      subtitle: card.description.isEmpty
                                          ? null
                                          : Text(
                                              card.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          settings: const RouteSettings(
                                            name: '/card',
                                          ),
                                          builder: (_) => Scaffold(
                                            appBar: AppBar(
                                              title: Text(card.title),
                                            ),
                                            body: SingleChildScrollView(
                                              padding: const EdgeInsets.all(24),
                                              child: SelectableText(
                                                card.description.isEmpty
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
                    ],
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

class _Problem extends StatelessWidget {
  const _Problem({required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage(error, text)),
            const SizedBox(height: 16),
            FilledButton(onPressed: retry, child: Text(text.retry)),
          ],
        ),
      ),
    );
  }
}
