import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/accounts.dart';
import 'package:nextclouddeck/data/card_link_inbox.dart';
import 'package:nextclouddeck/data/reminders.dart';
import 'package:nextclouddeck/features/reminder_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'test_support.dart';

final class _Item {
  _Item(this.at, this.title, this.body, this.payload);
  final DateTime at;
  final String title;
  final String body;
  final String payload;
}

final class _Platform implements ReminderPlatform {
  final items = <int, _Item>{};
  final taps_ = StreamController<String>.broadcast();
  var scheduleCalls = 0;
  var cancelCalls = 0;
  var grant = true;
  String? launch;

  @override
  Stream<String> get taps => taps_.stream;
  @override
  Future<String?> launchPayload() async => launch;
  @override
  Future<bool> requestPermission() async => grant;
  @override
  Future<List<ScheduledReminder>> scheduled() async => [
    for (final entry in items.entries)
      ScheduledReminder(entry.key, entry.value.payload),
  ];
  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required String payload,
    required String channelName,
  }) async {
    scheduleCalls++;
    items[id] = _Item(at, title, body, payload);
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    items.remove(id);
  }
}

Map<String, Object?> _card(
  int id, {
  String? due = '2030-05-01T10:00:00+00:00',
  Object? done,
}) => {
  'id': id,
  'stackId': 2,
  'title': 'Card $id',
  'description': '',
  'order': id,
  'type': 'plain',
  'owner': 'user',
  'archived': false,
  'deletedAt': 0,
  'duedate': due,
  'done': done,
  'assignedUsers': [
    {
      'participant': {'uid': 'user'},
      'type': 0,
    },
  ],
};

final _now = DateTime.utc(2030, 5, 1, 8);
const _on = ReminderPreferences(enabled: true, leadMinutes: 60);

