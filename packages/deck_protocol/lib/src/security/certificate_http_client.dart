import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'certificate_trust.dart';
import 'certificate_host.dart';

final class CertificateEncounter {
  const CertificateEncounter({
    required this.host,
    required this.port,
    required this.fingerprint,
    required this.outcome,
  });
  final String host;
  final int port;
  final String fingerprint;
  final CertificateTrustOutcome outcome;
  @override
  String toString() => 'CertificateEncounter(${outcome.decision.name})';
}

String certificateFingerprint(List<int> der) =>
    sha256.convert(der).toString().toLowerCase();

String? certificateSubjectHost(String subject) {
  for (final part in subject.split(RegExp('[,/]'))) {
    final value = part.trim();
    if (value.length > 3 && value.substring(0, 3).toUpperCase() == 'CN=') {
      final host = value.substring(3).trim();
      return host.isEmpty ? null : host;
    }
  }
  return null;
}

/// A pin belongs to one HTTPS origin and is checked before HTTP headers leave.
final class CertificateHttpClient extends http.BaseClient {
  CertificateHttpClient({
    required this.server,
    this.fingerprint,
    SecurityContext? trustedContext,
  }) {
    if (server.scheme != 'https' ||
        server.host.isEmpty ||
        server.userInfo.isNotEmpty) {
      throw ArgumentError('invalid_server_origin');
    }
    if (fingerprint != null &&
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(fingerprint!)) {
      throw ArgumentError('invalid_certificate_pin');
    }
    // Without an empty trust store, a renewed system-trusted certificate skips
    // badCertificateCallback and silently bypasses an explicit account pin.
    final context = fingerprint == null
        ? trustedContext
        : SecurityContext(withTrustedRoots: false);
    final client = HttpClient(context: context)
      ..connectionTimeout = const Duration(seconds: 30)
      ..badCertificateCallback = (certificate, host, port) {
        final outcome = decideCertificateTrust(
          requestedHost: host,
          certificateHost: certificateMatchesHost(certificate.der, host)
              ? host
              : '',
          presentedFingerprint: certificateFingerprint(certificate.der),
          pinnedFingerprints: {?fingerprint},
        );
        final sameOrigin =
            host.toLowerCase() == server.host.toLowerCase() &&
            port == server.port;
        if (sameOrigin && outcome.decision == CertificateTrustDecision.allow) {
          return true;
        }
        lastEncounter = CertificateEncounter(
          host: host,
          port: port,
          fingerprint: certificateFingerprint(certificate.der),
          outcome: sameOrigin
              ? outcome
              : const CertificateTrustOutcome.refuse(
                  CertificateRefusal.hostMismatch,
                ),
        );
        return false;
      };
    _client = IOClient(client);
  }

  final Uri server;
  final String? fingerprint;
  late final IOClient _client;
  CertificateEncounter? lastEncounter;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.scheme != 'https' ||
        request.url.origin != server.origin ||
        request.url.userInfo.isNotEmpty) {
      throw http.ClientException('untrusted_request_origin');
    }
    lastEncounter = null;
    request.followRedirects = false;
    try {
      return await _client.send(request);
    } on http.RequestAbortedException {
      throw http.RequestAbortedException();
    } on http.ClientException {
      throw http.ClientException(
        lastEncounter == null ? 'transport_failed' : 'certificate_rejected',
      );
    } on IOException {
      throw http.ClientException(
        lastEncounter == null ? 'transport_failed' : 'certificate_rejected',
      );
    }
  }

  @override
  void close() => _client.close();
}
