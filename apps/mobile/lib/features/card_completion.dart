import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/card_edits.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';

/// Whether [card] can be completed from a list outside its board.
bool canCompleteCard(DeckBoard board, DeckCard card) =>
    board.permissions.edit &&
    !board.archived &&
    board.deletedAt == 0 &&
    !card.archived &&
    card.raw.containsKey('done');

/// Runs the shared [setCardCompleted] write for a card shown in My tasks,
/// search or calendar and reports failures in a snack bar.
class CardCompletion extends StatefulWidget {
  const CardCompletion({
    super.key,
    required this.session,
    required this.board,
    required this.card,
    required this.builder,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckCard card;

  /// Gets a null `onChanged` when the card cannot be completed or is saving.
  final Widget Function(
    BuildContext context,
    ValueChanged<bool>? onChanged,
    bool saving,
  )
  builder;

  @override
  State<CardCompletion> createState() => _CardCompletionState();
}

class _CardCompletionState extends State<CardCompletion> {
  bool _saving = false;

  Future<void> _set(bool completed) async {
    if (_saving) return;
    final session = widget.session;
    setState(() => _saving = true);
    try {
      await setCardCompleted(session, widget.board.id, widget.card, completed);
    } catch (error) {
      if (mounted && widget.session == session) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localWriteErrorMessage(error, AppLocalizations.of(context)!),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    canCompleteCard(widget.board, widget.card) && !_saving ? _set : null,
    _saving,
  );
}
