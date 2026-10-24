import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  const ready = {
    'installed': true,
    'maintenance': false,
    'needsDbUpgrade': false,
  };
  Future<void> check(Map<String, Object?> status) => LoginClient(
    base: ServerBase.parse('https://cloud.example.com/subdir'),
    transport: MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/subdir/status.php');
      expect(request.followRedirects, isFalse);
      expect(request.headers.containsKey('authorization'), isFalse);
      return http.Response(
        jsonEncode(status),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  ).checkServer();

  test(
    'ready server permits login without sending credentials',
    () => check(ready),
  );
  for (final entry in {
    'server_maintenance': {...ready, 'maintenance': true},
    'server_upgrade': {...ready, 'needsDbUpgrade': true},
    'server_not_installed': {...ready, 'installed': false},
    'invalid_response': {...ready, 'installed': 'true'},
  }.entries) {
    test('rejects ${entry.key} before starting login', () async {
      await expectLater(
        check(entry.value),
        throwsA(
          isA<LoginException>().having(
            (error) => error.code,
            'code',
            entry.key,
          ),
        ),
      );
    });
  }
}
