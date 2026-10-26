import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

JsonObject activity(int id, {int cardId = 8, String type = 'deck_card'}) => {
  'activity_id': id,
  'datetime': '2026-10-24T12:00:00+00:00',
  'subject': 'You moved the card',
  'user': 'alice',
  'object_type': type,
  'object_id': cardId,
};

http.Response ocsReply(Object? data, [int status = 200]) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': data,
    },
  }),
  status,
  headers: {'content-type': 'application/json'},
);

DeckClient client(http.Client transport) => DeckClient(
  base: ServerBase.parse('https://cloud.example.com/nextcloud'),
  loginName: 'login-alias',
  appPassword: 'test-password',
  transport: transport,
);

void main() {
  group('card activity', () {
    test('requests the deck_card filter and pages with since', () async {
      final requests = <Uri>[];
      final api = client(
        MockClient((request) async {
          requests.add(request.url);
          return ocsReply(
            requests.length == 1
                ? [activity(30), activity(20)]
                : [activity(10)],
          );
        }),
      );
      final first = await api.cardActivity(8, limit: 2);
      final second = await api.cardActivity(8, since: first.next, limit: 2);
      expect(
        requests.first.path,
        endsWith('/apps/activity/api/v2/activity/filter'),
      );
      expect(
        requests.first.queryParameters,
        allOf(
          containsPair('object_type', 'deck_card'),
          containsPair('object_id', '8'),
          containsPair('limit', '2'),
          containsPair('sort', 'desc'),
          isNot(contains('since')),
        ),
      );
      expect(requests.last.queryParameters['since'], '20');
      expect(first.items.map((a) => a.id), [30, 20]);
      expect(first.items.first.subject, 'You moved the card');
      expect(first.items.first.user, 'alice');
      expect(second.items.map((a) => a.id), [10]);
      expect(second.next, isNull);
    });

    test('an empty stream and a 304 at the end both finish the list', () async {
      final empty = client(MockClient((_) async => http.Response('', 204)));
      expect((await empty.cardActivity(8)).items, isEmpty);
      final end = client(MockClient((_) async => http.Response('', 304)));
      final page = await end.cardActivity(8, since: 5);
      expect(page.items, isEmpty);
      expect(page.next, isNull);
    });

    test('activities of another object are rejected', () async {
      final api = client(
        MockClient((_) async => ocsReply([activity(1, cardId: 9)])),
      );
      expect(
        api.cardActivity(8),
        throwsA(
          isA<DeckException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    });
  });

  group('capabilities', () {
    JsonObject caps(Object? activity) => {
      'deck': {
        'version': '1.19.0',
        'apiVersions': ['1.1'],
      },
      'activity': ?activity,
    };

    test('activity is offered only with filters-api', () {
      expect(
        DeckCapabilities.fromJson(
          caps({
            'apiv2': ['filters', 'filters-api'],
          }),
        ).supportsActivity,
        isTrue,
      );
      expect(DeckCapabilities.fromJson(caps(null)).supportsActivity, isFalse);
      expect(
        DeckCapabilities.fromJson(
          caps({
            'apiv2': ['filters'],
          }),
        ).supportsActivity,
        isFalse,
      );
    });
  });
}
