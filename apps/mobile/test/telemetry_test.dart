import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/telemetry.dart';
import 'package:nextclouddeck/core/telemetry_preferences.dart';
import 'package:nextclouddeck/core/telemetry_sentry.dart';
import 'package:nextclouddeck/core/telemetry_transport.dart';
import 'package:rybbit_flutter_sdk/rybbit_flutter_sdk.dart';
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/http_client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'telemetry_runtime_test.dart' show MemoryPreferences;

const config = TelemetryConfig(
  sentryDsn: 'https://publickey@sentry.example.com/42',
  rybbitHost: 'https://analytics.example.com',
  rybbitSiteId: 'site42',
  environment: 'test',
  release: 'com.nkshub.nextclouddeck@0.1.0+1',
);

class RybbitRecorder implements RybbitTransport {
  final events = <TrackPayload>[];
  int identifications = 0;
  @override
  Future<bool> sendEvent(TrackPayload payload) async {
    events.add(payload);
    return true;
  }

  @override
  Future<bool> sendIdentify(IdentifyPayload payload) async {
    identifications++;
    return true;
  }

  @override
  Future<bool> hasSiteIcon(String siteId) async =>
      throw StateError('unexpected_icon_request');
  @override
  Future<bool> uploadSiteIcon(String siteId, String base64Png) async =>
      throw StateError('unexpected_icon_request');
}

