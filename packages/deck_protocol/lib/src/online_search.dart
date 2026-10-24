import 'client.dart';
import 'card_extras.dart';
import 'models.dart';

final class DeckSearchEntry {
  DeckSearchEntry.fromJson(JsonObject json)
    : card = DeckCard.fromJson(json),
      boardId = intField(json, 'boardId'),
      boardTitle = stringField(
        object(json['relatedBoard'] ?? json['board']),
        'title',
      ),
      boardArchived =
          json['relatedBoard'] is JsonObject &&
          object(json['relatedBoard'])['archived'] == true,
      stackTitle = json['relatedStack'] is JsonObject
          ? stringField(object(json['relatedStack']), 'title')
          : null {
    final board = object(json['relatedBoard'] ?? json['board']);
    final stack = json['relatedStack'];
    if (board['id'] != boardId ||
        stack is JsonObject &&
            (stack['id'] != card.stackId || stack['boardId'] != boardId)) {
      throw const FormatException('invalid_search_identity');
    }
  }
  final DeckCard card;
  final int boardId;
  final bool boardArchived;
  final String boardTitle;
  final String? stackTitle;
}

final class DeckSearchPage {
  const DeckSearchPage(this.items, {this.limited = false});
  final List<DeckSearchEntry> items;
  final bool limited;
}

final class DeckCardContext {
  const DeckCardContext({
    required this.board,
    required this.stack,
    required this.card,
  });
  final DeckBoard board;
  final DeckStack stack;
  final DeckCard card;
}

extension DeckOnlineSearch on DeckClient {
  Future<DeckSearchPage> searchCardsOnline(String query) async {
    if (query.length > 1024 || query.runes.any((c) => c < 32 || c == 127)) {
      throw ArgumentError('invalid_search');
    }
    final response = await ocs(
      'GET',
      ['apps', 'deck', 'api', 'v1.0', 'search'],
      query: {'term': query, 'limit': '200'},
    );
    try {
      final items = _searchEntries(objects(response.data));
      // The server cursor uses last_modified < timestamp, which can skip ties.
      return DeckSearchPage(items, limited: items.length >= 200);
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<DeckSearchPage> upcomingCards() async {
    final response = await ocs('GET', [
      'apps',
      'deck',
      'api',
      'v1.0',
      'overview',
      'upcoming',
    ]);
    try {
      if (response.data is List && (response.data as List).isEmpty) {
        return const DeckSearchPage([]);
      }
      final groups = object(response.data);
      const names = {
        'later',
        'nodue',
        'overdue',
        'today',
        'tomorrow',
        'nextSevenDays',
      };
      if (groups.keys.any((key) => !names.contains(key))) {
        throw const FormatException('invalid_overview');
      }
      return DeckSearchPage(
        _searchEntries([for (final value in groups.values) ...objects(value)]),
      );
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<DeckCardContext> readCardContext(
    int boardId,
    int cardId, {
    int? stackId,
  }) async {
    if (boardId <= 0 || cardId <= 0 || stackId != null && stackId <= 0) {
      throw ArgumentError('invalid_card_identity');
    }
    final board = DeckBoard.fromJson(
      object((await rest('GET', ['boards', '$boardId'])).data),
    );
    if (board.id != boardId ||
        !board.permissions.read ||
        board.deletedAt != 0) {
      throw const DeckException('permission_denied', status: 403);
    }
    DeckCard? card;
    if (stackId == null) {
      final all = await doneStackState(boardId);
      for (final stack in all) {
        final found = stack.cards
            .where((card) => card.id == cardId)
            .firstOrNull;
        if (found != null) {
          if (card != null) throw const DeckException('invalid_response');
          card = found;
          stackId = stack.id;
        }
      }
      if (card == null || stackId == null) {
        throw const DeckException('not_found', status: 404);
      }
    }
    final stack = DeckStack.fromJson(
      object(
        (await rest('GET', ['boards', '$boardId', 'stacks', '$stackId'])).data,
      ),
    );
    card = DeckCard.fromJson(
      object(
        (await rest('GET', [
          'boards',
          '$boardId',
          'stacks',
          '$stackId',
          'cards',
          '$cardId',
        ])).data,
      ),
    );
    if (stack.boardId != boardId ||
        stack.id != stackId ||
        card.id != cardId ||
        card.stackId != stackId ||
        (stack.raw['deletedAt'] ?? 0) != 0 ||
        (card.raw['deletedAt'] ?? 0) != 0) {
      throw const DeckException('invalid_response');
    }
    return DeckCardContext(board: board, stack: stack, card: card);
  }
}

List<DeckSearchEntry> _searchEntries(List<JsonObject> values) {
  final ids = <int>{};
  final result = values.map(DeckSearchEntry.fromJson).toList();
  if (result.any(
    (entry) =>
        entry.boardId <= 0 ||
        entry.card.id <= 0 ||
        entry.card.stackId <= 0 ||
        !ids.add(entry.card.id),
  )) {
    throw const FormatException('invalid_search_identity');
  }
  return List.unmodifiable(result);
}
