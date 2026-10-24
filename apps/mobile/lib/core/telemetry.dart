final class TelemetryConfig {
  const TelemetryConfig({
    this.sentryDsn = '',
    this.rybbitHost = '',
    this.rybbitSiteId = '',
    this.environment = 'development',
    this.release = '',
    this.releaseProbe = false,
  });

  factory TelemetryConfig.fromEnvironment() => const TelemetryConfig(
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
    rybbitHost: String.fromEnvironment('RYBBIT_HOST'),
    rybbitSiteId: String.fromEnvironment('RYBBIT_SITE_ID'),
    environment: String.fromEnvironment(
      'TELEMETRY_ENVIRONMENT',
      defaultValue: 'development',
    ),
    release: String.fromEnvironment('TELEMETRY_RELEASE'),
    releaseProbe: bool.fromEnvironment('TELEMETRY_RELEASE_PROBE'),
  );

  final String sentryDsn;
  final String rybbitHost;
  final String rybbitSiteId;
  final String environment;
  final String release;
  final bool releaseProbe;

  bool get crashReportingAvailable {
    final uri = Uri.tryParse(sentryDsn);
    return _https(uri) &&
        uri!.userInfo.isNotEmpty &&
        !uri.userInfo.contains(':') &&
        RegExp(r'^[a-zA-Z0-9]+$').hasMatch(uri.userInfo) &&
        uri.pathSegments.isNotEmpty &&
        RegExp(r'^\d+$').hasMatch(uri.pathSegments.last);
  }

  bool get analyticsAvailable {
    final uri = Uri.tryParse(rybbitHost);
    return _https(uri) &&
        uri!.userInfo.isEmpty &&
        RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(rybbitSiteId);
  }

  String get safeEnvironment =>
      const {
        'development',
        'staging',
        'production',
        'test',
      }.contains(environment)
      ? environment
      : 'development';
  String? get safeRelease =>
      RegExp(
        r'^com\.nkshub\.nextclouddeck@\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?\+\d+$',
      ).hasMatch(release)
      ? release
      : null;

  static bool _https(Uri? uri) =>
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      !uri.pathSegments.any(
        (part) =>
            part == '..' ||
            part == '.' ||
            part.contains('\\') ||
            part.contains('/') ||
            part.runes.any((c) => c < 32 || c == 127),
      );
}

const telemetryRoutes = {
  '/',
  '/login',
  '/onboarding/qr',
  '/accounts',
  '/boards',
  '/board',
  '/board/sharing',
  '/board/labels',
  '/card',
  '/card/edit',
  '/comment/edit',
  '/comments',
  '/attachments',
  '/files',
  '/drafts',
  '/sync',
  '/search',
  '/my-tasks',
  '/settings',
};

enum TelemetryEvent { appOpen, releaseProbe }

extension TelemetryEventName on TelemetryEvent {
  String get eventName => switch (this) {
    TelemetryEvent.appOpen => 'app_open',
    TelemetryEvent.releaseProbe => 'release_probe',
  };
}
