import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/telemetry.dart';
import 'package:nextclouddeck/core/telemetry_bootstrap.dart';
import 'package:nextclouddeck/core/telemetry_preferences.dart';

const configured = TelemetryConfig(
  sentryDsn: 'https://publickey@sentry.example.com/42',
  rybbitHost: 'https://analytics.example.com',
  rybbitSiteId: 'site42',
);

class MemoryPreferences implements TelemetryPreferenceStore {
  final values = <String, bool>{};
  int reads = 0;
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? writeGate;
  @override
  Future<bool?> read(String key) async {
    reads++;
    if (failRead) throw StateError('unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, bool value) async {
    await writeGate?.future;
    if (failWrite) throw StateError('unavailable');
    values[key] = value;
  }
}

class FakeBackend implements TelemetryBackend {
  int crashStarts = 0, crashStops = 0, analyticsStarts = 0, analyticsStops = 0;
  bool crashFailure = false, analyticsFailure = false;
  Completer<void>? analyticsGate;
  final screens = <String>[];
  final events = <TelemetryEvent>[];
  @override
  Future<void> startCrashes(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  ) async {
    crashStarts++;
    if (crashFailure) throw StateError('sdk_unavailable');
  }

  @override
  Future<void> startAnalytics(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  ) async {
    analyticsStarts++;
    await analyticsGate?.future;
    if (analyticsFailure) throw StateError('sdk_unavailable');
  }

  @override
  Future<void> stopCrashes() async {
    crashStops++;
  }

  @override
  Future<void> stopAnalytics() async {
    analyticsStops++;
  }

  @override
  void screen(String route) => screens.add(route);
  @override
  void event(TelemetryEvent event) => events.add(event);
}

void main() {
  test(
    'unconfigured builds never load preferences or initialize SDKs',
    () async {
      final store = MemoryPreferences();
      final backend = FakeBackend();
      final runtime = TelemetryRuntime(
        config: const TelemetryConfig(),
        preferences: TelemetryPreferences(store: store),
        backend: backend,
      );
      await runtime.initialize();
      expect(store.reads, 0);
      expect(backend.crashStarts, 0);
      expect(backend.analyticsStarts, 0);
      await runtime.close();
    },
  );

  test(
    'stored opt-outs survive a new runtime and services remain independent',
    () async {
      final store = MemoryPreferences()
        ..values.addAll({
          TelemetryPreferences.crashKey: false,
          TelemetryPreferences.analyticsKey: false,
        });
      final backend = FakeBackend();
      final runtime = TelemetryRuntime(
        config: configured,
        preferences: TelemetryPreferences(store: store),
        backend: backend,
      );
      await runtime.initialize();
      expect(backend.crashStarts + backend.analyticsStarts, 0);
      await runtime.setAnalytics(true);
      await runtime.synchronize();
      expect(runtime.analyticsReady, isTrue);
      expect(backend.crashStarts, 0);
      runtime.screen('/card');
      expect(backend.screens, ['/card']);
      final disabling = runtime.setAnalytics(false);
      runtime.screen('/boards');
      expect(backend.screens, ['/card']);
      await disabling;
      await runtime.synchronize();
      expect(runtime.analyticsReady, isFalse);
      await runtime.close();
      final restarted = TelemetryRuntime(
        config: configured,
        preferences: TelemetryPreferences(store: store),
        backend: FakeBackend(),
      );
      await restarted.initialize();
      expect(restarted.analyticsReady, isFalse);
      expect(restarted.crashesReady, isFalse);
      await restarted.close();
    },
  );

  test('unreadable preferences cannot enable collection', () async {
    final store = MemoryPreferences()..failRead = true;
    final backend = FakeBackend();
    final runtime = TelemetryRuntime(
      config: configured,
      preferences: TelemetryPreferences(store: store),
      backend: backend,
    );
    await runtime.initialize();
    expect(runtime.preferences.loaded, isFalse);
    expect(backend.crashStarts + backend.analyticsStarts, 0);
    await runtime.close();
  });

  test(
    'SDK failure does not throw or stop the other configured service',
    () async {
      final backend = FakeBackend()..crashFailure = true;
      final runtime = TelemetryRuntime(
        config: configured,
        preferences: TelemetryPreferences(store: MemoryPreferences()),
        backend: backend,
      );
      await runtime.initialize();
      expect(runtime.crashesReady, isFalse);
      expect(runtime.analyticsReady, isTrue);
      expect(backend.events, [TelemetryEvent.appOpen]);
      await runtime.close();
    },
  );

  test('a late enable cannot undo a newer opt-out', () async {
    final store = MemoryPreferences()
      ..values[TelemetryPreferences.analyticsKey] = false;
    final preferences = TelemetryPreferences(store: store);
    await preferences.load();
    store.writeGate = Completer<void>();
    final observed = <bool>[];
    preferences.addListener(() => observed.add(preferences.analytics));
    final enabling = preferences.setAnalytics(true);
    final disabling = preferences.setAnalytics(false);
    store.writeGate!.complete();
    await Future.wait([enabling, disabling]);
    expect(preferences.analytics, isFalse);
    expect(store.values[TelemetryPreferences.analyticsKey], isFalse);
    expect(observed, everyElement(isFalse));
  });

  test(
    'a failed write never turns collection back on during this run',
    () async {
      final store = MemoryPreferences();
      final preferences = TelemetryPreferences(store: store);
      await preferences.load();
      store.failWrite = true;
      await expectLater(preferences.setCrashReporting(false), throwsStateError);
      expect(preferences.crashReporting, isFalse);
    },
  );

  test(
    'opting out during initialization prevents the first analytics event',
    () async {
      final backend = FakeBackend()..analyticsGate = Completer<void>();
      final runtime = TelemetryRuntime(
        config: configured,
        preferences: TelemetryPreferences(store: MemoryPreferences()),
        backend: backend,
      );
      final start = runtime.initialize();
      while (backend.analyticsStarts == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      await runtime.setAnalytics(false);
      backend.analyticsGate!.complete();
      await start;
      await runtime.synchronize();
      expect(backend.events, isEmpty);
      expect(runtime.analyticsReady, isFalse);
      await runtime.close();
    },
  );

  test(
    'route names are allowed explicitly and duplicates are suppressed',
    () async {
      final backend = FakeBackend();
      final runtime = TelemetryRuntime(
        config: configured,
        preferences: TelemetryPreferences(store: MemoryPreferences()),
        backend: backend,
      );
      await runtime.initialize();
      runtime.screen('/card/private-title');
      runtime.screen('https://cloud.example.com/card/8');
      runtime.screen('/card');
      runtime.screen('/card');
      runtime.screen('/boards');
      expect(backend.screens, ['/card', '/boards']);
      await runtime.close();
    },
  );
}
