import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:deck_protocol/deck_protocol.dart';
import 'package:test/test.dart';

void main() {
  late Directory certificates;
  late String firstFingerprint;

  setUpAll(() async {
    certificates = await Directory.systemTemp.createTemp(
      'own-client-tls-test-',
    );
    for (final name in ['first', 'second', 'wrong-san', 'other-cn']) {
      final result = await Process.run('openssl', [
        'req',
        '-x509',
        '-newkey',
        'rsa:2048',
        '-sha256',
        '-days',
        '1',
        '-nodes',
        '-subj',
        name == 'other-cn' ? '/CN=other.example.com' : '/CN=127.0.0.1',
        '-addext',
        name == 'wrong-san'
            ? 'subjectAltName=DNS:other.example.com'
            : 'subjectAltName=IP:127.0.0.1',
        '-keyout',
        '${certificates.path}/$name.key',
        '-out',
        '${certificates.path}/$name.pem',
      ]);
      expect(
        result.exitCode,
        0,
        reason:
            'OpenSSL must generate the disposable localhost test certificates',
      );
    }
    final pem = await File('${certificates.path}/first.pem').readAsString();
    final der = base64Decode(
      const LineSplitter()
          .convert(pem)
          .where((line) => !line.startsWith('-----'))
          .join(),
    );
    firstFingerprint = certificateFingerprint(der);
  });
  tearDownAll(() async => certificates.delete(recursive: true));

  Future<HttpServer> serve(String name, void Function() received) async {
    final context = SecurityContext()
      ..useCertificateChain('${certificates.path}/$name.pem')
      ..usePrivateKey('${certificates.path}/$name.key');
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    server.listen((request) async {
      received();
      request.response.write('accepted');
      await request.response.close();
    }, onError: (Object _) {});
    addTearDown(() => server.close(force: true));
    return server;
  }

  test(
    'untrusted certificate is refused before HTTP and reported for confirmation',
    () async {
      var received = 0;
      final server = await serve('first', () => received++);
      final uri = Uri.parse('https://127.0.0.1:${server.port}');
      final client = CertificateHttpClient(server: uri);
      addTearDown(client.close);
      await expectLater(
        client.get(uri, headers: {'Authorization': 'Basic test-only'}),
        throwsA(isA<http.ClientException>()),
      );
      expect(received, 0);
      expect(client.lastEncounter?.fingerprint, firstFingerprint);
      expect(
        client.lastEncounter?.outcome.decision,
        CertificateTrustDecision.ask,
      );
    },
  );

  test(
    'the explicitly confirmed leaf certificate permits the request',
    () async {
      var received = 0;
      final server = await serve('first', () => received++);
      final uri = Uri.parse('https://127.0.0.1:${server.port}');
      final client = CertificateHttpClient(
        server: uri,
        fingerprint: firstFingerprint,
      );
      addTearDown(client.close);
      expect((await client.get(uri)).body, 'accepted');
      expect(received, 1);
      expect(client.lastEncounter, isNull);
    },
  );

  test(
    'a changed otherwise trusted certificate cannot bypass an explicit pin',
    () async {
      var received = 0;
      final server = await serve('second', () => received++);
      final uri = Uri.parse('https://127.0.0.1:${server.port}');
      final trusted = SecurityContext()
        ..setTrustedCertificates('${certificates.path}/second.pem');
      final unpinned = CertificateHttpClient(
        server: uri,
        trustedContext: trusted,
      );
      addTearDown(unpinned.close);
      expect((await unpinned.get(uri)).statusCode, 200);
      expect(received, 1);
      final pinned = CertificateHttpClient(
        server: uri,
        fingerprint: firstFingerprint,
        trustedContext: trusted,
      );
      addTearDown(pinned.close);
      await expectLater(
        pinned.get(uri, headers: {'Authorization': 'Basic test-only'}),
        throwsA(isA<http.ClientException>()),
      );
      expect(received, 1);
      expect(
        pinned.lastEncounter?.outcome.refusal,
        CertificateRefusal.pinnedFingerprintMismatch,
      );
    },
  );

  test('pins cannot be reused on another port or insecure origin', () async {
    final uri = Uri.parse('https://127.0.0.1:4443');
    final client = CertificateHttpClient(
      server: uri,
      fingerprint: firstFingerprint,
    );
    addTearDown(client.close);
    for (final other in [
      'http://127.0.0.1:4443',
      'https://127.0.0.1:4444',
      'https://localhost:4443',
    ]) {
      await expectLater(
        client.get(Uri.parse(other)),
        throwsA(
          isA<http.ClientException>().having(
            (e) => e.message,
            'message',
            'untrusted_request_origin',
          ),
        ),
      );
    }
  });

  for (final name in ['wrong-san', 'other-cn']) {
    test('SAN takes precedence over CN: $name', () async {
      var received = 0;
      final server = await serve(name, () => received++);
      final uri = Uri.parse('https://127.0.0.1:${server.port}');
      final pem = await File('${certificates.path}/$name.pem').readAsString();
      final der = base64Decode(
        const LineSplitter()
          .convert(pem)
          .where((line) => !line.startsWith('-----'))
          .join(),
      );
      final client = CertificateHttpClient(
        server: uri,
        fingerprint: certificateFingerprint(der),
      );
      addTearDown(client.close);
      if (name == 'wrong-san') {
        await expectLater(
          client.get(uri, headers: {'Authorization': 'Basic test-only'}),
          throwsA(isA<http.ClientException>()),
        );
        expect(received, 0);
        expect(
          client.lastEncounter?.outcome.refusal,
          CertificateRefusal.hostMismatch,
        );
      } else {
        expect((await client.get(uri)).body, 'accepted');
        expect(received, 1);
      }
    });
  }
}
