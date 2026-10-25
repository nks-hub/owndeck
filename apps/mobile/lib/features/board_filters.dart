import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'card_summary.dart';

enum BoardDueFilter { any, today, upcoming, overdue, noDate }

enum BoardCompletionFilter { any, open, completed }

final class BoardCardFilter {
  const BoardCardFilter({
    this.query = '',
    this.memberId,
    this.labelId,
    this.due = BoardDueFilter.any,
    this.completion = BoardCompletionFilter.any,
  });
  final String query;
  final String? memberId;
  final int? labelId;
  final BoardDueFilter due;
  final BoardCompletionFilter completion;

  int get count => [
    query.trim().isNotEmpty,
    memberId != null,
    labelId != null,
    due != BoardDueFilter.any,
    completion != BoardCompletionFilter.any,
  ].where((active) => active).length;
  bool get active => count != 0;

  BoardCardFilter withQuery(String value) => BoardCardFilter(
    query: value,
    memberId: memberId,
    labelId: labelId,
    due: due,
    completion: completion,
  );

  bool matches(DeckCard card, {DateTime? now}) {
    if (!active) return true;
    final completed = card.raw['done'] != null;
    if (completion == BoardCompletionFilter.open && completed ||
        completion == BoardCompletionFilter.completed && !completed) {
      return false;
    }
    final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
    final content = '${card.title}\n${card.description}'.toLowerCase();
    if (terms.any((term) => term.isNotEmpty && !content.contains(term))) {
      return false;
    }
    if (labelId != null &&
        !cardObjects(
          card.raw['labels'],
        ).any((label) => label['id'] == labelId)) {
      return false;
    }
    if (memberId != null) {
      final people = cardPeople(card);
      if (memberId!.isEmpty
          ? people.isNotEmpty
          : !people.any((person) => person.id == memberId)) {
        return false;
      }
    }
    if (due == BoardDueFilter.any) return true;
    final date = cardDueDate(card);
    final localNow = (now ?? DateTime.now()).toLocal();
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final tomorrow = DateTime(localNow.year, localNow.month, localNow.day + 1);
    return switch (due) {
      BoardDueFilter.any => true,
      BoardDueFilter.today =>
        date != null && !date.isBefore(today) && date.isBefore(tomorrow),
      BoardDueFilter.upcoming => date != null && !date.isBefore(tomorrow),
      BoardDueFilter.overdue =>
        !completed && date != null && date.isBefore(localNow),
      BoardDueFilter.noDate =>
        card.raw['duedate'] == null || card.raw['duedate'] == '',
    };
  }
}

String boardDueLabel(AppLocalizations text, BoardDueFilter value) =>
    switch (value) {
      BoardDueFilter.any => text.anyDueDate,
      BoardDueFilter.today => text.dueToday,
      BoardDueFilter.upcoming => text.upcomingTasks,
      BoardDueFilter.overdue => text.overdueTasks,
      BoardDueFilter.noDate => text.withoutDueDate,
    };

Future<BoardCardFilter?> showBoardFilters(
  BuildContext context, {
  required BoardCardFilter filter,
  required DeckBoard board,
  required List<DeckStack> stacks,
}) {
  final text = AppLocalizations.of(context)!;
  final members = <String, String>{
    for (final user in cardObjects(board.raw['users']))
      if (cardPerson(user) case final person?) person.id: person.name,
    for (final stack in stacks)
      for (final card in stack.cards)
        for (final person in cardPeople(card)) person.id: person.name,
  };
  final labels = <int, String>{
    for (final label in cardObjects(board.raw['labels']))
      if (label['id'] case final int id) id: cardLabelName(label, text),
    for (final stack in stacks)
      for (final card in stack.cards)
        for (final label in cardObjects(card.raw['labels']))
          if (label['id'] case final int id) id: cardLabelName(label, text),
  };
  if (filter.memberId?.isNotEmpty == true) {
    members.putIfAbsent(filter.memberId!, () => text.pendingValueUnavailable);
  }
  if (filter.labelId != null) {
    labels.putIfAbsent(filter.labelId!, () => text.pendingValueUnavailable);
  }
  final memberItems = members.entries.toList()
    ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  final labelItems = labels.entries.toList()
    ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
  var member = filter.memberId;
  var label = filter.labelId;
  var due = filter.due;
  var completion = filter.completion;
  return showModalBottomSheet<BoardCardFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  DropdownButtonFormField<String>(
                    key: const ValueKey('board-filter-member'),
                    initialValue: member,
                    hint: Text(text.anyMember),
                    isExpanded: true,
                    decoration: InputDecoration(labelText: text.assignees),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(text.anyMember),
                      ),
                      DropdownMenuItem(value: '', child: Text(text.noAssignee)),
                      for (final person in memberItems)
                        DropdownMenuItem(
                          value: person.key,
                          child: Text(
                            person.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => update(() => member = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: const ValueKey('board-filter-label'),
                    initialValue: label,
                    hint: Text(text.anyLabel),
                    isExpanded: true,
                    decoration: InputDecoration(labelText: text.labels),
                    items: [
                      DropdownMenuItem(value: null, child: Text(text.anyLabel)),
                      for (final item in labelItems)
                        DropdownMenuItem(
                          value: item.key,
                          child: Text(
                            item.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => update(() => label = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BoardDueFilter>(
                    key: const ValueKey('board-filter-due'),
                    initialValue: due,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: text.dueDate),
                    items: [
                      for (final value in BoardDueFilter.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(boardDueLabel(text, value)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) update(() => due = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BoardCompletionFilter>(
                    key: const ValueKey('board-filter-completion'),
                    initialValue: completion,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: text.pendingCompletion,
                    ),
                    items: [
                      for (final value in BoardCompletionFilter.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(switch (value) {
                            BoardCompletionFilter.any => text.allCards,
                            BoardCompletionFilter.open => text.openCards,
                            BoardCompletionFilter.completed => text.completed,
                          }),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) update(() => completion = value);
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, const BoardCardFilter()),
                      child: Text(text.clearFilters),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        BoardCardFilter(
                          query: filter.query,
                          memberId: member,
                          labelId: label,
                          due: due,
                          completion: completion,
                        ),
                      ),
                      child: Text(text.applyFilters),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
