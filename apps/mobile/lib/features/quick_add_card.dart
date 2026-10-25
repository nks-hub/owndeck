import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/app_preferences.dart';
import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'structure_editor.dart';

Future<void> showQuickAddCard(
  BuildContext context,
  DeckSession session, {
  DeckBoard? board,
  int? stackId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  enableDrag: false,
  showDragHandle: false,
  builder: (_) => _QuickAddCard(
    session: session,
    initialBoard: board,
    initialStackId: stackId,
  ),
);

class _QuickAddCard extends ConsumerStatefulWidget {
  const _QuickAddCard({
    required this.session,
    this.initialBoard,
    this.initialStackId,
  });
  final DeckSession session;
  final DeckBoard? initialBoard;
  final int? initialStackId;

  @override
  ConsumerState<_QuickAddCard> createState() => _QuickAddCardState();
}

class _QuickAddCardState extends ConsumerState<_QuickAddCard> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _draftKey = 'quick:${const Uuid().v4()}';
  List<DeckBoard> _boards = [];
  List<DeckStack> _stacks = [];
  DeckBoard? _board;
  int? _stackId;
  bool _loading = true;
  bool _columnsLoading = false;
  bool _details = false;
  bool _saving = false;
  bool _allowClose = false;
  bool _draftFailed = false;
  bool _draftStarted = false;
  int _pendingDrafts = 0;
  int _request = 0;
  Object? _error;
  Future<void> _draftTail = Future.value();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = widget.session;
    try {
      final previous = await ref
          .read(appPreferencesProvider)
          .lastCardDestination(session.account.id);
      final boards = (await session.database.boardView(session.account.id))
          .where((b) => b.permissions.edit && !b.archived && b.deletedAt == 0)
          .toList();
      final preferred = widget.initialBoard?.id ?? previous?.boardId;
      final resolved = preferred == null
          ? null
          : await session.database.resolveId(
                  session.account.id,
                  preferred,
                  'createBoard',
                ) ??
                preferred;
      if (!mounted) return;
      final requested = boards.where((b) => b.id == resolved).firstOrNull;
      final board = widget.initialBoard == null
          ? requested ?? boards.firstOrNull
          : requested;
      setState(() {
        _boards = boards;
        _board = board;
        _loading = false;
        if (widget.initialBoard != null && requested == null) {
          _error = StateError('permission_denied');
        }
      });
      if (board != null) {
        await _loadColumns(
          board,
          preferredStack:
              widget.initialStackId ??
              (board.id == resolved ? previous?.stackId : null),
          strictStack: widget.initialStackId != null,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _loadColumns(
    DeckBoard board, {
    int? preferredStack,
    bool strictStack = false,
  }) async {
    final request = ++_request;
    setState(() {
      _board = board;
      _stackId = null;
      _stacks = [];
      _columnsLoading = true;
      _error = null;
    });
    final session = widget.session;
    try {
      var stacks = await session.database.stackView(
        session.account.id,
        board.id,
      );
      if (stacks.isEmpty && board.id > 0) {
        await session.refreshStacks(board.id);
        stacks = await session.database.stackView(session.account.id, board.id);
      }
      stacks = stacks.where((s) => (s.raw['deletedAt'] ?? 0) == 0).toList();
      final resolved = preferredStack == null
          ? null
          : await session.database.resolveId(
                  session.account.id,
                  preferredStack,
                  'createStack',
                ) ??
                preferredStack;
      if (!mounted || request != _request) return;
      final requested = stacks.where((s) => s.id == resolved).firstOrNull;
      setState(() {
        _stacks = stacks;
        _stackId = strictStack
            ? requested?.id
            : requested?.id ?? stacks.firstOrNull?.id;
        _columnsLoading = false;
        if (strictStack && requested == null) {
          _error = StateError('invalid_destination');
        }
      });
      _persistDraft();
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _columnsLoading = false;
          _error = error;
        });
      }
    }
  }

  void _persistDraft() {
    final board = _board;
    final stack = _stackId;
    if (board == null || stack == null) return;
    final empty = _title.text.isEmpty && _description.text.isEmpty;
    if (empty && !_draftStarted) {
      setState(() {});
      return;
    }
    _draftStarted = true;
    final payload = <String, Object?>{
      'title': _title.text,
      'description': _description.text,
      'duedate': null,
    };
    _pendingDrafts++;
    setState(() {});
    _draftTail = _draftTail.then((_) async {
      try {
        if (empty) {
          await widget.session.database.deleteEditorDraft(
            widget.session.account.id,
            _draftKey,
          );
        } else {
          await widget.session.database.saveEditorDraft(
            widget.session.account,
            _draftKey,
            board.id,
            stack,
            payload,
            null,
          );
        }
        _draftFailed = false;
      } catch (_) {
        _draftFailed = true;
      } finally {
        _pendingDrafts--;
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _close() async {
    if (_saving) return;
    await _draftTail;
    if (!mounted) return;
    if (_draftFailed) {
      final text = AppLocalizations.of(context)!;
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(text.storageError),
          content: Text(text.unsavedChanges),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(text.leave),
            ),
          ],
        ),
      );
      if (leave != true || !mounted) return;
    }
    setState(() => _allowClose = true);
    Navigator.pop(context);
  }

  Future<void> _save() async {
    final board = _board;
    final stack = _stackId;
    final title = _title.text.trim();
    if (_saving || board == null || stack == null || title.isEmpty) return;
    final text = AppLocalizations.of(context)!;
    if (title.runes.length > 255) {
      setState(() => _error = StateError('invalid_title'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _draftTail;
      await widget.session.database.publishEditorDraft(
        widget.session.account,
        _draftKey,
        board.id,
        stack,
        {'title': title, 'description': _description.text},
        null,
      );
      unawaited(
        ref
            .read(appPreferencesProvider)
            .rememberCardDestination(
              widget.session.account.id,
              board.id,
              stack,
            ),
      );
      unawaited(widget.session.refreshStacks(board.id));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _allowClose = true);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(text.savedLocally)));
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error;
        });
      }
    }
  }

  @override
  void dispose() {
    _request++;
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final canEnter = !_saving && !_columnsLoading && _stackId != null;
    return PopScope(
      canPop: _allowClose || !_saving && !_draftFailed && _pendingDrafts == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_close());
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.addCard,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : _close,
                    tooltip: text.close,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (_loading)
                const LinearProgressIndicator()
              else if (_boards.isEmpty) ...[
                Text(text.noWritableBoards),
                if (widget.session.capabilities?.canCreateBoards == true)
                  TextButton.icon(
                    onPressed: () async {
                      await editStructure(context, widget.session);
                      if (mounted) await _load();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(text.addBoard),
                  ),
              ] else ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(('quick-board', _board?.id)),
                  initialValue: _board?.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: text.destinationBoard),
                  items: [
                    for (final board in _boards)
                      DropdownMenuItem(
                        value: board.id,
                        child: Text(
                          board.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (id) {
                          final board = _boards
                              .where((b) => b.id == id)
                              .firstOrNull;
                          if (board != null) unawaited(_loadColumns(board));
                        },
                ),
                const SizedBox(height: 12),
                if (_columnsLoading)
                  const LinearProgressIndicator()
                else if (_stacks.isEmpty) ...[
                  Text(text.noWritableColumns),
                  if (_board?.permissions.manage == true)
                    TextButton.icon(
                      onPressed: () async {
                        final board = _board!;
                        await editStructure(
                          context,
                          widget.session,
                          board: board,
                          column: true,
                        );
                        if (mounted) await _loadColumns(board);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(text.addStack),
                    ),
                ] else
                  DropdownButtonFormField<int>(
                    key: ValueKey(('quick-stack', _board?.id, _stackId)),
                    initialValue: _stackId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: text.destinationColumn,
                    ),
                    items: [
                      for (final stack in _stacks)
                        DropdownMenuItem(
                          value: stack.id,
                          child: Text(
                            stack.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (id) {
                            setState(() {
                              _stackId = id;
                              _error = null;
                            });
                            _persistDraft();
                          },
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  enabled: canEnter,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLength: 255,
                  decoration: InputDecoration(
                    labelText: text.cardTitle,
                    hintText: text.quickAddHint,
                  ),
                  onChanged: (_) => _persistDraft(),
                  onSubmitted: (_) => unawaited(_save()),
                ),
                if (_details)
                  TextField(
                    controller: _description,
                    enabled: canEnter,
                    minLines: 3,
                    maxLines: 8,
                    decoration: InputDecoration(labelText: text.description),
                    onChanged: (_) => _persistDraft(),
                  )
                else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: canEnter
                          ? () => setState(() => _details = true)
                          : null,
                      icon: const Icon(Icons.notes_outlined),
                      label: Text(text.quickAddDetails),
                    ),
                  ),
                if (_title.text.isNotEmpty || _description.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _draftFailed
                          ? text.storageError
                          : _pendingDrafts > 0
                          ? text.savingDraft
                          : text.quickAddSavedDraft,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: canEnter && _title.text.trim().isNotEmpty
                      ? _save
                      : null,
                  icon: const Icon(Icons.add),
                  label: Text(text.addCard),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(errorMessage(_error!, text)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