ReminderTexts _texts([AppLanguage language = AppLanguage.en]) =>
    reminderTexts(language);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DeckDatabase database;
  late AccountRepository repository;
  late StoredAccount account;
  late _Platform platform;
  late ReminderService service;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    database = DeckDatabase(NativeDatabase.memory());
    repository = AccountRepository(database, _Vault());
    account = await repository.add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
      userId: 'user',
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        'id': 1,
        'title': 'Board',
        'color': '008080',
        'archived': false,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
      }),
    ], null);
    platform = _Platform();
    service = ReminderService(platform, clock: () => _now);
  });
  tearDown(() => database.close());

  Future<void> seed(List<Map<String, Object?>> cards) =>
      database.saveStacks(account.id, account.generation, 1, [
        DeckStack.fromJson({
          'id': 2,
          'boardId': 1,
          'title': 'Stack',
          'order': 0,
          'cards': cards,
        }),
      ], null);

  Future<void> reconcile([
    ReminderPreferences preferences = _on,
    ReminderTexts? texts,
  ]) async => service.reconcile(
    await database.dueReminders(now: _now),
    preferences,
    texts ?? _texts(),
  );

  test(
    'schedules one hour before the due time with the card as payload',
    () async {
      await seed([_card(8)]);
      await reconcile();
      final item = platform.items.values.single;
      expect(item.at, DateTime.utc(2030, 5, 1, 9));
      expect(item.title, 'Card 8');
      expect(item.body, contains('Board'));
      expect(item.body, startsWith('Due '));
      final payload = jsonDecode(item.payload) as Map;
      expect(payload['a'], account.id);
      expect(payload['b'], 1);
      expect(payload['c'], 8);
    },
  );

  test('a lead time of zero fires at the due time', () async {
    await seed([_card(8)]);
    await reconcile(const ReminderPreferences(enabled: true, leadMinutes: 0));
    expect(platform.items.values.single.at, DateTime.utc(2030, 5, 1, 10));
  });

  test('a reminder time that already passed is not scheduled', () async {
    await seed([_card(8, due: '2030-05-01T08:30:00+00:00')]);
    await reconcile();
    expect(platform.items, isEmpty);
  });

  test(
    'a passed but undelivered reminder survives until its card changes',
    () async {
      var now = _now;
      service = ReminderService(platform, clock: () => now);
      await seed([_card(8)]);
      await reconcile();
      // Inexact alarms can be minutes late: past 9:00, not yet shown.
      now = DateTime.utc(2030, 5, 1, 9, 5);
      await service.reconcile(
        await database.dueReminders(now: now),
        _on,
        _texts(),
      );
      expect(platform.items.values.single.at, DateTime.utc(2030, 5, 1, 9));
      expect(platform.cancelCalls, 0);
      await database.saveCardDraft(account, 1, 2, {
        'done': '2030-05-01T09:04:00+00:00',
      }, original: DeckCard.fromJson(_card(8)));
      await service.reconcile(
        await database.dueReminders(now: now),
        _on,
        _texts(),
      );
      expect(platform.items, isEmpty);
    },
  );

  test('reconciling again changes nothing', () async {
    await seed([_card(8)]);
    await reconcile();
    await reconcile();
    expect(platform.scheduleCalls, 1);
    expect(platform.cancelCalls, 0);
  });

  test('a changed due date replaces the notification', () async {
    await seed([_card(8)]);
    await reconcile();
    await seed([_card(8, due: '2030-05-02T10:00:00+00:00')]);
    await reconcile();
    expect(platform.items, hasLength(1));
    expect(platform.items.values.single.at, DateTime.utc(2030, 5, 2, 9));
  });

  test('finishing the card, even offline, cancels it', () async {
    await seed([_card(8)]);
    await reconcile();
    await database.saveCardDraft(account, 1, 2, {
      'done': '2030-05-01T08:00:00+00:00',
    }, original: DeckCard.fromJson(_card(8)));
    await reconcile();
    expect(platform.items, isEmpty);
  });

  test('a card that is gone from the cache is cancelled', () async {
    await seed([_card(8), _card(9)]);
    await reconcile();
    expect(platform.items, hasLength(2));
    await seed([_card(9)]);
    await reconcile();
    expect(platform.items.values.map((item) => item.title), ['Card 9']);
  });

  test('removing the account cancels its reminders', () async {
    await seed([_card(8)]);
    await reconcile();
    await repository.remove(account.id);
    await reconcile();
    expect(platform.items, isEmpty);
  });

  test('turning reminders off cancels everything', () async {
    await seed([_card(8)]);
    await reconcile();
    await reconcile(const ReminderPreferences());
    expect(platform.items, isEmpty);
  });

  test('only the nearest 60 are scheduled', () async {
    await seed([
      for (var id = 1; id <= 70; id++)
        _card(id, due: DateTime.utc(2030, 6, 1, 0, id).toIso8601String()),
    ]);
    await reconcile();
    expect(platform.items, hasLength(reminderLimit));
    final titles = platform.items.values.map((item) => item.title).toSet();
    expect(titles, contains('Card 1'));
    expect(titles, isNot(contains('Card 70')));
  });

  test('a language change rewrites the notification text', () async {
    await seed([_card(8)]);
    await reconcile();
    await reconcile(_on, _texts(AppLanguage.cs));
    expect(platform.items, hasLength(1));
    expect(platform.items.values.single.body, startsWith('Termín '));
  });

  test('a notification this app did not write is cancelled', () async {
    platform.items[5] = _Item(_now, 'x', 'y', 'not json');
    await reconcile();
    expect(platform.items, isEmpty);
  });

  test('the coordinator follows changes in the cache', () async {
    await seed([_card(8)]);
    final opened = <String>[];
    final coordinator = ReminderCoordinator(
      database: database,
      service: service,
      language: () => AppLanguage.en,
      onOpen: (payload) async => opened.add(payload),
      debounce: Duration.zero,
      loadPreferences: () async => _on,
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    await pumpEventQueue();
    expect(platform.items.values.single.title, 'Card 8');

    await seed([_card(8, done: '2030-05-01T08:00:00+00:00')]);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await pumpEventQueue();
    expect(platform.items, isEmpty);
  });

  test('the coordinator passes taps and the launch notification on', () async {
    platform.launch = '{"a":"launch"}';
    final opened = <String>[];
    final coordinator = ReminderCoordinator(
      database: database,
      service: service,
      language: () => AppLanguage.en,
      onOpen: (payload) async => opened.add(payload),
      debounce: Duration.zero,
      loadPreferences: () async => const ReminderPreferences(),
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    platform.taps_.add('{"a":"tap"}');
    await pumpEventQueue();
    expect(opened, ['{"a":"launch"}', '{"a":"tap"}']);
  });

  test('the coordinator cancels stale reminders while they are off', () async {
    await seed([_card(8)]);
    await reconcile();
    final coordinator = ReminderCoordinator(
      database: database,
      service: service,
      language: () => AppLanguage.en,
      onOpen: (_) async {},
      loadPreferences: () async => const ReminderPreferences(),
    );
    addTearDown(coordinator.dispose);
    await coordinator.start();
    expect(platform.items, isEmpty);
  });

  group('opening a tapped reminder', () {
    late Accounts accounts;
    late CardLinkInbox inbox;
    late StoredAccount other;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel(
              'dev.fluttercommunity.plus/connectivity_status',
            ),
            (_) async => null,
          );
      accounts = Accounts(
        database: DeckDatabase(NativeDatabase.memory()),
        transportFactory: (_, _) => MockClient((_) async => throw Exception()),
      );
      await accounts.ready;
      await accounts.add(
        LoginCredentials(
          server: ServerBase.parse('https://cloud.example.com'),
          loginName: 'first',
          appPassword: 'test-password',
        ),
        userId: 'first',
      );
      await accounts.add(
        LoginCredentials(
          server: ServerBase.parse('https://cloud.example.com'),
          loginName: 'second',
          appPassword: 'test-password',
        ),
        userId: 'second',
      );
      other = accounts.items.firstWhere((a) => a.loginName == 'first');
      await accounts.select(other.id);
      inbox = CardLinkInbox();
    });
    tearDown(() async {
      inbox.dispose();
      accounts.dispose();
    });

    test('selects the owning account even on a shared server', () async {
      final target = accounts.items.firstWhere((a) => a.loginName == 'second');
      final opened = await openReminder(
        jsonEncode({'a': target.id, 'b': 3, 'c': 14}),
        accounts,
        inbox,
      );
      expect(opened, isTrue);
      expect(accounts.selected?.id, target.id);
      final link = inbox.pending!.link!;
      expect(link.boardId, 3);
      expect(link.cardId, 14);
      expect(link.server.uri.host, 'cloud.example.com');
    });

    test('ignores a removed account and damaged payloads', () async {
      expect(
        await openReminder(
          jsonEncode({'a': 'gone', 'b': 3, 'c': 14}),
          accounts,
          inbox,
        ),
        isFalse,
      );
      expect(await openReminder('not json', accounts, inbox), isFalse);
      expect(inbox.pending, isNull);
    });
  });

  group('settings', () {
    Widget app(_Platform platform, List<int> refreshed) => ProviderScope(
      overrides: [
        reminderSettingsProvider.overrideWith(
          (ref) => ReminderSettings(platform, () async => refreshed.add(1)),
        ),
      ],
      child: localizedTestApp(
        home: const Scaffold(
          body: SingleChildScrollView(child: ReminderSettingsTile()),
        ),
      ),
    );

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }

    testWidgets('are off by default and turning on asks for permission', (
      tester,
    ) async {
      final platform = _Platform();
      final refreshed = <int>[];
      await tester.pumpWidget(app(platform, refreshed));
      await settle(tester);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('reminders-enabled')))
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('reminders-enabled')));
      await settle(tester);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('reminders-enabled')))
            .value,
        isTrue,
      );
      expect((await ReminderPreferences.load()).enabled, isTrue);
      expect(refreshed, [1]);
    });

    testWidgets('a refused permission keeps reminders off and says why', (
      tester,
    ) async {
      final platform = _Platform()..grant = false;
      final refreshed = <int>[];
      await tester.pumpWidget(app(platform, refreshed));
      await settle(tester);
      await tester.tap(find.byKey(const Key('reminders-enabled')));
      await settle(tester);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('reminders-enabled')))
            .value,
        isFalse,
      );
      expect(find.textContaining('Notifications are blocked'), findsOneWidget);
      expect((await ReminderPreferences.load()).enabled, isFalse);
      expect(refreshed, isEmpty);
    });

    testWidgets('the lead time is stored once reminders are on', (
      tester,
    ) async {
      final platform = _Platform();
      final refreshed = <int>[];
      await tester.pumpWidget(app(platform, refreshed));
      await settle(tester);
      await tester.tap(find.byKey(const Key('reminders-enabled')));
      await settle(tester);
      await tester.tap(find.text('1 hour before'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 day before').last);
      await settle(tester);
      await tester.pumpAndSettle();
      expect((await ReminderPreferences.load()).leadMinutes, 1440);
      expect(refreshed, [1, 1]);
    });

    testWidgets('the text states the iOS limit', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(app(_Platform(), []));
      await settle(tester);
      expect(find.textContaining('64 scheduled notifications'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

final class _Vault implements CredentialVault {
  final _values = <String, String>{};
  @override
  Future<String?> read(String reference) async => _values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      _values[reference] = password;
  @override
  Future<void> delete(String reference) async => _values.remove(reference);
  @override
  Future<Set<String>> references() async => _values.keys.toSet();
}
