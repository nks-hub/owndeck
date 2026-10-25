import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/telemetry_bootstrap.dart';
import '../l10n/app_localizations.dart';

class TelemetrySettingsScreen extends StatefulWidget {
  const TelemetrySettingsScreen({super.key, this.runtime});
  final TelemetryRuntime? runtime;
  @override
  State<TelemetrySettingsScreen> createState() =>
      _TelemetrySettingsScreenState();
}

class _TelemetrySettingsScreenState extends State<TelemetrySettingsScreen> {
  late final _runtime = widget.runtime ?? telemetry;
  late final _changes = Listenable.merge([_runtime, _runtime.preferences]);
  late Future<void> _initializing = _runtime.initialize();
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _save(
    Future<void> Function() action, {
    bool retry = false,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      if (mounted && retry) setState(() => _saveFailed = false);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _retrySave() => _save(() async {
    if (_runtime.config.crashReportingAvailable) {
      await _runtime.setCrashReporting(_runtime.preferences.crashReporting);
    }
    if (_runtime.config.analyticsAvailable) {
      await _runtime.setAnalytics(_runtime.preferences.analytics);
    }
  }, retry: true);

  Future<void> _openPrivacyPolicy() async {
    final czech = Localizations.localeOf(context).languageCode == 'cs';
    final uri = Uri.parse(
      czech
          ? 'https://nks-hub.cz/stranka/owndeck-soukromi'
          : 'https://nks-hub.cz/en/stranka/owndeck-privacy',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _browserError();
      }
    } on PlatformException {
      _browserError();
    }
  }

  void _browserError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.browserError)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(text.telemetryTitle)),
      body: FutureBuilder<void>(
        future: _initializing,
        builder: (context, initialization) => ListenableBuilder(
          listenable: _changes,
          builder: (context, _) {
            final preferences = _runtime.preferences;
            final config = _runtime.config;
            final loading =
                initialization.connectionState != ConnectionState.done;
            final loadFailed =
                !loading &&
                !preferences.loaded &&
                (config.crashReportingAvailable || config.analyticsAvailable);
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (loading || _saving) const LinearProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(text.telemetryChoiceHelp),
                ),
                if (config.crashReportingAvailable || config.analyticsAvailable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      text.telemetryEnabledByDefault,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (loadFailed || _saveFailed)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text.telemetrySaveFailed),
                        TextButton(
                          onPressed: _saving
                              ? null
                              : loadFailed
                              ? () => setState(
                                  () => _initializing = preferences.load(),
                                )
                              : _retrySave,
                          child: Text(text.retry),
                        ),
                      ],
                    ),
                  ),
                SwitchListTile.adaptive(
                  key: const Key('telemetry-errors'),
                  title: Text(text.crashReporting),
                  subtitle: Text(
                    config.crashReportingAvailable
                        ? text.crashReportingDescription
                        : text.telemetryUnavailable,
                  ),
                  value:
                      config.crashReportingAvailable &&
                      preferences.crashReporting,
                  onChanged:
                      loading ||
                          _saving ||
                          !preferences.loaded ||
                          !config.crashReportingAvailable
                      ? null
                      : (value) =>
                            _save(() => _runtime.setCrashReporting(value)),
                ),
                SwitchListTile.adaptive(
                  key: const Key('telemetry-usage'),
                  title: Text(text.usageAnalytics),
                  subtitle: Text(
                    config.analyticsAvailable
                        ? text.usageAnalyticsDescription
                        : text.telemetryUnavailable,
                  ),
                  value: config.analyticsAvailable && preferences.analytics,
                  onChanged:
                      loading ||
                          _saving ||
                          !preferences.loaded ||
                          !config.analyticsAvailable
                      ? null
                      : (value) => _save(() => _runtime.setAnalytics(value)),
                ),
                const Divider(indent: 20, endIndent: 20),
                Semantics(
                  key: const Key('privacy-policy-link'),
                  link: true,
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(text.privacyPolicy),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openPrivacyPolicy,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
