import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'board_moves.dart';
import 'card_move_dialog.dart';

/// Cards picked for a bulk action, keyed by card id.
class BoardSelection extends ChangeNotifier {
  final _cards = <int, DeckCard>{};

  bool get active => _cards.isNotEmpty;
  int get length => _cards.length;
  List<DeckCard> get cards => _cards.values.toList();
  bool contains(DeckCard card) => _cards.containsKey(card.id);

  void toggle(DeckCard card) {
    if (_cards.remove(card.id) == null) _cards[card.id] = card;
    notifyListeners();
  }

  /// Replaces stored cards with fresher copies and drops ones no longer shown.
  void refresh(Iterable<DeckCard> visible) {
    final fresh = {for (final card in visible) card.id: card};
    _cards.removeWhere((id, _) => !fresh.containsKey(id));
    _cards.updateAll((id, _) => fresh[id]!);
  }

  void drop(Set<int> ids) {
    _cards.removeWhere((id, _) => ids.contains(id));
    notifyListeners();
  }

  void clear() {
    if (_cards.isEmpty) return;
    _cards.clear();
    notifyListeners();
  }
}

class BoardSelectionScope extends InheritedNotifier<BoardSelection> {
  const BoardSelectionScope({
    super.key,
    required BoardSelection selection,
    required super.child,
  }) : super(notifier: selection);

  static BoardSelection? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BoardSelectionScope>()
      ?.notifier;
}

enum BulkStatus { queued, failed, blocked }

class BulkOutcome {
  const BulkOutcome(this.card, this.status, [this.error]);
  final DeckCard card;
  final BulkStatus status;
  final Object? error;
}

/// Runs [operation] for each card on its own; one failure never stops the rest.
Future<List<BulkOutcome>> runPerCard(
  List<DeckCard> cards,
  Future<void> Function(DeckCard card) operation,
) async {
  final outcomes = <BulkOutcome>[];
  for (final card in cards) {
    try {
      await operation(card);
      outcomes.add(BulkOutcome(card, BulkStatus.queued));
    } catch (error) {
      final denied =
          error is StateError && error.message == 'permission_denied';
      outcomes.add(
        BulkOutcome(
          card,
          denied ? BulkStatus.blocked : BulkStatus.failed,
          error,
        ),
      );
    }
  }
  return outcomes;
}

Future<List<BulkOutcome>> archiveEach(
  DeckSession session,
  DeckBoard board,
  List<DeckCard> cards,
) => runPerCard(
  cards,
  (card) => session.database.queueCardAction(
    session.account,
    board.id,
    card,
    'archiveCard',
    {},
  ),
);

/// Moves cards one by one so that the picked order survives at the destination.
Future<List<BulkOutcome>> moveEach(
  DeckSession session,
  DeckBoard board,
  List<DeckCard> cards,
  CardMoveDestination move,
) async {
  // Each card lands on the same spot, so top/after placements go in reverse.
  final reverse = move.anchorCardId == null ? move.before : !move.before;
  final outcomes = await runPerCard(
    reverse ? cards.reversed.toList() : cards,
    (card) => queueCardMoveTo(session, board, card, move),
  );
  return reverse ? outcomes.reversed.toList() : outcomes;
}

/// Runs a bulk action, reports every card and lets the user retry failures.
Future<void> runBulkAction(
  BuildContext context,
  BoardSelection selection,
  Future<List<BulkOutcome>> Function(List<DeckCard> cards) action,
) async {
  var pending = selection.cards;
  while (pending.isNotEmpty) {
    final outcomes = await action(pending);
    selection.drop({
      for (final outcome in outcomes)
        if (outcome.status == BulkStatus.queued) outcome.card.id,
    });
    if (!context.mounted) return;
    final failed = [
      for (final outcome in outcomes)
        if (outcome.status == BulkStatus.failed) outcome.card,
    ];
    if (outcomes.every((o) => o.status == BulkStatus.queued)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.bulkAllQueued(outcomes.length),
          ),
        ),
      );
      return;
    }
    final retry = await showDialog<bool>(
      context: context,
      builder: (_) => BulkResultDialog(outcomes: outcomes),
    );
    if (retry != true) return;
    pending = failed;
  }
}

class BulkResultDialog extends StatelessWidget {
  const BulkResultDialog({super.key, required this.outcomes});
  final List<BulkOutcome> outcomes;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    int count(BulkStatus status) =>
        outcomes.where((outcome) => outcome.status == status).length;
    final failed = count(BulkStatus.failed);
    return AlertDialog(
      scrollable: true,
      title: Text(text.bulkResultTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text.bulkSummary(
              count(BulkStatus.queued),
              failed,
              count(BulkStatus.blocked),
            ),
          ),
          for (final outcome in outcomes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(switch (outcome.status) {
                BulkStatus.queued => Icons.check_circle_outline,
                BulkStatus.failed => Icons.error_outline,
                BulkStatus.blocked => Icons.lock_outline,
              }),
              title: Text(outcome.card.title),
              subtitle: Text(switch (outcome.status) {
                BulkStatus.queued => text.bulkStatusQueued,
                BulkStatus.failed => text.bulkStatusFailed(
                  errorMessage(outcome.error!, text),
                ),
                BulkStatus.blocked => text.bulkStatusBlocked,
              }),
            ),
          Text(text.bulkSelectionKept),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(text.close),
        ),
        if (failed > 0)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(text.bulkRetryFailed(failed)),
          ),
      ],
    );
  }
}
