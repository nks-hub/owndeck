import 'client.dart';
import 'models.dart';

// Nextcloud IComment::MAX_MESSAGE_LENGTH, stable35.
const deckCommentMaxLength = 1000;

// Nextcloud Comment::getMentions: @uid, or @"uid" when the uid contains a space.
final _mentionPattern = RegExp(
  r"""\B(?<![^a-z0-9_\-@.'\s])@("[a-z0-9_\-@.' ]+"|[a-z0-9_\-@.']+)""",
  caseSensitive: false,
);

/// A user mention inside a comment message, `start` to `end` includes the `@`.
final class DeckMention {
  const DeckMention(this.userId, this.start, this.end);
  final String userId;
  final int start;
  final int end;
}

List<DeckMention> findMentions(String message) => [
  for (final match in _mentionPattern.allMatches(message))
    DeckMention(match[1]!.replaceAll('"', ''), match.start, match.end),
];

/// Text to insert for mentioning [userId], quoted when it contains a space.
String mentionToken(String userId) =>
    RegExp(r"^[a-z0-9_\-@.']+$", caseSensitive: false).hasMatch(userId)
    ? '@$userId'
    : '@"$userId"';

final class DeckShareTarget {
  const DeckShareTarget({
    required this.id,
    required this.label,
    required this.type,
  });
  final String id;
  final String label;
  final int type;
}

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

  /// Display names the server resolved for mentioned users, by user id.
  Map<String, String> get mentionNames => {
    if (raw['mentions'] case final List mentions)
      for (final m in mentions)
        if (m is Map &&
            m['mentionType'] == 'user' &&
            m['mentionId'] is String &&
            m['mentionDisplayName'] is String &&
            (m['mentionDisplayName'] as String).isNotEmpty)
          m['mentionId'] as String: m['mentionDisplayName'] as String,
  };

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
  Future<List<DeckShareTarget>> searchDeckRecipients(String term) async {
    final response = await ocs(
      'GET',
      ['core', 'autocomplete', 'get'],
      query: {
        'search': term,
        'itemType': 'deck',
        'limit': '20',
        'shareTypes[0]': '0',
        'shareTypes[1]': '1',
        'shareTypes[2]': '6',
        'shareTypes[3]': '7',
      },
    );
    const types = {
      'users': 0,
      'groups': 1,
      'remotes': 6,
      'circles': 7,
      'teams': 7,
    };
    final result = <String, DeckShareTarget>{};
    for (final item in objects(response.data)) {
      final type = types[item['source']];
      if (type == null) continue;
      final id = stringField(item, 'id');
      final label = item['displayname'] ?? item['name'] ?? item['label'] ?? id;
      if (label is! String || id.isEmpty) {
        throw const DeckException('invalid_response');
      }
      result['$type:$id'] = DeckShareTarget(id: id, label: label, type: type);
    }
    return result.values.toList();
  }

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
