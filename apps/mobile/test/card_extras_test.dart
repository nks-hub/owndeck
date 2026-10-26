import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/card_links.dart';
import 'package:nextclouddeck/features/notifications.dart';
import 'package:nextclouddeck/features/structure_editor.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

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

http.Response reply(Object data) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': data,
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase db;
  late StoredAccount account;
  late DeckSession session;
  late DeckBoard board;
  late DeckCard card;
  late DeckStack stack;
  var requests = 0;
  final requestPaths = <String>[];

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(db, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Read only',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true},
    });
    card = DeckCard.fromJson({
      'id': 8,
      'stackId': 2,
      'title': 'Task',
      'description': '',
      'order': 0,
      'type': 'plain',
      'owner': 'user',
      'archived': false,
      'dependentCards': [],
    });
    stack = DeckStack.fromJson({
      'id': 2,
      'boardId': 1,
      'title': 'Column',
      'order': 0,
      'isDoneColumn': false,
      'cards': [card.raw],
    });
    await db.saveBoards(account.id, account.generation, [
      board,
      DeckBoard.fromJson({
        ...board.raw,
        'id': 3,
        'title': 'Writable',
        'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
      }),
    ], null);
    await db.saveStacks(account.id, account.generation, 1, [stack], null);
    requests = 0;
    requestPaths.clear();
    session = DeckSession(
      db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          requests++;
          requestPaths.add('${request.method} ${request.url.path}');
          if (request.url.path.endsWith('/capabilities')) {
            return reply({
              'capabilities': {
                'notifications': {
                  'ocs-endpoints': ['list'],
                },
              },
            });
          }
          if (request.url.path.endsWith('/notifications')) {
            return reply([
              {
                'notification_id': 1,
                'app': 'deck',
                'subject': 'Card updated',
                'message': 'A comment was added.',
                'datetime': '2026-01-01T12:00:00Z',
                'link': 'https://cloud.example.com/apps/deck/board/1/card/8',
              },
              {
                'notification_id': 2,
                'app': 'other',
                'subject': 'Other app content',
              },
            ]);
          }
          throw StateError('unexpected_request');
        }),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });
  Widget app(Widget home, {double scale = 1}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  );

  testWidgets('read-only cards offer copying without exposing edit actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(CardScreen(session: session, board: board, card: card)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Copy card'), findsOneWidget);
    expect(find.text('Delete card'), findsNothing);
    await tester.tap(find.text('Copy card'));
    await tester.pumpAndSettle();
    final destinations = find.byType(BottomSheet);
    expect(destinations, findsOneWidget);
    expect(
      find.descendant(of: destinations, matching: find.text('Writable')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: destinations, matching: find.text('Read only')),
      findsNothing,
    );
    expect(requestPaths, ['GET /index.php/apps/deck/api/v1.1/boards/1']);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'unsupported stacks hide the done action and the supported action explains its effects',
    (tester) async {
      final unsupported = DeckStack.fromJson(
        {...stack.raw}..remove('isDoneColumn'),
      );
      final managerBoard = DeckBoard.fromJson({
        ...board.raw,
        'permissions': {
          'PERMISSION_READ': true,
          'PERMISSION_EDIT': true,
          'PERMISSION_MANAGE': true,
        },
      });
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StackActions(session: session, board: board, stack: stack),
          ),
        ),
      );
      expect(find.text('Set as done column'), findsNothing);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StackActions(
              session: session,
              board: managerBoard,
              stack: unsupported,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Column actions'));
      await tester.pumpAndSettle();
      expect(find.text('Set as done column'), findsNothing);
      await tester.tapAt(const Offset(4, 100));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: StackActions(
              session: session,
              board: managerBoard,
              stack: stack,
            ),
          ),
          scale: 2,
        ),
      );
      await tester.tap(find.byTooltip('Column actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set as done column'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('active cards will be marked complete'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'copying offers stored destination columns without waiting for the network',
    (tester) async {
      await db.saveStacks(account.id, account.generation, 3, [
        DeckStack.fromJson({
          'id': 4,
          'boardId': 3,
          'title': 'Stored column',
          'order': 0,
          'cards': [],
        }),
      ], null);
      await tester.pumpWidget(
        app(CardScreen(session: session, board: board, card: card)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy card'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Writable'));
      await tester.pumpAndSettle();
      expect(find.text('Stored column'), findsOneWidget);
      expect(
        find.textContaining('Dates, comments and attachments are not copied.'),
        findsOneWidget,
      );
      expect(requestPaths, ['GET /index.php/apps/deck/api/v1.1/boards/1']);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PopupMenuButton<String>>(
              find.byType(PopupMenuButton<String>),
            )
            .enabled,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'linked-card overview explains that links do not block completion',
    (tester) async {
      await tester.pumpWidget(
        app(
          CardLinksScreen(session: session, boardId: board.id, cardId: card.id),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('They do not block completion.'),
        findsOneWidget,
      );
      expect(find.text('Link a card'), findsNothing);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('notification link override receives the filtered account URL', (
    tester,
  ) async {
    Uri? opened;
    await tester.pumpWidget(
      app(
        NotificationsScreen(
          session: session,
          openLink: (uri) async {
            opened = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Card updated'), findsOneWidget);
    expect(find.text('Other app content'), findsNothing);
    await tester.tap(find.text('Open card link'));
    await tester.pumpAndSettle();
    expect(
      opened,
      Uri.parse('https://cloud.example.com/apps/deck/board/1/card/8'),
    );
    expect(requests, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('card notification fetches and opens its native account card', (
    tester,
  ) async {
    const browser = MethodChannel('plugins.flutter.io/url_launcher');
    final launches = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(browser, (call) async {
          launches.add(call);
          return true;
        });
    final seen = <http.Request>[];
    final origin = Uri.parse(account.server).origin;
    final authorization =
        'Basic ${base64Encode(utf8.encode('${account.loginName}:test-password'))}';
    final fetchedCard = {
      ...card.raw,
      'title': 'Fetched notification card',
      'description': 'Loaded from the original account.',
    };
    final fetchedStack = {
      ...stack.raw,
      'cards': [fetchedCard],
    };
    http.Response raw(Object data) => http.Response(
      jsonEncode(data),
      200,
      headers: {'content-type': 'application/json'},
    );
    await tester.runAsync(() async {
      session.dispose();
      session = DeckSession(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'test-password',
          transport: MockClient((request) async {
            seen.add(request);
            if (request.url.origin != origin ||
                request.headers['authorization'] != authorization) {
              return http.Response('', 403);
            }
            final path = request.url.path;
            if (path.endsWith('/capabilities')) {
              return reply({
                'capabilities': {
                  'notifications': {
                    'ocs-endpoints': ['list'],
                  },
                },
              });
            }
            if (path.endsWith('/notifications')) {
              return reply([
                {
                  'notification_id': 7,
                  'app': 'deck',
                  'subject': 'Open this card',
                  'message': '',
                  'datetime': '2026-01-01T12:00:00Z',
                  'link': '$origin/index.php/apps/deck/board/1/card/8',
                },
              ]);
            }
            if (path.endsWith('/boards/1')) return raw(board.raw);
            if (path.endsWith('/boards/1/stacks')) return raw([fetchedStack]);
            if (path.endsWith('/boards/1/stacks/archived')) return raw([]);
            if (path.endsWith('/boards/1/stacks/2')) return raw(fetchedStack);
            if (path.endsWith('/boards/1/stacks/2/cards/8')) {
              return raw(fetchedCard);
            }
            return http.Response('', 404);
          }),
        ),
      );
    });
    Future<void> until(Finder finder) async {
      for (
        var attempt = 0;
        attempt < 100 && finder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 30));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(finder, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    }

    try {
      await tester.pumpWidget(app(NotificationsScreen(session: session)));
      await until(find.text('Open card link'));
      await tester.tap(find.text('Open card link'));
      await until(find.byType(CardScreen));
      await until(find.text('Fetched notification card'));
      final screen = tester.widget<CardScreen>(find.byType(CardScreen));
      expect(screen.session, same(session));
      expect(screen.session.account.id, account.id);
      expect(screen.board.id, 1);
      expect(screen.card.id, 8);
      expect(find.text('Loaded from the original account.'), findsOneWidget);
      expect(launches, isEmpty);
      expect(seen.every((request) => request.url.origin == origin), isTrue);
      expect(
        seen.every(
          (request) => request.headers['authorization'] == authorization,
        ),
        isTrue,
      );
      expect(seen.every((request) => request.method == 'GET'), isTrue);
      const prefix = '/index.php/apps/deck/api/v1.1/boards/1';
      expect(
        seen.map((request) => request.url.path),
        containsAll([
          prefix,
          '$prefix/stacks',
          '$prefix/stacks/archived',
          '$prefix/stacks/2',
          '$prefix/stacks/2/cards/8',
        ]),
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(browser, null);
    }
  });
}
