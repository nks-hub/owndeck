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

  Future<void> _toggle(MarkdownTask task, bool checked) async {
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
        {'description': toggleMarkdownTask(source, task, checked)},
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
        MarkdownBody(
          key: ValueKey((source, widget.canEdit, _saving)),
          data: source.isEmpty ? text.noDescription : source,
          selectable: true,
          styleSheet: MarkdownStyleSheet(listIndent: _tasks.isEmpty ? 24 : 48),
          checkboxBuilder: (checked) {
            if (_tasks.isEmpty)
              return Checkbox(value: checked, onChanged: null);
            final task = _tasks[checkbox++ % _tasks.length];
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
