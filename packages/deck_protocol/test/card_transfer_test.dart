import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

JsonObject source() => {
  'id': 8,
  'stackId': 2,
  'title': 'Current title',
  'description': 'Current description',
  'type': 'plain',
  'owner': {'uid': 'owner'},
  'order': 2,
  'archived': false,
  'deletedAt': 0,
  'duedate': '2030-02-03T15:30:00+01:00',
  'startdate': '2030-02-01T10:00:00+01:00',
  'color': '008080',
  'done': '2030-02-02T12:00:00+01:00',
};
http.Response reply(Object? value) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': value,
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);
DeckClient client(Future<http.Response> Function(http.Request) handler) =>
    DeckClient(
      base: ServerBase.parse('https://cloud.example.com/subdir'),
      loginName: 'user',
      appPassword: 'test-password',
      transport: MockClient(handler),
    );

void main() {
  test(
    'transfer uses full OCS update without changing content or resetting flags',
    () async {
      final card = DeckCard.fromJson(source());
      final request = CardUpdateRequest.transfer(
        card,
        destinationBoardId: 3,
        destinationStackId: 4,
        order: 12,
        done: card.raw['done'],
      );
      final moved = await client((sent) async {
        expect(sent.method, 'PUT');
        expect(sent.url.path, '/subdir/ocs/v2.php/apps/deck/api/v1.0/cards/8');
        expect(sent.followRedirects, isFalse);
        expect(jsonDecode(sent.body), {
        'id': 8,
          'boardId': 3,
          'stackId': 4,
          'title': 'Current title',
          'description': 'Current description',
          'type': 'plain',
          'owner': 'owner',
          'order': 12,
          'archived': null,
          'deletedAt': null,
          'duedate': card.raw['duedate'],
          'startdate': card.raw['startdate'],
          'color': '008080',
          'done': card.raw['done'],
        });
        return reply({...source(), 'stackId': 4, 'order': 12});
      }).updateCardSafely(request);
      expect(moved.id, 8);
      expect(moved.stackId, 4);
    },
  );

  test(
    'incomplete snapshots and unavailable cards fail before creating a request',
    () {
      final incomplete = source()..remove('startdate');
      expect(
        () => CardUpdateRequest.transfer(
          DeckCard.fromJson(incomplete),
          destinationBoardId: 3,
          destinationStackId: 4,
          order: 0,
          done: null,
        ),
        throwsFormatException,
      );
      expect(
        () => CardUpdateRequest.transfer(
          DeckCard.fromJson({...source(), 'deletedAt': 10}),
          destinationBoardId: 3,
          destinationStackId: 4,
          order: 0,
          done: null,
        ),
        throwsStateError,
      );
    },
  );

  test('a transfer receipt with another identity remains uncertain', () async {
    final request = CardUpdateRequest.transfer(
      DeckCard.fromJson(source()),
      destinationBoardId: 3,
      destinationStackId: 4,
      order: 0,
      done: null,
    );
    await expectLater(
      client(
        (_) async => reply({...source(), 'id': 99, 'stackId': 4}),
      ).updateCardSafely(request),
      throwsA(
        isA<DeckException>().having((e) => e.uncertain, 'uncertain', isTrue),
      ),
    );
  });

  test(
    'positioning uses the destination OCS reorder route after transfer',
    () async {
      await client((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.path,
          '/subdir/ocs/v2.php/apps/deck/api/v1.0/cards/8/reorder',
        );
        expect(jsonDecode(request.body), {
          'boardId': 3,
          'stackId': 4,
          'order': 1,
        });
        return reply([]);
      }).reorderCard(3, 4, 8, 1);
    },
  );
}
