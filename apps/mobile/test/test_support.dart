import 'package:flutter/material.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

Widget localizedTestApp({required Widget home}) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);
