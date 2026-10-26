import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'sharing.dart' show shareParticipantId, shareParticipantName;
import 'state_message.dart';

Future<void> openCommentEditor(
  BuildContext context,
  DeckSession session,
  int boardId,
  int stackId,
  int cardId, {
  DeckComment? original,
  DeckComment? replyTo,
  String? draftKey,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: '/comment/edit'),
    builder: (_) => CommentEditor(
      session: session,
      boardId: boardId,
      stackId: stackId,
      cardId: cardId,
      original: original,
      replyTo: replyTo,
      draftKey: draftKey,
    ),
  ),
);

class CommentEditor extends StatefulWidget {
  const CommentEditor({
    super.key,
    required this.session,
    required this.boardId,
    required this.stackId,
    required this.cardId,
    this.original,
    this.replyTo,
    this.draftKey,
  });
  final DeckSession session;
  final int boardId;
  final int stackId;
  final int cardId;
  final DeckComment? original;
  final DeckComment? replyTo;
  final String? draftKey;
  @override
  State<CommentEditor> createState() => _CommentEditorState();
}

class _CommentEditorState extends State<CommentEditor> {
  final _message = TextEditingController();
  late final _key =
      widget.draftKey ??
      'comment:${widget.cardId}:${widget.original?.id ?? 'new'}:${widget.replyTo?.id ?? 0}';
  DeckComment? _original;
  DeckComment? _replyTo;
  Future<void> _tail = Future.value();
  bool _loading = true;
  bool _loadFailed = false;
  bool _persistFailed = false;
  bool _saving = false;
  bool _dirty = false;
  bool _allowPop = false;
  int _revision = 0;
  int _savedRevision = 0;
  String? _error;
  List<({String id, String name})> _people = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final draft = await widget.session.database.editorDraft(
        widget.session.account.id,
        _key,
      );
      if (!mounted) return;
      if (draft != null && draft.kind != 'comment') {
        throw StateError('invalid_draft');
      }
      final payload = draft == null ? null : object(jsonDecode(draft.payload));
      _original = draft?.base != null
          ? DeckComment.fromJson(object(jsonDecode(draft!.base!)))
          : widget.original;
      _replyTo = payload?['replyTo'] is JsonObject
          ? DeckComment.fromJson(object(payload!['replyTo']))
          : widget.replyTo;
      _message.text = payload == null
          ? _original?.message ?? ''
          : stringField(payload, 'description');
      _dirty = draft != null;
      final board = await widget.session.database
          .watchBoard(widget.session.account.id, widget.boardId)
          .first;
      _people = [
        for (final user in board?.raw['users'] as List? ?? const [])
          if (shareParticipantId(user).isNotEmpty)
            (
              id: shareParticipantId(user),
              name: shareParticipantName(user, shareParticipantId(user)),
            ),
      ];
    } catch (_) {
      _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changed(String value) {
    setState(() {
      _dirty = true;
      _revision++;
    });
    final revision = _revision;
    _tail = _tail.then((_) async {
      try {
        await widget.session.database.saveCommentDraft(
          widget.session.account,
          _key,
          widget.boardId,
          widget.stackId,
          widget.cardId,
          value,
          original: _original,
          replyTo: _replyTo,
        );
        if (mounted) {
          setState(() {
            _savedRevision = revision;
            _persistFailed = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _persistFailed = true);
      }
    });
  }

  /// Board participants matching the `@term` typed right before the cursor.
  ({int start, List<({String id, String name})> people})? _mentionQuery() {
    final cursor = _message.selection.baseOffset;
    if (cursor < 0 || cursor > _message.text.length) return null;
    final match = RegExp(
      r'(?:^|\s)@([^\s@"]*)$',
    ).firstMatch(_message.text.substring(0, cursor));
    if (match == null) return null;
    final term = match[1]!.toLowerCase();
    final people = _people
        .where(
          (p) =>
              p.id.toLowerCase().contains(term) ||
              p.name.toLowerCase().contains(term),
        )
        .take(5)
        .toList();
    return people.isEmpty
        ? null
        : (start: cursor - term.length - 1, people: people);
  }

  void _mention(int start, String id) {
    final cursor = _message.selection.baseOffset;
    final inserted = '${mentionToken(id)} ';
    final value = _message.text.replaceRange(start, cursor, inserted);
    _message.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
    _changed(value);
  }

  void _close() {
    setState(() {
      _allowPop = true;
      _saving = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Future<void> _back(bool didPop, Object? _) async {
    if (didPop || _saving || _loading) return;
    await _tail;
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

  Future<void> _send() async {
    final text = AppLocalizations.of(context)!;
    if (_message.text.trim().isEmpty ||
        _message.text.runes.length > deckCommentMaxLength) {
      setState(() => _error = text.invalidComment);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _tail;
      await widget.session.database.publishCommentDraft(
        widget.session.account,
        _key,
        widget.boardId,
        widget.stackId,
        widget.cardId,
        _message.text,
        original: _original,
        replyTo: _replyTo,
      );
      if (!mounted) return;
      unawaited(widget.session.refreshComments(widget.cardId));
      _close();
    } catch (failure) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = localWriteErrorMessage(failure, text);
        });
      }
    }
  }

  @override
  void dispose() {
    _message.dispose();
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
          title: Text(_original == null ? text.addComment : text.editComment),
          actions: [
            IconButton.filled(
              onPressed: _loading || _loadFailed || _saving ? null : _send,
              icon: const Icon(Icons.send_outlined),
              tooltip: text.sendComment,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
            ? Center(
                child: StateMessage(
                  message: text.localReadError,
                  actionLabel: text.retry,
                  onAction: _load,
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_replyTo != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text('${text.replyTo}: ${_replyTo!.message}'),
                    ),
                  TextField(
                    controller: _message,
                    enabled: !_saving,
                    minLines: 5,
                    maxLines: null,
                    onChanged: _changed,
                    decoration: InputDecoration(
                      labelText: text.commentMessage,
                      counterText:
                          '${_message.text.runes.length}/$deckCommentMaxLength',
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _message,
                    builder: (context, _) {
                      final query = _saving ? null : _mentionQuery();
                      return Column(
                        children: [
                          if (query != null)
                            for (final person in query.people)
                              ListTile(
                                key: ValueKey('mention:${person.id}'),
                                dense: true,
                                leading: const Icon(Icons.alternate_email),
                                title: Text(person.name),
                                subtitle: person.name == person.id
                                    ? null
                                    : Text(person.id),
                                onTap: () => _mention(query.start, person.id),
                              ),
                        ],
                      );
                    },
                  ),
                  if (_dirty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _persistFailed
                            ? text.localSaveError
                            : _savedRevision == _revision
                            ? text.localDraftSaved
                            : text.savingDraft,
                      ),
                    ),
                  if (_error != null) Text(_error!),
                  const SizedBox(height: 24),
                  if (_saving) const LinearProgressIndicator(),
                ],
              ),
      ),
    );
  }
}
