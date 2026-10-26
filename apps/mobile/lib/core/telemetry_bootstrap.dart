import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rybbit_flutter_sdk/rybbit_flutter_sdk.dart';
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/http_client.dart';
// The pinned SDK keeps its default persistent queue type internal.
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/offline_store.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'telemetry.dart';
import 'telemetry_preferences.dart';
import 'telemetry_sentry.dart';
import 'telemetry_transport.dart';

abstract interface class TelemetryBackend {
  Future<void> startCrashes(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  );
  Future<void> stopCrashes();
  Future<void> startAnalytics(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  );
  Future<void> stopAnalytics({bool clearPendingEvents = false});
  void screen(String route);
  void event(TelemetryEvent event);
  Future<void> probeCrash();
}

final class TelemetrySdkBackend implements TelemetryBackend {
  RybbitHttpClient? _analyticsHttp;
  final _analyticsStore = HiveOfflineStore(maxEvents: 100, ttlDays: 1);
  bool _analyticsClearPending = false;

  @override
  Future<void> startCrashes(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  ) => SentryFlutter.init(
    (options) => configureSentryOptions(options, config, preferences),
  );

  @override
  Future<void> stopCrashes() => Sentry.close();

  @override
  Future<void> startAnalytics(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  ) async {
    final markerType = await FileSystemEntity.type(
      (await _clearMarker()).path,
      followLinks: false,
    );
    if (_analyticsClearPending || markerType != FileSystemEntityType.notFound) {
      await stopAnalytics(clearPendingEvents: true);
    }
    final host = config.rybbitHost.replaceFirst(RegExp(r'/$'), '');
    final http = RybbitHttpClient(
      host: host,
      client: TelemetryHttpClient(
        Uri.parse(host),
        () => preferences.loaded && preferences.analytics,
      ),
    );
    _analyticsHttp = http;
    await Rybbit.init(
      host: host,
      siteId: config.rybbitSiteId,
      transport: TelemetryRybbitTransport(http, config, preferences),
      autoTrackErrors: false,
      autoTrackLifecycle: false,
      autoUploadIcon: false,
      debug: false,
      maxOfflineEvents: _analyticsStore.maxEvents,
      offlineTtlDays: _analyticsStore.ttlDays,
      userAgent: 'OwnDeck',
    );
  }

  @override
  Future<void> stopAnalytics({bool clearPendingEvents = false}) async {
    _analyticsClearPending |= clearPendingEvents;
    File? marker;
    Object? markerError;
    StackTrace? markerStack;
    if (_analyticsClearPending) {
      try {
        marker = await _clearMarker();
        await marker.writeAsString('pending', flush: true);
      } catch (error, stack) {
        markerError = error;
        markerStack = stack;
      }
    }
    try {
      await Rybbit.reset();
      if (markerError != null) {
        Error.throwWithStackTrace(markerError, markerStack!);
      }
      if (_analyticsClearPending) {
        // reset waits for in-flight retries before closing the SDK's box.
        // An explicit path also works before this process has initialized SDKs.
        final box = await Hive.openBox<String>(
          _analyticsStore.boxName,
          path: marker!.parent.path,
        );
        try {
          await box.clear();
        } finally {
          await box.close();
        }
        await marker.delete();
        _analyticsClearPending = false;
      }
    } finally {
      _analyticsHttp?.close();
      _analyticsHttp = null;
    }
  }

  Future<File> _clearMarker() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/owndeck-analytics-clear-pending');
  }

  @override
  void screen(String route) {
    if (Rybbit.isInitialized) Rybbit.instance.screenView(route, title: route);
  }

  @override
  void event(TelemetryEvent event) {
    if (Rybbit.isInitialized) Rybbit.instance.event(event.eventName);
  }

  @override
  Future<void> probeCrash() async {
    await Sentry.captureException(
      const TelemetryReleaseProbe(),
      stackTrace: StackTrace.current,
    );
  }
}

final class TelemetryReleaseProbe implements Exception {
  const TelemetryReleaseProbe();
}

