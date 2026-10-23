final class ServerBase {
  ServerBase._(this.uri);

  factory ServerBase.parse(String input) {
    final uri = Uri.tryParse(input.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('invalid_server');
    }
    final segments = uri.pathSegments.toList();
    if (segments.isNotEmpty && segments.last.isEmpty) segments.removeLast();
    if (segments.any(
      (segment) =>
          segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.contains('/') ||
          segment.contains('\\') ||
          segment.runes.any((c) => c < 32 || c == 127),
    )) {
      throw const FormatException('invalid_server_path');
    }
    return ServerBase._(uri.replace(pathSegments: [...segments, '']));
  }

  final Uri uri;

  Uri endpoint(List<String> path, [Map<String, String>? query]) => uri.replace(
    pathSegments: [...uri.pathSegments.where((s) => s.isNotEmpty), ...path],
    queryParameters: query == null || query.isEmpty ? null : query,
  );

  Uri deck(String version, List<String> path, [Map<String, String>? query]) =>
      endpoint([
        'index.php',
        'apps',
        'deck',
        'api',
        'v$version',
        ...path,
      ], query);

  Uri ocs(List<String> path, [Map<String, String>? query]) =>
      endpoint(['ocs', 'v2.php', ...path], {'format': 'json', ...?query});
}
