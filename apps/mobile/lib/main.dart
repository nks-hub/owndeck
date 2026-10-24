import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/account_gate.dart';
import 'l10n/app_localizations.dart';
import 'core/telemetry_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OwnDeckApp()));
  unawaited(telemetry.initialize());
}

class OwnDeckApp extends StatelessWidget {
  const OwnDeckApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OwnDeck',
    debugShowCheckedModeBanner: false,
    navigatorObservers: [telemetry.navigatorObserver()],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: const DeckAccountGate(),
  );
}

ThemeData _theme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xff167a72),
    brightness: brightness,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
);