class SentryRecorder implements Transport {
  final envelopes = <SentryEnvelope>[];
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    envelopes.add(envelope);
    return envelope.header.eventId;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'missing or malformed configuration leaves the corresponding SDK disabled',
    () {
      expect(const TelemetryConfig().analyticsAvailable, isFalse);
      expect(const TelemetryConfig().crashReportingAvailable, isFalse);
      expect(
        const TelemetryConfig(
          sentryDsn: 'https://key:password@sentry.example.com/42',
        ).crashReportingAvailable,
        isFalse,
      );
      expect(
        const TelemetryConfig(
          rybbitHost: 'https://user@analytics.example.com',
          rybbitSiteId: '42',
        ).analyticsAvailable,
        isFalse,
      );
      expect(config.analyticsAvailable, isTrue);
      expect(config.crashReportingAvailable, isTrue);
    },
  );

  test('CI configuration is optional but a supplied complete set is valid', () {
    final build = TelemetryConfig.fromEnvironment();
    if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
      expect(build.crashReportingAvailable, isTrue);
    }
    if (const String.fromEnvironment('RYBBIT_HOST').isNotEmpty) {
      expect(build.analyticsAvailable, isTrue);
    }
  });

  test(
    'Sentry retains code locations but no values, context, paths or credentials',
    () {
      final event = SentryEvent(
        request: SentryRequest(url: 'https://cloud.example.com/card/8'),
        message: SentryMessage('private card contents'),
        user: SentryUser(id: 'private-user', email: 'person@example.com'),
        tags: {'private': 'private card contents'},
        contexts: Contexts.fromJson({
          'private': {'text': 'private card contents'},
        }),
        transaction: '/card/8',
        serverName: 'private-server',
        unknown: {'private': 'private card contents'},
        exceptions: [
          SentryException(
            type: 'FormatException',
            value: 'private card contents',
            stackTrace: SentryStackTrace(
              frames: [
                SentryStackFrame(
                  fileName: 'file.dart',
                  absPath: 'package:nextclouddeck/data/file.dart',
                  function: 'readFile',
                  lineNo: 12,
                  vars: {'text': 'private card contents'},
                  contextLine: 'private card contents',
                  preContext: ['private card contents'],
                ),
                SentryStackFrame(
                  fileName: 'private.txt',
                  absPath: 'C:/Users/private/private.txt',
                  function: 'private function',
                ),
              ],
            ),
          ),
        ],
        breadcrumbs: [
          Breadcrumb(message: 'Authorization: Basic private', category: 'http'),
        ],
      );
      final clean = scrubSentryEvent(event, config);
      final wire = jsonEncode(clean.toJson());
      expect(wire, isNot(contains('private')));
      expect(wire, isNot(contains('cloud.example.com')));
      expect(
        clean.exceptions!.single.stackTrace!.frames.single.fileName,
        'package:nextclouddeck/data/file.dart',
      );
      expect(clean.exceptions!.single.stackTrace!.frames.single.lineNo, 12);
      expect(clean.release, config.release);
    },
  );

  test('framework error without app frames keeps Flutter frames only', () {
    SentryStackFrame frame(String path) => SentryStackFrame(
      absPath: path,
      fileName: path,
      function: 'f',
      lineNo: 7,
    );
    final clean = scrubSentryEvent(
      SentryEvent(
        exceptions: [
          SentryException(
            type: 'FlutterError',
            value: 'private card contents',
            stackTrace: SentryStackTrace(
              frames: [
                frame('package:flutter/src/rendering/flex.dart'),
                frame('package:private_plugin/secret.dart'),
                frame('dart:core/errors.dart'),
              ],
            ),
          ),
        ],
      ),
      config,
    );
    final frames = clean.exceptions!.single.stackTrace!.frames;
    expect(frames.map((f) => f.fileName), [
      'package:flutter/src/rendering/flex.dart',
    ]);
    expect(frames.single.inApp, isFalse);
    expect(jsonEncode(clean.toJson()), isNot(contains('private')));
  });

  test('app frames win over Flutter frames', () {
    final clean = scrubSentryEvent(
      SentryEvent(
        exceptions: [
          SentryException(
            type: 'FlutterError',
            value: 'x',
            stackTrace: SentryStackTrace(
              frames: [
                SentryStackFrame(
                  absPath: 'package:flutter/src/widgets/framework.dart',
                ),
                SentryStackFrame(
                  absPath: 'package:nextclouddeck/ui/board.dart',
                ),
              ],
            ),
          ),
        ],
      ),
      config,
    );
    expect(clean.exceptions!.single.stackTrace!.frames.map((f) => f.fileName), [
      'package:nextclouddeck/ui/board.dart',
    ]);
  });

  test('only known protocol error codes survive repeated scrubbing', () {
    final clean = scrubSentryEvent(
      SentryEvent(throwable: const DeckException('timeout')),
      config,
    );
    expect(scrubSentryEvent(clean, config).tags, {'error.code': 'timeout'});
    expect(
      scrubSentryEvent(
        SentryEvent(throwable: const DeckException('private-content')),
        config,
      ).tags,
      isEmpty,
    );
  });

  test(
    'Sentry transport drops attachments, unknown item kinds and opted-out events',
    () async {
      final preferences = TelemetryPreferences(store: MemoryPreferences());
      await preferences.load();
      final recorder = SentryRecorder();
      final transport = TelemetrySentryTransport(recorder, config, preferences);
      final event = SentryEvent(message: SentryMessage('private contents'));
      final envelope = SentryEnvelope.fromEvent(
        event,
        SdkVersion(name: 'fixture', version: '1'),
        attachments: [
          SentryAttachment.fromIntList([1, 2, 3], 'private.txt'),
        ],
      );
      await transport.send(envelope);
      expect(recorder.envelopes.single.items.length, 1);
      expect(
        jsonEncode(
          (recorder.envelopes.single.items.single.originalObject as SentryEvent)
              .toJson(),
        ),
        isNot(contains('private')),
      );
      await preferences.setCrashReporting(false);
      await transport.send(envelope);
      expect(recorder.envelopes.length, 1);
    },
  );

  test(
    'Rybbit sends only fixed screen and event fields after SDK enrichment',
    () async {
      final preferences = TelemetryPreferences(store: MemoryPreferences());
      await preferences.load();
      final recorder = RybbitRecorder();
      final transport = TelemetryRybbitTransport(recorder, config, preferences);
      await transport.sendEvent(
        const TrackPayload(
          type: EventType.pageview,
          siteId: 'private-site',
          pathname: '/card',
          hostname: 'private-server',
          querystring: 'private-query',
          pageTitle: 'private-title',
          userId: 'private-user',
          anonymousId: 'private-device',
          referrer: 'private-url',
          deviceModel: 'private-model',
          properties: {'text': 'private-content'},
        ),
      );
      final wire = jsonEncode(recorder.events.single.toJson());
      expect(wire, isNot(contains('private')));
      expect(recorder.events.single.siteId, 'site42');
      await transport.sendEvent(
        const TrackPayload(
          type: EventType.pageview,
          siteId: 'site42',
          pathname: '/card/private',
        ),
      );
      await transport.sendEvent(
        const TrackPayload(
          type: EventType.error,
          siteId: 'site42',
          properties: {'message': 'private'},
        ),
      );
      expect(recorder.events.length, 1);
      await preferences.setAnalytics(false);
      await transport.sendEvent(
        const TrackPayload(
          type: EventType.pageview,
          siteId: 'site42',
          pathname: '/boards',
        ),
      );
      expect(recorder.events.length, 1);
    },
  );

  test(
    'telemetry HTTP refuses foreign origins and disables redirects',
    () async {
      var enabled = true;
      var requests = 0;
      final client = TelemetryHttpClient(
        Uri.parse('https://analytics.example.com'),
        () => enabled,
        client: MockClient((request) async {
          requests++;
          expect(request.followRedirects, isFalse);
          return http.Response(
            '',
            302,
            headers: {'location': 'https://other.example.com'},
          );
        }),
      );
      await client.get(Uri.parse('https://analytics.example.com/api/track'));
      await expectLater(
        client.get(Uri.parse('https://other.example.com')),
        throwsA(isA<http.ClientException>()),
      );
      enabled = false;
      await expectLater(
        client.get(Uri.parse('https://analytics.example.com/api/track')),
        throwsA(isA<http.ClientException>()),
      );
      expect(requests, 1);
      client.close();
    },
  );

  test(
    'the real Sentry Dart capture pipeline preserves an allowlisted stack',
    () async {
      final preferences = TelemetryPreferences(store: MemoryPreferences());
      await preferences.load();
      final recorder = SentryRecorder();
      final options = SentryFlutterOptions();
      await Sentry.init((options) {
        configureSentryOptions(
          options as SentryFlutterOptions,
          config,
          preferences,
        );
        options.transport = TelemetrySentryTransport(
          recorder,
          config,
          preferences,
        );
        // Exercise Dart capture without loading a native test host SDK.
        // ignore: invalid_use_of_internal_member
      }, options: options);
      try {
        await Sentry.captureException(
          const FormatException('private card'),
          stackTrace: StackTrace.fromString(
            '#0 readFile (package:nextclouddeck/data/file.dart:12:4)',
          ),
        );
        final event =
            recorder.envelopes.single.items.single.originalObject
                as SentryEvent;
        expect(event.exceptions!.single.type, 'FormatException');
        expect(event.exceptions!.single.stackTrace!.frames.single.lineNo, 12);
        expect(jsonEncode(event.toJson()), isNot(contains('private card')));
      } finally {
        await Sentry.close();
      }
    },
  );
}
