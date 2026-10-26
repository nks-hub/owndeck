import 'package:deck_protocol/deck_protocol.dart';
import 'package:drift/drift.dart';

import 'database.dart';

enum CardDueFilter { any, today, overdue, noDate }

final class CardSearchOptions {
  const CardSearchOptions({
    this.query = '',
    this.mineOnly = false,
    this.includeArchived = false,
    this.includeCompleted = false,
    this.due = CardDueFilter.any,
  });

  final String query;
  final bool mineOnly;
  final bool includeArchived;
  final bool includeCompleted;
  final CardDueFilter due;
}

final class CardSearchHit {
  const CardSearchHit({
    required this.board,
    required this.stack,
    required this.card,
  });
  final DeckBoard board;
  final DeckStack stack;
  final DeckCard card;

  DateTime? get due =>
      DateTime.tryParse(card.raw['duedate']?.toString() ?? '')?.toLocal();
  bool get completed => card.raw['done'] != null;
  bool get archived => board.archived || card.archived;
}

final class CardSearchResult {
  const CardSearchResult({
    required this.hits,
    required this.accountAvailable,
    required this.identityKnown,
    this.uncachedBoards = 0,
  });
  final List<CardSearchHit> hits;
  final bool accountAvailable;
  final bool identityKnown;

  /// Searched boards whose cards were never saved on this device.
  final int uncachedBoards;
}

extension DeckCardSearch on DeckDatabase {
  Stream<CardSearchResult> watchCardSearch(
    String accountId,
    CardSearchOptions options, {
    DateTime? now,
  }) => customSelect(
    'SELECT id FROM stored_accounts WHERE id = ?',
    variables: [Variable(accountId)],
    readsFrom: {
      storedAccounts,
      storedBoards,
      storedStacks,
      storedCards,
      pendingWrites,
    },
  ).watch().asyncMap((_) => searchCards(accountId, options, now: now));

  Future<CardSearchResult> searchCards(
    String accountId,
    CardSearchOptions options, {
    DateTime? now,
  }) => transaction(() async {
    final current = await account(accountId);
    if (current == null || current.state == 'deleting') {
      return const CardSearchResult(
        hits: [],
        accountAvailable: false,
        identityKnown: false,
      );
    }
    final uid = current.userId;
    final identityKnown = uid != null && uid.isNotEmpty;
    if (options.mineOnly && !identityKnown) {
      return const CardSearchResult(
        hits: [],
        accountAvailable: true,
        identityKnown: false,
      );
    }
    final terms = options.query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    final localNow = (now ?? DateTime.now()).toLocal();
    final start = DateTime(localNow.year, localNow.month, localNow.day);
    // Calendar construction keeps today correct across 23- and 25-hour days.
    final end = DateTime(localNow.year, localNow.month, localNow.day + 1);
    final hits = <CardSearchHit>[];
    final deletedBoards = <int>{};
    final deletedStacks = <int>{};
    final deletedCards = <int>{};
    var uncachedBoards = 0;
    for (final write in await writesFor(accountId)) {
      if (write.kind == 'deleteBoard') {
        deletedBoards.add(
          await resolveId(accountId, write.boardId, 'createBoard') ??
              write.boardId,
        );
      }
      if (write.kind == 'deleteStack') {
        deletedStacks.add(
          await resolveId(accountId, write.stackId, 'createStack') ??
              write.stackId,
        );
      }
      if (write.kind == 'deleteCard' && write.cardId != null) {
        deletedCards.add(
          await resolveId(accountId, write.cardId!, 'createCard') ??
              write.cardId!,
        );
      }
    }
    for (final board in await boardView(accountId)) {
      if (!board.permissions.read ||
          board.deletedAt != 0 ||
          deletedBoards.contains(board.id) ||
          board.archived && !options.includeArchived) {
        continue;
      }
      if (await checkpoint(accountId, 'board:${board.id}') == null) {
        uncachedBoards++;
      }
      for (final stack in await stackView(accountId, board.id)) {
        if (deletedStacks.contains(stack.id) ||
            (stack.raw['deletedAt'] ?? 0) != 0) {
          continue;
        }
        for (final card in stack.cards) {
          if ((card.raw['deletedAt'] ?? 0) != 0 ||
              deletedCards.contains(card.id) ||
              card.archived && !options.includeArchived) {
            continue;
          }
          final hit = CardSearchHit(board: board, stack: stack, card: card);
          if (hit.completed && !options.includeCompleted) continue;
          if (options.mineOnly && !cardAssignedTo(card, uid!)) continue;
          final due = hit.due;
          final matchesDate = switch (options.due) {
            CardDueFilter.any => true,
            CardDueFilter.today =>
              due != null && !due.isBefore(start) && due.isBefore(end),
            CardDueFilter.overdue => due != null && due.isBefore(localNow),
            CardDueFilter.noDate =>
              card.raw['duedate'] == null || card.raw['duedate'] == '',
          };
          if (!matchesDate) continue;
          final labels = card.raw['labels'];
          final haystack = [
            card.title,
            card.description,
            board.title,
            stack.title,
            if (labels is List)
              ...labels.whereType<JsonObject>().map(
                (label) => label['title']?.toString() ?? '',
              ),
          ].join('\n').toLowerCase();
          if (!terms.every(haystack.contains)) continue;
          hits.add(hit);
        }
      }
    }
    hits.sort((a, b) {
      final left = a.due;
      final right = b.due;
      if (left != null && right == null) return -1;
      if (left == null && right != null) return 1;
      final date = left == null || right == null ? 0 : left.compareTo(right);
      if (date != 0) return date;
      final name = a.card.title.toLowerCase().compareTo(
        b.card.title.toLowerCase(),
      );
      if (name != 0) return name;
      final board = a.board.id.compareTo(b.board.id);
      return board != 0 ? board : a.card.id.compareTo(b.card.id);
    });
    return CardSearchResult(
      hits: List.unmodifiable(hits),
      accountAvailable: true,
      identityKnown: identityKnown,
      uncachedBoards: uncachedBoards,
    );
  });
}

bool cardAssignedTo(DeckCard card, String uid) {
  final assigned = card.raw['assignedUsers'];
  final Iterable<JsonObject> entries = switch (assigned) {
    List values => values.whereType<JsonObject>(),
    JsonObject values => values.values.whereType<JsonObject>(),
    _ => const [],
  };
  return entries.any((entry) {
    if ((entry['type'] ?? 0) != 0) return false;
    final participant = entry['participant'];
    final id = participant is String
        ? participant
        : participant is JsonObject
        ? participant['uid'] ?? participant['primaryKey']
        : null;
    return id == uid;
  });
}
