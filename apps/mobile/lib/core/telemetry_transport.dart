import 'package:http/http.dart' as http;
import 'package:rybbit_flutter_sdk/rybbit_flutter_sdk.dart';
// The pinned SDK exposes transport injection but not its transport interface.
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/http_client.dart';

import 'telemetry.dart';
import 'telemetry_preferences.dart';

final class TelemetryHttpClient extends http.BaseClient {
  TelemetryHttpClient(this.origin, this.enabled, {http.Client? client})
    : _client = client ?? http.Client();
  final Uri origin;
  final bool Function() enabled;
  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!enabled() ||
        request.url.origin != origin.origin ||
        request.url.userInfo.isNotEmpty) {
      throw http.ClientException('telemetry_disabled_or_invalid_origin');
    }
    request.followRedirects = false;
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}

final class TelemetryRybbitTransport implements RybbitTransport {
  TelemetryRybbitTransport(this.delegate, this.config, this.preferences);
  final RybbitTransport delegate;
  final TelemetryConfig config;
  final TelemetryPreferences preferences;

  @override
  Future<bool> sendEvent(TrackPayload payload) async {
    if (!preferences.loaded ||
        !preferences.analytics ||
        !config.analyticsAvailable) {
      return true;
    }
    final isScreen =
        payload.type == EventType.pageview &&
        telemetryRoutes.contains(payload.pathname);
    final isEvent =
        payload.type == EventType.customEvent &&
        TelemetryEvent.values.any(
          (event) => event.eventName == payload.eventName,
        );
    if (!isScreen && !isEvent) return true;
    // Rebuild the payload so SDK enrichment, stale queues and direct SDK calls
    // cannot send account identifiers, titles, URLs, input or custom properties.
    return delegate.sendEvent(
      TrackPayload(
        type: payload.type,
        siteId: config.rybbitSiteId,
        hostname: 'com.nkshub.nextclouddeck',
        pathname: isScreen ? payload.pathname : '/',
        pageTitle: isScreen ? payload.pathname : null,
        eventName: isEvent ? payload.eventName : null,
        userAgent: 'OwnDeck',
        properties: {
          'environment': config.safeEnvironment,
          if (config.safeRelease != null) 'release': config.safeRelease,
        },
      ),
    );
  }

  // These SDK item kinds are deliberately discarded, not retried or sent.
  @override
  Future<bool> sendIdentify(IdentifyPayload payload) async => true;
  @override
  Future<bool> hasSiteIcon(String siteId) async => true;
  @override
  Future<bool> uploadSiteIcon(String siteId, String base64Png) async => true;
}
