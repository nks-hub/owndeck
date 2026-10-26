import 'dart:async';
import 'dart:io';

import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/data/accounts.dart';

enum _Mode { hang, fail }

/// A keystore that never answers or always fails, like a locked Linux keyring.
final class _BrokenStorage implements FlutterSecureStorage {
  _BrokenStorage(this.mode);
  final _Mode mode;
  int calls = 0;

  Future<T> _answer<T>() {
    calls++;
    return mode == _Mode.hang
        ? Completer<T>().future
        : Future<T>.error(StateError('keyring locked'));
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _answer();

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _answer();

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _answer();

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => _answer();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File marker;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('owndeck_vault');
    marker = File('${directory.path}/owndeck.vault-used');
  });
  tearDown(() {
    directory.deleteSync(recursive: true);
  });

  for (final mode in _Mode.values) {
    group('keystore that ${mode.name}s', () {
      test('Linux start with no stored secret never opens it', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final storage = _BrokenStorage(mode);
        final accounts = Accounts(
          storage: storage,
          database: DeckDatabase(NativeDatabase.memory()),
          vaultMarker: () async => marker,
        );
        await accounts.ready.timeout(const Duration(seconds: 3));
        expect(accounts.loadError, isNull);
        expect(accounts.items, isEmpty);
        expect(storage.calls, 0);
        debugDefaultTargetPlatformOverride = null;
        accounts.dispose();
        await accounts.database.close();
      });

      test('Windows and macOS start skips the phone-only migration', () async {
        for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
          debugDefaultTargetPlatformOverride = platform;
          final storage = _BrokenStorage(mode);
          final accounts = Accounts(
            storage: storage,
            database: DeckDatabase(NativeDatabase.memory()),
            vaultMarker: () async => marker,
          );
          await accounts.ready.timeout(const Duration(seconds: 3));
          expect(storage.calls, 0);
          accounts.dispose();
          await accounts.database.close();
        }
        debugDefaultTargetPlatformOverride = null;
      });
    });
  }

  test('a stored secret makes the next start read the keystore', () async {
    final storage = _BrokenStorage(_Mode.fail);
    final vault = SecureVault(storage, marker: () async => marker);
    expect(await vault.references(), isEmpty);
    await expectLater(vault.write('owndeck.account.x', 'p'), throwsStateError);
    expect(marker.existsSync(), isTrue);
    await expectLater(vault.references(), throwsStateError);
  });
}
