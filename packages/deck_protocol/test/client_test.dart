import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

DeckClient client(http.Client transport) => DeckClient(
  base: ServerBase.parse('https://cloud.example.com/nextcloud'),
  loginName: 'test-user',
  appPassword: 'test-app-password',
  transport: transport,
);

void main() {
  test('extended fields are offered only for a verified release family', () {
    DeckCapabilities capabilities(String version) => DeckCapabilities(
      version: version,
      apiVersion: '1.1',
      canCreateBoards: true,
    );
    expect(capabilities('1.18.0').supportsExtendedCardFields, isFalse);
    expect(capabilities('1.19.1').supportsExtendedCardFields, isTrue);
    expect(capabilities('unknown').supportsExtendedCardFields, isFalse);
  });

  test(
    'renaming preserves start and color while explicit null clears them',
    () {
      final card = DeckCard.fromJson({
        'id': 1,
        'stackId': 2,
        'title': 'Task',
        'description': 'Text',
        'order': 0,
        'archived': false,
        'type': 'plain',
        'owner': 'user',
        'startdate': '2026-11-01T08:00:00Z',
        'duedate': '2026-11-02T12:00:00Z',
        'color': '008080',
      });
      final rename = card.updateBody({'title': 'Renamed'});
      expect(rename['startdate'], '2026-11-01T08:00:00Z');
      expect(rename['color'], '008080');
      final clear = card.updateBody({'startdate': null, 'color': null});
      expect(clear.containsKey('startdate'), isTrue);
      expect(clear['startdate'], isNull);
      expect(clear['color'], isNull);
      expect(clear['duedate'], '2026-11-02T12:00:00Z');
    },
  );
  test('preserves installation subdirectory and REST response shape', () async {
    late Uri received;
    final transport = MockClient((request) async {
      received = request.url;
      return http.Response(
        jsonEncode([
          {
            'id': 5,
            'title': 'Projekt A',
            'color': '008080',
            'archived': false,
            'deletedAt': 0,
            'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': false},
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final boards = await client(transport).boards();
    expect(received.path, '/nextcloud/index.php/apps/deck/api/v1.1/boards');
    expect(boards.single.title, 'Projekt A');
    expect(boards.single.permissions.edit, isFalse);
    expect(boards.single.permissions.share, isFalse);
  });

  test('rejects a failed OCS envelope even when HTTP is successful', () async {
    final transport = MockClient(
      (_) async => http.Response(
        '{"ocs":{"meta":{"status":"failure","statuscode":997},"data":[]}}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    expect(
      client(transport).ocs('GET', ['cloud', 'capabilities']),
      throwsA(
        isA<DeckException>().having((e) => e.code, 'code', 'ocs_rejected'),
      ),
    );
  });

  test(
    'marks a POST with an unreadable successful response as uncertain',
    () async {
      var requests = 0;
      final transport = MockClient((_) async {
        requests++;
        return http.Response(
          '<html>proxy</html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      });
      await expectLater(
        client(transport).rest(
          'POST',
          ['boards'],
          body: {'title': 'Projekt A', 'color': '008080'},
        ),
        throwsA(
          isA<DeckException>().having((e) => e.uncertain, 'uncertain', isTrue),
        ),
      );
      expect(requests, 1);
    },
  );

  test('304 keeps cache semantics without decoding an empty body', () async {
    final transport = MockClient((_) async => http.Response('', 304));
    final response = await client(
      transport,
    ).rest('GET', ['boards'], etag: '"previous"');
    expect(response.notModified, isTrue);
    expect(response.data, isNull);
    expect(response.etag, '"previous"');
  });

  test('renaming retains fields that Deck PUT would otherwise clear', () {
    final card = DeckCard.fromJson({
      'id': 1,
      'stackId': 4,
      'title': 'Původní',
      'description': 'Neztratit',
      'order': 7,
      'archived': false,
      'type': 'plain',
      'owner': {'uid': 'user'},
      'duedate': '2026-11-01T10:00:00+00:00',
      'done': null,
    });
    final body = card.updateBody({'title': 'Nový'});
    expect(body, containsPair('title', 'Nový'));
    expect(body, containsPair('description', 'Neztratit'));
    expect(body, containsPair('order', 7));
    expect(body, containsPair('owner', 'user'));
    expect(body, containsPair('duedate', '2026-11-01T10:00:00+00:00'));
    expect(body.containsKey('done'), isTrue);
    expect(body.containsKey('color'), isFalse);
  });

  test('rejects base URLs that escape the installation boundary', () {
    for (final value in [
      'http://cloud.example.com',
      'https://user:secret@cloud.example.com',
      'https://cloud.example.com/a%2fb',
      'https://cloud.example.com/?token=secret',
    ]) {
      expect(() => ServerBase.parse(value), throwsFormatException);
    }
  });
}
