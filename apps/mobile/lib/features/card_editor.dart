import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'color_choices.dart';
import 'state_message.dart';

Future<void> editCard(
  BuildContext context,
  DeckSession session,
  int boardId,
  int stackId, {
  DeckCard? card,
  String? draftKey,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/card/edit'),
    builder: (_) => CardEditor(
      session: session,
      boardId: boardId,
      stackId: stackId,
      card: card,
      draftKey: draftKey,
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
    this.draftKey,
  });
  final DeckSession session;
  final int boardId;
  final int stackId;
  final DeckCard? card;
  final String? draftKey;
  @override
  State<CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<CardEditor> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _color = TextEditingController();
  late final String _key =
      widget.draftKey ??
      '${widget.boardId}:${widget.stackId}:${widget.card?.id ?? 'new'}';
  DeckCard? _original;
  DateTime? _due;
  DateTime? _start;
  bool _done = false;
  bool _dirty = false;
  bool _loading = true;
  bool _readFailed = false;
  bool _saving = false;
  bool _allowPop = false;
  bool _persistFailed = false;
  int _revision = 0;
  int _persistedRevision = 0;
  String? _error;
  Future<void> _draftTail = Future.value();

  bool _supports(String field) =>
      _original?.raw.containsKey(field) == true ||
      widget.session.capabilities?.supportsExtendedCardFields == true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _readFailed = false;
    });
    try {
      final draft = await widget.session.database.editorDraft(
        widget.session.account.id,
        _key,
      );
      if (!mounted) return;
      _original = draft == null
          ? widget.card
          : draft.base == null
          ? null
          : DeckCard.fromJson(object(jsonDecode(draft.base!)));
      final saved = draft == null ? null : object(jsonDecode(draft.payload));
      _title.text = saved == null
          ? _original?.title ?? ''
          : stringField(saved, 'title');
      _description.text = saved == null
          ? _original?.description ?? ''
          : stringField(saved, 'description');
      final due = saved == null ? _original?.raw['duedate'] : saved['duedate'];
      _due = DateTime.tryParse(due?.toString() ?? '')?.toLocal();
      final start = saved?.containsKey('startdate') == true
          ? saved!['startdate']
          : _original?.raw['startdate'];
      _start = DateTime.tryParse(start?.toString() ?? '')?.toLocal();
      _color.text =
          (saved?.containsKey('color') == true
                  ? saved!['color']
                  : _original?.raw['color'])
              ?.toString() ??
          '';
      _done = saved == null
          ? _original?.raw['done'] != null
          : saved['completed'] == true;
      _dirty = draft != null;
    } catch (_) {
      if (mounted) _readFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changed() {
    setState(() {
      _dirty = true;
      _revision++;
    });
    _persist();
  }

  void _persist() {
    final revision = _revision;
    final data = <String, Object?>{
      'title': _title.text,
      'description': _description.text,
      'duedate': _due?.toUtc().toIso8601String(),
      'startdate': _start?.toUtc().toIso8601String(),
      'color': _color.text,
      'completed': _done,
    };
    final original = _original;
    _draftTail = _draftTail.then((_) async {
      try {
        await widget.session.database.saveEditorDraft(
          widget.session.account,
          _key,
          widget.boardId,
          widget.stackId,
          data,
          original,
        );
        if (!mounted) return;
        setState(() {
          _persistedRevision = revision;
          _persistFailed = false;
        });
      } catch (_) {
        if (mounted) setState(() => _persistFailed = true);
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _loading || _readFailed) return;
    final text = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    if (title.isEmpty || title.runes.length > 255) {
      setState(() => _error = text.invalidTitle);
      return;
    }
    final color = _color.text.trim().replaceFirst('#', '');
    if (_supports('color') &&
        color.isNotEmpty &&
        !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(color)) {
      setState(() => _error = text.invalidColor);
      return;
    }
    if (_supports('startdate') &&
        _start != null &&
        _due != null &&
        _start!.isAfter(_due!)) {
      setState(() => _error = text.invalidDateRange);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _draftTail;
      final card = _original;
      final changes = <String, Object?>{};
      if (card == null || title != card.title) changes['title'] = title;
      if (card == null || _description.text != card.description) {
        changes['description'] = _description.text;
      }
      for (final field in {
        'duedate': _due,
        if (_supports('startdate')) 'startdate': _start,
      }.entries) {
        final previous = DateTime.tryParse(
          card?.raw[field.key]?.toString() ?? '',
        );
        final value = field.value;
        if (value == null
            ? previous != null
            : previous == null || !value.isAtSameMomentAs(previous)) {
          changes[field.key] = value?.toUtc().toIso8601String();
        }
      }
      if (_supports('color')) {
        final value = color.isEmpty ? null : color.toLowerCase();
        if (value != card?.raw['color']) changes['color'] = value;
      }
      if (card != null &&
          card.raw.containsKey('done') &&
          _done != (card.raw['done'] != null)) {
        changes['done'] = _done
            ? DateTime.now().toUtc().toIso8601String()
            : null;
      }
      await widget.session.database.publishEditorDraft(
        widget.session.account,
        _key,
        widget.boardId,
        widget.stackId,
        changes,
        card,
      );
      if (!mounted) return;
      if (changes.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.savedLocally)));
        unawaited(widget.session.refreshStacks(widget.boardId));
      }
      _close();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = localWriteErrorMessage(error, text);
        });
      }
    }
  }

  void _close() {
    setState(() {
      _allowPop = true;
      _saving = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _back(bool didPop, Object? _) async {
    if (didPop || _saving || _loading) return;
    await _draftTail;
    if (!mounted) return;
    if (!_persistFailed) {
      _close();
      return;
    }
    final text = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.unsavedChanges),
        content: Text(text.localSaveError),
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
    if (leave == true && mounted) _close();
  }

  Future<void> _chooseDate({bool start = false}) async {
    final initial = (start ? _start : _due) ?? DateTime.now();
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
    final value = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    if (start) {
      _start = value;
    } else {
      _due = value;
    }
    _changed();
  }

  Widget _dateTile(
    String label,
    DateTime? value,
    VoidCallback choose,
    VoidCallback clear,
  ) {
    final text = AppLocalizations.of(context)!;
    final locale = MaterialLocalizations.of(context);
    return ListTile(
      title: Text(label),
      leading: const Icon(Icons.event_outlined),
      subtitle: value == null
          ? null
          : Text(
              '${locale.formatMediumDate(value)} ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(value))}',
            ),
      onTap: _saving ? null : choose,
      trailing: value == null
          ? null
          : IconButton(
              tooltip: '${text.clearDate}: $label',
              icon: const Icon(Icons.close),
              onPressed: _saving ? null : clear,
            ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _color.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _allowPop || !_dirty && !_saving && !_loading,
      onPopInvokedWithResult: _back,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_original == null ? text.addCard : text.editCard),
          actions: [
            TextButton.icon(
              onPressed: _loading || _readFailed || _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(text.save),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _readFailed
            ? Center(
                child: StateMessage(
                  message: text.localReadError,
                  actionLabel: text.retry,
                  onAction: _load,
                ),
              )
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextField(
                      controller: _title,
                      enabled: !_saving,
                      decoration: InputDecoration(labelText: text.cardTitle),
                      onChanged: (_) => _changed(),
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
                      onChanged: (_) => _changed(),
                    ),
                    const SizedBox(height: 16),
                    if (_supports('startdate'))
                      _dateTile(
                        text.startDate,
                        _start,
                        () => _chooseDate(start: true),
                        () {
                          _start = null;
                          _changed();
                        },
                      ),
                    _dateTile(text.dueDate, _due, _chooseDate, () {
                      _due = null;
                      _changed();
                    }),
                    if (_supports('color'))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text.cardColor,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ColorChoices(
                              value: _color.text,
                              onChanged: _saving
                                  ? null
                                  : (value) {
                                      _color.text = value ?? '';
                                      _changed();
                                    },
                            ),
                          ],
                        ),
                      ),
                    if (_original?.raw.containsKey('done') == true)
                      SwitchListTile(
                        title: Text(text.completed),
                        value: _done,
                        onChanged: _saving
                            ? null
                            : (value) {
                                _done = value;
                                _changed();
                              },
                      ),
                    if (_dirty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _persistFailed
                              ? text.localSaveError
                              : _revision == _persistedRevision
                              ? text.draftSaved
                              : text.savingDraft,
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(_error!),
                      ),
                    const SizedBox(height: 24),
                    if (_saving) const LinearProgressIndicator(),
                  ],
                ),
              ),
      ),
    );
  }
}
