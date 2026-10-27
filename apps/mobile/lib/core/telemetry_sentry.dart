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

const _exceptionTypes = {
  'StateError',
  'ArgumentError',
  'RangeError',
  'TypeError',
  'FormatException',
  'FileSystemException',
  'SocketException',
  'HttpException',
  'ClientException',
  'TimeoutException',
  'TlsException',
  'HandshakeException',
  'FlutterError',
  'AssertionError',
  '_AssertionError',
  'UnsupportedError',
  'NoSuchMethodError',
  'OutOfMemoryError',
  'DeckException',
  'LoginException',
  'SqliteException',
  'TelemetryReleaseProbe',
};

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
            type: _exceptionTypes.contains(exception.type)
                ? exception.type
                : 'Error',
            value: '<redacted>',
            stackTrace: _safeStack(exception.stackTrace),
          ),
      ],
    );

final _appFrame = RegExp(
  r'^package:(nextclouddeck|deck_protocol|deck_store)/[a-zA-Z0-9_./-]+\.dart$',
);
final _flutterFrame = RegExp(r'^package:flutter/[a-zA-Z0-9_./-]+\.dart$');

/// App frames only. A FlutterError raised inside the framework has none, so its
/// framework frames are kept instead: public code locations, no user data.
SentryStackTrace? _safeStack(SentryStackTrace? trace) =>
    _framesMatching(trace, _appFrame, inApp: true) ??
    _framesMatching(trace, _flutterFrame, inApp: false);

SentryStackTrace? _framesMatching(
  SentryStackTrace? trace,
  RegExp allowed, {
  required bool inApp,
}) {
  if (trace == null) return null;
  final frames = <SentryStackFrame>[];
  for (final frame in trace.frames.take(100)) {
    final path = frame.absPath?.startsWith('package:') == true
        ? frame.absPath!
        : frame.fileName ?? '';
    if (!allowed.hasMatch(path) || path.contains('/../')) {
      continue;
    }
    final function = frame.function;
    frames.add(
      SentryStackFrame(
        fileName: path,
        function:
            function != null &&
                RegExp(
                  r'^[a-zA-Z_$][a-zA-Z0-9_.$<> ]{0,159}$',
                ).hasMatch(function)
            ? function
            : null,
        lineNo: frame.lineNo,
        colNo: frame.colNo,
        inApp: inApp,
      ),
    );
  }
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
