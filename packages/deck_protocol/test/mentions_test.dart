import 'package:deck_protocol/deck_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('mentions', () {
    test('tokens quote a user id only when it needs it', () {
      expect(mentionToken('alice'), '@alice');
      expect(mentionToken('a.b-c@example.com'), '@a.b-c@example.com');
      expect(mentionToken('Jan Novak'), '@"Jan Novak"');
    });

    test('finds plain and quoted mentions like Nextcloud does', () {
      const message = 'Hi @alice and @"Jan Novak", mail a@b.cz @bob.';
      final found = findMentions(message);
      expect(found.map((m) => m.userId), ['alice', 'Jan Novak', 'bob.']);
      expect(message.substring(found[1].start, found[1].end), '@"Jan Novak"');
    });

    test('ignores an at sign inside an address', () {
      expect(findMentions('write to me@example.com'), isEmpty);
    });

    test('comment exposes server resolved display names', () {
      final comment = DeckComment.fromJson({
        'id': 1,
        'objectId': 8,
        'message': '@alice hi',
        'actorId': 'bob',
        'actorType': 'users',
        'creationDateTime': '2026-10-24T12:00:00Z',
        'mentions': [
          {
            'mentionId': 'alice',
            'mentionType': 'user',
            'mentionDisplayName': 'Alice A',
          },
          {'mentionId': 'g', 'mentionType': 'group', 'mentionDisplayName': 'G'},
          {'mentionId': 'x', 'mentionType': 'user', 'mentionDisplayName': ''},
        ],
      });
      expect(comment.mentionNames, {'alice': 'Alice A'});
    });
  });
}
