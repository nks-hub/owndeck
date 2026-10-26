import 'client.dart';
import 'models.dart';
import 'server_base.dart';

/// One object linked to a card through a Nextcloud collaboration resource
/// (a "project"): a file, a Talk room, another card or a board.
final class ProjectResource {
  const ProjectResource({
    required this.type,
    required this.id,
    required this.name,
    this.link,
  });

  factory ProjectResource.fromJson(JsonObject json) => ProjectResource(
    type: stringField(json, 'type'),
    id: '${json['id']}',
    name: stringField(json, 'name'),
    link: json['link'] is String ? json['link'] as String : null,
  );

  final String type;
  final String id;
  final String name;
  final String? link;

  /// The target address resolved against [base]; only http and https without
  /// credentials are returned.
  Uri? openUri(ServerBase base) {
    final source = link;
    if (source == null || source.isEmpty) return null;
    final parsed = Uri.tryParse(source);
    if (parsed == null) return null;
    final uri = base.uri.resolveUri(parsed);
    return {'https', 'http'}.contains(uri.scheme) &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}

final class CardProject {
  const CardProject({
    required this.id,
    required this.name,
    required this.resources,
  });
  final int id;
  final String name;
  final List<ProjectResource> resources;
}

extension DeckCardProjects on DeckClient {
  /// Reads the projects a card belongs to from
  /// `GET ocs/v2.php/collaboration/resources/deck-card/{cardId}`.
  ///
  /// The server answers 404 when the card is not accessible or the resource
  /// type is unknown; callers treat that as "no projects". The card itself and
  /// projects without any other object are left out.
  Future<List<CardProject>> cardProjects(int cardId) async {
    if (cardId <= 0) throw ArgumentError('invalid_card');
    final response = await ocs('GET', [
      'collaboration',
      'resources',
      'deck-card',
      '$cardId',
    ]);
    try {
      final projects = <CardProject>[];
      for (final collection in objects(response.data)) {
        final resources = <ProjectResource>[];
        final seen = <String>{};
        final raw = collection['resources'];
        for (final item in raw is List ? raw : const []) {
          if (item is! Map<String, Object?>) continue;
          final ProjectResource resource;
          try {
            resource = ProjectResource.fromJson(item);
          } on FormatException {
            continue;
          }
          if (resource.type == 'deck-card' && resource.id == '$cardId') {
            continue;
          }
          if (seen.add('${resource.type}:${resource.id}')) {
            resources.add(resource);
          }
        }
        if (resources.isEmpty) continue;
        projects.add(
          CardProject(
            id: intField(collection, 'id'),
            name: stringField(collection, 'name'),
            resources: List.unmodifiable(resources),
          ),
        );
      }
      return List.unmodifiable(projects);
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }
}
