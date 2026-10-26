import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/data/keychain_migration.dart';

typedef _Item = ({String value, String accessibility});

/// Keeps the accessibility each value was written with, like the iOS keychain does.
final class _FakeKeychain implements SecretStore {
  _FakeKeychain(this.items, this.accessibility);
  final Map<String, _Item> items;
  final String accessibility;
  bool failWrites = false;

  @override
  Future<Map<String, String>> readAll() async => {
    for (final e in items.entries) e.key: e.value.value,
  };

  @override
  Future<void> write(String key, String value) async {
    if (failWrites) throw StateError('write');
    items[key] = (value: value, accessibility: accessibility);
  }

  @override
  Future<void> delete(String key) async => items.remove(key);
}

void main() {
  const target = 'first_unlock_this_device';
  late Map<String, _Item> items;
  late _FakeKeychain previous;
  late _FakeKeychain current;

  setUp(() {
    items = {
      'owndeck.account.a': (value: 'secret-a', accessibility: 'unlocked'),
      'owndeck.account.b': (value: 'secret-b', accessibility: 'unlocked'),
    };
    previous = _FakeKeychain(items, 'unlocked');
    current = _FakeKeychain(items, target);
  });

  test('existing items keep their values and become device only', () async {
    await migrateKeychainAccessibility(previous: previous, current: current);
    expect(items['owndeck.account.a']!.value, 'secret-a');
    expect(items['owndeck.account.b']!.value, 'secret-b');
    expect(items.values.every((e) => e.accessibility == target), isTrue);
    expect(items.containsKey(keychainMigrationMarker), isTrue);
  });

  test('a finished migration is not repeated', () async {
    await migrateKeychainAccessibility(previous: previous, current: current);
    items['owndeck.account.c'] = (value: 'new', accessibility: 'unlocked');
    await migrateKeychainAccessibility(previous: previous, current: current);
    expect(items['owndeck.account.c']!.accessibility, 'unlocked');
  });

  test('a failed rewrite restores the old item and is retried', () async {
    current.failWrites = true;
    await migrateKeychainAccessibility(previous: previous, current: current);
    expect(items['owndeck.account.a']!.value, 'secret-a');
    expect(items['owndeck.account.b']!.value, 'secret-b');
    expect(items.containsKey(keychainMigrationMarker), isFalse);
    current.failWrites = false;
    await migrateKeychainAccessibility(previous: previous, current: current);
    expect(items['owndeck.account.a']!.accessibility, target);
    expect(items.containsKey(keychainMigrationMarker), isTrue);
  });

  test('an empty keychain only records the marker', () async {
    items.clear();
    await migrateKeychainAccessibility(previous: previous, current: current);
    expect(items.keys, [keychainMigrationMarker]);
  });
}
