import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

JsonObject card(int id, int stackId, {bool archived = false}) => {
  'id': id,
  'stackId': stackId,
  'title': 'Task',
  'description': 'Text',
  'order': 0,
  'type': 'plain',
  'owner': 'user',
  'archived': archived,
};
JsonObject stack(int id, {bool done = false, List<JsonObject>? cards}) => {
  'id': id,
  'boardId': 1,
  'title': 'Column',
  'order': id,
  'isDoneColumn': done,
  'cards': ?cards,
};
http.Response json(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);
Object ocs(Object? data) => {
  'ocs': {
    'meta': {'status': 'ok', 'statuscode': 200},
    'data': data,
  },
};
DeckClient api(Future<http.Response> Function(http.Request) request) =>
    DeckClient(
      base: ServerBase.parse('https://cloud.example.com/nextcloud'),
      loginName: 'user',
      appPassword: 'test-password',
      transport: MockClient(request),
    );

void main() {
  test(
    'stack reorder uses OCS and accepts indexed object acknowledgements',
    () async {
      await api((request) async {
        expect(request.method, 'PUT');
        expect(
          request.url.path,
          '/nextcloud/ocs/v2.php/apps/deck/api/v1.0/stacks/2/reorder',
        );
        expect(jsonDecode(request.body), {'boardId': 1, 'order': 0});
        expect(request.followRedirects, isFalse);
        return json(ocs({'1': stack(3), '0': stack(2)}));
      }).reorderStack(1, 2, 0);
    },
  );

  test(
    'clone uses the OCS route with its documented bare-card response',
    () async {
      final copied = await api((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/nextcloud/ocs/v2.php/apps/deck/api/v1.0/cards/8/clone',
        );
        expect(jsonDecode(request.body), {'targetStackId': 4});
        expect(request.followRedirects, isFalse);
        return json(card(20, 4));
      }).cloneCard(8, 4);
      expect(copied.id, 20);
      expect(copied.stackId, 4);
    },
  );

  test('a malformed clone receipt remains an uncertain mutation', () async {
    await expectLater(
      api((_) async => json(card(8, 4))).cloneCard(8, 4),
      throwsA(
        isA<DeckException>().having((e) => e.uncertain, 'uncertain', isTrue),
      ),
    );
  });

  test('done-column request keeps board identity and boolean intent', () async {
    await api((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, endsWith('/stacks/2/done'));
      expect(jsonDecode(request.body), {'boardId': 1, 'isDone': true});
      return json(ocs([]));
    }).setDoneStack(1, 2, true);
  });

  test(
    'done read-back combines active and archived cards without losing empty stacks',
    () async {
      final result = await api(
        (request) async => json(
          request.url.path.endsWith('/archived')
              ? [
                  stack(2, done: true, cards: [card(9, 2, archived: true)]),
                ]
              : [
                  stack(2, done: true, cards: [card(8, 2)]),
                  stack(3),
                ],
        ),
      ).doneStackState(1);
      expect(result.first.cards.map((c) => c.id), [8, 9]);
      expect(result.last.cards, isEmpty);
      expect(result.first.isDoneColumn, isTrue);
      expect(result.last.supportsDoneColumn, isTrue);
    },
  );

  test(
    'missing notification capability avoids an unsupported endpoint',
    () async {
      var requests = 0;
      final result = await api((_) async {
        requests++;
        return json(ocs({'capabilities': {}}));
      }).notifications();
      expect(result.supported, isFalse);
      expect(requests, 1);
    },
  );

  test('notification 204 is empty and foreign apps are never exposed', () async {
    for (final empty in [true, false]) {
      final result = await api((request) async {
        if (request.url.path.endsWith('/capabilities')) {
          return json(
            ocs({
              'capabilities': {
                'notifications': {
                  'ocs-endpoints': ['list'],
                },
              },
            }),
          );
        }
        return empty
            ? http.Response('', 204)
            : json(
                ocs([
                  {'app': 'other', 'subject': 'Private other-app message'},
                  {
                    'notification_id': 1,
                    'app': 'deck',
                    'subject': 'Card updated',
                    'message': '',
                    'datetime': '2026-01-02T10:00:00Z',
                    'link':
                        'https://cloud.example.com/nextcloud/index.php/apps/deck/board/1/card/8',
                  },
                ]),
              );
      }).notifications();
      expect(result.supported, isTrue);
      expect(result.items.length, empty ? 0 : 1);
      if (!empty) expect(result.items.single.subject, 'Card updated');
    }
  });

  test('notification links stay on the account Deck installation', () {
    final base = ServerBase.parse('https://cloud.example.com/nextcloud');
    DeckNotification item(String link) => DeckNotification.fromJson({
      'notification_id': 1,
      'subject': 'Update',
      'message': '',
      'datetime': '2026-01-01T00:00:00Z',
      'link': link,
    });
    expect(
      item(
        'https://cloud.example.com/nextcloud/index.php/apps/deck/board/1/card/8',
      ).deckLink(base),
      isNotNull,
    );
    for (final link in [
      'https:invalid',
      'javascript:alert(1)',
      'https://other.example.com/nextcloud/apps/deck',
      'https://cloud.example.com/apps/deck',
      'https://cloud.example.com/nextcloud/logout',
      'https://user@cloud.example.com/nextcloud/apps/deck',
    ]) {
      expect(item(link).deckLink(base), isNull);
    }
  });
}
