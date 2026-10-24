import 'client.dart';
import 'models.dart';

// Nextcloud IComment::MAX_MESSAGE_LENGTH, stable35.
const deckCommentMaxLength = 1000;

final class DeckComment {
  DeckComment.fromJson(JsonObject json)
    : id = intField(json, 'id'),
      cardId = intField(json, 'objectId'),
      message = stringField(json, 'message'),
      actorId = stringField(json, 'actorId'),
      actorType = stringField(json, 'actorType'),
      actorName = json['actorDisplayName'] is String
          ? json['actorDisplayName'] as String
          : stringField(json, 'actorId'),
      created = DateTime.parse(stringField(json, 'creationDateTime')),
      raw = Map.unmodifiable(json);
  final int id;
  final int cardId;
  final String message;
  final String actorId;
  final String actorType;
  final String actorName;
  final DateTime created;
  final JsonObject raw;
}

extension DeckCollaborationClient on DeckClient {
  Future<String> currentUserId() async {
    final data = object((await ocs('GET', ['cloud', 'user'])).data);
    final id = stringField(data, 'id');
    if (id.isEmpty) throw const DeckException('invalid_response');
    return id;
  }

  Stream<List<DeckComment>> commentPages(
    int cardId, {
    int pageSize = 100,
  }) async* {
    if (pageSize < 1 || pageSize > 200) {
      throw ArgumentError('invalid_page_size');
    }
    final seen = <int>{};
    for (var offset = 0; ; offset += pageSize) {
      final result = await ocs(
        'GET',
        ['apps', 'deck', 'api', 'v1.0', 'cards', '$cardId', 'comments'],
        query: {'limit': '$pageSize', 'offset': '$offset'},
      );
      List<DeckComment> page;
      try {
        page = objects(result.data).map(DeckComment.fromJson).toList();
      } on FormatException {
        throw const DeckException('invalid_response');
      }
      if (page.any((comment) => comment.cardId != cardId)) {
        throw const DeckException('comment_card_mismatch');
      }
      if (page.isNotEmpty &&
          page.every((comment) => seen.contains(comment.id))) {
        throw const DeckException('pagination_repeated');
      }
      seen.addAll(page.map((comment) => comment.id));
      yield page;
      if (page.length < pageSize) return;
    }
  }
}
