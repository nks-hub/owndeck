import 'database.dart';
import 'search.dart';

/// A cached card assigned to the account's user that has a due date.
final class DueReminder {
  const DueReminder({
    required this.accountId,
    required this.boardId,
    required this.cardId,
    required this.title,
    required this.boardTitle,
    required this.due,
  });
  final String accountId;
  final int boardId;
  final int cardId;
  final String title;
  final String boardTitle;
  final DateTime due;
}

extension DeckReminders on DeckDatabase {
  /// Open, non-archived cards assigned to each account's user with a due date,
  /// read from the local copy including changes still waiting in the outbox.
  /// Cards that exist only locally (no server id yet) are left out because a
  /// notification could not open them.
  Future<List<DueReminder>> dueReminders({DateTime? now}) async {
    final reminders = <DueReminder>[];
    for (final account in await accounts()) {
      if (account.state == 'deleting') continue;
      final result = await searchCards(
        account.id,
        const CardSearchOptions(mineOnly: true),
        now: now,
      );
      for (final hit in result.hits) {
        final due = hit.due;
        if (due == null || hit.card.id <= 0 || hit.board.id <= 0) continue;
        reminders.add(
          DueReminder(
            accountId: account.id,
            boardId: hit.board.id,
            cardId: hit.card.id,
            title: hit.card.title,
            boardTitle: hit.board.title,
            due: due.toUtc(),
          ),
        );
      }
    }
    return reminders;
  }

  Stream<List<DueReminder>> watchDueReminders() => customSelect(
    'SELECT id FROM stored_accounts',
    readsFrom: {
      storedAccounts,
      storedBoards,
      storedStacks,
      storedCards,
      pendingWrites,
    },
  ).watch().asyncMap((_) => dueReminders());
}
