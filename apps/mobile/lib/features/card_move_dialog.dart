import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_summary.dart' show cardObjects;

final class CardMoveDestination {
  const CardMoveDestination({
    required this.board,
    required this.stack,
    required this.before,
    this.anchorCardId,
  });
  final DeckBoard board;
  final DeckStack stack;
  final int? anchorCardId;
  final bool before;
}

class CardMoveDialog extends StatefulWidget {
  const CardMoveDialog({
    super.key,
    required this.session,
    required this.source,
    required this.card,
    required this.boards,
    required this.stacks,
  });
  final DeckSession session;
  final DeckBoard source;
  final DeckCard card;
  final List<DeckBoard> boards;
  final List<DeckStack> stacks;
  @override
  State<CardMoveDialog> createState() => _CardMoveDialogState();
}

class _CardMoveDialogState extends State<CardMoveDialog> {
  final _scroll = ScrollController();
  late DeckBoard _board = widget.source;
  late List<DeckBoard> _boards = widget.boards;
  late int _sourceId = widget.source.id;
  late int _movingCardId = widget.card.id;
  late List<DeckStack> _stacks = widget.stacks;
  late int? _stackId = widget.stacks.any((s) => s.id == widget.card.stackId)
      ? widget.card.stackId
      : widget.stacks.firstOrNull?.id;
  String _placement = 'end';
  int? _anchor;
  bool _loading = false;
  Object? _error;
  Object? _boardsError;
  int _request = 0;
  bool _selectionRequested = true;
  bool _sourceAllowed = true;

  DeckStack? get _stack => _stacks.where((s) => s.id == _stackId).firstOrNull;
  bool get _transfer => _board.id != _sourceId;

