import 'package:deck_protocol/deck_protocol.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
// Use the pinned Dart transport: native cached envelopes bypass Dart consent.
// ignore: implementation_imports
import 'package:sentry/src/transport/http_transport.dart';
// ignore: implementation_imports
import 'package:sentry/src/transport/rate_limiter.dart';

import 'telemetry.dart';
import 'telemetry_preferences.dart';
import 'telemetry_transport.dart';

const _errorCodes = {
  'timeout',
  'transport_failed',
  'authentication_required',
  'permission_denied',
  'rate_limited',
  'tls_failed',
  'invalid_response',
  'response_too_large',
  'cancelled',
  'invalid_content_type',
  'not_found',
  'request_rejected',
  'ocs_rejected',
  'deck_unavailable',
};

String? _errorCode(SentryEvent event) {
  final error = event.throwable;
  final code = error is DeckException ? error.code : event.tags?['error.code'];
  return _errorCodes.contains(code) ? code : null;
}

SentryEvent scrubSentryEvent(SentryEvent event, TelemetryConfig config) =>
    SentryEvent(
      eventId: event.eventId,
      timestamp: event.timestamp,
      platform: 'dart',
      level: event.level,
      environment: config.safeEnvironment,
      release: config.safeRelease,
      transaction: telemetryRoutes.contains(event.transaction)
          ? event.transaction
          : null,
      tags: {if (_errorCode(event) case final String code) 'error.code': code},
      exceptions: [
        for (final exception in (event.exceptions ?? <SentryException>[]).take(
          10,
        ))
          SentryException(
            type: _truncate(exception.type ?? 'Error', 200),
            value: exception.value == null
                ? null
                : _truncate(scrubSecrets(exception.value!), 8000),
            stackTrace: _readableStack(exception.stackTrace),
          ),
      ],
    );

String _truncate(String text, int max) =>
    text.length <= max ? text : text.substring(0, max);

final _secretPatterns = <(RegExp, String)>[
  // https://user:password@host
  (RegExp(r'(\w+://)[^/\s:@]+:[^/\s@]+@'), r'$1[credentials]@'),
  // Authorization / OCS headers and bearer tokens
  (
    RegExp(
      r'(authorization|ocs-apirequest|cookie)\s*[:=]\s*\S+(\s+\S+)?',
      caseSensitive: false,
    ),
    r'$1: [filtered]',
  ),
  (
    RegExp(r'\b(bearer|basic)\s+[A-Za-z0-9._~+/=-]{8,}', caseSensitive: false),
    r'$1 [filtered]',
  ),
  // app password / token / password query or json values
  (
    RegExp(
      r'("?(?:password|passwd|apppassword|app_password|token|secret)"?\s*[:=]\s*)("[^"]*"|\S+)',
      caseSensitive: false,
    ),
    r'$1[filtered]',
  ),
  // Nextcloud app passwords: five dash-separated groups of five characters
  (RegExp(r'\b[A-Za-z0-9]{5}(-[A-Za-z0-9]{5}){4}\b'), '[filtered]'),
];

/// Error text stays readable; only credentials are cut out.
String scrubSecrets(String text) {
  var out = text;
  for (final (pattern, replacement) in _secretPatterns) {
    out = out.replaceAllMapped(pattern, (m) {
      var r = replacement;
      for (var i = m.groupCount; i >= 1; i--) {
        r = r.replaceAll('\$$i', m.group(i) ?? '');
      }
      return r;
    });
  }
  return out;
}

final _appFrame = RegExp(r'^package:(nextclouddeck|deck_protocol|deck_store)/');

/// Full stack: code locations only (no local variables or source lines).
SentryStackTrace? _readableStack(SentryStackTrace? trace) {
  if (trace == null) return null;
  final frames = [
    for (final frame in trace.frames.take(200))
      SentryStackFrame(
        fileName: frame.fileName,
        absPath: frame.absPath,
        module: frame.module,
        package: frame.package,
        function: frame.function,
        lineNo: frame.lineNo,
        colNo: frame.colNo,
        inApp: _appFrame.hasMatch(frame.absPath ?? frame.fileName ?? ''),
        platform: frame.platform,
      ),
  ];
  return frames.isEmpty ? null : SentryStackTrace(frames: frames);
}

void configureSentryOptions(
  SentryFlutterOptions options,
  TelemetryConfig config,
  TelemetryPreferences preferences,
) {
  options
    ..dsn = config.sentryDsn
    ..environment = config.safeEnvironment
    ..release = config.safeRelease
    ..debug = false
    ..diagnosticLevel = SentryLevel.fatal
    ..sendDefaultPii = false
    ..sendClientReports = false
    ..enableLogs = false
    ..attachScreenshot = false
    // ignore: experimental_member_use
    ..attachViewHierarchy = false
    ..attachThreads = false
    ..autoInitializeNativeSdk = false
    ..enableNativeCrashHandling = false
    ..enableAutoSessionTracking = false
    ..enableAppHangTracking = false
    ..enableWatchdogTerminationTracking = false
    ..enableAutoNativeBreadcrumbs = false
    ..enableUserInteractionBreadcrumbs = false
    ..enableUserInteractionTracing = false
    ..enablePrintBreadcrumbs = false
    ..recordHttpBreadcrumbs = false
    ..enableMemoryPressureBreadcrumbs = false
    ..enableAutoPerformanceTracing = false
    ..enableNativeTraceSync = false
    ..enableScopeSync = false
    ..reportPackages = false
    ..tracesSampleRate = 0
    // ignore: experimental_member_use
    ..profilesSampleRate = 0
    ..beforeBreadcrumb = ((_, _) => null)
    ..beforeSendTransaction = ((_, _) => null)
    ..beforeSend = ((event, _) =>
        preferences.loaded && preferences.crashReporting
        ? scrubSentryEvent(event, config)
        : null);
  options.replay
    ..sessionSampleRate = 0
    ..onErrorSampleRate = 0
    ..networkCaptureBodies = false;
  options.httpClient = TelemetryHttpClient(
    Uri.parse(config.sentryDsn).replace(userInfo: ''),
    () => preferences.loaded && preferences.crashReporting,
  );
  final limiter = RateLimiter(options);
  options.transport = TelemetrySentryTransport(
    HttpTransport(options, limiter),
    config,
    preferences,
    rateLimiter: limiter,
  );
}

final class TelemetrySentryTransport implements Transport {
  TelemetrySentryTransport(
    this.delegate,
    this.config,
    this.preferences, {
    this.rateLimiter,
  });
  final Transport delegate;
  final TelemetryConfig config;
  final TelemetryPreferences preferences;
  final RateLimiter? rateLimiter;

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    SentryId? result;
    for (final item in envelope.items) {
      if (!preferences.loaded ||
          !preferences.crashReporting ||
          !config.crashReportingAvailable) {
        return null;
      }
      final event = item.originalObject;
      if (item.header.type != 'event' || event is! SentryEvent) continue;
      final clean = SentryEnvelope.fromEvent(
        scrubSentryEvent(event, config),
        SdkVersion(name: 'sentry.dart.flutter', version: '9.30.1'),
      );
      final limited = rateLimiter == null ? clean : rateLimiter!.filter(clean);
      if (limited != null) result = await delegate.send(limited);
    }
    return result;
  }
}
