import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../core/deck_theme.dart';
import '../core/markdown_tasks.dart';
import '../core/markdown_preview.dart';
import '../l10n/app_localizations.dart';
import 'sync_state.dart';

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
    JsonObject person => [
      person['uid'],
      person['primaryKey'],
    ].whereType<String>().where((id) => id.trim().isNotEmpty).firstOrNull,
    _ => null,
  };
  if (id == null || id.trim().isEmpty) return null;
  return (id: id, name: _participantName(value));
}

String _participantName(Object? value) {
  if (value is! JsonObject) return '';
  for (final key in ['displayname', 'displayName', 'name']) {
    final name = value[key];
    if (name is String && name.trim().isNotEmpty) return name.trim();
  }
  return '';
}

List<({String name, IconData icon})> _assignedDisplay(
  DeckCard card,
  AppLocalizations text,
) {
  final result = <({String name, IconData icon})>[];
  for (final assignment in cardObjects(card.raw['assignedUsers'])) {
    final name = _participantName(assignment['participant']);
    result.add((
      name: name.isNotEmpty
          ? name
          : switch (assignment['type'] ?? 0) {
              0 => text.user,
              1 => text.group,
              6 => text.externalRecipient,
              7 => text.team,
              _ => text.assignees,
            },
      icon: switch (assignment['type'] ?? 0) {
        1 || 7 => Icons.groups_outlined,
        6 => Icons.public,
        _ => Icons.person_outline,
      },
    ));
  }
  return result;
}

DateTime? _cardDate(Object? value) {
  final source = value?.toString();
  if (source == null || source.isEmpty) return null;
  return DateTime.tryParse(source)?.toLocal();
}

DateTime? cardDueDate(DeckCard card) => _cardDate(card.raw['duedate']);

/// The 48 dp completion checkbox of a card, or a spinner while it saves.
class CompletionBox extends StatelessWidget {
  const CompletionBox({
    super.key,
    required this.card,
    required this.saving,
    required this.onChanged,
  });
  final DeckCard card;
  final bool saving;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return SizedBox(
      width: 48,
      height: 48,
      child: saving
          ? Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: text.savingDraft,
                ),
              ),
            )
          : Checkbox(
              value: card.raw['done'] != null,
              shape: const CircleBorder(),
              semanticLabel: '${text.completed}: ${card.title}',
              onChanged: (value) {
                if (value != null) onChanged?.call(value);
              },
            ),
    );
  }
}

class CardSummary extends StatelessWidget {
  const CardSummary({
    super.key,
    required this.card,
    this.contextLabel,
    this.onOpen,
    this.trailing,
    this.showDescription = true,
    this.onCompletedChanged,
    this.changingCompletion = false,
  });

  final DeckCard card;
  final String? contextLabel;
  final VoidCallback? onOpen;
  final Widget? trailing;
  final bool showDescription;
  final ValueChanged<bool>? onCompletedChanged;
  final bool changingCompletion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = card.raw['done'] != null;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextLabel case final String label)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 8),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CardLabels(card: card, limit: 3),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onCompletedChanged != null || changingCompletion)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CompletionBox(
                    card: card,
                    saving: changingCompletion,
                    onChanged: onCompletedChanged,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: onCompletedChanged != null || changingCompletion
                        ? 12
                        : 2,
                    right: trailing == null ? 8 : 0,
                  ),
                  child: Text(
                    card.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: completed
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (showDescription && card.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CardDescriptionPreview(description: card.description),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: CardMetadata(card: card),
          ),
        ],
      ),
    );
    return onOpen == null
        ? content
        : InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(DeckTheme.cardRadius),
            child: content,
          );
  }
}

class CardDescriptionPreview extends StatefulWidget {
  const CardDescriptionPreview({
    super.key,
    required this.description,
    this.buildPreview = markdownPreview,
  });

  final String description;
  @visibleForTesting
  final String Function(String) buildPreview;

  @override
  State<CardDescriptionPreview> createState() => _CardDescriptionPreviewState();
}

class _CardDescriptionPreviewState extends State<CardDescriptionPreview> {
  late String _input;
  late String _preview;

  @override
  void initState() {
    super.initState();
    _input = markdownPreviewInput(_withoutTasks(widget.description));
    _preview = widget.buildPreview(_input);
  }

