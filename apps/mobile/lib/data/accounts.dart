import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'keychain_migration.dart';
import 'session.dart';
import 'attachment_files.dart';
import '../platform/attachment_storage.dart';

final accountsProvider = ChangeNotifierProvider((ref) => Accounts());

final class SecureVault implements CredentialVault {
  const SecureVault(this.storage);
  final FlutterSecureStorage storage;
  @override
  Future<String?> read(String reference) => storage.read(key: reference);
  @override
  Future<void> write(String reference, String password) =>
      storage.write(key: reference, value: password);
  @override
  Future<void> delete(String reference) => storage.delete(key: reference);
  @override
  Future<Set<String>> references() async =>
      (await storage.readAll()).keys.toSet();
}

final class Accounts extends ChangeNotifier {
  Accounts({
    FlutterSecureStorage? storage,
    DeckDatabase? database,
    this.transportFactory,
  }) : _storage =
           storage ?? const FlutterSecureStorage(iOptions: deviceOnlyKeychain),
       _migrateKeychain =
           storage == null && defaultTargetPlatform == TargetPlatform.iOS,
       database = database ?? DeckDatabase(driftDatabase(name: 'owndeck')) {
    vault = SecureVault(_storage);
    repository = AccountRepository(
      this.database,
      vault,
      clearFiles: (id) async => (await _files()).removeAccount(id),
    );
    ready = _load();
  }

  final FlutterSecureStorage _storage;
  final bool _migrateKeychain;
  final http.Client Function(Uri server, String? fingerprint)? transportFactory;
  final DeckDatabase database;
  late final CredentialVault vault;
  late final AccountRepository repository;
  late final Future<void> ready;
  List<StoredAccount> _accounts = [];
  String? loadError;
  bool _disposed = false;
  bool busy = false;
  http.Client? _transport;
  DeckSession? session;
  int _generation = 0;
  int _onboarding = 0;
  Future<AttachmentFiles>? _fileStore;

  Future<AttachmentFiles> _files() async {
    final existing = _fileStore;
    if (existing != null) return existing;
    final opening = () async {
      final files = await openAttachmentFiles();
      await files.pruneAccounts(
        (await database.accounts()).map((a) => a.id).toSet(),
      );
      return files;
    }();
    _fileStore = opening;
    try {
      return await opening;
    } catch (_) {
      if (identical(_fileStore, opening)) _fileStore = null;
      rethrow;
    }
  }

  List<StoredAccount> get items => List.unmodifiable(_accounts);
  StoredAccount? get selected =>
      _accounts.where((a) => a.selected).firstOrNull ?? _accounts.firstOrNull;

  Future<void> _load() async {
    try {
      if (_migrateKeychain) {
        await migrateKeychainAccessibility(
          previous: const FlutterSecretStore(FlutterSecureStorage()),
          current: FlutterSecretStore(_storage),
        );
      }
      await repository.recover();
      await _migrateLegacy();
      await _reload();
      loadError = null;
    } catch (_) {
      // A locked vault or corrupt database must not become an empty account list.
      loadError = 'storage_unavailable';
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> _migrateLegacy() async {
    final legacy = await _storage.read(key: 'accounts.v1');
    if (legacy == null) return;
    final json = object(jsonDecode(legacy));
    String? selectedId;
    for (final entry in objects(json['accounts'])) {
      final account = await repository.add(
        LoginCredentials(
          server: ServerBase.parse(stringField(entry, 'server')),
          loginName: stringField(entry, 'loginName'),
          appPassword: stringField(entry, 'appPassword'),
        ),
      );
      if (entry['id'] == json['selected']) selectedId = account.id;
    }
    if (selectedId != null) await repository.select(selectedId);
    await _storage.delete(key: 'accounts.v1');
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    _transport?.close();
    session?.dispose();
    session = null;
    final values = await database.accounts();
    if (_disposed || generation != _generation) return;
    _accounts = values.where((a) => a.state != 'deleting').toList();
    final account = selected;
    if (account == null || account.state != 'active') return;
    final password = await vault.read(account.credentialRef);
    if (_disposed || generation != _generation) return;
    if (password == null) return;
    final transport = _client(account);
    _transport = transport;
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: password,
        transport: transport,
        retryUntil: account.syncNotBefore,
      ),
      files: _files,
      onAuthenticationRequired: () => _requireAuthentication(account),
    );
  }

  Future<void> _requireAuthentication(StoredAccount account) async {
    if (_disposed || !await repository.requireAuthentication(account)) return;
    if (_disposed ||
        busy ||
        _onboarding != 0 ||
        session?.account.id != account.id ||
        session?.account.generation != account.generation) {
      return;
    }
    try {
      await _reload();
    } catch (_) {
      loadError = 'storage_unavailable';
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  http.Client _client(StoredAccount account) {
    final uri = ServerBase.parse(account.server).uri;
    return transportFactory?.call(uri, account.certificateFingerprint) ??
        CertificateHttpClient(
          server: uri,
          fingerprint: account.certificateFingerprint,
        );
  }

  void beginOnboarding() => _onboarding++;

  Future<void> endOnboarding() async {
    if (_onboarding > 0) _onboarding--;
    if (_disposed || busy || _onboarding != 0) return;
    await _reloadInvalidSession();
    if (!_disposed) notifyListeners();
  }

  Future<void> _reloadInvalidSession() async {
    final active = session;
    if (_disposed || active == null) return;
    try {
      final current = await database.account(active.account.id);
      if (_disposed || !identical(session, active)) return;
      if (current == null ||
          current.state != 'active' ||
          current.generation != active.account.generation) {
        await _reload();
      }
    } catch (_) {
      loadError = 'storage_unavailable';
    }
  }

  Future<T> _change<T>(Future<T> Function() operation) async {
    await ready;
    if (busy || loadError != null || _disposed) {
      throw StateError('accounts_unavailable');
    }
    busy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      if (_onboarding == 0) await _reloadInvalidSession();
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> retryLoad() async {
    if (busy) return;
    busy = true;
    try {
      await _load();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> add(
    LoginCredentials credentials, {
    String? userId,
    String? certificateFingerprint,
    bool Function()? canCommit,
  }) => _change(() async {
    await repository.add(
      credentials,
      userId: userId,
      certificateFingerprint: certificateFingerprint,
      canCommit: canCommit,
    );
    await _reload();
  });

  Future<void> select(String id) => _change(() async {
    await repository.select(id);
    await _reload();
  });

  Future<bool> remove(String id) => _change(() async {
    final account = await database.account(id);
    if (account == null) return true;
    final password = await vault.read(account.credentialRef);
    ++_generation;
    _transport?.close();
    session?.dispose();
    session = null;
    try {
      await repository.remove(id);
    } finally {
      await _reload();
    }
    if (password == null) return false;
    final transport = _client(account);
    try {
      await DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: password,
        transport: transport,
        timeout: const Duration(seconds: 15),
      ).ocs('DELETE', ['core', 'apppassword']);
      return true;
    } on DeckException {
      // Local removal is complete even if server-side revocation cannot be confirmed.
      return false;
    } finally {
      transport.close();
    }
  });

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _transport?.close();
    session?.dispose();
    unawaited(database.close());
    super.dispose();
  }
}
