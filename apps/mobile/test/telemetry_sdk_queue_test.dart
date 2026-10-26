import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/telemetry.dart';
import 'package:nextclouddeck/core/telemetry_bootstrap.dart';
import 'package:nextclouddeck/core/telemetry_preferences.dart';
import 'package:nextclouddeck/core/telemetry_transport.dart';
// Host-only path injection for the SDK's real Hive store.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:rybbit_flutter_sdk/rybbit_flutter_sdk.dart';
// The pinned SDK accepts these dependencies but does not export their types.
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/device_info.dart';
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/http_client.dart';
// ignore: implementation_imports
import 'package:rybbit_flutter_sdk/src/services/offline_store.dart';

const config = TelemetryConfig(
  rybbitHost: 'https://analytics.example.com',
  rybbitSiteId: 'queue-test',
);

class Preferences implements TelemetryPreferenceStore {
  final values = <String, bool>{};
  Completer<void>? writing;
  @override
  Future<bool?> read(String key) async => values[key];
  @override
  Future<void> write(String key, bool value) async {
    await writing?.future;
    values[key] = value;
  }
}

class Paths extends PathProviderPlatform {
  Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

class DeviceInfo implements DeviceInfoProvider {
  @override
  Future<DeviceData> collect() async => const DeviceData(
    appName: 'Test',
    packageName: 'example.test',
    appVersion: '1',
    sdkVersion: 'test',
    platform: 'test',
    osVersion: 'test',
    deviceModel: 'test',
    screenWidth: 320,
    screenHeight: 640,
    language: 'en',
  );
}

class TransportRecorder implements RybbitTransport {
  final attempts = <String?>[];
  bool succeeds = false;
  Completer<void>? sending;
  @override
  Future<bool> sendEvent(TrackPayload payload) async {
    attempts.add(payload.pathname);
    await sending?.future;
    return succeeds;
  }

  @override
  Future<bool> sendIdentify(IdentifyPayload payload) async => true;
  @override
  Future<bool> hasSiteIcon(String siteId) async => true;
  @override
  Future<bool> uploadSiteIcon(String siteId, String base64Png) async => true;
}

Future<void> until(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) fail('SDK operation did not settle');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory folder;
  late PathProviderPlatform previousPaths;
  late Preferences storage;
  late TelemetryPreferences preferences;
  late TransportRecorder recorder;
  late TelemetryRuntime runtime;
  late HiveOfflineStore queue;

  Future<void> startSdk() => Rybbit.init(
    host: config.rybbitHost,
    siteId: config.rybbitSiteId,
    deviceInfoProvider: DeviceInfo(),
    transport: TelemetryRybbitTransport(recorder, config, preferences),
    autoTrackErrors: false,
    autoTrackLifecycle: false,
    autoUploadIcon: false,
    flushThreshold: 1,
    flushInterval: const Duration(hours: 1),
  );

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('owndeck-sdk-queue-');
    previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = Paths(folder.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
    storage = Preferences();
    preferences = TelemetryPreferences(store: storage);
    await preferences.load();
    recorder = TransportRecorder();
    // Control only platform/network inputs; use real SDK buffering and Hive.
    await startSdk();
    runtime = TelemetryRuntime(config: config, preferences: preferences);
    await runtime.initialize();
    queue = HiveOfflineStore();
    await queue.init();
    await until(() => recorder.attempts.isNotEmpty);
    for (var i = 0; i < 100 && await queue.count == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(await queue.count, greaterThan(0));
  });

  tearDown(() async {
    if (recorder.sending case final pending? when !pending.isCompleted) {
      pending.complete();
    }
    await runtime.close();
    await Rybbit.reset();
    await queue.init();
    await queue.close();
    PathProviderPlatform.instance = previousPaths;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          null,
        );
    expect(folder.parent.absolute.path, Directory.systemTemp.absolute.path);
    expect(
      folder.path.split(Platform.pathSeparator).last,
      startsWith('owndeck-sdk-queue-'),
    );
    await folder.delete(recursive: true);
  });

  test('analytics opt-out clears persisted SDK retry events', () async {
    await runtime.setAnalytics(false);
    await runtime.synchronize();
    await queue.init();
    expect(await queue.count, 0);
    await queue.close();
    recorder.succeeds = true;
    await startSdk();
    await runtime.setAnalytics(true);
    await runtime.synchronize();
    runtime.screen('/settings');
    await until(() => recorder.attempts.contains('/settings'));
    await queue.init();
    expect(await queue.count, 0);
  });

  test(
    'opt-out clears a late failed send even when preference saving fails',
    () async {
      recorder.sending = Completer<void>();
      runtime.screen('/card/links');
      await until(() => recorder.attempts.contains('/card/links'));
      storage.writing = Completer<void>();
      final saving = runtime.setAnalytics(false);
      final failedSave = expectLater(saving, throwsStateError);
      final stopped = runtime.synchronize();
      recorder.sending!.complete();
      recorder.sending = null;
      await stopped;
      expect(preferences.analytics, isFalse);
      expect(runtime.analyticsReady, isFalse);
      await queue.init();
      try {
        expect(await queue.count, 0);
      } finally {
        storage.writing!.completeError(StateError('unavailable'));
        await failedSave;
      }
    },
  );

  test('normal SDK shutdown preserves retry events', () async {
    final before = await queue.count;
    await TelemetrySdkBackend().stopAnalytics();
    await queue.init();
    expect(await queue.count, before);
  });
}
