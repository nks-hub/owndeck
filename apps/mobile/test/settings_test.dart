import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/settings.dart';
import 'package:nextclouddeck/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _Store implements AppPreferenceStore {
  final values = <String, String>{};
  Future<String?> Function(String)? reader;
  Future<void> Function(String, String)? beforeWrite;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<String?> read(String key) async {
    if (failReads) throw MissingPluginException('private diagnostic');
    if (reader != null) return reader!(key);
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw PlatformException(code: 'private diagnostic');
    await beforeWrite?.call(key, value);
    values[key] = value;
  }
}

final _package = PackageInfo(
  appName: 'OwnDeck',
  packageName: 'com.example.app',
  version: '2.4.1',
  buildNumber: '42',
);

Widget _app(AppPreferences preferences, Widget home) => ProviderScope(
  overrides: [
    appPreferencesProvider.overrideWith((ref) => preferences),
    packageInfoProvider.overrideWith((ref) async => _package),
  ],
  child: OwnDeckApp(home: home),
);

class _DraftEditor extends StatefulWidget {
  const _DraftEditor();

  @override
  State<_DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends State<_DraftEditor> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('editor')),
    body: Column(
      children: [
        TextField(key: const Key('draft'), controller: controller),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('settings')),
                body: const SettingsView(),
              ),
            ),
          ),
          child: const Text('open settings'),
        ),
      ],
    ),
  );
}

void main() {
  test(
    'preferences survive reload and board views stay account scoped',
    () async {
      final store = _Store();
      final first = AppPreferences(store: store);
      final second = AppPreferences(store: store);
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await first.load();
      expect(first.themeMode, ThemeMode.system);
      expect(first.locale, isNull);
      await first.setThemeMode(ThemeMode.dark);
      await first.setLanguage(AppLanguage.cs);
      await first.setBoardViewMode('account/a', 7, BoardViewMode.list);
      await first.setBoardViewMode('account%2Fa', 7, BoardViewMode.columns);
      await first.setBoardViewMode('account/a', 8, BoardViewMode.columns);
      await second.load();
      await Future.wait([
        second.loadBoardViewMode('account/a', 7),
        second.loadBoardViewMode('account%2Fa', 7),
        second.loadBoardViewMode('account/a', 8),
      ]);
      expect(second.themeMode, ThemeMode.dark);
      expect(second.locale, const Locale('cs'));
      expect(second.boardViewMode('account/a', 7), BoardViewMode.list);
      expect(second.boardViewMode('account%2Fa', 7), BoardViewMode.columns);
      expect(second.boardViewMode('account/a', 8), BoardViewMode.columns);
    },
  );

  test('rapid writes persist the most recent choice', () async {
    final gate = Completer<void>();
    final writes = <String>[];
    final store = _Store()
      ..beforeWrite = (key, value) async {
        writes.add(value);
        if (writes.length == 1) await gate.future;
      };
    final preferences = AppPreferences(store: store);
    addTearDown(preferences.dispose);
    final first = preferences.setThemeMode(ThemeMode.light);
    final last = preferences.setThemeMode(ThemeMode.dark);
    await Future<void>.delayed(Duration.zero);
    expect(writes, ['light']);
    expect(preferences.themeMode, ThemeMode.dark);
    gate.complete();
    expect(await Future.wait([first, last]), [true, true]);
    final restored = AppPreferences(store: store);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.themeMode, ThemeMode.dark);
  });

  test('late initial load does not replace user choices', () async {
    final theme = Completer<String?>();
    final language = Completer<String?>();
    final store = _Store()
      ..reader = (key) =>
          key == AppPreferences.themeKey ? theme.future : language.future;
    final preferences = AppPreferences(store: store);
    addTearDown(preferences.dispose);
    final loading = preferences.load();
    await preferences.setThemeMode(ThemeMode.dark);
    await preferences.setLanguage(AppLanguage.en);
    theme.complete('light');
    language.complete('cs');
    await loading;
    expect(preferences.themeMode, ThemeMode.dark);
    expect(preferences.locale, const Locale('en'));
  });

  test(
    'late board preference read does not replace a new view choice',
    () async {
      final read = Completer<String?>();
      final store = _Store()..reader = (_) => read.future;
      final preferences = AppPreferences(store: store);
      addTearDown(preferences.dispose);
      final loading = preferences.loadBoardViewMode('account', 7);
      await preferences.setBoardViewMode('account', 7, BoardViewMode.list);
      read.complete('columns');
      await loading;
      expect(preferences.boardViewMode('account', 7), BoardViewMode.list);
    },
  );

  test(
    'missing storage keeps choices usable and retry persists them',
    () async {
      final store = _Store()
        ..failReads = true
        ..failWrites = true;
      store.values[AppPreferences.languageKey] = 'cs';
      final preferences = AppPreferences(store: store);
      addTearDown(preferences.dispose);
      await preferences.load();
      expect(preferences.loaded, isTrue);
      expect(preferences.persistenceError, isTrue);
      expect(await preferences.setThemeMode(ThemeMode.dark), isFalse);
      expect(preferences.themeMode, ThemeMode.dark);
      store.failReads = store.failWrites = false;
      expect(await preferences.retryPersistence(), isTrue);
      expect(preferences.persistenceError, isFalse);
      expect(preferences.locale, const Locale('cs'));
      final restored = AppPreferences(store: store);
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.locale, const Locale('cs'));
    },
  );

  testWidgets('settings changes preserve navigator and unsent editor text', (
    tester,
  ) async {
    final preferences = AppPreferences(store: _Store());
    await preferences.load();
    await preferences.setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      _app(
        preferences,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _DraftEditor()),
              ),
              child: const Text('edit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('draft')), 'Unsent draft');
    final editor = tester.state<_DraftEditorState>(find.byType(_DraftEditor));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
    expect(find.text('2.4.1 (42)'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Čeština').last);
    await tester.pumpAndSettle();
    expect(find.text('Vzhled'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tmavý').last);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsView))).brightness,
      Brightness.dark,
    );
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)),
      same(navigator),
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.state<_DraftEditorState>(find.byType(_DraftEditor)),
      same(editor),
    );
    expect(editor.controller.text, 'Unsent draft');
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing plugins show safe errors without blocking settings', (
    tester,
  ) async {
    final preferences = AppPreferences(
      store: _Store()
        ..failReads = true
        ..failWrites = true,
    );
    await preferences.load();
    await preferences.setLanguage(AppLanguage.en);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWith((ref) => preferences),
          packageInfoProvider.overrideWith(
            (ref) => Future.error(MissingPluginException('private diagnostic')),
          ),
        ],
        child: const OwnDeckApp(home: Scaffold(body: SettingsView())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SettingsView), findsOneWidget);
    expect(find.text('The app version could not be read.'), findsOneWidget);
    expect(find.textContaining('private diagnostic'), findsNothing);
    expect(find.byType(DropdownButtonFormField<ThemeMode>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
