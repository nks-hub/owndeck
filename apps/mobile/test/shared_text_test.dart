import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/accounts.dart';
import 'package:nextclouddeck/data/card_link_inbox.dart';
import 'package:nextclouddeck/data/shared_text_inbox.dart';
import 'package:nextclouddeck/features/account_gate.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/login.dart';
import 'package:nextclouddeck/platform/shared_text.dart';

import 'test_support.dart';

Map<String, Object?> get board => {
  'id': 1,
  'title': 'Board',
  'color': '008080',
  'archived': false,
  'deletedAt': 0,
  'permissions': {
    'PERMISSION_READ': true,
    'PERMISSION_EDIT': true,
    'PERMISSION_MANAGE': true,
  },
};
Map<String, Object?> get stack => {
  'id': 2,
  'boardId': 1,
  'title': 'Inbox',
  'order': 0,
  'cards': [card],
};
Map<String, Object?> get card => {
  'id': 8,
  'stackId': 2,
  'title': 'Linked card',
  'description': '',
  'order': 0,
  'archived': false,
  'deletedAt': 0,
};

final class MemoryStore implements AppPreferenceStore {
  MemoryStore([Map<String, String>? values]) : values = {...?values};
  final Map<String, String> values;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

http.Response json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );

  group('SharedText.parse', () {
    test(
      'uses the subject as title and keeps the shared text as description',
      () {
        final value = SharedText.parse(
          'https://example.com/a',
          subject: 'Article',
        )!;
        expect(value.title, 'Article');
        expect(value.description, 'https://example.com/a');
      },
    );

    test('a bare URL becomes the title without a duplicate description', () {
      final value = SharedText.parse('  https://example.com/a \n')!;
      expect(value.title, 'https://example.com/a');
      expect(value.description, isEmpty);
    });

    test('the first line is the title and the whole text is kept', () {
      final value = SharedText.parse('\n First line \nSecond line')!;
      expect(value.title, 'First line');
      expect(value.description, '\n First line \nSecond line'.trim());
    });

    test('long titles are cut to the card title limit by characters', () {
      final value = SharedText.parse('😀' * 300)!;
      expect(value.title.runes.length, sharedTitleLimit);
      expect(value.description.runes.length, 300);
    });

    test('blank content is rejected', () {
      expect(SharedText.parse('  \n ', subject: ' '), isNull);
      expect(SharedText.parse(null), isNull);
    });
  });

  group('inbox and native bridge', () {
    test('a newer share replaces a pending one and complete is idempotent', () {
      final inbox = SharedTextInbox();
      inbox.offer('one');
      final first = inbox.pending!;
      inbox.offer('two');
      expect(inbox.contains(first), isFalse);
      inbox.complete(first);
      expect(inbox.pending?.content?.title, 'two');
      inbox.complete(inbox.pending!);
      expect(inbox.pending, isNull);
      inbox.dispose();
    });

    test(
      'launch and warm shares reach the inbox, a closed bridge is silent',
      () async {
        const channel = MethodChannel('test.deck.share');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => {'text': 'https://example.com', 'subject': 'Cold'},
        );
        final inbox = SharedTextInbox();
        final native = NativeSharedText(inbox, channel: channel);
        await native.start();
        expect(inbox.pending?.content?.title, 'Cold');
        await messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('share', {'text': 'Warm text'}),
          ),
          (_) {},
        );
        expect(inbox.pending?.content?.title, 'Warm text');
        native.close();
        await messenger.handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('share', {'text': 'Late'}),
          ),
          (_) {},
        );
        expect(inbox.pending?.content?.title, 'Warm text');
        messenger.setMockMethodCallHandler(channel, null);
        inbox.dispose();
      },
    );
  });

  group('persistence', () {
    String saved(String title, [String description = '']) =>
        jsonEncode({'title': title, 'description': description});

    test(
      'a pending share is restored by a new inbox until it is completed',
      () async {
        final store = MemoryStore();
        final before = SharedTextInbox(store: store)
          ..offer('https://example.com/a', subject: 'Article');
        await Future<void>.delayed(Duration.zero);
        before.dispose();

        final after = SharedTextInbox(store: store);
        await after.restore();
        expect(after.pending?.content?.title, 'Article');
        expect(after.pending?.content?.description, 'https://example.com/a');

        after.complete(after.pending!);
        await Future<void>.delayed(Duration.zero);
        final third = SharedTextInbox(store: store);
        await third.restore();
        expect(third.pending, isNull);
        for (final inbox in [after, third]) {
          inbox.dispose();
        }
      },
    );

    test('a newer share is not replaced by the saved one', () async {
      final inbox = SharedTextInbox(
        store: MemoryStore({SharedTextInbox.storeKey: saved('Old')}),
      )..offer('New');
      await inbox.restore();
      expect(inbox.pending?.content?.title, 'New');
      inbox.dispose();
    });

    test('blank and damaged saved values are ignored', () async {
      for (final raw in ['', 'not json', '[]', saved(''), '{"title":1}']) {
        final inbox = SharedTextInbox(
          store: MemoryStore({SharedTextInbox.storeKey: raw}),
        );
        await inbox.restore();
        expect(inbox.pending, isNull, reason: raw);
        inbox.dispose();
      }
    });

    test('a blank share clears the saved one', () async {
      final store = MemoryStore({SharedTextInbox.storeKey: saved('Old')});
      final inbox = SharedTextInbox(store: store)..offer('  ');
      await Future<void>.delayed(Duration.zero);
      expect(store.values[SharedTextInbox.storeKey], isEmpty);
      inbox.dispose();
    });

    test(
      'a store that fails to read or write does not break the inbox',
      () async {
        final inbox = SharedTextInbox(store: _BrokenStore())..offer('Text');
        await inbox.restore();
        expect(inbox.pending?.content?.title, 'Text');
        inbox.complete(inbox.pending!);
        await Future<void>.delayed(Duration.zero);
        expect(inbox.pending, isNull);
        inbox.dispose();
      },
    );
  });

  group('gate', () {
    late DeckDatabase database;
    late Accounts accounts;
    late ProviderContainer container;
    late SharedTextInbox inbox;
    late CardLinkInbox links;
    late MemoryStore store;
    late StoredAccount first;

    Future<void> until(WidgetTester tester, bool Function() condition) async {
      for (var index = 0; index < 100 && !condition(); index++) {
        await tester.pump(const Duration(milliseconds: 30));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(condition(), isTrue);
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<List<EditorDraft>> draftsOf(WidgetTester tester, String id) async {
      var drafts = <EditorDraft>[];
      for (var index = 0; index < 50 && drafts.isEmpty; index++) {
        await tester.pump(const Duration(milliseconds: 30));
        drafts = (await tester.runAsync(
          () => database.watchEditorDrafts(id).first,
        ))!;
        if (drafts.isEmpty) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
        }
      }
      return drafts;
    }

    Future<void> modelChange(WidgetTester tester, Future<void> change) async {
      var done = false;
      unawaited(
        change.then<void>(
          (_) => done = true,
          onError: (Object _, StackTrace _) => done = true,
        ),
      );
      await until(tester, () => done);
      await change;
    }

    Future<void> prepare(int accountCount, Map<String, String> saved) async {
      FlutterSecureStorage.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivity, (_) async => null);
      database = DeckDatabase(NativeDatabase.memory());
      accounts = Accounts(
        database: database,
        transportFactory: (_, _) => MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/cloud/user')) {
            return json({
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': {'id': 'user'},
              },
            });
          }
          if (path.endsWith('/cloud/capabilities')) {
            return http.Response('', 503);
          }
          if (path.endsWith('/boards/1')) return json(board);
          if (path.endsWith('/cards/8')) return json(card);
          if (path.endsWith('/boards')) return json([board]);
          if (path.endsWith('/stacks/archived')) return json([]);
          if (path.endsWith('/stacks')) return json([stack]);
          if (path.endsWith('/stacks/2')) return json(stack);
          return http.Response('', 404);
        }),
      );
      await accounts.ready;
      for (var index = 0; index < accountCount; index++) {
        await accounts.add(
          LoginCredentials(
            server: ServerBase.parse('https://cloud$index.example.com'),
            loginName: 'user$index',
            appPassword: 'test-password',
          ),
          userId: 'user$index',
        );
        await database.saveBoards(
          accounts.selected!.id,
          accounts.selected!.generation,
          [DeckBoard.fromJson(board)],
          null,
        );
        await database.saveStacks(
          accounts.selected!.id,
          accounts.selected!.generation,
          1,
          [DeckStack.fromJson(stack)],
          null,
        );
      }
      if (accounts.items.isNotEmpty) {
        first = accounts.items.first;
        await accounts.select(first.id);
      }
      container = ProviderContainer(
        overrides: [accountsProvider.overrideWith((_) => accounts)],
      );
      container.read(accountsProvider);
      store = MemoryStore(saved);
      inbox = SharedTextInbox(store: store);
      links = CardLinkInbox();
    }

    void testGate(
      String name,
      int accountCount,
      Future<void> Function(WidgetTester) body, {
      Map<String, String> saved = const {},
    }) {
      testWidgets(name, (tester) async {
        await tester.runAsync(() => prepare(accountCount, saved));
        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: localizedTestApp(
                home: DeckAccountGate(shares: inbox, links: links),
              ),
            ),
          );
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
          inbox.dispose();
          links.dispose();
          container.dispose();
          await tester.pump(const Duration(seconds: 1));
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(connectivity, null);
        }
      });
    }

    Future<void> waitForBoards(WidgetTester tester) => until(
      tester,
      () =>
          find.byType(BoardsScreen).evaluate().isNotEmpty &&
          !accounts.session!.loading('boards') &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );

    testGate(
      'asks for the account, then shows the shared text in quick add',
      2,
      (tester) async {
        await waitForBoards(tester);
        inbox.offer('https://example.com/read', subject: 'Read later');
        await until(
          tester,
          () => find
              .text('Choose an account for the new card')
              .evaluate()
              .isNotEmpty,
        );
        expect(accounts.selected!.id, first.id);
        await tester.tap(find.textContaining('user1'));
        await until(
          tester,
          () =>
              find
                  .byKey(const Key('quick-add-account'))
                  .evaluate()
                  .isNotEmpty &&
              find.byType(LinearProgressIndicator).evaluate().isEmpty,
        );
        expect(accounts.selected!.loginName, 'user1');
        expect(find.textContaining('user1'), findsWidgets);
        expect(find.text('Read later'), findsOneWidget);
        expect(find.text('https://example.com/read'), findsOneWidget);
        expect(inbox.pending, isNull);
        final drafts = await draftsOf(tester, accounts.selected!.id);
        expect(drafts.single.draftKey, startsWith('quick:'));
      },
    );

    testGate('a single account is confirmed in the sheet without a picker', 1, (
      tester,
    ) async {
      await waitForBoards(tester);
      inbox.offer('Buy milk');
      await until(
        tester,
        () => find.byKey(const Key('quick-add-account')).evaluate().isNotEmpty,
      );
      expect(find.text('Choose an account for the new card'), findsNothing);
      expect(find.text('Buy milk'), findsOneWidget);
    });

    testGate(
      'cancelled re-authentication keeps the shared text as a draft',
      1,
      (tester) async {
        await waitForBoards(tester);
        await modelChange(tester, () async {
          await accounts.repository.requireAuthentication(accounts.selected!);
          await accounts.retryLoad();
        }());
        await until(tester, () => accounts.session == null);
        inbox.offer('https://example.com/later', subject: 'Later');
        await until(
          tester,
          () => find.byType(LoginScreen).evaluate().length == 2,
        );
        Navigator.of(tester.element(find.byType(LoginScreen).last)).pop();
        await until(tester, () => inbox.pending == null);
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.text(
            'Shared text is saved in Drafts. Sign in to add it as a card.',
          ),
          findsOneWidget,
        );
        final drafts = await draftsOf(tester, first.id);
        expect(drafts, hasLength(1));
        expect(drafts.single.draftKey, startsWith(sharedDraftPrefix));
        final payload =
            jsonDecode(drafts.single.payload) as Map<String, Object?>;
        expect(payload['title'], 'Later');
        expect(payload['description'], 'https://example.com/later');
      },
    );

    testGate('blank shared content reports that there is nothing to add', 1, (
      tester,
    ) async {
      await waitForBoards(tester);
      inbox.offer('   ');
      await until(
        tester,
        () => find
            .text('There was no text to add as a card.')
            .evaluate()
            .isNotEmpty,
      );
      expect(inbox.pending, isNull);
    });

    testGate(
      'a share saved before the app was killed opens in quick add after start',
      1,
      (tester) async {
        await waitForBoards(tester);
        await until(
          tester,
          () =>
              find.byKey(const Key('quick-add-account')).evaluate().isNotEmpty,
        );
        expect(find.text('Saved earlier'), findsOneWidget);
        expect(inbox.pending, isNull);
        expect(store.values[SharedTextInbox.storeKey], isEmpty);
      },
      saved: {
        SharedTextInbox.storeKey: jsonEncode({
          'title': 'Saved earlier',
          'description': 'https://example.com/saved',
        }),
      },
    );

    testGate(
      'a share received without an account is kept and offered after sign-in',
      0,
      (tester) async {
        await tester.pump(const Duration(milliseconds: 300));
        inbox.offer('https://example.com/later', subject: 'Later');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        expect(inbox.pending, isNotNull);
        expect(jsonDecode(store.values[SharedTextInbox.storeKey]!), {
          'title': 'Later',
          'description': 'https://example.com/later',
        });
        await modelChange(
          tester,
          accounts.add(
            LoginCredentials(
              server: ServerBase.parse('https://cloud9.example.com'),
              loginName: 'user9',
              appPassword: 'test-password',
            ),
            userId: 'user9',
          ),
        );
        await modelChange(
          tester,
          database.saveBoards(
            accounts.selected!.id,
            accounts.selected!.generation,
            [DeckBoard.fromJson(board)],
            null,
          ),
        );
        await modelChange(
          tester,
          database.saveStacks(
            accounts.selected!.id,
            accounts.selected!.generation,
            1,
            [DeckStack.fromJson(stack)],
            null,
          ),
        );
        await until(
          tester,
          () =>
              find.byKey(const Key('quick-add-account')).evaluate().isNotEmpty,
        );
        expect(find.text('Later'), findsOneWidget);
        expect(inbox.pending, isNull);
        expect(store.values[SharedTextInbox.storeKey], isEmpty);
      },
    );

    testGate(
      'a card link and a shared text delivered together are both handled, link first',
      1,
      (tester) async {
        await waitForBoards(tester);
        final order = <String>[];
        links.addListener(() {
          if (links.pending == null) order.add('link');
        });
        inbox.addListener(() {
          if (inbox.pending == null) order.add('text');
        });
        links.offer('https://cloud0.example.com/apps/deck/board/1/card/8');
        inbox.offer('https://example.com/read', subject: 'Read later');
        await until(
          tester,
          () =>
              find
                  .byKey(const Key('quick-add-account'))
                  .evaluate()
                  .isNotEmpty &&
              find
                  .byType(CardScreen, skipOffstage: false)
                  .evaluate()
                  .isNotEmpty,
        );
        expect(order, ['link', 'text']);
        expect(find.text('Read later'), findsOneWidget);
        expect(links.pending, isNull);
        expect(inbox.pending, isNull);
      },
    );
  });
}

final class _BrokenStore implements AppPreferenceStore {
  @override
  Future<String?> read(String key) => Future.error(StateError('read'));

  @override
  Future<void> write(String key, String value) =>
      Future.error(StateError('write'));
}
