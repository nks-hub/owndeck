import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('capabilities keep the Nextcloud version from the OCS reply', () async {
    final client = DeckClient(
      base: ServerBase.parse('https://cloud.example.com'),
      loginName: 'user',
      appPassword: 'test-password',
      transport: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': {
                'version': {'string': '31.0.2'},
                'capabilities': {
                  'deck': {
                    'version': '1.14.0',
                    'apiVersions': ['1.1'],
                    'canCreateBoards': true,
                  },
                },
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    final capabilities = await client.capabilities();
    expect(capabilities.serverVersion, '31.0.2');
    expect(capabilities.version, '1.14.0');
  });
}
