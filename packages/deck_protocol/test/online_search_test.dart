import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

Map<String, Object?> card(int id) => {
  'id': id,
  'boardId': 1,
  'stackId': 2,
  'title': 'Card $id',
  'description': '',
  'order': 0,
  'board': {'id': 1, 'title': 'Board'},
  'assignedUsers': [],
  'archived': false,
};
http.Response ocs(Object value) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': value,
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);
DeckClient client(http.Client transport) => DeckClient(
  base: ServerBase.parse('https://cloud.example.com/subdir'),
  loginName: 'user',
  appPassword: 'test-password',
  transport: transport,
);

void main() {
  test(
    'server search uses an explicit bounded first page without a lossy timestamp cursor',
    () async {
      final api = client(
        MockClient((request) async {
          expect(
            request.url.path,
            '/subdir/ocs/v2.php/apps/deck/api/v1.0/search',
          );
          expect(request.url.queryParameters['term'], 'title:"Task name"');
          expect(request.url.queryParameters['limit'], '200');
          expect(request.url.queryParameters.containsKey('cursor'), isFalse);
          return ocs([for (var id = 1; id <= 200; id++) card(id)]);
        }),
      );
      final result = await api.searchCardsOnline('title:"Task name"');
      expect(result.items.length, 200);
      expect(result.limited, isTrue);
    },
  );

  test(
    'overview combines documented groups and accepts the empty PHP array',
    () async {
      var empty = false;
      final api = client(
        MockClient((request) async {
          expect(request.url.path, endsWith('/overview/upcoming'));
          return ocs(
            empty
                ? []
                : {
                    'today': [card(1)],
                    'nodue': [card(2)],
                  },
          );
        }),
      );
      expect((await api.upcomingCards()).items.map((entry) => entry.card.id), [
        1,
        2,
      ]);
      empty = true;
      expect((await api.upcomingCards()).items, isEmpty);
    },
  );

  test('duplicate cards and unknown overview groups are rejected', () async {
    await expectLater(
      client(
        MockClient((_) async => ocs([card(1), card(1)])),
      ).searchCardsOnline('test'),
      throwsA(isA<DeckException>()),
    );
    await expectLater(
      client(
        MockClient(
          (_) async => ocs({
            'unknown': [card(1)],
          }),
        ),
      ).upcomingCards(),
      throwsA(isA<DeckException>()),
    );
  });

  test('opening a result checks the board before reading card data', () async {
    var requests = 0;
    final api = client(
      MockClient((_) async {
        requests++;
        return http.Response(
          jsonEncode({
            'id': 1,
            'title': 'Board',
            'color': '008080',
            'deletedAt': 0,
            'permissions': {'PERMISSION_READ': false},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await expectLater(
      api.readCardContext(1, 8, stackId: 2),
      throwsA(
        isA<DeckException>().having((error) => error.status, 'status', 403),
      ),
    );
    expect(requests, 1);
  });
}