  @override
  void didUpdateWidget(covariant CardDescriptionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.description, oldWidget.description) &&
        widget.buildPreview == oldWidget.buildPreview) {
      return;
    }
    final input = markdownPreviewInput(_withoutTasks(widget.description));
    if (input != _input || widget.buildPreview != oldWidget.buildPreview) {
      _input = input;
      _preview = widget.buildPreview(input);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_preview.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Checklist items are summarised by the progress badge, so the preview skips them.
final _taskLine = RegExp(
  r'^\s*(?:[-*+]|\d+[.)])\s+\[[ xX]\].*$',
  multiLine: true,
);

String _withoutTasks(String description) => description.contains('[')
    ? description.replaceAll(_taskLine, '')
    : description;

class CardLabels extends StatelessWidget {
  const CardLabels({super.key, required this.card, this.limit});
  final DeckCard card;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final labels = cardObjects(card.raw['labels']).toList(growable: false);
    if (labels.isEmpty) return const SizedBox.shrink();
    final text = AppLocalizations.of(context)!;
    final visibleCount = limit == null
        ? labels.length
        : limit!.clamp(0, labels.length);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final label in labels.take(visibleCount)) _LabelBadge(label),
          if (labels.length > visibleCount)
            Tooltip(
              message: labels
                  .skip(visibleCount)
                  .map((label) => cardLabelName(label, text))
                  .join(', '),
              child: Text('+${labels.length - visibleCount}'),
            ),
        ],
      ),
    );
  }
}

class CardMetadata extends StatefulWidget {
  const CardMetadata({
    super.key,
    required this.card,
    this.showStartDate = false,
    this.showAllAssignees = false,
  });
  final DeckCard card;
  final bool showStartDate;
  final bool showAllAssignees;

  @override
  State<CardMetadata> createState() => _CardMetadataState();
}

class _CardMetadataState extends State<CardMetadata> {
  String? _description;
  ({int completed, int total}) _checklist = (completed: 0, total: 0);

  DeckCard get card => widget.card;

  int? _count(String countKey, String listKey) {
    final count = card.raw[countKey];
    if (count is int && count >= 0) return count;
    final items = card.raw[listKey];
    return items is List ? items.length : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_description != card.description) {
      _description = card.description;
      final tasks = markdownTasks(card.description);
      _checklist = (
        completed: tasks.where((task) => task.checked).length,
        total: tasks.length,
      );
    }
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final due = cardDueDate(card);
    final start = widget.showStartDate
        ? _cardDate(card.raw['startdate'])
        : null;
    final completed = card.raw['done'] != null;
    final assignees = _assignedDisplay(card, text);
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
    final badges = Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (start != null)
          _MetadataBadge(
            icon: Icons.event_outlined,
            label: '${text.startDate}: ${local.formatMediumDate(start)}',
            semanticLabel:
                '${text.startDate}: ${local.formatMediumDate(start)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
          ),
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
        if (widget.showAllAssignees)
          for (final assignee in assignees)
            _MetadataBadge(
              icon: assignee.icon,
              label: assignee.name,
              semanticLabel: '${text.assignees}: ${assignee.name}',
            ),
        if (_checklist.total > 0)
          _MetadataBadge(
            icon: Icons.checklist,
            label: '${_checklist.completed}/${_checklist.total}',
            semanticLabel:
                '${text.completed}: ${_checklist.completed}/${_checklist.total}',
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
        if (sync != null)
          _MetadataBadge(
            icon: syncStateIcon(sync),
            label: syncStateLabel(sync, text),
            semanticLabel: syncStateDetail(sync, text),
          ),
      ],
    );
    if (widget.showAllAssignees || assignees.isEmpty) return badges;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: badges),
        Semantics(
          label:
              '${text.assignees}: ${assignees.map((assignee) => assignee.name).join(', ')}',
          excludeSemantics: true,
          child: _Avatars(assignees),
        ),
      ],
    );
  }
}

/// Up to three overlapping initials, with the rest summarised as +n.
class _Avatars extends StatelessWidget {
  const _Avatars(this.people);
  final List<({String name, IconData icon})> people;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = people.take(3).toList(growable: false);
    const size = 26.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + (shown.length - 1) * (size - 8),
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * (size - 8),
                  child: _Avatar(shown[i], size: size),
                ),
            ],
          ),
        ),
        if (people.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '+${people.length - shown.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.person, {required this.size});
  final ({String name, IconData icon}) person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final hue = (person.name.hashCode % 360).abs().toDouble();
    final background = HSLColor.fromAHSL(
      1,
      hue,
      .45,
      dark ? .62 : .42,
    ).toColor();
    final words = person.name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    final initials = words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first).toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.surfaceContainerLowest,
          width: 2,
        ),
      ),
      child: person.icon == Icons.person_outline && initials.isNotEmpty
          ? Text(
              initials,
              // Names are announced by the parent semantics; keep the circle legible.
              textScaler: TextScaler.noScaling,
              style: theme.textTheme.labelSmall?.copyWith(
                color: dark ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            )
          : Icon(
              person.icon,
              size: 14,
              color: dark ? Colors.black87 : Colors.white,
            ),
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
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          cardLabelName(label, AppLocalizations.of(context)!),
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

String cardLabelName(JsonObject label, AppLocalizations text) {
  final raw = label['title'];
  final title = raw is String ? raw.trim() : '';
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
