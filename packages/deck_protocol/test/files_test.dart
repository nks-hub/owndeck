import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

String entry(String href, {bool directory = false}) =>
    '<d:response><d:href>$href</d:href>'
    '<d:propstat><d:prop><d:resourcetype>${directory ? '<d:collection/>' : ''}</d:resourcetype>'
    '<d:getcontentlength>3</d:getcontentlength><d:getcontenttype>text/plain</d:getcontenttype>'
    '<oc:fileid>7</oc:fileid><oc:permissions>GRS</oc:permissions></d:prop>'
    '<d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response>';

String listing(String body) =>
    '<d:multistatus xmlns:d="DAV:" xmlns:oc="http://owncloud.org/ns">$body</d:multistatus>';

void main() {
  const parent = '/nextcloud/remote.php/dav/files/user%40example.com/';
  DeckClient api(String body) => DeckClient(
    base: ServerBase.parse('https://cloud.example.com/nextcloud'),
    loginName: 'login-alias',
    appPassword: 'test-password',
    transport: MockClient((request) async {
      expect(request.method, 'PROPFIND');
      expect(request.url.host, 'cloud.example.com');
      expect(request.url.pathSegments.where((part) => part.isNotEmpty), [
        'nextcloud',
        'remote.php',
        'dav',
        'files',
        'user@example.com',
      ]);
      expect(request.headers['depth'], '1');
      expect(request.followRedirects, isFalse);
      return http.Response(
        body,
        207,
        headers: {'content-type': 'application/xml'},
      );
    }),
  );

  test(
    'uses canonical UID and decodes names while preserving account and directory boundaries',
    () async {
      final files = await api(
        listing(
          entry(parent, directory: true) +
              entry('${parent}report%20%26%20plan.txt') +
              entry('${parent}Folder/', directory: true),
        ),
      ).files('user@example.com', []);
      expect(files.map((file) => file.name), ['Folder', 'report & plan.txt']);
      expect(files.last.path, '/report & plan.txt');
      expect(files.last.readable, isTrue);
      expect(files.last.shareable, isTrue);
    },
  );

  test('R permits sharing while S only marks an existing share', () async {
    for (final permissions in ['GR', 'SG']) {
      final body = listing(
        entry('${parent}report.txt'),
      ).replaceAll('GRS', permissions);
      final files = await api(body).files('user@example.com', []);
      expect(files.single.shareable, permissions == 'GR');
      expect(files.single.readable, isTrue);
    }
  });

  for (final href in [
    'https://other.example.com${parent}secret.txt',
    '/nextcloud/remote.php/dav/files/other/secret.txt',
    '${parent}folder/secret.txt',
    '$parent%2e%2e/secret.txt',
    '${parent}folder%2fsecret.txt',
    '${parent}file.txt?token=invalid',
  ]) {
    test('refuses an out-of-scope DAV entry: $href', () async {
      await expectLater(
        api(listing(entry(href))).files('user@example.com', []),
        throwsA(
          isA<DeckException>().having(
            (error) => error.code,
            'code',
            'invalid_dav_listing',
          ),
        ),
      );
    });
  }

  test(
    'a failed propstat is not converted into an empty successful folder',
    () async {
      final body = listing(
        entry('${parent}report.txt'),
      ).replaceAll('200 OK', '403 Forbidden');
      await expectLater(
        api(body).files('user@example.com', []),
        throwsA(isA<DeckException>()),
      );
    },
  );

  test('rejects foreign XML namespaces and document types', () async {
    for (final body in [
      listing('').replaceFirst('DAV:', 'https://other.example.com'),
      '<!DOCTYPE x>${listing('')}',
    ]) {
      await expectLater(
        api(body).files('user@example.com', []),
        throwsA(isA<DeckException>()),
      );
    }
  });
}
