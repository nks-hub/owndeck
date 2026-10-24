import 'dart:async';

import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_detail.dart';

class CardSearchScreen extends StatelessWidget {
  const CardSearchScreen({
    super.key,
    required this.session,
    this.mineOnly = false,
  });
  final DeckSession session;
  final bool mineOnly;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context)!.searchCards)),
    body: CardSearchView(session: session, initiallyMineOnly: mineOnly),
  );
}

class CardSearchView extends StatefulWidget {
  const CardSearchView({
    super.key,
    required this.session,
    this.initiallyMineOnly = false,
    this.fixedMineOnly = false,
  });
  final DeckSession session;
  final bool initiallyMineOnly;
  final bool fixedMineOnly;
  @override
  State<CardSearchView> createState() => _CardSearchViewState();
}

class _CardSearchViewState extends State<CardSearchView> {
  final _query = TextEditingController();
  late bool _mineOnly = widget.initiallyMineOnly || widget.fixedMineOnly;
  bool _archived = false;
  bool _completed = false;
  CardDueFilter _due = CardDueFilter.any;
  Timer? _typing;
  Timer? _clock;
  AppLifecycleListener? _lifecycle;
  bool _queryPending = false;
  int _request = 0;
  late Stream<CardSearchResult> _results = _search();

  Stream<CardSearchResult> _search() => widget.session.database.watchCardSearch(
    widget.session.account.id,
    CardSearchOptions(
      query: _query.text,
      mineOnly: _mineOnly,
      includeArchived: _archived,
      includeCompleted: _completed,
      due: _due,
    ),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted &&
          ModalRoute.of(context)?.isCurrent != false &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refresh();
      }
    });
  }

  void _refresh() {
    if (!mounted) return;
    _typing?.cancel();
    setState(() {
      _queryPending = false;
      _request++;
      _results = _search();
    });
  }

  void _changed(String _) {
    _typing?.cancel();
    setState(() => _queryPending = true);
    _typing = Timer(const Duration(milliseconds: 200), _refresh);
  }

  void _filter(VoidCallback update) {
    update();
    _refresh();
  }

  @override
  void dispose() {
    _typing?.cancel();
    _clock?.cancel();
    _lifecycle?.dispose();
    _query.dispose();
    super.dispose();
  }

  Widget _filters(AppLocalizations text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const Key('card-search-query'),
        controller: _query,
        onChanged: _changed,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _refresh(),
        decoration: InputDecoration(
          labelText: text.searchCards,
          hintText: text.searchCardsHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.text.isEmpty
              ? null
              : IconButton(
                  tooltip: text.clearSearch,
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _query.clear();
                    _refresh();
                  },
                ),
        ),
      ),
      const SizedBox(height: 12),
      Text(text.localSearchNotice),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (!widget.fixedMineOnly)
            FilterChip(
              label: Text(text.myTasks),
              selected: _mineOnly,
              onSelected: (value) => _filter(() => _mineOnly = value),
            ),
          FilterChip(
            label: Text(text.includeArchived),
            selected: _archived,
            onSelected: (value) => _filter(() => _archived = value),
          ),
          FilterChip(
            label: Text(text.includeCompleted),
            selected: _completed,
            onSelected: (value) => _filter(() => _completed = value),
          ),
        ],
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<CardDueFilter>(
        isExpanded: true,
        key: ValueKey(_due),
        initialValue: _due,
        decoration: InputDecoration(labelText: text.dueDate),
        items: [
          DropdownMenuItem(
            value: CardDueFilter.any,
            child: Text(text.anyDueDate),
          ),
          DropdownMenuItem(
            value: CardDueFilter.today,
            child: Text(text.dueToday),
          ),
          DropdownMenuItem(
            value: CardDueFilter.overdue,
            child: Text(text.overdueTasks),
          ),
          DropdownMenuItem(
            value: CardDueFilter.noDate,
            child: Text(text.withoutDueDate),
          ),
        ],
        onChanged: (value) {
          if (value != null) _filter(() => _due = value);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return CustomScrollView(
      key: const Key('card-search-results'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: _filters(text)),
        ),
        StreamBuilder<CardSearchResult>(
          key: ValueKey(_request),
          stream: _results,
          builder: (context, snapshot) {
            final result = snapshot.data;
            if (_queryPending ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(child: LinearProgressIndicator());
            }
            if (snapshot.hasError) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(text.loadError),
                      TextButton(onPressed: _refresh, child: Text(text.retry)),
                    ],
                  ),
                ),
              );
            }
            if (result == null || !result.accountAvailable) {
              return _empty(text.accountSearchUnavailable);
            }
            if (_mineOnly && !result.identityKnown) {
              return _empty(text.myTasksIdentityRequired);
            }
            if (result.hits.isEmpty) return _empty(text.noMatchingCards);
            return SliverList.builder(
              itemCount: result.hits.length,
              itemBuilder: (context, index) {
                final hit = result.hits[index];
                final due = hit.due;
                final material = MaterialLocalizations.of(context);
                final dateText = due == null
                    ? null
                    : '${material.formatMediumDate(due)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(due))}';
                return ListTile(
                  key: ValueKey('search:${hit.board.id}:${hit.card.id}'),
                  leading: Icon(
                    hit.completed
                        ? Icons.task_alt
                        : hit.archived
                        ? Icons.archive_outlined
                        : Icons.check_box_outline_blank,
                  ),
                  title: Text(hit.card.title),
                  subtitle: Text(
                    '${hit.board.title} · ${hit.stack.title}${dateText == null ? '' : '\n$dateText'}',
                  ),
                  isThreeLine: dateText != null,
                  trailing: hit.card.raw['syncState'] == null
                      ? null
                      : Tooltip(
                          message: text.pendingChanges,
                          child: const Icon(Icons.sync),
                        ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: '/card'),
                      builder: (_) => CardScreen(
                        session: widget.session,
                        board: hit.board,
                        card: hit.card,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _empty(String message) => SliverToBoxAdapter(
    child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
  );
}
