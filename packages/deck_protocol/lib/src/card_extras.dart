import 'client.dart';
import 'models.dart';
import 'server_base.dart';

final class DeckNotification {
  DeckNotification.fromJson(JsonObject json)
    : id = intField(json, 'notification_id'),
      subject = stringField(json, 'subject'),
      message = stringField(json, 'message'),
      created = DateTime.parse(stringField(json, 'datetime')),
      link = stringField(json, 'link');

  final int id;
  final String subject;
  final String message;
  final DateTime created;
  final String link;

  Uri? deckLink(ServerBase base) {
    final uri = Uri.tryParse(link);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.origin != base.uri.origin) {
      return null;
    }
    final prefix = base.uri.pathSegments
        .where((part) => part.isNotEmpty)
        .toList();
    final segments = uri.pathSegments;
    if (segments.any(
          (part) =>
              part == '.' ||
              part == '..' ||
              part.contains('/') ||
              part.contains('\\') ||
              part.runes.any((c) => c < 32 || c == 127),
        ) ||
        segments.length < prefix.length ||
        !Iterable<int>.generate(
          prefix.length,
        ).every((i) => segments[i] == prefix[i])) {
      return null;
    }
    final relative = segments.skip(prefix.length).toList();
    if (relative.firstOrNull == 'index.php') relative.removeAt(0);
    return relative.length >= 2 &&
            relative[0] == 'apps' &&
            relative[1] == 'deck'
        ? uri
        : null;
  }
}

final class DeckNotifications {
  const DeckNotifications({required this.supported, required this.items});
  final bool supported;
  final List<DeckNotification> items;
}

final class DeckActivity {
  DeckActivity.fromJson(JsonObject json)
    : id = intField(json, 'activity_id'),
      subject = stringField(json, 'subject'),
      user = json['user'] is String ? json['user'] as String : '',
      created = DateTime.parse(stringField(json, 'datetime')),
      objectType = stringField(json, 'object_type'),
      objectId = int.tryParse('${json['object_id']}') ?? 0;

  final int id;
  final String subject;
  final String user;
  final DateTime created;
  final String objectType;
  final int objectId;
}

final class DeckActivityPage {
  const DeckActivityPage(this.items, {this.next});
  final List<DeckActivity> items;

  /// Value for the `since` argument of the next page, null at the end.
  final int? next;
}

extension DeckCardExtras on DeckClient {
  /// Reads card history from the Activity app (`object_type` deck_card).
  Future<DeckActivityPage> cardActivity(
    int cardId, {
    int? since,
    int limit = 30,
  }) async {
    if (cardId <= 0 || limit < 1 || limit > 100) {
      throw ArgumentError('invalid_activity_request');
    }
    final DeckResponse response;
    try {
      response = await ocs(
        'GET',
        ['apps', 'activity', 'api', 'v2', 'activity', 'filter'],
        query: {
          'object_type': 'deck_card',
          'object_id': '$cardId',
          'limit': '$limit',
          'sort': 'desc',
          'since': ?since?.toString(),
        },
        allowNoContent: true,
      );
    } on DeckException catch (error) {
      // The server answers 304 when the end of the list was reached.
      if (error.status == 304) return const DeckActivityPage([]);
      rethrow;
    }
    try {
      final items = objects(response.data).map(DeckActivity.fromJson).toList();
      if (items.any(
        (a) => a.objectType != 'deck_card' || a.objectId != cardId,
      )) {
        throw const FormatException('activity_card_mismatch');
      }
      final last = items.isEmpty ? null : items.last.id;
      return DeckActivityPage(
        items,
        next:
            items.length >= limit &&
                last != null &&
                (since == null || last < since)
            ? last
            : null,
      );
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<void> reorderStack(int boardId, int stackId, int order) async {
    if (boardId <= 0 || stackId <= 0 || order < 0) {
      throw ArgumentError('invalid_stack_position');
    }
    await ocs(
      'PUT',
      ['apps', 'deck', 'api', 'v1.0', 'stacks', '$stackId', 'reorder'],
      body: {'boardId': boardId, 'order': order},
    );
  }

  Future<DeckCard> cloneCard(int cardId, int destinationStackId) async {
    if (cardId <= 0 || destinationStackId <= 0) {
      throw ArgumentError('invalid_clone_destination');
    }
    final result = await ocs(
      'POST',
      ['apps', 'deck', 'api', 'v1.0', 'cards', '$cardId', 'clone'],
      body: {'targetStackId': destinationStackId},
      envelope: false,
    );
    try {
      final card = DeckCard.fromJson(object(result.data));
      if (card.id <= 0 ||
          card.id == cardId ||
          card.stackId != destinationStackId) {
        throw const FormatException('invalid_clone_identity');
      }
      return card;
    } on FormatException {
      throw const DeckException('invalid_response', uncertain: true);
    }
  }

  Future<void> setDoneStack(int boardId, int stackId, bool isDone) async {
    if (boardId <= 0 || stackId <= 0) throw ArgumentError('invalid_done_stack');
    await ocs(
      'PUT',
      ['apps', 'deck', 'api', 'v1.0', 'stacks', '$stackId', 'done'],
      body: {'boardId': boardId, 'isDone': isDone},
    );
  }

  Future<List<DeckStack>> doneStackState(int boardId) async {
    final active = await stacks(boardId);
    final archived = await rest('GET', [
      'boards',
      '$boardId',
      'stacks',
      'archived',
    ]);
    try {
      final combined = <int, DeckStack>{};
      for (final stack in [
        ...active,
        ...objects(archived.data).map(DeckStack.fromJson),
      ]) {
        if (stack.boardId != boardId ||
            stack.cards.any((card) => card.stackId != stack.id)) {
          throw const FormatException('invalid_stack_identity');
        }
        final cards = {
          for (final card in combined[stack.id]?.cards ?? <DeckCard>[])
            card.id: card.raw,
          for (final card in stack.cards) card.id: card.raw,
        };
        combined[stack.id] = DeckStack.fromJson({
          ...stack.raw,
          'cards': cards.values.toList(),
        });
      }
      return combined.values.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<DeckNotifications> notifications() async {
    try {
      final capabilities = object(
        object(
          (await ocs('GET', ['cloud', 'capabilities'])).data,
        )['capabilities'],
      );
      final notificationCapabilities = capabilities['notifications'];
      if (notificationCapabilities == null) {
        return const DeckNotifications(supported: false, items: []);
      }
      final endpoints = object(notificationCapabilities)['ocs-endpoints'];
      if (endpoints is! List || !endpoints.contains('list')) {
        return const DeckNotifications(supported: false, items: []);
      }
      final response = await ocs('GET', [
        'apps',
        'notifications',
        'api',
        'v2',
        'notifications',
      ], allowNoContent: true);
      final items = objects(response.data)
          .where((item) => item['app'] == 'deck')
          .map(DeckNotification.fromJson)
          .toList();
      final ids = <int>{};
      if (items.any((item) => item.id <= 0 || !ids.add(item.id))) {
        throw const FormatException('invalid_notification_id');
      }
      items.sort((a, b) => b.created.compareTo(a.created));
      return DeckNotifications(supported: true, items: items);
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }
}
