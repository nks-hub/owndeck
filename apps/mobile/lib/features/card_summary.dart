import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

Iterable<JsonObject> cardObjects(Object? value) => switch (value) {
  List values => values.whereType<JsonObject>(),
  JsonObject values => values.values.whereType<JsonObject>(),
  _ => const [],
};

List<({String id, String name})> cardPeople(DeckCard card) => [
  for (final assignment in cardObjects(card.raw['assignedUsers']))
    if ((assignment['type'] ?? 0) == 0) ?cardPerson(assignment['participant']),
];

({String id, String name})? cardPerson(Object? value) {
  final id = switch (value) {
    String id => id,
    JsonObject person => (person['uid'] ?? person['primaryKey'])?.toString(),
    _ => null,
  };
  if (id == null || id.isEmpty) return null;
  final name = value is JsonObject
      ? (value['displayname'] ?? value['displayName'] ?? id).toString()
      : id;
  return (id: id, name: name.isEmpty ? id : name);
}

DateTime? cardDueDate(DeckCard card) =>
    DateTime.tryParse(card.raw['duedate']?.toString() ?? '')?.toLocal();

class CardSummary extends StatelessWidget {
  const CardSummary({
    super.key,
    required this.card,
    this.contextLabel,
    this.onOpen,
    this.trailing,
    this.showDescription = true,
  });

  final DeckCard card;
  final String? contextLabel;
  final VoidCallback? onOpen;
  final Widget? trailing;
  final bool showDescription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = cardObjects(card.raw['labels']).toList(growable: false);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextLabel case final String label)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (labels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final label in labels.take(3)) _LabelBadge(label),
                  if (labels.length > 3)
                    Tooltip(
                      message: labels
                          .skip(3)
                          .map(
                            (label) => cardLabelName(
                              label,
                              AppLocalizations.of(context)!,
                            ),
                          )
                          .join(', '),
                      child: Text('+${labels.length - 3}'),
                    ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    card.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (showDescription && card.description.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                card.description.trim().replaceAll(RegExp(r'\s+'), ' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          CardMetadata(card: card),
        ],
      ),
    );
    return onOpen == null ? content : InkWell(onTap: onOpen, child: content);
  }
}

class CardMetadata extends StatelessWidget {
  const CardMetadata({super.key, required this.card});
  final DeckCard card;

  int? _count(String countKey, String listKey) {
    final count = card.raw[countKey];
    if (count is int && count >= 0) return count;
    final items = card.raw[listKey];
    return items is List ? items.length : null;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final due = cardDueDate(card);
    final completed = card.raw['done'] != null;
    final people = cardPeople(card);
    final comments = _count('commentsCount', 'comments');
    final attachments = _count('attachmentCount', 'attachments');
    final sync = card.raw['syncState'];
    final now = DateTime.now();
    final overdue = !completed && due != null && due.isBefore(now);
    final soon =
        !completed &&
        due != null &&
        !overdue &&
        due.isBefore(now.add(const Duration(hours: 24)));
    final local = MaterialLocalizations.of(context);
    final syncText = switch (sync) {
      'sending' => text.sending,
      'applied' => text.awaitingReadback,
      'conflict' => text.conflict,
      'uncertain' => text.uncertain,
      'blocked' => text.blocked,
      null => null,
      _ => text.savedLocally,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (due != null || completed)
          _MetadataBadge(
            icon: completed ? Icons.task_alt : Icons.schedule_outlined,
            label: due == null ? text.completed : local.formatMediumDate(due),
            semanticLabel: [
              completed
                  ? text.completed
                  : overdue
                  ? text.overdueTasks
                  : soon
                  ? text.dueSoon
                  : text.dueDate,
              if (due != null)
                '${local.formatMediumDate(due)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(due), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
            ].join(': '),
            background: overdue
                ? theme.colorScheme.errorContainer
                : completed
                ? theme.colorScheme.primaryContainer
                : soon
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.surfaceContainerLow,
            foreground: overdue
                ? theme.colorScheme.onErrorContainer
                : completed
                ? theme.colorScheme.onPrimaryContainer
                : soon
                ? theme.colorScheme.onTertiaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
        if (people.isNotEmpty)
          _MetadataBadge(
            icon: Icons.person_outline,
            label: people.length == 1
                ? people.first.name
                : '${people.first.name} +${people.length - 1}',
            semanticLabel:
                '${text.assignees}: ${people.map((person) => person.name).join(', ')}',
          ),
        if (comments != null && comments > 0)
          _MetadataBadge(
            icon: Icons.chat_bubble_outline,
            label: '$comments',
            semanticLabel: '${text.comments}: $comments',
          ),
        if (attachments != null && attachments > 0)
          _MetadataBadge(
            icon: Icons.attach_file,
            label: '$attachments',
            semanticLabel: '${text.attachments}: $attachments',
          ),
        if (syncText != null)
          _MetadataBadge(
            icon: sync == 'conflict' || sync == 'blocked' || sync == 'uncertain'
                ? Icons.error_outline
                : Icons.cloud_upload_outlined,
            label: switch (sync) {
              'sending' => text.sending,
              'conflict' || 'blocked' || 'uncertain' => text.pendingChanges,
              _ => text.queued,
            },
            semanticLabel: syncText,
          ),
      ],
    );
  }
}

class _LabelBadge extends StatelessWidget {
  const _LabelBadge(this.label);
  final JsonObject label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = label['color']?.toString().replaceFirst('#', '') ?? '';
    final color = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw)
        ? Color(0xff000000 | int.parse(raw, radix: 16))
        : theme.colorScheme.outline;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          cardLabelName(label, AppLocalizations.of(context)!),
          style: theme.textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

String cardLabelName(JsonObject label, AppLocalizations text) {
  final title = label['title']?.toString().trim() ?? '';
  return title.isEmpty ? text.unnamedLabel : title;
}

class _MetadataBadge extends StatelessWidget {
  const _MetadataBadge({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    this.background,
    this.foreground,
  });
  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    excludeSemantics: true,
    child: Tooltip(
      message: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
