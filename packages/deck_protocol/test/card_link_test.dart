import 'package:deck_protocol/deck_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('web and app links preserve the installation prefix and identity', () {
    final link = DeckCardLink(
      server: ServerBase.parse('https://cloud.example.com/nextcloud'),
      boardId: 7,
      cardId: 9,
    );
    expect(
      link.webUri.toString(),
      'https://cloud.example.com/nextcloud/index.php/apps/deck/board/7/card/9',
    );
    for (final value in [
      link.webUri.toString(),
      link.appUri.toString(),
      'https://cloud.example.com/nextcloud/apps/deck/#/board/7/card/9',
      'https://cloud.example.com/nextcloud/apps/deck/boards/7/cards/9',
    ]) {
      final parsed = parseDeckCardLink(value)!;
      expect(parsed.server.uri, link.server.uri);
      expect(parsed.boardId, 7);
      expect(parsed.cardId, 9);
    }
    expect(link.toString(), 'DeckCardLink(redacted)');
  });

  for (final value in [
    'http://cloud.example.com/apps/deck/board/7/card/9',
    'https://user:test-password@cloud.example.com/apps/deck/board/7/card/9',
    'https://cloud.example.com/apps/deck/board/7/card/9?token=test-token',
    'https://cloud.example.com/nextcloud/../apps/deck/board/7/card/9',
    'https://cloud.example.com/nextcloud/%2e%2e/apps/deck/board/7/card/9',
    'https://cloud.example.com/nextcloud%2fother/apps/deck/board/7/card/9',
    'https://cloud.example.com/apps/deck/board/-7/card/9',
    'https://cloud.example.com/apps/deck/board/7/card/0',
    'https://cloud.example.com/apps/deckevil/board/7/card/9',
    'https://cloud.example.com/apps/deck/#//other.example.com/board/7/card/9',
    'https://cloud.example.com/apps/deck/#/board/7/card/9?token=x',
    'ncdeck://open?uri=https%3A%2F%2Fcloud.example.com&uri=other',
  ]) {
    test(
      'rejects an unsafe or ambiguous link: $value',
      () => expect(parseDeckCardLink(value), isNull),
    );
  }
}
