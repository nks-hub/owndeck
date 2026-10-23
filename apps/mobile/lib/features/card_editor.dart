import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';

Future<void> editCard(
  BuildContext context,
  DeckSession session,
  int boardId,
  int stackId, {
  DeckCard? card,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/card/edit'),
    builder: (_) => CardEditor(
      session: session,
      boardId: boardId,
      stackId: stackId,
      card: card,
    ),
  ),
);

class CardEditor extends StatefulWidget {
  const CardEditor({
    super.key,
    required this.session,
    required this.boardId,
    required this.stackId,
    this.card,
  });
  final DeckSession session;
  final int boardId;
  final int stackId;
  final DeckCard? card;
  @override
  State<CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<CardEditor> {
  late final _title = TextEditingController(text: widget.card?.title ?? '');
  late final _description = TextEditingController(
    text: widget.card?.description ?? '',
  );
  late DateTime? _due = DateTime.tryParse(
    widget.card?.raw['duedate']?.toString() ?? '',
  )?.toLocal();
  late bool _done = widget.card?.raw['done'] != null;
  bool _dirty = false;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    final text = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    if (title.isEmpty || title.runes.length > 255) {
      setState(() => _error = text.invalidTitle);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final card = widget.card;
      final changes = <String, Object?>{};
      if (card == null || title != card.title) changes['title'] = title;
      if (card == null || _description.text != card.description)
        changes['description'] = _description.text;
      final originalDue = DateTime.tryParse(
        card?.raw['duedate']?.toString() ?? '',
      );
      if (_due != null
          ? originalDue == null || !_due!.isAtSameMomentAs(originalDue)
          : originalDue != null) {
        changes['duedate'] = _due?.toUtc().toIso8601String();
      }
      if (card != null &&
          card.raw.containsKey('done') &&
          _done != (card.raw['done'] != null)) {
        changes['done'] = _done
            ? DateTime.now().toUtc().toIso8601String()
            : null;
      }
      if (changes.isNotEmpty) {
        await widget.session.database.saveCardDraft(
          widget.session.account,
          widget.boardId,
          widget.stackId,
          changes,
          original: card,
        );
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text.savedLocally)));
      unawaited(widget.session.refreshStacks(widget.boardId));
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = error is StateError && error.message == 'pending_decision'
              ? text.pendingDecision
              : text.storageError;
        });
    }
  }

  Future<void> _chooseDate() async {
    final initial = _due ?? DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2200),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _due = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      _dirty = true;
    });
  }

  Future<void> _back(bool didPop, Object? _) async {
    if (didPop || _saving || !_dirty) return;
    final text = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.unsavedChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(text.leave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _dirty = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final locale = MaterialLocalizations.of(context);
    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: _back,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.card == null ? text.addCard : text.editCard),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: _title,
                enabled: !_saving,
                decoration: InputDecoration(labelText: text.cardTitle),
                onChanged: (_) => setState(() => _dirty = true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                enabled: !_saving,
                minLines: 5,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: text.description,
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => setState(() => _dirty = true),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(text.dueDate),
                subtitle: _due == null
                    ? null
                    : Text(
                        '${locale.formatMediumDate(_due!)} ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(_due!))}',
                      ),
                leading: const Icon(Icons.event_outlined),
                onTap: _saving ? null : _chooseDate,
                trailing: _due == null
                    ? null
                    : IconButton(
                        tooltip: text.clearDate,
                        icon: const Icon(Icons.close),
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _due = null;
                                _dirty = true;
                              }),
                      ),
              ),
              if (widget.card?.raw.containsKey('done') == true)
                SwitchListTile(
                  title: Text(text.completed),
                  value: _done,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _done = value;
                          _dirty = true;
                        }),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(_error!),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(text.save),
              ),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
