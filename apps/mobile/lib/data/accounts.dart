import 'dart:convert';
import 'dart:math';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

final accountsProvider = ChangeNotifierProvider((ref) => Accounts());

final class SavedAccount {
  const SavedAccount(this.id, this.credentials);
  final String id;
  final LoginCredentials credentials;
}

final class Accounts extends ChangeNotifier {
  Accounts({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    ready = _load();
  }

  final FlutterSecureStorage _storage;
  late final Future<void> ready;
  final List<SavedAccount> _accounts = [];
  String? _selectedId;
  String? loadError;
  bool _disposed = false;
  bool busy = false;
  http.Client? _transport;
  DeckClient? client;

  List<SavedAccount> get items => List.unmodifiable(_accounts);
  SavedAccount? get selected =>
      _accounts.where((a) => a.id == _selectedId).firstOrNull;

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: 'accounts.v1');
      if (_disposed || saved == null) return;
      final json = object(jsonDecode(saved));
      final loaded = objects(json['accounts'])
          .map(
            (entry) => SavedAccount(
              stringField(entry, 'id'),
              LoginCredentials(
                server: ServerBase.parse(stringField(entry, 'server')),
                loginName: stringField(entry, 'loginName'),
                appPassword: stringField(entry, 'appPassword'),
              ),
            ),
          )
          .toList(growable: false);
      _accounts.addAll(loaded);
      _selectedId = json['selected'] as String?;
      if (selected == null && _accounts.isNotEmpty)
        _selectedId = _accounts.first.id;
      _openClient();
    } catch (_) {
      // A locked vault must not be treated as an empty account collection.
      loadError = 'secure_storage_unavailable';
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> retryLoad() async {
    _accounts.clear();
    loadError = null;
    await _load();
  }

  Future<void> add(LoginCredentials credentials) async {
    await ready;
    if (busy || loadError != null) throw StateError('accounts_unavailable');
    busy = true;
    try {
      final existing = _accounts
          .where(
            (a) =>
                a.credentials.server.uri == credentials.server.uri &&
                a.credentials.loginName == credentials.loginName,
          )
          .firstOrNull;
      final random = Random.secure();
      final id =
          existing?.id ??
          base64UrlEncode(List.generate(18, (_) => random.nextInt(256)));
      final next = [
        ..._accounts.where((a) => a.id != id),
        SavedAccount(id, credentials),
      ];
      await _persist(next, id);
      if (_disposed) return;
      _accounts
        ..clear()
        ..addAll(next);
      _selectedId = id;
      _openClient();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> select(String id) async {
    if (busy || !_accounts.any((a) => a.id == id)) return;
    busy = true;
    try {
      await _persist(_accounts, id);
      if (_disposed) return;
      _selectedId = id;
      _openClient();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    if (busy) return;
    busy = true;
    try {
      final next = _accounts.where((a) => a.id != id).toList();
      final selectedId = _selectedId == id ? next.firstOrNull?.id : _selectedId;
      await _persist(next, selectedId);
      if (_disposed) return;
      _accounts
        ..clear()
        ..addAll(next);
      _selectedId = selectedId;
      _openClient();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _persist(List<SavedAccount> values, String? selected) =>
      _storage.write(
        key: 'accounts.v1',
        value: jsonEncode({
          'selected': selected,
          'accounts': [
            for (final account in values)
              {
                'id': account.id,
                'server': account.credentials.server.uri.toString(),
                'loginName': account.credentials.loginName,
                'appPassword': account.credentials.appPassword,
              },
          ],
        }),
      );

  void _openClient() {
    _transport?.close();
    client = null;
    final account = selected;
    if (account == null) return;
    _transport = http.Client();
    client = DeckClient(
      base: account.credentials.server,
      loginName: account.credentials.loginName,
      appPassword: account.credentials.appPassword,
      transport: _transport!,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _transport?.close();
    super.dispose();
  }
}
