import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminders.dart';
import '../l10n/app_localizations.dart';

/// Switch and lead time for due date reminders, with the platform's limits.
class ReminderSettingsTile extends ConsumerWidget {
  const ReminderSettingsTile({super.key});

  static String _label(AppLocalizations text, int minutes) => switch (minutes) {
    15 => text.reminderLead15Minutes,
    60 => text.reminderLead1Hour,
    1440 => text.reminderLead1Day,
    _ => text.reminderLeadAtDue,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasLocalReminders) return const SizedBox.shrink();
    final text = AppLocalizations.of(context)!;
    final settings = ref.watch(reminderSettingsProvider);
    final preferences = settings.preferences;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            text.reminderTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SwitchListTile(
          key: const Key('reminders-enabled'),
          contentPadding: EdgeInsets.zero,
          title: Text(text.reminderSwitch),
          subtitle: Text(text.reminderSwitchHint),
          value: preferences.enabled,
          onChanged: settings.loaded
              ? (value) => unawaited(settings.update(enabled: value))
              : null,
        ),
        if (settings.denied)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                text.reminderDenied,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        DropdownButtonFormField<int>(
          key: ValueKey(('reminder-lead', preferences.leadMinutes)),
          initialValue: preferences.leadMinutes,
          isExpanded: true,
          decoration: InputDecoration(labelText: text.reminderLead),
          items: [
            for (final minutes in ReminderPreferences.leads)
              DropdownMenuItem(
                value: minutes,
                child: Text(_label(text, minutes)),
              ),
          ],
          onChanged: settings.loaded && preferences.enabled
              ? (value) {
                  if (value != null) {
                    unawaited(settings.update(leadMinutes: value));
                  }
                }
              : null,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            ios ? text.reminderHelpIos : text.reminderHelpAndroid,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