final class TelemetryRuntime extends ChangeNotifier {
  TelemetryRuntime({
    required this.config,
    TelemetryPreferences? preferences,
    TelemetryBackend? backend,
  }) : preferences = preferences ?? TelemetryPreferences(),
       _backend = backend ?? TelemetrySdkBackend();
  final TelemetryConfig config;
  final TelemetryPreferences preferences;
  final TelemetryBackend _backend;
  Future<void>? _initializing;
  Future<void> _tail = Future.value();
  bool _closed = false;
  bool crashesReady = false;
  bool analyticsReady = false;
  String? _lastScreen;
  String? _currentScreen;
  bool _crashProbed = false;
  bool _analyticsProbed = false;
  bool _analyticsOptOutHandled = false;

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!config.crashReportingAvailable && !config.analyticsAvailable) return;
    await preferences.load();
    if (_closed) return;
    preferences.addListener(_changed);
    await synchronize();
  }

  void _changed() {
    unawaited(synchronize());
  }

  Future<void> setCrashReporting(bool value) =>
      preferences.setCrashReporting(value);
  Future<void> setAnalytics(bool value) async {
    if (value && config.analyticsAvailable && !preferences.analytics) {
      await _tail;
      if (!_analyticsOptOutHandled) {
        await _backend.stopAnalytics(clearPendingEvents: true);
        _analyticsOptOutHandled = true;
      }
    }
    await preferences.setAnalytics(value);
  }

  Future<void> synchronize() {
    final next = _tail.then((_) => _synchronize());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _synchronize() async {
    if (_closed) return;
    final crash =
        config.crashReportingAvailable &&
        preferences.loaded &&
        preferences.crashReporting;
    if (crash && !crashesReady) {
      try {
        await _backend.startCrashes(config, preferences);
        crashesReady = true;
      } catch (_) {
        crashesReady = false;
        // Optional SDK failure never prevents the already-running app from opening.
        try {
          await _backend.stopCrashes();
        } catch (_) {}
      }
    } else if (!crash && crashesReady) {
      crashesReady = false;
      try {
        await _backend.stopCrashes();
      } catch (_) {}
    }
    final analytics =
        config.analyticsAvailable &&
        preferences.loaded &&
        preferences.analytics;
    if (analytics && !analyticsReady) {
      _analyticsOptOutHandled = false;
      try {
        await _backend.startAnalytics(config, preferences);
        analyticsReady = true;
        if (preferences.analytics && !_closed) {
          _backend.event(TelemetryEvent.appOpen);
          final current = _currentScreen;
          if (current != null) {
            _backend.screen(current);
            _lastScreen = current;
          }
        }
      } catch (_) {
        analyticsReady = false;
        try {
          await _backend.stopAnalytics();
        } catch (_) {}
      }
    } else if (!analytics &&
        (analyticsReady ||
            (config.analyticsAvailable &&
                preferences.loaded &&
                !_analyticsOptOutHandled))) {
      analyticsReady = false;
      _lastScreen = null;
      try {
        final clearPending = preferences.loaded && !preferences.analytics;
        await _backend.stopAnalytics(clearPendingEvents: clearPending);
        if (clearPending) {
          _analyticsOptOutHandled = true;
        }
      } catch (_) {}
    }
    if (config.releaseProbe && !_closed) {
      if (crashesReady && preferences.crashReporting && !_crashProbed) {
        _crashProbed = true;
        try {
          await _backend.probeCrash();
        } catch (_) {}
      }
      if (analyticsReady && preferences.analytics && !_analyticsProbed) {
        _analyticsProbed = true;
        event(TelemetryEvent.releaseProbe);
      }
    }
    if (!_closed) notifyListeners();
  }

  void screen(String route) {
    if (_closed || !telemetryRoutes.contains(route)) return;
    _currentScreen = route;
    if (_closed ||
        !analyticsReady ||
        !preferences.analytics ||
        !telemetryRoutes.contains(route) ||
        _lastScreen == route) {
      return;
    }
    _lastScreen = route;
    try {
      _backend.screen(route);
    } catch (_) {
      _lastScreen = null;
    }
  }

  void event(TelemetryEvent event) {
    if (!_closed && analyticsReady && preferences.analytics) {
      try {
        _backend.event(event);
      } catch (_) {}
    }
  }

  NavigatorObserver navigatorObserver() => TelemetryNavigatorObserver(this);

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    preferences.removeListener(_changed);
    preferences.crashReporting = preferences.analytics = false;
    await _tail;
    try {
      await _backend.stopAnalytics();
    } catch (_) {}
    try {
      await _backend.stopCrashes();
    } catch (_) {}
    crashesReady = analyticsReady = false;
    super.dispose();
  }
}

final class TelemetryNavigatorObserver extends NavigatorObserver {
  TelemetryNavigatorObserver(this.runtime);
  final TelemetryRuntime runtime;
  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) runtime.screen(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _track(newRoute);
}

final telemetry = TelemetryRuntime(config: TelemetryConfig.fromEnvironment());
