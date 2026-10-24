import 'server_base.dart';

final class DeckCardLink {
  const DeckCardLink({
    required this.server,
    required this.boardId,
    required this.cardId,
  });
  final ServerBase server;
  final int boardId;
  final int cardId;

  Uri get webUri {
    if (boardId <= 0 || cardId <= 0) throw ArgumentError('invalid_card_link');
    return server.endpoint([
      'index.php',
      'apps',
      'deck',
      'board',
      '$boardId',
      'card',
      '$cardId',
    ]);
  }

  Uri get appUri => Uri(
    scheme: 'ncdeck',
    host: 'open',
    queryParameters: {'uri': webUri.toString()},
  );

  @override
  String toString() => 'DeckCardLink(redacted)';
}

DeckCardLink? parseDeckCardLink(String input) {
  if (input.length > 4096 ||
      input.runes.any((c) => c < 32 || c == 127) ||
      input.contains('\\')) {
    return null;
  }
  try {
    var raw = input.trim();
    var uri = Uri.parse(raw);
    if (uri.scheme == 'ncdeck') {
      if (uri.host != 'open' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          !{'', '/'}.contains(uri.path) ||
          uri.hasFragment ||
          uri.queryParametersAll.keys.length != 1 ||
          uri.queryParametersAll['uri']?.length != 1) {
        return null;
      }
      raw = uri.queryParametersAll['uri']!.single;
      uri = Uri.parse(raw);
    }
    if (uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        raw.contains('\\') ||
        raw.runes.any((c) => c < 32 || c == 127) ||
        RegExp(r'%(?![0-9a-fA-F]{2})').hasMatch(raw) ||
        RegExp(r'/(?:\.|%2e){1,2}(?:/|$)', caseSensitive: false).hasMatch(raw)) {
      return null;
    }
    final segments = uri.pathSegments.toList();
    if (segments.lastOrNull == '') segments.removeLast();
    if (segments.any(_badSegment)) return null;
    var marker = -1;
    for (var index = 0; index + 1 < segments.length; index++) {
      if (segments[index] == 'apps' && segments[index + 1] == 'deck') {
        marker = index;
      }
    }
    if (marker < 0) return null;
    var route = segments.sublist(marker + 2);
    if (uri.hasFragment) {
      if (route.isNotEmpty || !uri.fragment.startsWith('/')) return null;
      final fragment = Uri.parse(uri.fragment);
      if (fragment.hasAuthority ||
          fragment.hasScheme ||
          fragment.hasQuery ||
          fragment.hasFragment) {
        return null;
      }
      route = fragment.pathSegments.toList();
      if (route.lastOrNull == '') route.removeLast();
    }
    if (route.any(_badSegment)) return null;
    if (route.firstOrNull == '!') route.removeAt(0);
    if (route.length != 4) return null;
    if (!((route[0] == 'board' && route[2] == 'card') ||
        (route[0] == 'boards' && route[2] == 'cards'))) {
      return null;
    }
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(route[1]) ||
        !RegExp(r'^[1-9][0-9]*$').hasMatch(route[3])) {
      return null;
    }
    final board = int.tryParse(route[1]);
    final card = int.tryParse(route[3]);
    if (board == null || card == null || board <= 0 || card <= 0) return null;
    final prefix = segments.sublist(0, marker);
    if (prefix.lastOrNull == 'index.php') prefix.removeLast();
    final server = ServerBase.parse(
      uri
          .replace(pathSegments: [...prefix, ''], fragment: '')
          .toString()
          .replaceFirst(RegExp(r'#$'), ''),
    );
    return DeckCardLink(server: server, boardId: board, cardId: card);
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}

bool _badSegment(String value) =>
    value.isEmpty ||
    value == '.' ||
    value == '..' ||
    value.contains('/') ||
    value.contains('\\') ||
    value.runes.any((c) => c < 32 || c == 127);
