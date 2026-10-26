import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/background_sync.dart';
import '../l10n/app_localizations.dart';

/// Interval choice and Wi-Fi switch for the background run, with the limits
/// of the current platform stated plainly.
class BackgroundSyncSettingsTile extends ConsumerWidget {
  const BackgroundSyncSettingsTile({super.key});

  static String _label(AppLocalizations text, int minutes) => switch (minutes) {
    15 => text.backgroundSync15Minutes,
    60 => text.backgroundSync1Hour,
    360 => text.backgroundSync6Hours,
    _ => text.backgroundSyncOff,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasBackgroundSync) return const SizedBox.shrink();
    final text = AppLocalizations.of(context)!;
    final settings = ref.watch(backgroundSyncSettingsProvider);
    final preferences = settings.preferences;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            text.backgroundSyncTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        DropdownButtonFormField<int>(
          key: ValueKey(('background-interval', preferences.minutes)),
          initialValue: preferences.minutes,
          isExpanded: true,
          decoration: InputDecoration(labelText: text.backgroundSyncInterval),
          items: [
            for (final minutes in BackgroundSyncPreferences.intervals)
              DropdownMenuItem(
                value: minutes,
                child: Text(_label(text, minutes)),
              ),
          ],
          onChanged: !settings.loaded
              ? null
              : (value) {
                  if (value != null) {
                    unawaited(settings.update(minutes: value));
                  }
                },
        ),
        SwitchListTile(
          key: const Key('background-wifi-only'),
          contentPadding: EdgeInsets.zero,
          title: Text(text.backgroundSyncWifiOnly),
          subtitle: Text(text.backgroundSyncWifiOnlyHint),
          value: preferences.wifiOnly,
          onChanged: !settings.loaded || !preferences.enabled
              ? null
              : (value) => unawaited(settings.update(wifiOnly: value)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            ios ? text.backgroundSyncHelpIos : text.backgroundSyncHelpAndroid,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
