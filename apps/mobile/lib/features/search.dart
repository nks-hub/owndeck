import 'dart:async';

import 'package:deck_store/deck_store.dart';
import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../data/card_reads.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'card_completion.dart';
import 'card_detail.dart';
import 'card_link_dialog.dart';
import 'card_summary.dart';
import 'quick_add_card.dart';
import 'state_message.dart';

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
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.searchCards),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.openCardLink,
          icon: const Icon(Icons.link),
          onPressed: () => enterCardLink(context),
        ),
      ],
    ),
    body: CardSearchView(session: session, initiallyMineOnly: mineOnly),
  );
}

class CardSearchView extends StatefulWidget {
  const CardSearchView({
    super.key,
    required this.session,
    this.initiallyMineOnly = false,
    this.fixedMineOnly = false,
    this.active = true,
  });
  final DeckSession session;
  final bool initiallyMineOnly;
  final bool fixedMineOnly;
  final bool active;
  @override
  State<CardSearchView> createState() => _CardSearchViewState();
}

class _CardSearchViewState extends State<CardSearchView> {
  final _query = TextEditingController();
  late bool _mineOnly = widget.initiallyMineOnly || widget.fixedMineOnly;
  bool _online = false;
  bool _remoteBusy = false;
  bool _limited = false;
  Object? _remoteError;
  List<DeckSearchEntry> _remote = [];
  String? _remoteQuery;
  String? _uid;
  int? _opening;
  bool _archived = false;
  bool _completed = false;
  bool _upcoming = false;
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
          widget.active &&
          ModalRoute.of(context)?.isCurrent != false &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _refresh();
      }
    });
  }

  @override
  void didUpdateWidget(covariant CardSearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _typing?.cancel();
      _request++;
      _query.clear();
      _mineOnly = widget.initiallyMineOnly || widget.fixedMineOnly;
      _remote = [];
      _remoteQuery = null;
      _uid = null;
      _online = _archived = _completed = _upcoming = false;
      _due = CardDueFilter.any;
      _remoteError = null;
      _remoteBusy = false;
      _queryPending = false;
      _results = _search();
    }
    if (!widget.active && oldWidget.active) {
      _typing?.cancel();
      _request++;
      _remoteBusy = false;
    } else if (widget.active && !oldWidget.active) {
      _refresh();
    }
  }

  void _refresh() {
    if (!mounted || !widget.active) return;
    _typing?.cancel();
    setState(() {
      _queryPending = false;
      _request++;
      _results = _search();
    });
    if (_online) unawaited(_loadOnline(_request));
  }

  void _changed(String _) {
    _typing?.cancel();
    setState(() {
      _queryPending = true;
      _request++;
    });
    _typing = Timer(const Duration(milliseconds: 200), _refresh);
  }

  void _filter(VoidCallback update) {
    update();
    _refresh();
  }

  Future<void> _loadOnline(int request) async {
    final term = _query.text.trim();
    final mine = _mineOnly;
    if (!widget.active) return;
    final key = '$mine:$term';
    setState(() {
      if (_remoteQuery != key) {
        _remote = [];
        _limited = false;
      }
      _remoteQuery = key;
      _remoteBusy = true;
      _remoteError = null;
    });
    try {
      final uid = await widget.session.readServer((api) => api.currentUserId());
      await widget.session.database.saveUserIdentity(
        widget.session.account,
        uid,
      );
      if (!mounted || request != _request || !_online || !widget.active) return;
      final page = await widget.session.readServer(
        (api) => mine && term.isEmpty
            ? api.upcomingCards()
            : api.searchCardsOnline(term),
      );
      if (!mounted || request != _request || !_online || !widget.active) return;
      setState(() {
        _uid = uid;
        _remote = page.items;
        _limited = page.limited;
      });
    } catch (error) {
      if (mounted && request == _request && _online) {
        setState(() => _remoteError = error);
      }
    } finally {
      if (mounted && request == _request && _online) {
        setState(() => _remoteBusy = false);
      }
    }
  }

  bool _remoteMatches(DeckSearchEntry entry) {
    final card = entry.card;
    if ((card.raw['deletedAt'] ?? 0) != 0 ||
        !_archived && (card.archived || entry.boardArchived) ||
        !_completed && card.raw['done'] != null) {
      return false;
    }
    if (_mineOnly && (_uid == null || !cardAssignedTo(card, _uid!))) {
      return false;
    }
    final due = DateTime.tryParse(
      card.raw['duedate']?.toString() ?? '',
    )?.toLocal();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    if (_upcoming && (due == null || due.isBefore(end))) return false;
    return switch (_due) {
      CardDueFilter.any => true,
      CardDueFilter.today =>
        due != null && !due.isBefore(start) && due.isBefore(end),
      CardDueFilter.overdue => due != null && due.isBefore(now),
      CardDueFilter.noDate =>
        card.raw['duedate'] == null || card.raw['duedate'] == '',
    };
  }

  Future<void> _openRemote(DeckSearchEntry entry) async {
    if (_opening != null) return;
    final request = _request;
    setState(() => _opening = entry.card.id);
    try {
      final result = await widget.session.openRemoteCard(
        entry.boardId,
        entry.card.id,
        stackId: entry.card.stackId,
      );
      if (!mounted || request != _request) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/card'),
          builder: (_) => CardScreen(
            session: widget.session,
            board: result.board,
            card: result.card,
          ),
        ),
      );
    } catch (error) {
      if (mounted && request == _request) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage(error, AppLocalizations.of(context)!)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  List<Widget> _remoteSlivers(AppLocalizations text) {
    final entries = _queryPending
        ? <DeckSearchEntry>[]
        : _remote.where(_remoteMatches).toList();
    return [
      if (_remoteBusy || _queryPending || _opening != null)
        const SliverToBoxAdapter(child: LinearProgressIndicator()),
      if (_remoteError != null)
        _empty(
          errorMessage(_remoteError!, text),
          actionLabel: text.retry,
          onAction: _refresh,
        ),
      if (_limited) _empty(text.serverSearchLimited),
      if (entries.isEmpty &&
          !_remoteBusy &&
          !_queryPending &&
          _remoteError == null)
        _empty(text.noServerMatches, clearFilters: _filtered),
      SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Card(
            semanticContainer: false,
            key: ValueKey('remote:${entry.card.id}'),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            clipBehavior: Clip.antiAlias,
            child: CardSummary(
              card: entry.card,
              contextLabel:
                  '${entry.boardTitle}${entry.stackTitle == null ? '' : ' · ${entry.stackTitle}'}',
              onOpen: _opening == null ? () => _openRemote(entry) : null,
            ),
          );
        },
      ),
    ];
  }

  @override
  void dispose() {
    _typing?.cancel();
    _clock?.cancel();
    _lifecycle?.dispose();
    _query.dispose();
    super.dispose();
  }

  bool get _filtered =>
      _query.text.trim().isNotEmpty ||
      _archived ||
      _completed ||
      _upcoming ||
      _due != CardDueFilter.any ||
      (_mineOnly && !widget.fixedMineOnly);

  void _clearFilters() {
    _query.clear();
    _filter(() {
      _mineOnly = widget.fixedMineOnly;
      _archived = _completed = _upcoming = false;
      _due = CardDueFilter.any;
    });
  }

  Future<void> _showFilters() async {
    final text = AppLocalizations.of(context)!;
    var online = _online;
    var mine = _mineOnly;
    var archived = _archived;
    var completed = _completed;
    var due = _due;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: .75,
          minChildSize: .4,
          maxChildSize: .95,
          builder: (context, scroll) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text.filterCards,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: text.close,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(text.localSearchMode),
                          selected: !online,
                          onSelected: (_) => update(() => online = false),
                        ),
                        ChoiceChip(
                          label: Text(text.serverSearchMode),
                          selected: online,
                          onSelected: (_) => update(() => online = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      online ? text.serverSearchNotice : text.localSearchNotice,
                    ),
                    if (online && mine && _query.text.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(text.serverMyTasksNotice),
                      ),
                    const SizedBox(height: 8),
                    if (!widget.fixedMineOnly)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(text.myTasks),
                        value: mine,
                        onChanged: (value) => update(() => mine = value),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(text.includeArchived),
                      value: archived,
                      onChanged: online && mine && _query.text.trim().isEmpty
                          ? null
                          : (value) => update(() => archived = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(text.includeCompleted),
                      value: completed,
                      onChanged: online && mine && _query.text.trim().isEmpty
                          ? null
                          : (value) => update(() => completed = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<CardDueFilter>(
                      initialValue: due,
                      isExpanded: true,
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
                        if (value != null) update(() => due = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(text.applyFilters),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      _filter(() {
        _online = online;
        _mineOnly = mine;
        _archived = archived;
        _completed = completed;
        if (_due != due) _upcoming = false;
        _due = due;
      });
    }
  }

  Widget _filters(AppLocalizations text) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('card-search-query'),
              controller: _query,
              onChanged: _changed,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _refresh(),
              decoration: InputDecoration(
                hintText: text.searchCardsHint,
                labelText: text.searchCards,
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
          ),
          IconButton(
            key: const ValueKey('search-filter-menu'),
            tooltip: text.filterCards,
            icon: Badge(
              isLabelVisible: _filtered,
              child: const Icon(Icons.tune),
            ),
            onPressed: _showFilters,
          ),
        ],
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final choice in [
              (CardDueFilter.any, false, text.allCards),
              (CardDueFilter.today, false, text.dueToday),
              (CardDueFilter.overdue, false, text.overdueTasks),
              (CardDueFilter.any, true, text.upcomingTasks),
            ])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  label: Text(choice.$3),
                  selected: _due == choice.$1 && _upcoming == choice.$2,
                  onSelected: (_) => _filter(() {
                    _due = choice.$1;
                    _upcoming = choice.$2;
                  }),
                ),
              ),
          ],
        ),
      ),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: _showFilters,
            icon: Icon(
              _online ? Icons.cloud_outlined : Icons.offline_pin_outlined,
              size: 18,
            ),
            label: Text(_online ? text.serverSearchMode : text.localSearchMode),
          ),
          if (_filtered)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close, size: 18),
              label: Text(text.clearFilters),
            ),
        ],
      ),
      if (_online && _mineOnly && _query.text.trim().isEmpty)
        Text(
          text.serverMyTasksNotice,
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) => _resultList(text),
    );
  }

  Widget _resultList(AppLocalizations text) {
    return CustomScrollView(
      key: const Key('card-search-results'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(child: _filters(text)),
        ),
        if (_online)
          ..._remoteSlivers(text)
        else
          StreamBuilder<CardSearchResult>(
            // Keyed by the query itself: hiding the tab must not re-run it.
            key: ObjectKey(_results),
            stream: _results,
            builder: (context, snapshot) {
              final result = snapshot.data;
              if (_queryPending ||
                  snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: LinearProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return _empty(
                  text.localReadError,
                  actionLabel: text.retry,
                  onAction: _refresh,
                );
              }
              if (result == null || !result.accountAvailable) {
                return _empty(text.accountSearchUnavailable);
              }
              if (_mineOnly && !result.identityKnown) {
                return _empty(
                  text.myTasksIdentityRequired,
                  actionLabel: text.retry,
                  onAction: widget.session.refreshBoards,
                );
              }
              final now = DateTime.now();
              final tomorrow = DateTime(now.year, now.month, now.day + 1);
              final hits = _upcoming
                  ? result.hits
                        .where(
                          (hit) =>
                              hit.due != null && !hit.due!.isBefore(tomorrow),
                        )
                        .toList()
                  : result.hits;
              final incomplete = result.uncachedBoards > 0;
              return SliverMainAxisGroup(
                slivers: [
                  if (incomplete)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: IncompleteDataNotice(
                          key: const Key('search-incomplete'),
                          message: text.searchIncomplete(result.uncachedBoards),
                          actionLabel: text.loadCards,
                          onAction: () =>
                              unawaited(widget.session.loadUncachedBoards()),
                        ),
                      ),
                    ),
                  if (hits.isEmpty)
                    // Never claim a confirmed-empty account over unloaded boards.
                    if (!incomplete || _filtered) _emptyLocal(text),
                  SliverList.builder(
                    itemCount: hits.length,
                    itemBuilder: (context, index) {
                      final hit = hits[index];
                      return Card(
                        semanticContainer: false,
                        key: ValueKey('search:${hit.board.id}:${hit.card.id}'),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CardCompletion(
                          session: widget.session,
                          board: hit.board,
                          card: hit.card,
                          builder: (context, onChanged, saving) => CardSummary(
                            card: hit.card,
                            contextLabel:
                                '${hit.board.title} · ${hit.stack.title}',
                            onCompletedChanged: onChanged,
                            changingCompletion: saving,
                            onOpen: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                settings: const RouteSettings(name: '/card'),
                                builder: (_) => CardScreen(
                                  session: widget.session,
                                  board: hit.board,
                                  card: hit.card,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }

  Widget _empty(
    String message, {
    bool clearFilters = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) => SliverToBoxAdapter(
    child: StateMessage(
      message: message,
      actionLabel: clearFilters
          ? AppLocalizations.of(context)!.clearFilters
          : actionLabel,
      onAction: clearFilters ? _clearFilters : onAction,
    ),
  );

  /// Distinguishes a filtered-out result, an unfinished first sync and a
  /// confirmed empty account for the local search.
  Widget _emptyLocal(AppLocalizations text) {
    if (_filtered) {
      return _empty(text.noMatchingCards, clearFilters: true);
    }
    if (widget.session.error('boards') != null) {
      return _empty(
        text.noSavedContent,
        actionLabel: text.retry,
        onAction: widget.session.refreshBoards,
      );
    }
    return _empty(
      _mineOnly ? text.myTasksEmpty : text.noCardsYet,
      actionLabel: text.addCard,
      onAction: () => showQuickAddCard(context, widget.session),
    );
  }
}
