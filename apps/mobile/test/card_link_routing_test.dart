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
import 'package:nextclouddeck/data/accounts.dart';
import 'package:nextclouddeck/data/card_link_inbox.dart';
import 'package:nextclouddeck/features/account_gate.dart';
import 'package:nextclouddeck/features/accounts.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/card_editor.dart';
import 'package:nextclouddeck/features/card_link_dialog.dart';
import 'package:nextclouddeck/platform/card_links.dart';

import 'test_support.dart';
import 'board_test_support.dart' show settleBoard;

Map<String, Object?> get board => {
  'id': 1,
  'title': 'Board',
  'color': '008080',
  'archived': false,
  'deletedAt': 0,
  'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': false},
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
Map<String, Object?> get stack => {
  'id': 2,
  'boardId': 1,
  'title': 'Stack',
  'order': 0,
  'cards': [card],
};
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
  late DeckDatabase database;
  late Accounts accounts;
  late ProviderContainer container;
  late CardLinkInbox inbox;
  late StoredAccount first;
  late StoredAccount second;
  final requests = <Uri>[];
  bool containerDisposed = false;

  setUp(() async {
    containerDisposed = false;
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    requests.clear();
    accounts = Accounts(
      database: database,
      transportFactory: (_, _) => MockClient((request) async {
        requests.add(request.url);
        final path = request.url.path;
        if (path.endsWith('/cloud/user')) {
          final authorization = request.headers['authorization']!;
          final user = utf8
              .decode(base64Decode(authorization.substring(6)))
              .split(':')
              .first;
          return json({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': {'id': user},
            },
          });
        }
        if (path.endsWith('/cloud/capabilities')) return http.Response('', 503);
        if (path.endsWith('/boards/1')) return json(board);
        if (path.endsWith('/stacks/archived')) return json([]);
        if (path.endsWith('/stacks')) return json([stack]);
        if (path.endsWith('/stacks/2')) return json(stack);
        if (path.endsWith('/cards/8')) return json(card);
        return http.Response('', 404);
      }),
    );
    await accounts.ready;
    for (final host in ['cloud.example.com', 'other.example.com']) {
      await accounts.add(
        LoginCredentials(
          server: ServerBase.parse('https://$host'),
          loginName: 'user',
          appPassword: 'test-password',
        ),
        userId: 'user',
      );
      await database.saveBoards(
        accounts.selected!.id,
        accounts.selected!.generation,
        [DeckBoard.fromJson(board)],
        null,
      );
    }
    first = accounts.items.firstWhere(
      (account) => account.server.contains('cloud.example.com'),
    );
    second = accounts.items.firstWhere(
      (account) => account.server.contains('other.example.com'),
    );
    await accounts.select(first.id);
    container = ProviderContainer(
      overrides: [accountsProvider.overrideWith((_) => accounts)],
    );
    container.read(accountsProvider);
    inbox = CardLinkInbox();
  });
  void testClean(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        container.dispose();
        containerDisposed = true;
        await tester.pumpAndSettle();
      }
    });
  }

  tearDown(() async {
    inbox.dispose();
    if (!containerDisposed) container.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

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

  Future<void> modelChange(WidgetTester tester, Future<void> change) async {
    var done = false;
    unawaited(
      change.then<void>(
        (_) {
          done = true;
        },
        onError: (Object _, StackTrace _) {
          done = true;
        },
      ),
    );
    await until(tester, () => done);
    await change;
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: localizedTestApp(home: DeckAccountGate(links: inbox)),
      ),
    );
    await tester.pump();
    await until(
      tester,
      () =>
          find.byType(BoardsScreen).evaluate().isNotEmpty &&
          requests.any((uri) => uri.path.endsWith('/cloud/capabilities')) &&
          !accounts.session!.loading('boards') &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty &&
          find.byType(LinearProgressIndicator).evaluate().isEmpty,
    );
  }

  Future<int> systemBack(WidgetTester tester) async {
    var exits = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exits++;
      return null;
    });
    try {
      await messenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
        (_) {},
      );
      await settleBoard(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      return exits;
    } finally {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    }
  }

  void openCard(WidgetTester tester) {
    Navigator.of(tester.element(find.byType(BoardsScreen))).push(
      MaterialPageRoute<void>(
        builder: (_) => CardScreen(
          session: accounts.session!,
          board: DeckBoard.fromJson(board),
          card: DeckCard.fromJson(card),
        ),
      ),
    );
  }

  testClean(
    'platform Back pops card and accounts routes before exiting the root',
    (tester) async {
      await mount(tester);
      openCard(tester);
      await settleBoard(tester);
      expect(find.byType(CardScreen), findsOneWidget);
      expect(await systemBack(tester), 0);
      expect(find.byType(CardScreen), findsNothing);
      final navigator = Navigator.of(tester.element(find.byType(BoardsScreen)));
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const AccountsScreen()),
      );
      await settleBoard(tester);
      expect(find.byType(AccountsScreen), findsOneWidget);
      expect(await systemBack(tester), 0);
      expect(find.byType(AccountsScreen), findsNothing);
      expect(await systemBack(tester), 1);
    },
  );

  testClean('platform Back uses only the current account navigator', (
    tester,
  ) async {
    await mount(tester);
    openCard(tester);
    await settleBoard(tester);
    await modelChange(tester, accounts.select(second.id));
    await settleBoard(tester);
    expect(find.byType(CardScreen), findsNothing);
    expect(await systemBack(tester), 1);
    openCard(tester);
    await settleBoard(tester);
    expect(await systemBack(tester), 0);
    expect(find.byType(CardScreen), findsNothing);
    expect(accounts.selected!.id, second.id);
  });

  testClean(
    'platform Back honors editor PopScope and preserves a failed draft on cancel',
    (tester) async {
      await mount(tester);
      unawaited(
        editCard(
          tester.element(find.byType(BoardsScreen)),
          accounts.session!,
          1,
          2,
          card: DeckCard.fromJson(card),
        ),
      );
      await settleBoard(tester);
      await modelChange(
        tester,
        database.customStatement(
          "CREATE TRIGGER fail_draft BEFORE INSERT ON editor_drafts BEGIN SELECT RAISE(ABORT, 'private failure'); END",
        ),
      );
      await tester.enterText(
        find.byType(TextField).first,
        'Keep unsaved title',
      );
      await settleBoard(tester);
      expect(await systemBack(tester), 0);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Leave unsaved changes?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await settleBoard(tester);
      expect(find.byType(CardEditor), findsOneWidget);
      expect(find.text('Keep unsaved title'), findsOneWidget);
      await modelChange(
        tester,
        database.customStatement('DROP TRIGGER fail_draft'),
      );
      await tester.enterText(find.byType(TextField).first, 'Saved draft title');
      await settleBoard(tester);
      expect(await systemBack(tester), 0);
      expect(find.byType(CardEditor), findsNothing);
      String? savedTitle;
      await modelChange(tester, () async {
        final drafts = await database
            .watchEditorDrafts(accounts.selected!.id)
            .first;
        savedTitle = jsonDecode(drafts.single.payload)['title'] as String;
      }());
      expect(savedTitle, 'Saved draft title');
    },
  );

  testClean(
    'incoming cards belong to the session navigator and disappear on account switch',
    (tester) async {
      await mount(tester);
      inbox.offer(
        'ncdeck://open?uri=https%3A%2F%2Fcloud.example.com%2Fapps%2Fdeck%2Fboard%2F1%2Fcard%2F8',
      );
      await until(tester, () => find.byType(CardScreen).evaluate().isNotEmpty);
      expect(find.text('Linked card'), findsOneWidget);
      await modelChange(tester, accounts.select(second.id));
      await until(
        tester,
        () =>
            find.byType(CardScreen).evaluate().isEmpty &&
            !accounts.session!.loading('boards') &&
            find.byType(CircularProgressIndicator).evaluate().isEmpty &&
            find.byType(LinearProgressIndicator).evaluate().isEmpty,
      );
      expect(find.byType(CardScreen), findsNothing);
      expect(accounts.selected!.id, second.id);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testClean(
    'an unknown server asks to add an account without sending credentials there',
    (tester) async {
      await mount(tester);
      inbox.offer('https://unknown.example.com/apps/deck/board/1/card/8');
      await until(
        tester,
        () => find.text('Add an account for this server').evaluate().isNotEmpty,
      );
      expect(requests.any((uri) => uri.host == 'unknown.example.com'), isFalse);
      await tester.tap(find.text('Cancel'));
      await until(tester, () => inbox.pending == null);
      expect(accounts.selected!.id, first.id);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testClean(
    'an incoming link preserves a typed card-link dialog before switching accounts',
    (tester) async {
      await mount(tester);
      unawaited(enterCardLink(tester.element(find.byType(BoardsScreen))));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('card-link-input')),
        'https://cloud.example.com/unfinished',
      );
      inbox.offer('https://other.example.com/apps/deck/board/1/card/8');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      expect(accounts.selected!.id, first.id);
      expect(requests.any((uri) => uri.host == 'other.example.com'), isFalse);
      expect(find.text('https://cloud.example.com/unfinished'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await until(tester, () => find.byType(CardScreen).evaluate().isNotEmpty);
      expect(accounts.selected!.id, second.id);
    },
  );

  testClean(
    'multiple matching accounts require a choice when another server is active',
    (tester) async {
      await modelChange(tester, () async {
        await accounts.add(
          LoginCredentials(
            server: ServerBase.parse(first.server),
            loginName: 'third-user',
            appPassword: 'test-password',
          ),
          userId: 'third-user',
        );
        await accounts.select(second.id);
      }());
      final third = accounts.items.singleWhere(
        (account) => account.loginName == 'third-user',
      );
      await mount(tester);
      inbox.offer('https://cloud.example.com/apps/deck/board/1/card/8');
      await until(
        tester,
        () => find
            .text('Choose an account to open the card')
            .evaluate()
            .isNotEmpty,
      );
      expect(accounts.selected!.id, second.id);
      await tester.tap(find.text('third-user'));
      await until(tester, () => find.byType(CardScreen).evaluate().isNotEmpty);
      expect(
        tester.widget<CardScreen>(find.byType(CardScreen)).session.account.id,
        third.id,
      );
    },
  );

  test('account matching includes the installation path', () {
    final link = parseDeckCardLink(
      'https://cloud.example.com/sub/apps/deck/board/1/card/8',
    )!;
    expect(
      accountsForCardLink([
        first,
        first.copyWith(id: 'sub', server: 'https://cloud.example.com/sub/'),
      ], link).single.id,
      'sub',
    );
  });

  test('a closed bridge ignores a late launch-link read', () async {
    const channel = MethodChannel('test.deck.links');
    final ready = Completer<String?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) => ready.future);
    final native = NativeCardLinks(inbox, channel: channel);
    final starting = native.start();
    native.close();
    ready.complete(
      'ncdeck://open?uri=https%3A%2F%2Fcloud.example.com%2Fapps%2Fdeck%2Fboard%2F1%2Fcard%2F8',
    );
    await starting;
    expect(inbox.pending, isNull);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'native launch and warm messages feed the same deduplicated inbox',
    () async {
      const channel = MethodChannel('test.deck.links.delivery');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const first = 'https://cloud.example.com/apps/deck/board/1/card/8';
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getLaunchLink');
        return first;
      });
      final native = NativeCardLinks(inbox, channel: channel);
      await native.start();
      final sequence = inbox.pending!.sequence;
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('link', first),
        ),
        (_) {},
      );
      expect(inbox.pending!.sequence, sequence);
      inbox.complete(inbox.pending!);
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall(
            'link',
            'https://cloud.example.com/apps/deck/board/1/card/9',
          ),
        ),
        (_) {},
      );
      expect(inbox.pending!.link!.cardId, 9);
      native.close();
      messenger.setMockMethodCallHandler(channel, null);
    },
  );
}
