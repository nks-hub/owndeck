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
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/card_column.dart';
import 'package:nextclouddeck/features/search.dart';
import 'package:nextclouddeck/features/sharing.dart';
import 'package:nextclouddeck/features/structure_editor.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

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
  _Fixture({this.offline = true, this.cachedBoard = false});
  final bool cachedBoard;
  bool offline;
  final database = DeckDatabase(NativeDatabase.memory());
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
      'PERMISSION_SHARE': true,
    },
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
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'demo',
        appPassword: 'test-password',
        transport: MockClient((request) async {
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

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

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
    await tester.pumpAndSettle();
    await tester.runAsync(fixture.database.close);
    messenger.setMockMethodCallHandler(channel, null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

const _noSaved = 'No content is saved on this device yet.';

void main() {
  testWidgets(
    'search with an unsynced empty cache offers a retry, not "no match"',
    (tester) async {
      final fixture = _Fixture();
      await _using(tester, fixture, () async {
        await tester.runAsync(fixture.session.refreshBoards);
        expect(fixture.session.error('boards'), isNotNull);
        await tester.pumpWidget(
          _app(CardSearchScreen(session: fixture.session)),
        );
        await _until(tester, () => find.text(_noSaved).evaluate().isNotEmpty);
        expect(
          find.text('No saved cards match the search and filters.'),
          findsNothing,
        );
        fixture.offline = false;
        await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
        await _until(
          tester,
          () => find
              .text('There are no cards on your boards yet.')
              .evaluate()
              .isNotEmpty,
        );
        expect(find.text(_noSaved), findsNothing);
        expect(find.widgetWithText(OutlinedButton, 'Add card'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'confirmed empty search and an active filter name different actions',
    (tester) async {
      final fixture = _Fixture(offline: false);
      await _using(tester, fixture, () async {
        await tester.runAsync(fixture.session.refreshBoards);
        await tester.pumpWidget(
          _app(CardSearchScreen(session: fixture.session)),
        );
        await _until(
          tester,
          () => find
              .text('There are no cards on your boards yet.')
              .evaluate()
              .isNotEmpty,
        );
        expect(find.widgetWithText(OutlinedButton, 'Add card'), findsOneWidget);
        expect(find.text('Clear filters'), findsNothing);
        await tester.enterText(
          find.byKey(const Key('card-search-query')),
          'unmatched',
        );
        await tester.pump(const Duration(milliseconds: 250));
        await _until(
          tester,
          () => find
              .text('No saved cards match the search and filters.')
              .evaluate()
              .isNotEmpty,
        );
        expect(
          find.text('There are no cards on your boards yet.'),
          findsNothing,
        );
        expect(find.widgetWithText(OutlinedButton, 'Add card'), findsNothing);
        expect(
          find.widgetWithText(OutlinedButton, 'Clear filters'),
          findsOneWidget,
        );
      });
    },
  );

  testWidgets('my tasks without a verified identity can retry the sync', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _using(tester, fixture, () async {
      await tester.pumpWidget(
        _app(CardSearchScreen(session: fixture.session, mineOnly: true)),
      );
      await _until(
        tester,
        () => find
            .textContaining('My tasks will be available after sync')
            .evaluate()
            .isNotEmpty,
      );
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
    });
  });

  testWidgets('labels and sharing without access offer one way back', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _using(tester, fixture, () async {
      for (final screen in <Widget>[
        BoardLabelsScreen(session: fixture.session, boardId: 1),
        SharingScreen(session: fixture.session, boardId: 1),
      ]) {
        await tester.pumpWidget(
          _app(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => screen)),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await _until(
          tester,
          () => find
              .text('You no longer have access to this content.')
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(find.widgetWithText(OutlinedButton, 'Close'));
        await tester.pumpAndSettle();
        expect(find.text('open'), findsOneWidget);
      }
    });
  });

  testWidgets('labels and sharing do not claim emptiness after a failed read', (
    tester,
  ) async {
    final fixture = _Fixture(cachedBoard: true);
    await _using(tester, fixture, () async {
      for (final entry in <(Widget, String)>[
        (
          BoardLabelsScreen(session: fixture.session, boardId: 1),
          'This board has no labels.',
        ),
        (
          SharingScreen(session: fixture.session, boardId: 1),
          'This board is not shared yet.',
        ),
      ]) {
        await tester.pumpWidget(_app(entry.$1));
        await _until(
          tester,
          () =>
              fixture.session.error('board:1') != null &&
              find.text(_noSaved).evaluate().isNotEmpty,
        );
        expect(find.text(entry.$2), findsNothing);
      }
    });
  });

  testWidgets('an empty archive view does not call the column empty', (
    tester,
  ) async {
    final fixture = _Fixture(cachedBoard: true);
    await _using(tester, fixture, () async {
      final stack = DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Saved column',
        'order': 0,
        'cards': <Object?>[],
      });
      for (final archived in [false, true]) {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: BoardColumnFooter(
                session: fixture.session,
                board: fixture.board,
                stack: stack,
                empty: true,
                editable: false,
                archived: archived,
              ),
            ),
          ),
        );
        expect(
          find.text(
            archived
                ? 'There are no archived cards in this column.'
                : 'There are no cards in this column.',
          ),
          findsOneWidget,
        );
      }
    });
  });
}
