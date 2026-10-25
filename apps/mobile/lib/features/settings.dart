import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_preferences.dart';
import '../l10n/app_localizations.dart';
import 'accounts.dart';
import 'telemetry_settings.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context)!;
    final preferences = ref.watch(appPreferencesProvider);
    final package = ref.watch(packageInfoProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<ThemeMode>(
          key: ValueKey(('appearance', preferences.themeMode)),
          initialValue: preferences.themeMode,
          isExpanded: true,
          decoration: InputDecoration(labelText: text.appearance),
          items: [
            DropdownMenuItem(
              value: ThemeMode.system,
              child: Text(text.systemDefault),
            ),
            DropdownMenuItem(
              value: ThemeMode.light,
              child: Text(text.lightTheme),
            ),
            DropdownMenuItem(
              value: ThemeMode.dark,
              child: Text(text.darkTheme),
            ),
          ],
          onChanged: (value) {
            if (value != null) unawaited(preferences.setThemeMode(value));
          },
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<AppLanguage>(
          key: ValueKey(('language', preferences.language)),
          initialValue: preferences.language,
          isExpanded: true,
          decoration: InputDecoration(labelText: text.language),
          items: [
            DropdownMenuItem(
              value: AppLanguage.system,
              child: Text(text.systemDefault),
            ),
            DropdownMenuItem(
              value: AppLanguage.cs,
              child: Text(text.languageCzech),
            ),
            DropdownMenuItem(
              value: AppLanguage.en,
              child: Text(text.languageEnglish),
            ),
          ],
          onChanged: (value) {
            if (value != null) unawaited(preferences.setLanguage(value));
          },
        ),
        if (preferences.persistenceError)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(text.preferenceStorageError),
                ),
                TextButton(
                  onPressed: () => unawaited(preferences.retryPersistence()),
                  child: Text(text.retry),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(text.accounts),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/accounts'),
              builder: (_) => const AccountsScreen(),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: Text(text.telemetryTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              settings: const RouteSettings(name: '/settings/telemetry'),
              builder: (_) => const TelemetrySettingsScreen(),
            ),
          ),
        ),
        ListTile(
          key: const Key('app-version'),
          leading: const Icon(Icons.info_outline),
          title: Text(text.appVersion),
          subtitle: package.when(
            data: (info) => Text(
              info.buildNumber.isEmpty
                  ? info.version
                  : text.versionBuild(info.version, info.buildNumber),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(text.versionUnavailable),
          ),
        ),
      ],
    );
  }
}
