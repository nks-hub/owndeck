import 'client.dart';
import 'models.dart';

final class CardUpdateRequest {
  CardUpdateRequest.fromCard(
    DeckCard card, {
    required int boardId,
    JsonObject changes = const {},
  }) : cardId = card.id,
       stackId = changes['stackId'] is int
           ? changes['stackId']! as int
           : card.stackId {
    if (card.id <= 0 || boardId <= 0 || stackId <= 0) {
      throw ArgumentError('invalid_card_identity');
    }
    const allowed = {
      'title',
      'description',
      'duedate',
      'startdate',
      'color',
      'done',
      'stackId',
      'order',
    };
    if (changes.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('invalid_card_changes');
    }
    for (final field in ['owner', 'type', 'description', 'duedate']) {
      if (!card.raw.containsKey(field)) {
        throw const FormatException('incomplete_card_snapshot');
      }
    }
    if (card.archived || (card.raw['deletedAt'] ?? 0) != 0) {
      throw StateError('card_unavailable');
    }
    body = Map.unmodifiable(
      card.updateBody({
        ...changes,
        'boardId': boardId,
        'stackId': stackId,
        // OCS treats an omitted done value as null, not as an unchanged field.
        'done': changes.containsKey('done')
            ? changes['done']
            : card.raw['done'],
        // Preserve flags: zero would restore a card deleted after the preflight GET.
        'deletedAt': null,
        'archived': null,
      }),
    );
  }

  factory CardUpdateRequest.transfer(
    DeckCard card, {
    required int destinationBoardId,
    required int destinationStackId,
    required int order,
    required Object? done,
  }) {
    if (order < 0) throw ArgumentError('invalid_card_position');
    for (final field in ['startdate', 'color', 'done']) {
      if (!card.raw.containsKey(field)) {
        throw const FormatException('incomplete_card_snapshot');
      }
    }
    return CardUpdateRequest.fromCard(
      card,
      boardId: destinationBoardId,
      changes: {'stackId': destinationStackId, 'order': order, 'done': done},
    );
  }

  final int cardId;
  final int stackId;
  late final JsonObject body;
}

extension DeckCardUpdates on DeckClient {
  Future<DeckCard> updateCardSafely(CardUpdateRequest request) async {
    final response = await ocs('PUT', [
      'apps',
      'deck',
      'api',
      'v1.0',
      'cards',
      '${request.cardId}',
    ], body: request.body);
    try {
      final card = DeckCard.fromJson(object(response.data));
      if (card.id != request.cardId || card.stackId != request.stackId) {
        throw const FormatException('invalid_card_identity');
      }
      return card;
    } on FormatException {
      throw const DeckException('invalid_response', uncertain: true);
    }
  }

  Future<void> reorderCard(
    int boardId,
    int stackId,
    int cardId,
    int order,
  ) async {
    if (boardId <= 0 || stackId <= 0 || cardId <= 0 || order < 0) {
      throw ArgumentError('invalid_card_position');
    }
    await ocs(
      'PUT',
      ['apps', 'deck', 'api', 'v1.0', 'cards', '$cardId', 'reorder'],
      body: {'boardId': boardId, 'stackId': stackId, 'order': order},
    );
  }
}
