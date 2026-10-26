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
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/board_view.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

import 'board_test_support.dart' show MemoryBoardPreferences;

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

http.Response _json(Object data, int status) => http.Response(
  jsonEncode({
    'ocs': {
      'meta': {'status': status == 200 ? 'ok' : 'failure', 'statuscode': status},
      'data': data,
    },
  }),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase db;
  late DeckSession session;
  late DeckBoard board;
  late DeckCard card;
  late http.Response Function() projects;
  final paths = <String>[];

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    db = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(db, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    DeckBoard makeBoard(int id, String title) => DeckBoard.fromJson({
      'id': id,
      'title': title,
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true},
    });
    board = makeBoard(1, 'Project');
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
    await db.saveBoards(account.id, account.generation, [
      board,
      makeBoard(5, 'Linked board'),
    ], null);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'isDoneColumn': false,
        'cards': [card.raw],
      }),
    ], null);
    paths.clear();
    projects = () => _json([], 200);
    session = DeckSession(
      db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.contains('/collaboration/resources/')) {
            return projects();
          }
          return http.Response('', 503);
        }),
      ),
    )..capabilities = const DeckCapabilities(
        version: '1.14.0',
        apiVersion: '1.1',
        canCreateBoards: true,
      );
  });
  tearDown(() async {
    session.dispose();
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWith(
            (ref) => AppPreferences(store: MemoryBoardPreferences()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CardScreen(session: session, board: board, card: card),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('lists linked files, rooms, cards and boards under Projects', (
    tester,
  ) async {
    projects = () => _json([
      {
        'id': 4,
        'name': 'Launch',
        'resources': [
          {'type': 'deck-card', 'id': '8', 'name': 'Project: Task'},
          {
            'type': 'file',
            'id': 55,
            'name': 'plan.pdf',
            'link': 'https://cloud.example.com/f/55',
          },
          {'type': 'room', 'id': 'abc', 'name': 'Team chat', 'link': '/call/abc'},
          {'type': 'deck', 'id': '5', 'name': 'Linked board', 'link': '/b/5'},
        ],
      },
    ], 200);
    await open(tester);
    await tester.scrollUntilVisible(
      find.text('plan.pdf'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(paths, contains('/ocs/v2.php/collaboration/resources/deck-card/8'));
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Launch'), findsOneWidget);
    expect(find.text('Team chat'), findsOneWidget);
    expect(find.text('Project: Task'), findsNothing);

    await tester.tap(find.text('Linked board'));
    await tester.pumpAndSettle();
    expect(find.byType(BoardScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  });

  testWidgets('the section is hidden when empty or when the server says 404', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Projects'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());

    projects = () => _json(<Object>[], 404);
    await open(tester);
    expect(find.text('Projects'), findsNothing);
    expect(paths.where((p) => p.contains('collaboration')), hasLength(2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  });
}
