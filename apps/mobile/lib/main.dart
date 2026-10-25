import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/account_gate.dart';
import 'l10n/app_localizations.dart';
import 'core/telemetry_bootstrap.dart';
import 'core/app_preferences.dart';
import 'core/deck_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OwnDeckApp()));
  unawaited(telemetry.initialize());
}

class OwnDeckApp extends ConsumerStatefulWidget {
  const OwnDeckApp({super.key, this.home = const DeckAccountGate()});
  final Widget home;

  @override
  ConsumerState<OwnDeckApp> createState() => _OwnDeckAppState();
}

class _OwnDeckAppState extends ConsumerState<OwnDeckApp> {
  late final _observer = telemetry.navigatorObserver();

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(appPreferencesProvider);
    return MaterialApp(
      title: 'OwnDeck',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [_observer],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: preferences.locale,
      themeMode: preferences.themeMode,
      theme: DeckTheme.light(),
      darkTheme: DeckTheme.dark(),
      home: widget.home,
    );
  }
}
