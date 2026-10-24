import 'dart:async';
import 'dart:convert';
import 'dart:io' show IOException, TlsException;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:xml/xml.dart';

import 'attachments.dart';
import 'models.dart';
import 'server_base.dart';

part 'attachment_client.dart';
part 'dav_client.dart';

final class DeckException implements Exception {
  const DeckException(
    this.code, {
    this.status,
    this.uncertain = false,
    this.retryAt,
  });

  final String code;
  final int? status;
  final bool uncertain;
  final DateTime? retryAt;

  @override
  String toString() => 'DeckException($code, $status, uncertain: $uncertain)';
}

final class DeckResponse {
  const DeckResponse(this.data, {this.etag, this.notModified = false});
  final Object? data;
  final String? etag;
  final bool notModified;
}

final class DeckClient {
  DeckClient({
    required this.base,
    required String loginName,
    required String appPassword,
    required this.transport,
    this.apiVersion = '1.1',
    this.timeout = const Duration(seconds: 30),
    DateTime? retryUntil,
    DateTime Function()? now,
  }) : _retryUntil = retryUntil?.toUtc(),
       _now = now ?? DateTime.now,
       _authorization =
           'Basic ${base64Encode(utf8.encode('$loginName:$appPassword'))}' {
    if (loginName.isEmpty || loginName.contains(':') || appPassword.isEmpty) {
      throw ArgumentError('invalid_credentials');
    }
    if (!{'1.0', '1.1'}.contains(apiVersion) || timeout <= Duration.zero) {
      throw ArgumentError('invalid_client_configuration');
    }
  }

  final ServerBase base;
  final http.Client transport;
  final String apiVersion;
  final Duration timeout;
  final String _authorization;
  final DateTime Function() _now;
  DateTime? _retryUntil;
  DateTime? get retryUntil => _retryUntil;

  void deferUntil(DateTime? until) {
    if (until != null && (_retryUntil == null || until.isAfter(_retryUntil!))) {
      _retryUntil = until.toUtc();
    }
  }

  Future<DeckCapabilities> capabilities() async {
    final response = await ocs('GET', ['cloud', 'capabilities']);
    try {
      return DeckCapabilities.fromJson(
        object(object(response.data)['capabilities']),
      );
    } on FormatException {
      throw const DeckException('deck_unavailable');
    }
  }

