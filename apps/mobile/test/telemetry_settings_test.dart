import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/telemetry.dart';
import 'package:nextclouddeck/core/telemetry_bootstrap.dart';
import 'package:nextclouddeck/core/telemetry_preferences.dart';
import 'package:nextclouddeck/features/telemetry_settings.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

import 'test_support.dart';

class _Store implements TelemetryPreferenceStore {
  final values = <String, bool>{};
  var failWrites = false;
  var reads = 0;
  @override
  Future<bool?> read(String key) async {
    reads++;
    return values[key];
  }

  @override
  Future<void> write(String key, bool value) async {
    if (failWrites) throw StateError('unavailable');
    values[key] = value;
  }
}

class _Backend implements TelemetryBackend {
  int crashesStarted = 0;
  int analyticsStarted = 0;
  int analyticsStopped = 0;
  @override
  Future<void> startCrashes(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  ) async {
    crashesStarted++;
  }

  @override
  Future<void> startAnalytics(
    TelemetryConfig config,
    TelemetryPreferences preferences,
  ) async {
    analyticsStarted++;
  }

  @override
  Future<void> stopAnalytics({bool clearPendingEvents = false}) async {
    analyticsStopped++;
  }

  @override
  Future<void> stopCrashes() async {}
  @override
  Future<void> probeCrash() async {}
  @override
  void event(TelemetryEvent event) {}
  @override
  void screen(String route) {}
}

const _configured = TelemetryConfig(
  sentryDsn: 'https://public@example.com/1',
  rybbitHost: 'https://analytics.example.com',
  rybbitSiteId: '7',
);

void main() {
  const browser = MethodChannel('plugins.flutter.io/url_launcher');
  final launches = <MethodCall>[];
  var launchResult = true;
  PlatformException? launchError;

  setUp(() {
    launches.clear();
    launchResult = true;
    launchError = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(browser, (call) async {
          launches.add(call);
          if (launchError != null) throw launchError!;
          return launchResult;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(browser, null);
  });

  for (final locale in ['en', 'cs']) {
    testWidgets('privacy policy opens the $locale page without telemetry', (
      tester,
    ) async {
      final runtime = TelemetryRuntime(config: const TelemetryConfig());
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TelemetrySettingsScreen(runtime: runtime),
        ),
      );
      await tester.pumpAndSettle();
      final link = find.byKey(const Key('privacy-policy-link'));
      final semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(tester.getSemantics(link).flagsCollection.isLink, isTrue);
      } finally {
        semantics.dispose();
      }
      expect(
        find.text(
          locale == 'cs' ? 'Zásady ochrany soukromí' : 'Privacy policy',
        ),
        findsOneWidget,
      );
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(launches, hasLength(1));
      expect(launches.single.method, 'launch');
      expect(
        launches.single.arguments['url'],
        locale == 'cs'
            ? 'https://nks-hub.cz/stranka/owndeck-soukromi'
            : 'https://nks-hub.cz/en/stranka/owndeck-privacy',
      );
      expect(launches.single.arguments['useWebView'], isFalse);
      expect(launches.single.arguments['useSafariVC'], isFalse);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    });
  }

  for (final throws in [false, true]) {
    testWidgets('privacy policy reports a browser failure (throws=$throws)', (
      tester,
    ) async {
      launchResult = false;
      if (throws) launchError = PlatformException(code: 'unavailable');
      final runtime = TelemetryRuntime(config: const TelemetryConfig());
      await tester.pumpWidget(
        localizedTestApp(home: TelemetrySettingsScreen(runtime: runtime)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('privacy-policy-link')));
      await tester.pumpAndSettle();
      expect(find.text('The browser could not be opened.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    });
  }

  testWidgets(
    'unconfigured builds show disabled controls without loading preferences or SDKs',
    (tester) async {
      final store = _Store();
      final backend = _Backend();
      final runtime = TelemetryRuntime(
        config: const TelemetryConfig(),
        preferences: TelemetryPreferences(store: store),
        backend: backend,
      );
      await tester.pumpWidget(
        localizedTestApp(home: TelemetrySettingsScreen(runtime: runtime)),
      );
      await tester.pumpAndSettle();
      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(tile.onChanged, isNull);
        expect(tile.value, isFalse);
      }
      expect(store.reads, 0);
      expect(backend.crashesStarted + backend.analyticsStarted, 0);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    },
  );

  testWidgets('usage opt-out persists independently from error reporting', (
    tester,
  ) async {
    final store = _Store();
    final backend = _Backend();
    final runtime = TelemetryRuntime(
      config: _configured,
      preferences: TelemetryPreferences(store: store),
      backend: backend,
    );
    await tester.pumpWidget(
      localizedTestApp(home: TelemetrySettingsScreen(runtime: runtime)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('telemetry-usage')));
    await tester.pumpAndSettle();
    expect(store.values[TelemetryPreferences.analyticsKey], isFalse);
    expect(runtime.preferences.crashReporting, isTrue);
    expect(runtime.preferences.analytics, isFalse);
    expect(backend.analyticsStopped, 1);
    await tester.pumpWidget(const SizedBox());
    await runtime.close();
  });

  testWidgets(
    'a failed opt-out stays off and can be saved again without re-enabling it',
    (tester) async {
      final store = _Store()..failWrites = true;
      final runtime = TelemetryRuntime(
        config: _configured,
        preferences: TelemetryPreferences(store: store),
        backend: _Backend(),
      );
      await tester.pumpWidget(
        localizedTestApp(home: TelemetrySettingsScreen(runtime: runtime)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('telemetry-errors')));
      await tester.pumpAndSettle();
      expect(runtime.preferences.crashReporting, isFalse);
      expect(find.text('The setting could not be saved.'), findsOneWidget);
      store.failWrites = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(store.values[TelemetryPreferences.crashKey], isFalse);
      expect(find.text('The setting could not be saved.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await runtime.close();
    },
  );
}
