import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/settings.dart';
import 'package:nextclouddeck/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'board_test_support.dart';

final class _ShellFixture {
  late final BoardFixture model;
  bool offline = false;
  int searchRequests = 0;

  static Future<_ShellFixture> create() async {
    final result = _ShellFixture();
    final original = await BoardFixture.create(counts: [1]);
    original.session.dispose();
    await original.db.saveUserIdentity(original.account, 'user');
    final account = (await original.db.account(original.account.id))!;
    final session = DeckSession(
      original.db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient(result.handle),
      ),
      pollInterval: const Duration(hours: 1),
    );
    result.model = BoardFixture(
      original.db,
      account,
      session,
      original.board,
      original.stacks,
    );
    return result;
  }

  http.Response json(Object value, {bool ocs = false}) => http.Response(
    jsonEncode(
      ocs
          ? {
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': value,
              },
            }
          : value,
    ),
    200,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> handle(http.Request request) async {
    if (offline) throw const SocketException('fixture_offline');
    final path = request.url.path;
    if (path.endsWith('/cloud/user')) return json({'id': 'user'}, ocs: true);
    if (path.endsWith('/cloud/capabilities')) {
      return json({
        'capabilities': {
          'deck': {
            'version': '1.19.1',
            'apiVersions': ['1.1'],
            'canCreateBoards': true,
          },
        },
      }, ocs: true);
    }
    if (path.endsWith('/boards')) return json([model.board.raw]);
    if (path.endsWith('/boards/1')) return json(model.board.raw);
    if (path.endsWith('/stacks')) {
      return json(model.stacks.map((stack) => stack.raw).toList());
    }
    if (path.endsWith('/search') || path.endsWith('/overview/upcoming')) {
      searchRequests++;
      final card = {
        ...model.stacks.first.cards.first.raw,
        'title': 'Keep this task',
        'boardId': 1,
        'board': {'id': 1, 'title': 'Board'},
        'done': null,
        'duedate': DateTime.now().toUtc().toIso8601String(),
        'assignedUsers': [
          {
            'type': 0,
            'participant': {'uid': 'user'},
          },
        ],
      };
      return json(
        path.endsWith('/search')
            ? [card]
            : {
                'today': [card],
              },
        ocs: true,
      );
    }
    return http.Response('', 404);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Widget app(
    _ShellFixture fixture,
    AppPreferences preferences, {
    double scale = 1,
  }) => ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWith((ref) => preferences),
      packageInfoProvider.overrideWith(
        (ref) async => PackageInfo(
          appName: 'OwnDeck',
          packageName: 'example.deck',
          version: '0.1.0',
          buildNumber: '2',
        ),
      ),
    ],
    child: OwnDeckApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: BoardsScreen(session: fixture.model.session),
        ),
      ),
    ),
  );

  Future<void> until(WidgetTester tester, bool Function() ready) async {
    for (var i = 0; i < 100 && !ready(); i++) {
      await tester.pump(const Duration(milliseconds: 30));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready(), isTrue);
  }

  testWidgets(
    'main tabs preserve task filters while the hidden task tab makes no server requests',
    (tester) async {
      final fixture = (await tester.runAsync(_ShellFixture.create))!;
      try {
        await tester.pumpWidget(
          app(fixture, AppPreferences(store: MemoryBoardPreferences())),
        );
        await until(tester, () => !fixture.model.session.loading('boards'));
        await tester.tap(find.byType(NavigationDestination).at(1));
        await settleBoard(tester);
        await tester.enterText(
          find.byKey(const Key('card-search-query')),
          'keep',
        );
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byKey(const ValueKey('search-filter-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Search on server'));
        await tester.tap(find.widgetWithText(FilledButton, 'Apply filters'));
        await until(tester, () => fixture.searchRequests == 1);
        await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
        await until(tester, () => fixture.searchRequests == 2);
        final reads = fixture.searchRequests;
        await tester.tap(find.byType(NavigationDestination).at(2));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(minutes: 2));
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        await settleBoard(tester);
        expect(fixture.searchRequests, reads);
        expect(find.byKey(const Key('card-search-query')), findsNothing);
        await tester.tap(find.byType(NavigationDestination).at(1));
        await until(tester, () => fixture.searchRequests == reads + 1);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('card-search-query')))
              .controller!
              .text,
          'keep',
        );
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Today'))
              .selected,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.model.close());
      }
    },
  );

  testWidgets(
    'main shell scrolls its controls and offline notice at 200 percent landscape text',
    (tester) async {
      final fixture = (await tester.runAsync(_ShellFixture.create))!;
      fixture.offline = true;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 360);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      try {
        await tester.pumpWidget(
          app(
            fixture,
            AppPreferences(store: MemoryBoardPreferences()),
            scale: 2,
          ),
        );
        await until(
          tester,
          () => fixture.model.session.error('boards') != null,
        );
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Board'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Board').hitTestable(), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.model.close());
      }
    },
  );
}
