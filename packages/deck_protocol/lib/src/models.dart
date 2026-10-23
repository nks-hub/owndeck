typedef JsonObject = Map<String, Object?>;

JsonObject object(Object? value) {
  if (value is! JsonObject) throw const FormatException('invalid_object');
  return value;
}

List<JsonObject> objects(Object? value) {
  if (value is! List) throw const FormatException('invalid_list');
  return value.map(object).toList(growable: false);
}

String stringField(JsonObject json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('invalid_$key');
  return value;
}

int intField(JsonObject json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('invalid_$key');
  return value;
}

final class DeckCapabilities {
  const DeckCapabilities({
    required this.version,
    required this.apiVersion,
    required this.canCreateBoards,
  });

  factory DeckCapabilities.fromJson(JsonObject capabilities) {
    final deck = object(capabilities['deck']);
    final versions = deck['apiVersions'];
    if (versions is! List || !versions.contains('1.1')) {
      throw const FormatException('unsupported_deck_api');
    }
    return DeckCapabilities(
      version: stringField(deck, 'version'),
      apiVersion: '1.1',
      canCreateBoards: deck['canCreateBoards'] == true,
    );
  }

  final String version;
  final String apiVersion;
  final bool canCreateBoards;
}

final class BoardPermissions {
  const BoardPermissions({
    required this.read,
    required this.edit,
    required this.manage,
    required this.share,
  });

  factory BoardPermissions.fromJson(JsonObject json) => BoardPermissions(
    read: json['PERMISSION_READ'] == true,
    edit: json['PERMISSION_EDIT'] == true,
    manage: json['PERMISSION_MANAGE'] == true,
    share: json['PERMISSION_SHARE'] == true,
  );

  final bool read;
  final bool edit;
  final bool manage;
  final bool share;
}

final class DeckBoard {
  DeckBoard.fromJson(JsonObject json)
    : id = intField(json, 'id'),
      title = stringField(json, 'title'),
      color = stringField(json, 'color'),
      archived = json['archived'] == true,
      deletedAt = intField(json, 'deletedAt'),
      permissions = BoardPermissions.fromJson(object(json['permissions'])),
      raw = Map.unmodifiable(json);

  final int id;
  final String title;
  final String color;
  final bool archived;
  final int deletedAt;
  final BoardPermissions permissions;
  final JsonObject raw;
}

final class DeckStack {
  DeckStack.fromJson(JsonObject json)
    : id = intField(json, 'id'),
      boardId = intField(json, 'boardId'),
      title = stringField(json, 'title'),
      order = intField(json, 'order'),
      cards = objects(
        json['cards'],
      ).map(DeckCard.fromJson).toList(growable: false);

  final int id;
  final int boardId;
  final String title;
  final int order;
  final List<DeckCard> cards;
}

final class DeckCard {
  DeckCard.fromJson(JsonObject json)
    : id = intField(json, 'id'),
      stackId = intField(json, 'stackId'),
      title = stringField(json, 'title'),
      description = stringField(json, 'description'),
      order = intField(json, 'order'),
      archived = json['archived'] == true,
      raw = Map.unmodifiable(json);

  final int id;
  final int stackId;
  final String title;
  final String description;
  final int order;
  final bool archived;
  final JsonObject raw;

  // REST update defaults clear omitted fields; preserve the full writable state.
  JsonObject updateBody(JsonObject changes) {
    final owner = raw['owner'];
    final ownerId = owner is String ? owner : stringField(object(owner), 'uid');
    return {
      'title': title,
      'type': stringField(raw, 'type'),
      'owner': ownerId,
      'description': description,
      'order': order,
      'duedate': raw['duedate'],
      if (raw.containsKey('startdate')) 'startdate': raw['startdate'],
      'archived': archived,
      if (raw.containsKey('done')) 'done': raw['done'],
      if (raw.containsKey('color')) 'color': raw['color'],
      ...changes,
    };
  }
}
