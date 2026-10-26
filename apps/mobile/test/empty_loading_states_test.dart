import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/boards.dart';

import 'board_test_support.dart' show MemoryBoardPreferences, boardTestApp;

const _noSavedContent = 'No content is saved on this device yet.';

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
  _Fixture({
    this.offline = true,
    this.cachedBoard = false,
    this.cachedColumn = false,
  });
  final database = DeckDatabase(NativeDatabase.memory());
  final bool cachedBoard;
  final bool cachedColumn;
  bool offline;
  Completer<void>? gate;
  final requests = <String>[];
  late StoredAccount account;
  late DeckSession session;
  final board = DeckBoard.fromJson({
    'id': 1,
    'title': 'Project A',
    'color': '008080',
    'archived': false,
    'deletedAt': 0,
    'permissions': {
      'PERMISSION_READ': true,
      'PERMISSION_EDIT': true,
      'PERMISSION_MANAGE': true,
    },
  });
  late final column = DeckStack.fromJson({
    'id': 2,
    'boardId': 1,
    'title': 'Saved column',
    'order': 0,
    'cards': [
      {
        'id': 8,
        'stackId': 2,
        'title': 'Saved task',
        'description': 'Saved text',
        'type': 'plain',
        'owner': 'demo',
        'order': 0,
        'archived': false,
        'deletedAt': 0,
      },
    ],
  });

  Future<void> initialize() async {
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'demo',
        appPassword: 'test-password',
      ),
    );
    if (cachedBoard) {
      await database.saveBoards(account.id, account.generation, [board], null);
    }
    if (cachedColumn) {
      await database.saveStacks(account.id, account.generation, 1, [
        column,
      ], null);
    }
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'demo',
        appPassword: 'test-password',
        transport: MockClient((request) async {
          requests.add(request.url.path);
          if (gate != null) await gate!.future;
          if (offline) throw const SocketException('offline');
          final path = request.url.path;
          if (path.endsWith('/cloud/user')) return _ocs({'id': 'demo'});
          if (path.endsWith('/capabilities')) {
            return _ocs({
              'capabilities': {
                'deck': {
                  'version': '1.19.1',
                  'apiVersions': ['1.1'],
                  'canCreateBoards': true,
                },
              },
            });
          }
          if (path.endsWith('/boards')) return _reply([]);
          if (path.endsWith('/boards/1')) return _reply(board.raw);
          if (path.endsWith('/stacks') || path.endsWith('/stacks/archived')) {
            return _reply([]);
          }
          throw StateError('unexpected_request');
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  }

  http.Response _reply(Object value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );
  http.Response _ocs(Object value) => _reply({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': value,
    },
  });
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 200; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (ready()) return;
  }
  expect(ready(), isTrue);
}

Future<void> _using(
  WidgetTester tester,
  _Fixture fixture,
  Future<void> Function() body,
) async {
  const channel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (_) async => null);
  tester.view.physicalSize = const Size(1100, 1800);
  tester.view.devicePixelRatio = 1;
  await tester.runAsync(fixture.initialize);
  try {
    await body();
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.session.dispose();
    if (fixture.gate?.isCompleted == false) fixture.gate!.complete();
    await tester.pumpAndSettle();
    await tester.runAsync(fixture.database.close);
    messenger.setMockMethodCallHandler(channel, null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

Future<void> _mount(
  WidgetTester tester,
  _Fixture fixture, {
  required bool detail,
}) async {
  await tester.pumpWidget(
    boardTestApp(
      detail
          ? BoardScreen(session: fixture.session, board: fixture.board)
          : BoardsScreen(session: fixture.session),
      preferences: AppPreferences(store: MemoryBoardPreferences()),
    ),
  );
}

void main() {
  for (final detail in [false, true]) {
    final scope = detail ? 'board:1' : 'boards';
    testWidgets(
      'offline empty ${detail ? 'columns' : 'boards'} do not claim the server is empty',
      (tester) async {
        final fixture = _Fixture(cachedBoard: detail);
        await _using(tester, fixture, () async {
          await _mount(tester, fixture, detail: detail);
          await _until(
            tester,
            () =>
                fixture.session.error(scope) != null &&
                !fixture.session.loading(scope),
          );
          expect(find.text(_noSavedContent), findsOneWidget);
          expect(find.text('No boards yet'), findsNothing);
          expect(
            find.text('This account has no active boards available.'),
            findsNothing,
          );
          expect(find.text('This board has no columns.'), findsNothing);
          expect(find.byTooltip('Retry'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'empty ${detail ? 'columns' : 'boards'} stay loading until the first read completes',
      (tester) async {
        final fixture = _Fixture(offline: false, cachedBoard: detail)
          ..gate = Completer<void>();
        await _using(tester, fixture, () async {
          await _mount(tester, fixture, detail: detail);
          await _until(
            tester,
            () => fixture.requests.isNotEmpty && fixture.session.loading(scope),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('No boards yet'), findsNothing);
          expect(find.text('This board has no columns.'), findsNothing);
          expect(find.text(_noSavedContent), findsNothing);
          fixture.gate!.complete();
          await _until(tester, () => !fixture.session.loading(scope));
          expect(fixture.session.error(scope), isNull);
          expect(
            find.text(detail ? 'This board has no columns.' : 'No boards yet'),
            findsOneWidget,
          );
          expect(find.text(_noSavedContent), findsNothing);
        });
      },
    );

    testWidgets(
      'offline cached ${detail ? 'columns' : 'boards'} remain visible',
      (tester) async {
        final fixture = _Fixture(cachedBoard: true, cachedColumn: detail);
        await _using(tester, fixture, () async {
          await _mount(tester, fixture, detail: detail);
          await _until(
            tester,
            () =>
                fixture.session.error(scope) != null &&
                !fixture.session.loading(scope),
          );
          expect(
            find.text(detail ? 'Saved task' : 'Project A'),
            findsOneWidget,
          );
          expect(find.text(_noSavedContent), findsNothing);
          expect(find.text('No boards yet'), findsNothing);
          expect(find.text('This board has no columns.'), findsNothing);
          final cached = await tester.runAsync(
            () => fixture.database.boardView(fixture.account.id),
          );
          expect(cached!.single.id, 1);
        });
      },
    );
  }

  testWidgets(
    'a filter hiding cached boards is distinct from an empty account',
    (tester) async {
      final fixture = _Fixture(cachedBoard: true);
      await _using(tester, fixture, () async {
        await _mount(tester, fixture, detail: false);
        await _until(
          tester,
          () =>
              fixture.session.error('boards') != null &&
              !fixture.session.loading('boards'),
        );
        await tester.enterText(find.byType(TextField), 'unmatched');
        await tester.pump();
        expect(find.text('No boards match this filter.'), findsOneWidget);
        expect(find.text('No boards yet'), findsNothing);
        expect(find.text(_noSavedContent), findsNothing);
        expect(
          find.text('This account has no active boards available.'),
          findsNothing,
        );
        expect(find.text('Project A'), findsNothing);
        final cached = await tester.runAsync(
          () => fixture.database.boardView(fixture.account.id),
        );
        expect(cached!.single.title, 'Project A');
      });
    },
  );
}
