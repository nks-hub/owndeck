import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'server_tools.dart';

Future<void> showBoardClone(
  BuildContext context,
  DeckSession session,
  DeckBoard board, {
  Future<bool> Function(Uri)? openBrowser,
}) => showDialog<void>(
  context: context,
  builder: (_) => _BoardCloneDialog(
    session: session,
    board: board,
    openBrowser: openBrowser,
  ),
);

class _BoardCloneDialog extends StatefulWidget {
  const _BoardCloneDialog({
    required this.session,
    required this.board,
    this.openBrowser,
  });
  final DeckSession session;
  final DeckBoard board;
  final Future<bool> Function(Uri)? openBrowser;
  @override
  State<_BoardCloneDialog> createState() => _BoardCloneDialogState();
}

class _BoardCloneDialogState extends State<_BoardCloneDialog> {
  bool _cards = true;
  bool _assignments = false;
  bool _labels = true;
  bool _dates = true;
  bool _firstColumn = false;
  bool _restore = false;
  bool _busy = false;
  String? _error;

  Future<void> _copy() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.database.queueBoardClone(
        widget.session.account,
        widget.board.id,
        BoardCloneOptions(
          withCards: _cards,
          withAssignments: _assignments,
          withLabels: _labels,
          withDueDate: _dates,
          moveCardsToLeftStack: _firstColumn,
          restoreArchivedCards: _restore,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      unawaited(widget.session.refreshBoards());
    } catch (error) {
      if (!mounted) return;
      final text = AppLocalizations.of(context)!;
      setState(() {
        _busy = false;
        _error = error is StateError && error.message == 'pending_decision'
            ? text.pendingBoardDecision
            : error is StateError && error.message == 'unsupported_operation'
            ? text.copyBoardInBrowser
            : text.loadError;
      });
    }
  }

  Future<void> _browser() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final opened = await openDeckWeb(
        widget.session,
        board: widget.board,
        openBrowser: widget.openBrowser,
      );
      if (!mounted) return;
      if (opened) {
        Navigator.pop(context);
        return;
      }
    } catch (_) {
      // Keep server addresses out of user-visible launch failures.
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context)!.browserError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final native = widget.session.capabilities?.supportsBoardCloning == true;
    Widget option(
      String label,
      bool value,
      void Function(bool) change, {
      bool enabled = true,
    }) => CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: enabled && !_busy
          ? (value) => setState(() => change(value!))
          : null,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.copyBoard,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                native ? text.copyBoardDescription : text.copyBoardInBrowser,
              ),
              if (native) ...[
                option(
                  text.copyBoardWithCards,
                  _cards,
                  (value) => _cards = value,
                ),
                option(
                  text.copyBoardWithAssignments,
                  _assignments,
                  (value) => _assignments = value,
                  enabled: _cards,
                ),
                option(
                  text.copyBoardWithLabels,
                  _labels,
                  (value) => _labels = value,
                  enabled: _cards,
                ),
                option(
                  text.copyBoardWithDueDate,
                  _dates,
                  (value) => _dates = value,
                  enabled: _cards,
                ),
                option(
                  text.copyBoardMoveCards,
                  _firstColumn,
                  (value) => _firstColumn = value,
                  enabled: _cards,
                ),
                option(
                  text.copyBoardRestoreArchived,
                  _restore,
                  (value) => _restore = value,
                  enabled: _cards,
                ),
              ],
              if (_error != null)
                Semantics(liveRegion: true, child: Text(_error!)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(text.cancel),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _browser,
                    child: Text(text.openInNextcloud),
                  ),
                  if (native)
                    FilledButton(
                      onPressed: _busy ? null : _copy,
                      child: Text(text.copyBoard),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
