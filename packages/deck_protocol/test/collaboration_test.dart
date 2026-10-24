import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

JsonObject comment(int id, {int cardId = 8}) => {
  'id': id,
  'objectId': cardId,
  'message': 'Comment',
  'actorId': 'uid-1',
  'actorType': 'users',
  'creationDateTime': '2026-10-24T12:00:00Z',
};
http.Response ocsReply(Object? data) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': data,
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);
DeckClient client(http.Client transport) => DeckClient(
  base: ServerBase.parse('https://cloud.example.com/nextcloud'),
  loginName: 'login-alias',
  appPassword: 'test-password',
  transport: transport,
);

void main() {
  test(
    'Deck autocomplete maps users groups teams and federated recipients',
    () async {
      late Map<String, String> query;
      final api = client(
        MockClient((request) async {
          query = request.url.queryParameters;
          return ocsReply([
            {'id': 'user-a', 'label': 'User A', 'source': 'users'},
            {'id': 'group-a', 'label': 'Group A', 'source': 'groups'},
            {'id': 'team-a', 'label': 'Team A', 'source': 'teams'},
            {
              'id': 'person@example.com',
              'label': 'External',
              'source': 'remotes',
            },
            {'id': 'mail@example.com', 'label': 'Email', 'source': 'emails'},
          ]);
        }),
      );
      final targets = await api.searchDeckRecipients('project');
      expect(query['itemType'], 'deck');
      expect(query['shareTypes[2]'], '6');
      expect(targets.map((t) => t.type).toList(), [0, 1, 7, 6]);
    },
  );
  test(
    'comment pages advance offsets and preserve server author identity',
    () async {
      final offsets = <String?>[];
      final api = client(
        MockClient((request) async {
          offsets.add(request.url.queryParameters['offset']);
          return ocsReply(
            offsets.length == 1 ? [comment(3), comment(2)] : [comment(1)],
          );
        }),
      );
      final pages = await api.commentPages(8, pageSize: 2).toList();
      expect(offsets, ['0', '2']);
      expect(pages.expand((page) => page).map((c) => c.id).toList(), [3, 2, 1]);
      expect(pages.first.first.actorId, 'uid-1');
    },
  );

  test(
    'a server repeating a complete page cannot create an endless loop',
    () async {
      final api = client(MockClient((_) async => ocsReply([comment(1)])));
      await expectLater(
        api.commentPages(8, pageSize: 1).toList(),
        throwsA(
          isA<DeckException>().having(
            (e) => e.code,
            'code',
            'pagination_repeated',
          ),
        ),
      );
    },
  );

  test(
    'comments for another card are rejected before they enter the cache',
    () async {
      final api = client(
        MockClient((_) async => ocsReply([comment(1, cardId: 99)])),
      );
      await expectLater(
        api.commentPages(8).toList(),
        throwsA(
          isA<DeckException>().having(
            (e) => e.code,
            'code',
            'comment_card_mismatch',
          ),
        ),
      );
    },
  );

  test('server UID is not inferred from the login alias', () async {
    final api = client(MockClient((_) async => ocsReply({'id': 'uid-1'})));
    expect(await api.currentUserId(), 'uid-1');
  });
}
