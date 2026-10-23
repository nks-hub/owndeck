import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/accounts.dart';
import 'features/boards.dart';
import 'features/login.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OwnDeckApp()));
}

class OwnDeckApp extends StatelessWidget {
  const OwnDeckApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OwnDeck',
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: const _AccountGate(),
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

class _AccountGate extends ConsumerWidget {
  const _AccountGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    return FutureBuilder<void>(
      future: accounts.ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (accounts.loadError != null) {
          final text = AppLocalizations.of(context)!;
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text.storageError),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: accounts.retryLoad,
                      child: Text(text.retry),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final session = accounts.session;
        if (session == null)
          return LoginScreen(initialServer: accounts.selected?.server);
        return Navigator(
          key: ObjectKey(session),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/boards'),
            builder: (_) => BoardsScreen(session: session),
          ),
        );
      },
    );
  }
}
