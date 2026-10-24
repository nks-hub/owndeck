import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:http_parser/http_parser.dart';
import 'package:test/test.dart';

void main() {
  final instant = DateTime.utc(2030, 1, 1, 12);
  for (final (header, expected) in [
    ('60', instant.add(const Duration(seconds: 60))),
    (
      formatHttpDate(instant.add(const Duration(minutes: 2))),
      instant.add(const Duration(minutes: 2)),
    ),
    ('invalid', instant.add(const Duration(seconds: 30))),
  ]) {
    test('pauses all requests until Retry-After $header', () async {
      var now = instant;
      var requests = 0;
      final api = DeckClient(
        base: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
        now: () => now,
        transport: MockClient((_) async {
          requests++;
          return requests == 1
              ? http.Response('', 429, headers: {'retry-after': header})
              : http.Response(
                  '[]',
                  200,
                  headers: {'content-type': 'application/json'},
                );
        }),
      );
      await expectLater(
        api.boards(),
        throwsA(
          isA<DeckException>().having((e) => e.retryAt, 'retryAt', expected),
        ),
      );
      await expectLater(
        api.boards(),
        throwsA(
          isA<DeckException>().having((e) => e.code, 'code', 'rate_limited'),
        ),
      );
      expect(requests, 1);
      now = expected;
      expect(await api.boards(), isEmpty);
      expect(requests, 2);
    });
  }

  test(
    '503 after a POST remains uncertain even with a retry deadline',
    () async {
      var requests = 0;
      final api = DeckClient(
        base: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
        now: () => instant,
        transport: MockClient((_) async {
          requests++;
          return http.Response('', 503, headers: {'retry-after': '120'});
        }),
      );
      await expectLater(
        api.rest('POST', ['boards'], body: {'title': 'Board'}),
        throwsA(
          isA<DeckException>().having((e) => e.uncertain, 'uncertain', isTrue),
        ),
      );
      await expectLater(
        api.rest('POST', ['boards'], body: {'title': 'Board'}),
        throwsA(
          isA<DeckException>()
              .having((e) => e.uncertain, 'uncertain', isFalse)
              .having((e) => e.status, 'status', 429),
        ),
      );
      expect(requests, 1);
    },
  );

  test(
    'a restored deadline blocks the first request without sending credentials',
    () async {
      var requests = 0;
      final api = DeckClient(
        base: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
        now: () => instant,
        retryUntil: instant.add(const Duration(hours: 1)),
        transport: MockClient((_) async {
          requests++;
          return http.Response('', 500);
        }),
      );
      await expectLater(api.boards(), throwsA(isA<DeckException>()));
      expect(requests, 0);
    },
  );
}
