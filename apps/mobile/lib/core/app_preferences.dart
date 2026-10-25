import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, cs, en }

enum BoardViewMode { columns, list }

abstract interface class AppPreferenceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

final class SharedAppPreferenceStore implements AppPreferenceStore {
  late final _preferences = SharedPreferencesAsync();

  @override
  Future<String?> read(String key) => _preferences.getString(key);

  @override
  Future<void> write(String key, String value) =>
      _preferences.setString(key, value);
}

final appPreferencesProvider = ChangeNotifierProvider<AppPreferences>((ref) {
  final preferences = AppPreferences();
  unawaited(preferences.load());
  return preferences;
});

final class AppPreferences extends ChangeNotifier {
  AppPreferences({AppPreferenceStore? store})
    : _store = store ?? SharedAppPreferenceStore();

  static const themeKey = 'app.theme';
  static const languageKey = 'app.language';
  final AppPreferenceStore _store;
  final _changed = <String>{};
  final _failed = <String>{};
  final _boardModes = <String, BoardViewMode>{};
  final _boardLoads = <String, Future<void>>{};
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  bool _loaded = false;
  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.system;

  bool get loaded => _loaded;
  bool get persistenceError => _failed.isNotEmpty;
  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  Locale? get locale => switch (_language) {
    AppLanguage.system => null,
    AppLanguage.cs => const Locale('cs'),
    AppLanguage.en => const Locale('en'),
  };

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final values = await Future.wait([_read(themeKey), _read(languageKey)]);
    _applyLoaded(themeKey, values[0]);
    _applyLoaded(languageKey, values[1]);
    _loaded = true;
    _notify();
  }

  void _applyLoaded(String key, String? value) {
    if (_changed.contains(key)) return;
    if (key == themeKey) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );
    } else if (key == languageKey) {
      _language = AppLanguage.values.firstWhere(
        (language) => language.name == value,
        orElse: () => AppLanguage.system,
      );
    } else {
      _boardModes[key] = BoardViewMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => BoardViewMode.columns,
      );
    }
  }

  Future<bool> setThemeMode(ThemeMode value) {
    _themeMode = value;
    _changed.add(themeKey);
    _notify();
    return _persist(themeKey, value.name);
  }

  Future<bool> setLanguage(AppLanguage value) {
    _language = value;
    _changed.add(languageKey);
    _notify();
    return _persist(languageKey, value.name);
  }

  static String _boardKey(String accountId, int boardId) =>
      'app.board-view.${base64Url.encode(utf8.encode(accountId))}.$boardId';

  BoardViewMode boardViewMode(String accountId, int boardId) =>
      _boardModes[_boardKey(accountId, boardId)] ?? BoardViewMode.columns;

  Future<void> loadBoardViewMode(String accountId, int boardId) {
    final key = _boardKey(accountId, boardId);
    return _boardLoads.putIfAbsent(key, () async {
      _boardModes.putIfAbsent(key, () => BoardViewMode.columns);
      final value = await _read(key);
      _applyLoaded(key, value);
      _notify();
    });
  }

  Future<bool> setBoardViewMode(
    String accountId,
    int boardId,
    BoardViewMode value,
  ) {
    final key = _boardKey(accountId, boardId);
    _boardModes[key] = value;
    _changed.add(key);
    _notify();
    return _persist(key, value.name);
  }

  Future<bool> retryPersistence() async {
    final results = await Future.wait([
      for (final key in _failed.toList())
        _changed.contains(key)
            ? _persist(key, switch (key) {
                themeKey => _themeMode.name,
                languageKey => _language.name,
                _ => _boardModes[key]!.name,
              })
            : _retryRead(key),
    ]);
    return results.every((saved) => saved);
  }

  Future<bool> _retryRead(String key) async {
    final value = await _read(key, retry: true);
    _applyLoaded(key, value);
    _notify();
    return !_failed.contains(key);
  }

  Future<String?> _read(String key, {bool retry = false}) async {
    try {
      final value = await _store.read(key);
      if (retry && !_changed.contains(key)) _failed.remove(key);
      return value;
    } on Object {
      // Platform registration and stored value types can both fail at this boundary.
      if (!_changed.contains(key)) _failed.add(key);
      return null;
    }
  }

  Future<bool> _persist(String key, String value) {
    final result = _writes.then((_) async {
      try {
        await _store.write(key, value);
        _failed.remove(key);
        _notify();
        return true;
      } on Object {
        // A failed platform write must not undo an in-memory user choice.
        _failed.add(key);
        _notify();
        return false;
      }
    });
    _writes = result.then((_) {});
    return result;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
