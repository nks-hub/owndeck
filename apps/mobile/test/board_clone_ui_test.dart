import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/features/board_clone_dialog.dart';
import 'package:nextclouddeck/features/server_tools.dart';
import 'package:nextclouddeck/features/settings.dart';
import 'package:nextclouddeck/features/structure_editor.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_support.dart';

class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String reference) async => values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      values[reference] = password;
  @override
  Future<void> delete(String reference) async => values.remove(reference);
  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

class _Fixture {
  final database = DeckDatabase(NativeDatabase.memory());
  final requests = <http.Request>[];
  late final DeckSession session;
  late final DeckBoard board;
  Future<http.Response> Function(http.Request)? intercept;

  Future<void> initialize({
    String version = '1.19.1',
    bool create = true,
    bool read = true,
    bool edit = false,
    String host = 'cloud.example.com',
  }) async {
    final account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://$host/cloud'),
        loginName: 'demo',
        appPassword: 'fixture-password',
      ),
      userId: 'demo',
    );
    final capabilities = DeckCapabilities(
      version: version,
      apiVersion: '1.1',
      canCreateBoards: create,
    );
    await database.saveCapabilities(account, capabilities);
    board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Source board',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': read, 'PERMISSION_EDIT': edit},
    });
    await database.saveBoards(account.id, account.generation, [board], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [],
      }),
    ], null);
    session = DeckSession(
      database,
      (await database.account(account.id))!,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'fixture-password',
        transport: MockClient((request) async {
          expect(request.url.host, host);
          requests.add(request);
          if (intercept != null) return intercept!(request);
          expect(request.method, 'GET');
          final path = request.url.path;
          if (path.endsWith('/cloud/user')) {
            return _json({'id': 'demo'}, ocs: true);
          }
          if (path.endsWith('/cloud/capabilities')) {
            return _json({
              'capabilities': {
                'deck': {
                  'version': version,
                  'apiVersions': ['1.1'],
                  'canCreateBoards': create,
                },
              },
            }, ocs: true);
          }
          if (path.endsWith('/boards')) return _json([board.raw]);
          if (path.endsWith('/boards/1')) return _json(board.raw);
          if (path.endsWith('/stacks') || path.endsWith('/stacks/archived')) {
            return _json([]);
          }
          throw StateError('unexpected_request');
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  }

  Future<void> mount(WidgetTester tester, {Widget? child}) => tester.pumpWidget(
    localizedTestApp(
      home: Scaffold(
        body: child ?? BoardActions(session: session, board: board),
      ),
    ),
  );

  Future<void> dialog(
    WidgetTester tester, {
    Future<bool> Function(Uri)? browser,
  }) async {
    await mount(tester);
    final context = tester.element(find.byType(BoardActions));
    // The dialog future completes only after dismissal.
    showBoardClone(context, session, board, openBrowser: browser);
    await tester.pumpAndSettle();
  }
}

http.Response _json(Object value, {bool ocs = false}) => http.Response(
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

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 200; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (ready()) return;
  }
  expect(ready(), isTrue, reason: 'The asynchronous operation did not settle.');
}

