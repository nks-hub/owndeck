import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TelemetryPreferenceStore {
  Future<bool?> read(String key);
  Future<void> write(String key, bool value);
}

final class SharedTelemetryPreferenceStore implements TelemetryPreferenceStore {
  SharedTelemetryPreferenceStore() : _preferences = SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  @override
  Future<bool?> read(String key) => _preferences.getBool(key);
  @override
  Future<void> write(String key, bool value) =>
      _preferences.setBool(key, value);
}

final class TelemetryPreferences extends ChangeNotifier {
  TelemetryPreferences({TelemetryPreferenceStore? store})
    : _store = store ?? SharedTelemetryPreferenceStore();
  final TelemetryPreferenceStore _store;
  static const crashKey = 'telemetry.crashes';
  static const analyticsKey = 'telemetry.analytics';
  bool crashReporting = false;
  bool analytics = false;
  bool loaded = false;
  Future<void> _tail = Future.value();
  int _generation = 0;
  final _revisions = <String, int>{};

  Future<void> load() async {
    final generation = _generation;
    try {
      final crash = await _store.read(crashKey) ?? true;
      final usage = await _store.read(analyticsKey) ?? true;
      if (generation != _generation) return;
      crashReporting = crash;
      analytics = usage;
      loaded = true;
    } catch (_) {
      if (generation != _generation) return;
      // An unreadable opt-out never enables either service.
      crashReporting = analytics = loaded = false;
    }
    notifyListeners();
  }

  Future<void> setCrashReporting(bool value) => _save(crashKey, value);
  Future<void> setAnalytics(bool value) => _save(analyticsKey, value);

  Future<void> _save(String key, bool value) {
    final revision = ++_generation;
    _revisions[key] = revision;
    if (!value) {
      _set(key, false);
      notifyListeners();
    }
    final result = _tail.then((_) async {
      await _store.write(key, value);
      if (_revisions[key] != revision) return;
      _set(key, value);
      loaded = true;
      notifyListeners();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  void _set(String key, bool value) {
    if (key == crashKey) {
      crashReporting = value;
    } else {
      analytics = value;
    }
  }
}