  Future<List<DeckBoard>> boards() async {
    final response = await rest('GET', ['boards']);
    try {
      return objects(
        response.data,
      ).map(DeckBoard.fromJson).toList(growable: false);
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<List<DeckStack>> stacks(int boardId) async {
    final response = await rest('GET', ['boards', '$boardId', 'stacks']);
    try {
      return objects(
          response.data,
        ).map(DeckStack.fromJson).toList(growable: false)
        ..sort((a, b) => a.order.compareTo(b.order));
    } on FormatException {
      throw const DeckException('invalid_response');
    }
  }

  Future<DeckResponse> rest(
    String method,
    List<String> path, {
    JsonObject? body,
    String? etag,
    Map<String, String>? query,
  }) => _request(method, base.deck(apiVersion, path, query), body, etag, false);

  Future<DeckResponse> ocs(
    String method,
    List<String> path, {
    JsonObject? body,
    Map<String, String>? query,
  }) => _request(method, base.ocs(path, query), body, null, true);

  Future<DeckResponse> _request(
    String method,
    Uri uri,
    JsonObject? body,
    String? etag,
    bool envelope,
  ) async {
    final mutation = method != 'GET';
    final response = await _send(
      (abort) {
        final request = http.AbortableRequest(method, uri, abortTrigger: abort)
          ..headers.addAll({
            'Accept': 'application/json',
            'If-None-Match': ?etag,
          });
        if (body != null) {
          request.headers['Content-Type'] = 'application/json';
          request.body = jsonEncode(body);
        }
        return request;
      },
      mutation: mutation,
      allowNotModified: etag != null,
    );
    if (response.statusCode == 304) {
      return DeckResponse(null, notModified: true, etag: etag);
    }
    final data = _json(response, mutation: mutation);
    if (!envelope) return DeckResponse(data, etag: response.headers['etag']);
    try {
      final ocsData = object(object(data)['ocs']);
      final meta = object(ocsData['meta']);
      if (meta['status'] != 'ok' || ![100, 200].contains(meta['statuscode'])) {
        throw DeckException('ocs_rejected', uncertain: mutation);
      }
      return DeckResponse(ocsData['data'], etag: response.headers['etag']);
    } on FormatException {
      throw DeckException('invalid_response', uncertain: mutation);
    }
  }

  Object? _json(http.Response response, {bool mutation = false}) {
    if (response.headers['content-type']
            ?.split(';')
            .first
            .trim()
            .toLowerCase() !=
        'application/json') {
      throw DeckException('invalid_content_type', uncertain: mutation);
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw DeckException('invalid_response', uncertain: mutation);
    }
  }

  Future<http.Response> _send(
    http.BaseRequest Function(Future<void> abort) create, {
    bool mutation = false,
    bool allowNotModified = false,
    int maxBytes = 16 * 1024 * 1024,
    Future<void>? cancelled,
    Duration? requestTimeout,
  }) async {
    final deadline = _retryUntil;
    if (deadline != null && deadline.isAfter(_now().toUtc())) {
      throw DeckException('rate_limited', status: 429, retryAt: deadline);
    }
    final abort = Completer<void>();
    final request = create(abort.future)
      ..followRedirects = false
      ..headers.addAll({
        'Authorization': _authorization,
        'OCS-APIRequest': 'true',
        'User-Agent': 'OwnDeck',
      });
    if (request.url.origin != base.uri.origin ||
        request.url.userInfo.isNotEmpty) {
      throw const DeckException('untrusted_endpoint');
    }
    cancelled?.then((_) {
      if (!abort.isCompleted) abort.complete();
    });
    try {
      return await (() async {
        final response = await transport.send(request);
        if (response.statusCode == 304 && !mutation && allowNotModified) {
          return http.Response.bytes(const [], 304, headers: response.headers);
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          if (response.statusCode == 429 || response.statusCode == 503) {
            final now = _now().toUtc();
            final until =
                _retryDeadline(response.headers['retry-after'], now) ??
                (response.statusCode == 429
                    ? now.add(const Duration(seconds: 30))
                    : null);
            deferUntil(until);
          }
          throw DeckException(
            switch (response.statusCode) {
              401 => 'authentication_required',
              403 => 'permission_denied',
              404 => 'not_found',
              429 => 'rate_limited',
              _ => 'request_rejected',
            },
            status: response.statusCode,
            retryAt: _retryUntil,
            uncertain:
                mutation &&
                (response.statusCode >= 500 ||
                    response.statusCode >= 300 && response.statusCode < 400),
          );
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > maxBytes) {
            throw DeckException('response_too_large', uncertain: mutation);
          }
          bytes.add(chunk);
        }
        return http.Response.bytes(
          bytes.takeBytes(),
          response.statusCode,
          headers: response.headers,
        );
      })().timeout(requestTimeout ?? timeout);
    } on DeckException {
      rethrow;
    } on FormatException {
      throw DeckException('invalid_response', uncertain: mutation);
    } on TimeoutException {
      throw DeckException('timeout', uncertain: mutation);
    } on TlsException {
      throw const DeckException('tls_failed');
    } on http.RequestAbortedException {
      throw DeckException('cancelled', uncertain: mutation);
    } on http.ClientException {
      throw DeckException('transport_failed', uncertain: mutation);
    } on IOException {
      throw DeckException('transport_failed', uncertain: mutation);
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }
}

DateTime? _retryDeadline(String? value, DateTime now) {
  if (value == null) return null;
  final input = value.trim();
  if (RegExp(r'^[0-9]{1,10}$').hasMatch(input)) {
    return now.add(Duration(seconds: int.parse(input)));
  }
  try {
    final parsed = parseHttpDate(input).toUtc();
    return parsed.isBefore(now) ? now : parsed;
  } on FormatException {
    return null;
  }
}
