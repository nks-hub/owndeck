import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/deck_theme.dart';

void main() {
  const keys = ['plain', 'two-line', 'switch', 'icon', 'button'];

  Future<Map<String, double>> measure(
    WidgetTester tester,
    TargetPlatform platform,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    final theme = DeckTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: ListView(
            children: [
              const ListTile(key: Key('plain'), title: Text('Board')),
              const ListTile(
                key: Key('two-line'),
                title: Text('Board'),
                subtitle: Text('Archive'),
              ),
              SwitchListTile(
                key: const Key('switch'),
                value: true,
                onChanged: (_) {},
                title: const Text('Option'),
              ),
              IconButton(
                key: const Key('icon'),
                onPressed: () {},
                icon: const Icon(Icons.add),
              ),
              FilledButton(
                key: const Key('button'),
                onPressed: () {},
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    // The theme change is animated.
    await tester.pumpAndSettle();
    final desktop = {
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }.contains(platform);
    expect(
      theme.visualDensity,
      desktop ? VisualDensity.compact : VisualDensity.standard,
    );
    final heights = {
      for (final key in keys) key: tester.getSize(find.byKey(Key(key))).height,
    };
    debugDefaultTargetPlatformOverride = null;
    return heights;
  }

  testWidgets('desktop rows and controls are shorter than on a phone', (
    tester,
  ) async {
    final phone = await measure(tester, TargetPlatform.android);
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      final desktop = await measure(tester, platform);
      for (final key in keys) {
        expect(
          desktop[key],
          lessThan(phone[key]!),
          reason: '$key on ${platform.name}',
        );
      }
    }
  });

  testWidgets('iOS keeps the phone density', (tester) async {
    final phone = await measure(tester, TargetPlatform.android);
    expect(await measure(tester, TargetPlatform.iOS), phone);
  });
}