Future<void> _using(
  WidgetTester tester,
  Future<void> Function(_Fixture fixture) body, {
  String version = '1.19.1',
  bool create = true,
  bool read = true,
  bool edit = false,
}) async {
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(connectivity, (_) async => null);
  final fixture = (await tester.runAsync(() async {
    final fixture = _Fixture();
    await fixture.initialize(
      version: version,
      create: create,
      read: read,
      edit: edit,
    );
    return fixture;
  }))!;
  addTearDown(() async {
    await fixture.database.close();
    messenger.setMockMethodCallHandler(connectivity, null);
  });
  try {
    await body(fixture);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.session.dispose();
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('read-only source offers copying without manage actions', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await fixture.mount(tester);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Copy board'), findsOneWidget);
      expect(find.text('Edit board'), findsNothing);
      await tester.tap(find.text('Copy board'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNWidgets(6));
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(fixture.requests, isEmpty);
    });
  });

  for (final gate in ['create', 'read']) {
    testWidgets('copy action is absent without $gate permission', (
      tester,
    ) async {
      await _using(
        tester,
        (fixture) async {
          await fixture.mount(tester);
          expect(find.byType(PopupMenuButton<String>), findsNothing);
        },
        create: gate != 'create',
        read: gate != 'read',
      );
    });
  }

  testWidgets('1.18 uses a credential-free web link without a clone POST', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      final opened = <Uri>[];
      await fixture.dialog(
        tester,
        browser: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      await tester.tap(find.text('Open in Nextcloud'));
      await tester.pumpAndSettle();
      expect(
        opened.single.toString(),
        'https://cloud.example.com/cloud/index.php/apps/deck/board/1',
      );
      expect(opened.single.userInfo, isEmpty);
      expect(opened.single.query, isEmpty);
      expect(fixture.requests, isEmpty);
      expect(
        await tester.runAsync(
          () => fixture.database.writesFor(fixture.session.account.id),
        ),
        isEmpty,
      );
    }, version: '1.18.5');
  });

  testWidgets('six options are saved durably before the first API request', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      List<PendingWrite>? atFirstRequest;
      fixture.intercept = (_) async {
        atFirstRequest = await fixture.database.writesFor(
          fixture.session.account.id,
        );
        return http.Response('', 503);
      };
      await fixture.dialog(tester);
      for (final label in [
        'Keep card assignments',
        'Keep labels on cards',
        'Move all cards to the first column',
        'Restore archived cards',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pump();
      }
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await _until(
        tester,
        () => atFirstRequest != null && !fixture.session.loading('boards'),
      );
      expect(atFirstRequest, hasLength(1));
      final write = atFirstRequest!.single;
      expect(write.kind, 'boardClone');
      expect(write.state, 'queued');
      expect(jsonDecode(write.proposal), {
        'title': 'Source board',
        'withCards': true,
        'withAssignments': true,
        'withLabels': false,
        'withDueDate': true,
        'moveCardsToLeftStack': true,
        'restoreArchivedCards': true,
      });
      expect(fixture.requests.where((r) => r.method != 'GET'), isEmpty);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets('pending source work stays intact when copying is refused', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.runAsync(
        () => fixture.database.saveCardDraft(fixture.session.account, 1, 2, {
          'title': 'Unsent work',
        }),
      );
      final before = (await tester.runAsync(
        () => fixture.database.writesFor(fixture.session.account.id),
      ))!.single;
      await fixture.dialog(tester);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await _until(
        tester,
        () => find
            .textContaining('Open Pending changes first.')
            .evaluate()
            .isNotEmpty,
      );
      final after = (await tester.runAsync(
        () => fixture.database.writesFor(fixture.session.account.id),
      ))!.single;
      expect(after.id, before.id);
      expect(after.proposal, before.proposal);
      expect(after.state, before.state);
      expect(fixture.requests, isEmpty);
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }, edit: true);
  });

  testWidgets(
    'landscape at 200 percent scrolls every option and cancels cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _using(tester, (fixture) async {
        await fixture.dialog(tester);
        for (final label in [
          'Include cards',
          'Keep card assignments',
          'Keep labels on cards',
          'Keep due dates',
          'Move all cards to the first column',
          'Restore archived cards',
        ]) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          expect(find.text(label).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.ensureVisible(find.text('Cancel'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);
        expect(tester.takeException(), isNull);
        expect(fixture.requests, isEmpty);
      });
    },
  );

  testWidgets(
    'web return refreshes board list once then resumes the open board normally',
    (tester) async {
      await _using(tester, (fixture) async {
        final session = fixture.session;
        session.openBoard(1);
        await _until(tester, () => !session.loading('board:1'));
        fixture.requests.clear();
        await openDeckWeb(
          session,
          board: fixture.board,
          openBrowser: (_) async => true,
        );
        session.didChangeAppLifecycleState(AppLifecycleState.paused);
        session.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await _until(
          tester,
          () => !session.loading('boards') && !session.loading('board:1'),
        );
        expect(
          fixture.requests.where((r) => r.url.path.endsWith('/boards')),
          hasLength(1),
        );
        expect(
          fixture.requests.where(
            (r) => r.url.path.endsWith('/boards/1/stacks'),
          ),
          hasLength(1),
        );
        fixture.requests.clear();
        session.didChangeAppLifecycleState(AppLifecycleState.paused);
        session.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await _until(tester, () => !session.loading('board:1'));
        expect(
          fixture.requests.where((r) => r.url.path.endsWith('/boards')),
          isEmpty,
        );
        expect(
          fixture.requests.where(
            (r) => r.url.path.endsWith('/boards/1/stacks'),
          ),
          hasLength(1),
        );
      });
    },
  );

  testWidgets(
    'import dialog keeps its original account when Settings changes session',
    (tester) async {
      await _using(tester, (fixture) async {
        final other = (await tester.runAsync(() async {
          final other = _Fixture();
          await other.initialize(host: 'other.example.com');
          return other;
        }))!;
        addTearDown(other.database.close);
        const browser = MethodChannel('plugins.flutter.io/url_launcher');
        final launches = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(browser, (call) async {
          launches.add(call);
          return true;
        });
        final active = ValueNotifier(fixture.session);
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                packageInfoProvider.overrideWith(
                  (ref) async => PackageInfo(
                    appName: 'OwnDeck',
                    packageName: 'example',
                    version: '1',
                    buildNumber: '1',
                  ),
                ),
              ],
              child: localizedTestApp(
                home: Scaffold(
                  body: ValueListenableBuilder(
                    valueListenable: active,
                    builder: (_, session, _) => SettingsView(session: session),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Import in Nextcloud'));
          await tester.tap(find.text('Import in Nextcloud'));
          await tester.pumpAndSettle();
          active.value = other.session;
          await tester.pump();
          await tester.tap(find.text('Open in Nextcloud'));
          await tester.pumpAndSettle();
          expect(launches, hasLength(1));
          final uri = Uri.parse(
            (launches.single.arguments as Map)['url'] as String,
          );
          expect(
            uri.toString(),
            'https://cloud.example.com/cloud/index.php/apps/deck',
          );
          expect(uri.userInfo, isEmpty);
          expect(uri.query, isEmpty);
          expect(fixture.requests, isEmpty);
          expect(other.requests, isEmpty);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          other.session.dispose();
          await tester.pumpAndSettle();
          active.dispose();
          messenger.setMockMethodCallHandler(browser, null);
        }
      });
    },
  );
}
