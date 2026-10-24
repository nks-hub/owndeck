import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  DeckClient client(http.Response response) => DeckClient(
    base: ServerBase.parse('https://cloud.example.com'),
    loginName: 'user',
    appPassword: 'test-password',
    transport: MockClient((_) async => response),
  );

  test('204 is accepted only for an explicitly empty read endpoint', () async {
    final api = client(http.Response('', 204));
    await expectLater(
      api.ocs('GET', ['apps', 'notifications', 'api', 'v2', 'notifications']),
      throwsA(isA<DeckException>()),
    );
    final result = await api.ocs('GET', [
      'apps',
      'notifications',
      'api',
      'v2',
      'notifications',
    ], allowNoContent: true);
    expect(result.data, isEmpty);
    await expectLater(
      api.ocs('POST', ['apps', 'deck'], allowNoContent: true),
      throwsA(
        isA<DeckException>().having(
          (error) => error.uncertain,
          'uncertain',
          isTrue,
        ),
      ),
    );
  });

  test('unwrapped OCS-path responses require an explicit contract', () async {
    final api = client(
      http.Response(
        '{"id":7}',
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    await expectLater(
      api.ocs('POST', ['apps', 'deck']),
      throwsA(isA<DeckException>()),
    );
    expect((await api.ocs('POST', ['apps', 'deck'], envelope: false)).data, {
      'id': 7,
    });
  });
}
