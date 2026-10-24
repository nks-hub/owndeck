import 'dart:async';
import 'dart:convert';
import 'dart:io' show TlsException;

import 'package:http/http.dart' as http;

import 'server_base.dart';

/// Safe error code only: never include response bodies, tokens or URLs.
final class LoginException implements Exception {
  const LoginException(this.code);
  final String code;
  @override
  String toString() => 'LoginException($code)';
}

final class LoginCredentials {
  const LoginCredentials({
    required this.server,
    required this.loginName,
    required this.appPassword,
  });
  final ServerBase server;
  final String loginName;
  final String appPassword;
  @override
  String toString() => 'LoginCredentials(redacted)';
}

/// A single-use flow. Call poll sequentially; persist its successful result
/// before reporting login complete. A lost successful response requires a new
/// flow because the server returns credentials only once.
final class LoginSession {
  LoginSession._(this._client, this.loginUri, this._endpoint, this._token)
    : _age = Stopwatch()..start();
  final LoginClient _client;
  final Uri loginUri;
  final Uri _endpoint;
  String? _token;
  final Stopwatch _age;
  bool _busy = false;
  bool get isClosed => _token == null;

  void cancel() {
    _token = null;
    _age.stop();
  }

  Future<LoginCredentials?> poll() async {
    if (_busy) throw const LoginException('poll_in_progress');
    if (_age.elapsed >= const Duration(minutes: 20)) cancel();
    final token = _token;
    if (token == null) throw const LoginException('flow_closed');
    _busy = true;
    try {
      final response = await _client._post(_endpoint, {'token': token});
      if (isClosed) throw const LoginException('flow_closed');
      if (response.statusCode == 404) return null;
      cancel();
      if (response.statusCode != 200) {
        throw const LoginException('poll_rejected');
      }
      final json = _decode(response);
      final server = _string(json, 'server');
      final loginName = _string(json, 'loginName');
      final password = _string(json, 'appPassword');
      ServerBase returned;
      try {
        returned = ServerBase.parse(server);
      } on FormatException {
        throw const LoginException('invalid_server');
      }
      if (returned.uri != _client.base.uri || loginName.contains(':')) {
        throw const LoginException('server_identity_changed');
      }
      return LoginCredentials(
        server: returned,
        loginName: loginName,
        appPassword: password,
      );
    } on LoginException catch (e) {
      // A transport failure usually means the poll never reached the server,
      // so the flow stays open for another poll. If a successful response was
      // lost instead, later polls keep returning pending until the caller
      // cancels or the flow expires.
      if (e.code != 'transport_failed' && e.code != 'timeout') cancel();
      rethrow;
    } catch (_) {
      cancel();
      rethrow;
    } finally {
      _busy = false;
    }
  }

  @override
  String toString() => 'LoginSession(redacted)';
}

final class LoginClient {
  LoginClient({
    required this.base,
    required this.transport,
    this.timeout = const Duration(seconds: 30),
  }) {
    if (timeout <= Duration.zero) throw ArgumentError('Invalid timeout');
  }
  final ServerBase base;
  final http.Client transport;
  final Duration timeout;

  Future<void> checkServer() async {
    final response = await _request('GET', base.uri.resolve('status.php'), {});
    if (response.statusCode != 200) {
      throw const LoginException('invalid_response');
    }
    final status = _decode(response);
    if ([
      'installed',
      'maintenance',
      'needsDbUpgrade',
    ].any((key) => status[key] is! bool)) {
      throw const LoginException('invalid_response');
    }
    if (status['maintenance'] == true) {
      throw const LoginException('server_maintenance');
    }
    if (status['needsDbUpgrade'] == true) {
      throw const LoginException('server_upgrade');
    }
    if (status['installed'] != true) {
      throw const LoginException('server_not_installed');
    }
  }

  Future<LoginSession> start() async {
    final response = await _post(base.uri.resolve('index.php/login/v2'), {});
    if (response.statusCode != 200) {
      throw const LoginException('start_rejected');
    }
    final json = _decode(response);
    final poll = json['poll'];
    if (poll is! Map<String, Object?>) {
      throw const LoginException('invalid_response');
    }
    return LoginSession._(
      this,
      _trustedUri(_string(json, 'login')),
      _trustedUri(_string(poll, 'endpoint')),
      _string(poll, 'token'),
    );
  }

  Uri _trustedUri(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.scheme != 'https' ||
        uri.origin != base.uri.origin ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.hasQuery ||
        !uri.path.startsWith(base.uri.path) ||
        uri.pathSegments.any(
          (s) =>
              s == '..' ||
              s == '.' ||
              s.contains('/') ||
              s.contains('\\') ||
              s.runes.any((c) => c < 32 || c == 127),
        )) {
      throw const LoginException('untrusted_endpoint');
    }
    return uri;
  }

  Future<http.Response> _post(Uri uri, Map<String, String> fields) =>
      _request('POST', uri, fields);

  Future<http.Response> _request(
    String method,
    Uri uri,
    Map<String, String> fields,
  ) async {
    final abort = Completer<void>();
    final request =
        http.AbortableRequest(method, uri, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers.addAll({
            'Accept': 'application/json',
            'User-Agent': 'OwnDeck',
          });
    if (method == 'POST') request.bodyFields = fields;
    try {
      return await (() async {
        final response = await transport.send(request);
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 65536) {
            throw const LoginException('response_too_large');
          }
          bytes.addAll(chunk);
        }
        return http.Response.bytes(
          bytes,
          response.statusCode,
          headers: response.headers,
        );
      })().timeout(timeout);
    } on LoginException {
      rethrow;
    } on TimeoutException {
      throw const LoginException('timeout');
    } on TlsException {
      throw const LoginException('tls_failed');
    } catch (_) {
      throw const LoginException('transport_failed');
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }
}

Map<String, Object?> _decode(http.Response response) {
  if (response.headers['content-type']?.split(';').first.trim().toLowerCase() !=
      'application/json') {
    throw const LoginException('invalid_content_type');
  }
  try {
    final value = jsonDecode(utf8.decode(response.bodyBytes));
    if (value is Map<String, Object?>) return value;
  } on FormatException {
    throw const LoginException('invalid_response');
  }
  throw const LoginException('invalid_response');
}

String _string(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! String ||
      value.isEmpty ||
      value.runes.any((c) => c < 32 || c == 127)) {
    throw const LoginException('invalid_response');
  }
  return value;
}
