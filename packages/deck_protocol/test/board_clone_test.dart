import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _flags = [
  'withCards',
  'withAssignments',
  'withLabels',
  'withDueDate',
  'moveCardsToLeftStack',
  'restoreArchivedCards',
];

JsonObject _board(Object? id) => {
  'id': id,
  'title': 'Board copy',
  'color': '008080',
  'archived': false,
  'deletedAt': 0,
  'permissions': {'PERMISSION_READ': true, 'PERMISSION_MANAGE': true},
};

http.Response _json(Object? data, {int status = 200}) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);

DeckClient _api(Future<http.Response> Function(http.Request) handle) {
  final transport = MockClient(handle);
  addTearDown(transport.close);
  return DeckClient(
    base: ServerBase.parse('https://cloud.example.com/nextcloud'),
    loginName: 'user',
    appPassword: 'test-password',
    transport: transport,
  );
}

void main() {
  const cases = {
    'defaults': BoardCloneOptions(),
    'withCards': BoardCloneOptions(withCards: true),
    'withAssignments': BoardCloneOptions(withAssignments: true),
    'withLabels': BoardCloneOptions(withLabels: true),
    'withDueDate': BoardCloneOptions(withDueDate: true),
    'moveCardsToLeftStack': BoardCloneOptions(moveCardsToLeftStack: true),
    'restoreArchivedCards': BoardCloneOptions(restoreArchivedCards: true),
  };
  for (final entry in cases.entries) {
    test('clone POST preserves six boolean flags for ${entry.key}', () async {
      var calls = 0;
      final client = _api((request) async {
        calls++;
        expect(request.method, 'POST');
        expect(
          request.url.path,
          '/nextcloud/index.php/apps/deck/api/v1.1/boards/7/clone',
        );
        expect(request.headers['content-type'], startsWith('application/json'));
        expect(request.followRedirects, isFalse);
        expect(jsonDecode(request.body), {
          for (final flag in _flags) flag: flag == entry.key,
        });
        return _json(_board(53));
      });
      final result = await client.cloneBoard(7, entry.value);
      expect(result.id, 53);
      expect(result.title, 'Board copy');
      expect(calls, 1);
    });
  }

  test('cloning gate starts at 1.19 independently of extended card fields', () {
    const versions = [
      (version: '1.18.0', clone: false, extended: true),
      (version: '1.18.5', clone: false, extended: true),
      (version: '1.19.0', clone: true, extended: true),
      (version: '1.19.1', clone: true, extended: true),
      (version: 'unknown', clone: false, extended: false),
      (version: '', clone: false, extended: false),
    ];
    for (final value in versions) {
      final capabilities = DeckCapabilities(
        version: value.version,
        apiVersion: '1.1',
        canCreateBoards: true,
      );
      expect(
        capabilities.supportsBoardCloning,
        value.clone,
        reason: value.version,
      );
      expect(
        capabilities.supportsExtendedCardFields,
        value.extended,
        reason: value.version,
      );
    }
  });

  test(
    'invalid clone receipts are uncertain and never resend the POST',
    () async {
      final receipts = <String, Object?>{
        'same source id': _board(7),
        'zero id': _board(0),
        'negative id': _board(-1),
        'wrong id type': _board('53'),
        'missing id': _board(53)..remove('id'),
        'not an object': <Object?>[],
      };
      for (final entry in receipts.entries) {
        var calls = 0;
        final client = _api((request) async {
          calls++;
          return _json(entry.value);
        });
        await expectLater(
          client.cloneBoard(7, const BoardCloneOptions(withCards: true)),
          throwsA(
            isA<DeckException>()
                .having((error) => error.code, 'code', 'invalid_response')
                .having((error) => error.uncertain, 'uncertain', isTrue),
          ),
          reason: entry.key,
        );
        expect(calls, 1, reason: entry.key);
      }
    },
  );

  test('HTTP 405 rejects even a board-shaped response without retry', () async {
    var calls = 0;
    final client = _api((request) async {
      calls++;
      return _json(_board(53), status: 405);
    });
    await expectLater(
      client.cloneBoard(7, const BoardCloneOptions()),
      throwsA(
        isA<DeckException>()
            .having((error) => error.code, 'code', 'request_rejected')
            .having((error) => error.status, 'status', 405)
            .having((error) => error.uncertain, 'uncertain', isFalse),
      ),
    );
    expect(calls, 1);
  });
}
