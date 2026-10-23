import 'dart:async';
import 'dart:convert';
import 'dart:io' show TlsException;

import 'package:http/http.dart' as http;

import 'models.dart';
import 'server_base.dart';

final class DeckException implements Exception {
  const DeckException(this.code, {this.status, this.uncertain = false});

  final String code;
  final int? status;
  final bool uncertain;

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
  }) : _authorization =
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
    final abort = Completer<void>();
    final request =
        http.AbortableRequest(method, uri, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers.addAll({
            'Authorization': _authorization,
            'OCS-APIRequest': 'true',
            'Accept': 'application/json',
            'User-Agent': 'OwnDeck',
            if (etag != null) 'If-None-Match': etag,
          });
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      return await (() async {
        final response = await transport.send(request);
        if (response.statusCode == 304 && !mutation) {
          return DeckResponse(null, notModified: true, etag: etag);
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw DeckException(
            switch (response.statusCode) {
              401 => 'authentication_required',
              403 => 'permission_denied',
              404 => 'not_found',
              429 => 'rate_limited',
              _ => 'request_rejected',
            },
            status: response.statusCode,
            uncertain:
                mutation &&
                (response.statusCode >= 500 ||
                    response.statusCode >= 300 && response.statusCode < 400),
          );
        }
        if (response.headers['content-type']
                ?.split(';')
                .first
                .trim()
                .toLowerCase() !=
            'application/json') {
          throw DeckException('invalid_content_type', uncertain: mutation);
        }
        final bytes = <int>[];
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > 16 * 1024 * 1024) {
            throw DeckException('response_too_large', uncertain: mutation);
          }
          bytes.addAll(chunk);
        }
        Object? data = jsonDecode(utf8.decode(bytes));
        if (envelope) {
          final ocsData = object(object(data)['ocs']);
          final meta = object(ocsData['meta']);
          if (meta['status'] != 'ok' ||
              ![100, 200].contains(meta['statuscode'])) {
            throw DeckException('ocs_rejected', uncertain: mutation);
          }
          data = ocsData['data'];
        }
        return DeckResponse(data, etag: response.headers['etag']);
      })().timeout(timeout);
    } on DeckException {
      rethrow;
    } on FormatException {
      throw DeckException('invalid_response', uncertain: mutation);
    } on TimeoutException {
      throw DeckException('timeout', uncertain: mutation);
    } on TlsException {
      throw const DeckException('tls_failed');
    } on http.ClientException {
      throw DeckException('transport_failed', uncertain: mutation);
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }
}
