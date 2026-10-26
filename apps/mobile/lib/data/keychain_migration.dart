import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain items readable after the first unlock and never copied to another device or backup.
const deviceOnlyKeychain = IOSOptions(
  accessibility: KeychainAccessibility.first_unlock_this_device,
);

/// The login keychain works for sandboxed builds without a restricted access-group entitlement.
const desktopMacKeychain = MacOsOptions(
  usesDataProtectionKeychain: false,
  synchronizable: false,
);

/// Minimal secret storage used by the keychain migration.
abstract interface class SecretStore {
  Future<Map<String, String>> readAll();
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class FlutterSecretStore implements SecretStore {
  const FlutterSecretStore(this.storage);
  final FlutterSecureStorage storage;

  @override
  Future<Map<String, String>> readAll() => storage.readAll();
  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => storage.delete(key: key);
}

const keychainMigrationMarker = 'keychain.device_only.v1';

/// Rewrites every item read through [previous] so it carries the accessibility of [current].
/// An item whose rewrite fails is restored with the old options, and the whole run repeats on the next start.
Future<void> migrateKeychainAccessibility({
  required SecretStore previous,
  required SecretStore current,
}) async {
  final items = await previous.readAll();
  if (items.containsKey(keychainMigrationMarker)) return;
  var complete = true;
  for (final entry in items.entries) {
    try {
      await previous.delete(entry.key);
    } catch (_) {
      complete = false;
      continue;
    }
    try {
      await current.write(entry.key, entry.value);
    } catch (_) {
      complete = false;
      await previous.write(entry.key, entry.value);
    }
  }
  if (complete) await current.write(keychainMigrationMarker, '1');
}
