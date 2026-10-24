import 'models.dart';

final class DeckAttachment {
  DeckAttachment.fromJson(JsonObject json)
    : id = intField(json, 'id'),
      cardId = intField(json, 'cardId'),
      type = stringField(json, 'type'),
      name = json['data'] is String ? json['data'] as String : '',
      deletedAt = json['deletedAt'] == null ? 0 : intField(json, 'deletedAt'),
      modified = json['lastModified'] == null
          ? 0
          : intField(json, 'lastModified'),
      extended = json['extendedData'] is JsonObject
          ? object(json['extendedData'])
          : const {},
      raw = Map.unmodifiable(json);

  final int id;
  final int cardId;
  final String type;
  final String name;
  final int deletedAt;
  final int modified;
  final JsonObject extended;
  final JsonObject raw;
  bool get supported => type == 'file' || type == 'deck_file';
  bool get canRestore => type == 'deck_file' && deletedAt != 0;
  int? get size =>
      extended['filesize'] is int && (extended['filesize'] as int) >= 0
      ? extended['filesize'] as int
      : null;
  String? get mime =>
      extended['mimetype'] is String ? extended['mimetype'] as String : null;
  String? get path =>
      extended['path'] is String ? extended['path'] as String : null;
}

final class CloudFile {
  const CloudFile({
    required this.segments,
    required this.directory,
    required this.readable,
    required this.shareable,
    this.size,
    this.mime,
    this.id,
  });
  final List<String> segments;
  final bool directory;
  final bool readable;
  final bool shareable;
  final int? size;
  final String? mime;
  final int? id;
  String get name => segments.last;
  String get path => '/${segments.join('/')}';
}
