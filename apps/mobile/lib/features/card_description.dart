import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../core/errors.dart';
import '../core/markdown_tasks.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';

class CardDescription extends StatefulWidget {
  const CardDescription({
    super.key,
    required this.session,
    required this.boardId,
    required this.card,
    required this.canEdit,
    required this.openLink,
  });
  final DeckSession session;
  final int boardId;
  final DeckCard card;
  final bool canEdit;
  final ValueChanged<String?> openLink;
  @override
  State<CardDescription> createState() => _CardDescriptionState();
}

class _CardDescriptionState extends State<CardDescription> {
  String? _parsed;
  List<MarkdownTask> _tasks = [];
  bool _saving = false;
  bool _hideCompleted = false;

  Future<void> _addItems() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => const _ChecklistItemsDialog(),
    );
    if (value == null || !mounted) return;
    await _save((source) => appendMarkdownTasks(source, value));
  }

  Future<void> _toggle(MarkdownTask task, bool checked) =>
      _save((source) => toggleMarkdownTask(source, task, checked));

  Future<void> _save(String Function(String source) change) async {
    if (_saving || !widget.canEdit) return;
    final source = widget.card.description;
    setState(() => _saving = true);
    try {
      final current = await widget.session.database
          .watchCard(widget.session.account.id, widget.boardId, widget.card.id)
          .first;
      if (current == null) throw StateError('card_unavailable');
      if (current.description != source) throw StateError('concurrent_edit');
      await widget.session.database.saveCardDraft(
        widget.session.account,
        widget.boardId,
        current.stackId,
        {'description': change(source)},
        original: current,
      );
      unawaited(widget.session.refreshStacks(widget.boardId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage(error, AppLocalizations.of(context)!)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final source = widget.card.description;
    if (_parsed != source) {
      _parsed = source;
      _tasks = markdownTasks(source);
    }
    final hidden = _hideCompleted ? hideCompletedTasks(source) : null;
    final shownTasks = hidden?.tasks ?? _tasks;
    final shownSource = hidden?.view ?? source;
    var checkbox = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_tasks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              label:
                  '${text.completed}: ${_tasks.where((task) => task.checked).length} / ${_tasks.length}',
              child: LinearProgressIndicator(
                value:
                    _tasks.where((task) => task.checked).length / _tasks.length,
              ),
            ),
          ),
        if (_tasks.isNotEmpty || widget.canEdit)
          Wrap(
            spacing: 8,
            children: [
              if (_tasks.any((task) => task.checked) || _hideCompleted)
                FilterChip(
                  label: Text(text.hideCompletedItems),
                  selected: _hideCompleted,
                  onSelected: (value) => setState(() => _hideCompleted = value),
                ),
              if (widget.canEdit)
                ActionChip(
                  avatar: const Icon(Icons.playlist_add),
                  label: Text(text.addChecklistItems),
                  onPressed: _saving ? null : _addItems,
                ),
            ],
          ),
        if (_hideCompleted && shownSource.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(text.allItemsCompleted),
          )
        else
          MarkdownBody(
            key: ValueKey((shownSource, widget.canEdit, _saving)),
            data: shownSource.isEmpty ? text.noDescription : shownSource,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              listIndent: _tasks.isEmpty ? 24 : 48,
            ),
            checkboxBuilder: (checked) {
              if (shownTasks.isEmpty) {
                return Checkbox(value: checked, onChanged: null);
              }
              final task = shownTasks[checkbox++ % shownTasks.length];
              return Semantics(
                label: task.label,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Checkbox(
                    value: checked,
                    onChanged: widget.canEdit && !_saving
                        ? (value) => unawaited(_toggle(task, value!))
                        : null,
                  ),
                ),
              );
            },
            onTapLink: (_, href, _) => widget.openLink(href),
            imageBuilder: (uri, title, alt) => TextButton.icon(
              onPressed: () => widget.openLink(uri.toString()),
              icon: const Icon(Icons.image_outlined),
              label: Text(alt?.isNotEmpty == true ? alt! : text.externalImage),
            ),
          ),
      ],
    );
  }
}

class _ChecklistItemsDialog extends StatefulWidget {
  const _ChecklistItemsDialog();
  @override
  State<_ChecklistItemsDialog> createState() => _ChecklistItemsDialogState();
}

class _ChecklistItemsDialogState extends State<_ChecklistItemsDialog> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(text.addChecklistItems),
      content: TextField(
        controller: _input,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(helperText: text.addChecklistItemsHelp),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _input.text),
          child: Text(text.addItems),
        ),
      ],
    );
  }
}
