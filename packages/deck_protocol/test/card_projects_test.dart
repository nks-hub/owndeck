import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

http.Response _ocs(Object data, [int status = 200]) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': status},
      'data': data,
    },
  }),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  final base = ServerBase.parse('https://cloud.example.com');
  DeckClient client(http.Response Function(http.Request) answer) =>
      DeckClient(
        base: base,
        loginName: 'user',
        appPassword: 'test-password',
        transport: MockClient((request) async => answer(request)),
      );

  test('reads projects of a card from the collaboration resources route', () async {
    late Uri requested;
    final projects = await client((request) {
      requested = request.url;
      return _ocs([
        {
          'id': 4,
          'name': 'Launch',
          'resources': [
            {'type': 'deck-card', 'id': '8', 'name': 'Board: This card'},
            {
              'type': 'file',
              'id': 55,
              'name': 'plan.pdf',
              'link': 'https://cloud.example.com/f/55',
            },
            {
              'type': 'room',
              'id': 'abc123',
              'name': 'Team',
              'link': '/index.php/call/abc123',
            },
            {'type': 'file', 'id': 55, 'name': 'plan.pdf'},
            {
              'type': 'deck-card',
              'id': '9',
              'name': 'Board: Other',
              'link': '/index.php/apps/deck/board/1/card/9',
            },
          ],
        },
        {
          'id': 5,
          'name': 'Only me',
          'resources': [
            {'type': 'deck-card', 'id': '8', 'name': 'Board: This card'},
          ],
        },
      ]);
    }).cardProjects(8);

    expect(
      requested.path,
      '/ocs/v2.php/collaboration/resources/deck-card/8',
    );
    expect(projects, hasLength(1));
    final project = projects.single;
    expect(project.name, 'Launch');
    expect(project.resources.map((r) => r.type), ['file', 'room', 'deck-card']);
    expect(
      project.resources[1].openUri(base).toString(),
      'https://cloud.example.com/index.php/call/abc123',
    );
    expect(project.resources[0].openUri(base).toString(),
        'https://cloud.example.com/f/55');
  });

  test('links with other schemes or credentials are not openable', () {
    for (final link in [
      'javascript:alert(1)',
      'https://user:pw@cloud.example.com/x',
      'file:///etc/passwd',
    ]) {
      expect(
        ProjectResource(type: 'file', id: '1', name: 'x', link: link)
            .openUri(base),
        isNull,
      );
    }
  });

  test('an unknown or inaccessible card is a not_found error', () async {
    await expectLater(
      client((_) => http.Response(
        jsonEncode({
          'ocs': {
            'meta': {'status': 'failure', 'statuscode': 404},
            'data': <Object>[],
          },
        }),
        404,
        headers: {'content-type': 'application/json'},
      )).cardProjects(8),
      throwsA(isA<DeckException>().having((e) => e.code, 'code', 'not_found')),
    );
  });

  test('an empty answer yields no projects', () async {
    expect(await client((_) => _ocs([])).cardProjects(8), isEmpty);
  });
}