  Future<void> _loadBoard(
    DeckBoard board, {
    bool preserveChoice = false,
    bool refresh = false,
  }) async {
    final request = ++_request;
    setState(() {
      _board = board;
      _stacks = [];
      if (!preserveChoice) {
        _stackId = null;
        _selectionRequested = false;
        _placement = 'end';
        _anchor = null;
      }
      _loading = true;
      _error = null;
    });
    try {
      var stacks = await widget.session.database.stackView(
        widget.session.account.id,
        board.id,
      );
      if (!mounted || request != _request) return;
      if (stacks.isNotEmpty) await _applyStacks(stacks, request);
      if (!mounted || request != _request) return;
      final checkpoint = await widget.session.database.checkpoint(
        widget.session.account.id,
        'board:${board.id}',
      );
      if (board.id > 0 && (refresh || stacks.isEmpty || checkpoint == null)) {
        await widget.session.refreshStacks(board.id);
        stacks = await widget.session.database.stackView(
          widget.session.account.id,
          board.id,
        );
      }
      if (!mounted || request != _request) return;
      await _applyStacks(stacks, request);
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = widget.session.error('board:${board.id}') ?? _error;
      });
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = error;
        });
      }
    }
  }

  Future<void> _applyStacks(List<DeckStack> stacks, int request) async {
    final visible = stacks
        .where((s) => (s.raw['deletedAt'] ?? 0) == 0)
        .toList();
    final database = widget.session.database;
    final accountId = widget.session.account.id;
    final selected = _stackId;
    final previous = selected == null
        ? null
        : await database.resolveId(accountId, selected, 'createStack') ??
              selected;
    final anchor = _anchor;
    final resolvedAnchor = anchor == null
        ? null
        : await database.resolveId(accountId, anchor, 'createCard') ?? anchor;
    final cardId =
        await database.resolveId(accountId, widget.card.id, 'createCard') ??
        widget.card.id;
    if (!mounted || request != _request) return;
    setState(() {
      _stacks = visible;
      _anchor = resolvedAnchor;
      _movingCardId = cardId;
      if (previous != null) {
        _stackId = visible.any((s) => s.id == previous) ? previous : null;
        if (_stackId == null) _error = StateError('invalid_destination');
      } else if (!_selectionRequested) {
        _stackId = visible.firstOrNull?.id;
      }
      if (_stackId != null) _selectionRequested = true;
    });
  }

  Future<void> _refreshChoices() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _boardsError = null;
    });
    try {
      await widget.session.refreshBoards();
      final database = widget.session.database;
      final accountId = widget.session.account.id;
      final sourceId =
          await database.resolveId(
            accountId,
            widget.source.id,
            'createBoard',
          ) ??
          widget.source.id;
      final targetId =
          await database.resolveId(accountId, _board.id, 'createBoard') ??
          _board.id;
      final boards = (await database.boardView(accountId))
          .where(
            (board) =>
                board.permissions.read &&
                board.permissions.edit &&
                !board.archived &&
                board.deletedAt == 0 &&
                board.raw['externalId'] == null,
          )
          .toList();
      if (!mounted || request != _request) return;
      final target = boards.where((board) => board.id == targetId).firstOrNull;
      setState(() {
        _boards = boards;
        _sourceId = sourceId;
        _boardsError = widget.session.error('boards');
        _sourceAllowed = boards.any((board) => board.id == sourceId);
        _loading = false;
        if (!_sourceAllowed || target == null) {
          _error = StateError('permission_denied');
          _stacks = [];
          _stackId = null;
        }
      });
      if (_sourceAllowed && target != null) {
        await _loadBoard(target, preserveChoice: true, refresh: true);
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _boardsError = error;
        });
      }
    }
  }

  List<String> _lostLabels(AppLocalizations text) {
    if (!_transfer || _board.permissions.manage) return const [];
    final targetNames = cardObjects(
      _board.raw['labels'],
    ).map((label) => label['title']).whereType<String>().toSet();
    return [
      for (final label in cardObjects(widget.card.raw['labels']))
        if (!targetNames.contains(label['title']))
          label['title'] is String && (label['title'] as String).isNotEmpty
              ? label['title'] as String
              : text.unnamedLabel,
    ];
  }

  @override
  void dispose() {
    _request++;
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final stack = _stack;
    final cards =
        stack?.cards
            .where(
              (card) =>
                  card.id != _movingCardId &&
                  !card.archived &&
                  (card.raw['deletedAt'] ?? 0) == 0,
            )
            .toList() ??
        <DeckCard>[];
    final relative = _placement == 'before' || _placement == 'after';
    final lostLabels = _lostLabels(text);
    final sourceStack = widget.stacks
        .where((s) => s.id == widget.card.stackId)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Destination hints must not shift the dialog's accessibility targets.
        final height =
            (constraints.maxHeight -
                    MediaQuery.viewInsetsOf(context).vertical -
                    48)
                .clamp(0.0, 640.0)
                .toDouble();
        return AlertDialog(
          insetPadding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: height, maxWidth: 480),
          title: Row(
            children: [
              Expanded(child: Text(text.moveCard)),
              IconButton(
                onPressed: _loading ? null : _refreshChoices,
                tooltip: text.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            height: height,
            child: Scrollbar(
              controller: _scroll,
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _sourceAllowed ? widget.card.title : text.permissionError,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey((
                        'move-board',
                        _boards.any((b) => b.id == _board.id)
                            ? _board.id
                            : null,
                      )),
                      initialValue:
                          _boards.any((board) => board.id == _board.id)
                          ? _board.id
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: text.destinationBoard,
                      ),
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
                      onChanged: !_sourceAllowed
                          ? null
                          : (value) {
                              final board = _boards
                                  .where((b) => b.id == value)
                                  .firstOrNull;
                              if (board != null && board.id != _board.id) {
                                unawaited(_loadBoard(board));
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    if (_loading) const LinearProgressIndicator(),
                    if (_stacks.isNotEmpty)
                      DropdownButtonFormField<int>(
                        key: ValueKey(('move-column', _board.id, _stackId)),
                        initialValue: _stackId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: text.destinationColumn,
                        ),
                        items: [
                          for (final column in _stacks)
                            DropdownMenuItem(
                              value: column.id,
                              child: Text(
                                column.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _stackId = value;
                          _placement = 'end';
                          _anchor = null;
                          _error = null;
                          _selectionRequested = true;
                        }),
                      )
                    else if (!_loading)
                      Text(text.noStacks),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey((
                        'move-placement',
                        _board.id,
                        _stackId,
                        _placement,
                      )),
                      initialValue: _placement,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: text.position),
                      items: [
                        DropdownMenuItem(
                          value: 'start',
                          child: Text(text.moveToTop),
                        ),
                        DropdownMenuItem(
                          value: 'end',
                          child: Text(text.moveToBottom),
                        ),
                        if (cards.isNotEmpty || relative) ...[
                          DropdownMenuItem(
                            value: 'before',
                            child: Text(text.moveBefore),
                          ),
                          DropdownMenuItem(
                            value: 'after',
                            child: Text(text.moveAfter),
                          ),
                        ],
                      ],
                      onChanged: stack == null
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _placement = value;
                                  _anchor ??= cards.firstOrNull?.id;
                                });
                              }
                            },
                    ),
                    if (relative)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: DropdownButtonFormField<int>(
                          key: ValueKey((
                            'move-anchor',
                            _board.id,
                            _stackId,
                            _anchor,
                          )),
                          initialValue: cards.any((card) => card.id == _anchor)
                              ? _anchor
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: text.moveRelativeCard,
                          ),
                          items: [
                            for (final card in cards)
                              DropdownMenuItem(
                                value: card.id,
                                child: Text(
                                  card.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => setState(() => _anchor = value),
                        ),
                      ),
                    if (_transfer)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text.transferCardHint),
                            const SizedBox(height: 8),
                            Text(text.transferAccessHint),
                            if (lostLabels.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  text.transferLabelLoss(lostLabels.join(', ')),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (stack?.isDoneColumn == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(text.transferToDone),
                      ),
                    if (stack != null &&
                        !stack.isDoneColumn &&
                        sourceStack?.isDoneColumn == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(text.transferFromDone),
                      ),
                    if (_sourceAllowed &&
                        (_error != null || _boardsError != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          errorMessage((_error ?? _boardsError)!, text),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed:
                  _loading ||
                      !_sourceAllowed ||
                      !_boards.any((b) => b.id == _board.id) ||
                      stack == null ||
                      relative && !cards.any((c) => c.id == _anchor)
                  ? null
                  : () => Navigator.pop(
                      context,
                      CardMoveDestination(
                        board: _board,
                        stack: stack,
                        anchorCardId: relative ? _anchor : null,
                        before: _placement == 'start' || _placement == 'before',
                      ),
                    ),
              child: Text(text.moveCard),
            ),
          ],
        );
      },
    );
  }
}
