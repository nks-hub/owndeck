import 'dart:async';

import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_detail.dart';

enum CalendarKind { start, due, done }

/// One dated marker of a card on a local calendar day.
final class CalendarEntry {
  const CalendarEntry(this.kind, this.hit, this.at);
  final CalendarKind kind;
  final CardSearchHit hit;
  final DateTime at;
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

/// Groups existing card dates by local calendar day without copying them.
Map<DateTime, List<CalendarEntry>> calendarEntries(
  Iterable<CardSearchHit> hits,
) {
  final days = <DateTime, List<CalendarEntry>>{};
  void add(CalendarKind kind, CardSearchHit hit, DateTime? at) {
    if (at == null) return;
    days.putIfAbsent(_day(at), () => []).add(CalendarEntry(kind, hit, at));
  }

  for (final hit in hits) {
    add(
      CalendarKind.start,
      hit,
      DateTime.tryParse(hit.card.raw['startdate']?.toString() ?? '')?.toLocal(),
    );
    add(hit.completed ? CalendarKind.done : CalendarKind.due, hit, hit.due);
  }
  for (final list in days.values) {
    list.sort((a, b) => a.at.compareTo(b.at));
  }
  return days;
}

/// Month grid and day agenda over the dates already cached for My tasks.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key, required this.session, this.active = true});
  final DeckSession session;
  final bool active;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  StreamSubscription<CardSearchResult>? _subscription;
  CardSearchResult? _result;
  Object? _error;
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = _day(DateTime.now());

  @override
  void initState() {
    super.initState();
    _subscription = widget.session.database
        .watchCardSearch(
          widget.session.account.id,
          const CardSearchOptions(mineOnly: true, includeCompleted: true),
        )
        .listen(
          (result) => setState(() {
            _result = result;
            _error = null;
          }),
          onError: (Object error) => setState(() => _error = error),
        );
    if (!widget.active) _subscription!.pause();
  }

  @override
  void didUpdateWidget(covariant CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      widget.active ? _subscription?.resume() : _subscription?.pause();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _shift(int months) => setState(
    () => _month = DateTime(_month.year, _month.month + months),
  );

  void _open(CardSearchHit hit) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/card'),
      builder: (_) => CardScreen(
        session: widget.session,
        board: hit.board,
        card: hit.card,
      ),
    ),
  );

  static IconData _icon(CalendarKind kind) => switch (kind) {
    CalendarKind.start => Icons.event_outlined,
    CalendarKind.due => Icons.schedule_outlined,
    CalendarKind.done => Icons.task_alt,
  };

  static String _kindLabel(AppLocalizations text, CalendarKind kind) =>
      switch (kind) {
        CalendarKind.start => text.startDate,
        CalendarKind.due => text.dueDate,
        CalendarKind.done => text.completed,
      };

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final result = _result;
    if (_error != null) {
      return Center(child: Text(text.loadError));
    }
    if (result == null) return const LinearProgressIndicator();
    if (!result.accountAvailable) {
      return Center(child: Text(text.accountSearchUnavailable));
    }
    if (!result.identityKnown) {
      return Center(child: Text(text.myTasksIdentityRequired));
    }
    final days = calendarEntries(result.hits);
    final local = MaterialLocalizations.of(context);
    final agenda = days[_selected] ?? const <CalendarEntry>[];
    return ListView(
      key: const Key('calendar-view'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        if (result.uncachedBoards > 0)
          Card(
            key: const Key('calendar-incomplete'),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(text.calendarIncomplete(result.uncachedBoards)),
            ),
          ),
        Row(
          children: [
            IconButton(
              tooltip: text.calendarPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shift(-1),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  local.formatMonthYear(_month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              tooltip: text.calendarNextMonth,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _shift(1),
            ),
          ],
        ),
        _grid(context, text, days),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            local.formatFullDate(_selected),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (agenda.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(text.calendarNothingOnDay),
          ),
        for (final entry in agenda)
          Card(
            key: ValueKey(
              'calendar:${entry.kind.name}:${entry.hit.board.id}:${entry.hit.card.id}',
            ),
            child: ListTile(
              leading: Icon(_icon(entry.kind)),
              title: Text(entry.hit.card.title),
              subtitle: Text(
                '${_kindLabel(text, entry.kind)} · '
                '${local.formatTimeOfDay(TimeOfDay.fromDateTime(entry.at), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}'
                '\n${entry.hit.board.title} · ${entry.hit.stack.title}',
              ),
              isThreeLine: true,
              onTap: () => _open(entry.hit),
            ),
          ),
      ],
    );
  }

  Widget _grid(
    BuildContext context,
    AppLocalizations text,
    Map<DateTime, List<CalendarEntry>> days,
  ) {
    final local = MaterialLocalizations.of(context);
    final first = local.firstDayOfWeekIndex;
    final lead = (_month.weekday % 7 - first + 7) % 7;
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final rows = ((lead + count) / 7).ceil();
    final today = _day(DateTime.now());
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    local.narrowWeekdays[(first + i) % 7],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final number = row * 7 + col - lead + 1;
                      if (number < 1 || number > count) {
                        return const SizedBox(height: 56);
                      }
                      final date = DateTime(_month.year, _month.month, number);
                      return _cell(
                        context,
                        text,
                        date,
                        days[date] ?? const [],
                        selected: date == _selected,
                        today: date == today,
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    AppLocalizations text,
    DateTime date,
    List<CalendarEntry> entries, {
    required bool selected,
    required bool today,
  }) {
    final theme = Theme.of(context);
    int count(CalendarKind kind) => entries.where((e) => e.kind == kind).length;
    final summary = entries.isEmpty
        ? text.calendarDayEmpty
        : text.calendarDaySummary(
            count(CalendarKind.start),
            count(CalendarKind.due),
            count(CalendarKind.done),
          );
    final kinds = {for (final entry in entries) entry.kind};
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: text.calendarDayLabel(
        MaterialLocalizations.of(context).formatFullDate(date),
        summary,
      ),
      onTap: () => setState(() => _selected = date),
      child: InkWell(
        key: ValueKey('calendar-day:${date.day}'),
        onTap: () => setState(() => _selected = date),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : null,
            border: today
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${date.day}'),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final kind in CalendarKind.values)
                    if (kinds.contains(kind))
                      Icon(
                        _icon(kind),
                        size: 12,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.primary,
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
