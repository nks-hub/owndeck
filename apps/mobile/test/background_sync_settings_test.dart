import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/data/background_sync.dart';
import 'package:nextclouddeck/features/background_sync_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'test_support.dart';

final class _Scheduler implements BackgroundScheduler {
  final calls = <bool>[];
  @override
  Future<void> apply({required bool hasAccounts}) async =>
      calls.add(hasAccounts);
}

Widget _app(_Scheduler scheduler) => ProviderScope(
  overrides: [
    backgroundSyncSettingsProvider.overrideWith(
      (ref) => BackgroundSyncSettings(scheduler, () => true),
    ),
  ],
  child: localizedTestApp(
    home: const Scaffold(body: BackgroundSyncSettingsTile()),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('shows the 15 minute default and applies a new interval', (
    tester,
  ) async {
    final scheduler = _Scheduler();
    await tester.pumpWidget(_app(scheduler));
    await _settle(tester);
    expect(find.text('15 minutes'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('background-wifi-only')))
          .value,
      isFalse,
    );

    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 hours').last);
    await _settle(tester);
    await tester.pumpAndSettle();

    expect((await BackgroundSyncPreferences.load()).minutes, 360);
    expect(scheduler.calls, [true]);
  });

  testWidgets('Wi-Fi only is saved and off disables the switch', (
    tester,
  ) async {
    final scheduler = _Scheduler();
    await tester.pumpWidget(_app(scheduler));
    await _settle(tester);

    await tester.tap(find.byKey(const Key('background-wifi-only')));
    await _settle(tester);
    expect((await BackgroundSyncPreferences.load()).wifiOnly, isTrue);

    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off').last);
    await _settle(tester);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('background-wifi-only')))
          .onChanged,
      isNull,
    );
    expect(scheduler.calls, [true, true]);
  });

  testWidgets('the text states the Android limits', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(_app(_Scheduler()));
    await _settle(tester);
    expect(
      find.textContaining('Android chooses the exact time'),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the text states the iOS limits', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(_app(_Scheduler()));
    await _settle(tester);
    expect(find.textContaining('may skip runs'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('is hidden where there is no background scheduler', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await tester.pumpWidget(_app(_Scheduler()));
    await _settle(tester);
    expect(find.text('Background sync'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
