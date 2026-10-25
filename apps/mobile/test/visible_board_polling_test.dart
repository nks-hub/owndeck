import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/board_view.dart';
import 'package:nextclouddeck/features/card_detail.dart';

import 'board_test_support.dart';

class _PollingFixture {
  _PollingFixture(this.data);
  final BoardFixture data;
  late final DeckSession session;
  final requests = <String>[];
  String title = 'Server card';

  void connect() {
    session = DeckSession(
      data.db,
      data.account,
      DeckClient(
        base: ServerBase.parse(data.account.server),
        loginName: data.account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          final path = request.url.path;
          requests.add(path);
          final boardId = path.contains('/boards/2') ? 2 : 1;
          Object value;
          if (path.endsWith('/boards/$boardId')) {
            value = boardData(boardId).raw;
          } else if (path.endsWith('/boards/$boardId/stacks')) {
            value = [
              {
                ...data.stacks.first.raw,
                'id': boardId * 10,
                'boardId': boardId,
                'cards': [
                  {...cardData(boardId).raw, 'title': title},
                ],
              },
            ];
          } else if (path.endsWith('/boards/$boardId/stacks/archived')) {
            value = [];
          } else {
            return http.Response('', 404);
          }
          return http.Response(
            jsonEncode(value),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      pollInterval: const Duration(seconds: 10),
    );
  }

  DeckBoard boardData(int id) =>
      DeckBoard.fromJson({...data.board.raw, 'id': id, 'title': 'Board $id'});

  DeckCard cardData(int boardId) => DeckCard.fromJson({
    ...data.stacks.first.cards.first.raw,
    'stackId': boardId * 10,
  });

  Widget card({int boardId = 1}) => CardScreen(
    session: session,
    board: boardData(boardId),
    card: cardData(boardId),
  );

  Widget board() => BoardScreen(session: session, board: data.board);
}

Future<void> _using(
  WidgetTester tester,
  Future<void> Function(_PollingFixture fixture) run,
) async {
  final data = (await tester.runAsync(() => BoardFixture.create(counts: [1])))!;
  final fixture = _PollingFixture(data)..connect();
  try {
    await run(fixture);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await settleBoard(tester);
    fixture.session.dispose();
    await tester.runAsync(data.close);
  }
}

Future<void> _tick(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 11));
  await settleBoard(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
  });

  testWidgets('direct card detail reads server updates on the polling clock', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.pumpWidget(boardTestApp(fixture.card()));
      await settleBoard(tester);
      fixture.title = 'Changed remotely';
      fixture.requests.clear();
      await _tick(tester);
      expect(find.text('Changed remotely'), findsOneWidget);
      expect(
        fixture.requests.where((p) => p.endsWith('/stacks')),
        hasLength(1),
      );
      final stored = await boardModel(
        tester,
        fixture.data.db.watchCard(fixture.data.account.id, 1, 100).first,
      );
      expect(stored!.title, 'Changed remotely');
    });
  });

  testWidgets('covered board stops polling and resumes after returning', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.pumpWidget(
        boardTestApp(
          fixture.board(),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
        ),
      );
      await settleBoard(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Child screen')),
        ),
      );
      await settleBoard(tester);
      fixture.requests.clear();
      fixture.session.didChangeAppLifecycleState(AppLifecycleState.paused);
      fixture.session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await _tick(tester);
      expect(fixture.requests, isEmpty);
      fixture.title = 'Changed while hidden';
      navigator.pop();
      await settleBoard(tester);
      expect(find.text('Changed while hidden'), findsOneWidget);
      expect(
        fixture.requests.where((p) => p.endsWith('/stacks')),
        hasLength(1),
      );
    });
  });

  testWidgets('card and parent keep separate board ownership when popped', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.pumpWidget(
        boardTestApp(
          fixture.board(),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
        ),
      );
      await settleBoard(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(builder: (_) => fixture.card()));
      await settleBoard(tester);
      fixture.requests.clear();
      await _tick(tester);
      expect(
        fixture.requests.where((p) => p.endsWith('/stacks')),
        hasLength(1),
      );
      navigator.pop();
      await settleBoard(tester);
      fixture.requests.clear();
      fixture.title = 'Changed after closing detail';
      await _tick(tester);
      expect(find.text('Changed after closing detail'), findsOneWidget);
      expect(
        fixture.requests.where((p) => p.endsWith('/stacks')),
        hasLength(1),
      );
    });
  });

  testWidgets('background and disposed detail never initiate polling', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      fixture.session.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pumpWidget(boardTestApp(fixture.card()));
      await settleBoard(tester);
      await _tick(tester);
      expect(fixture.requests, isEmpty);
      fixture.session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settleBoard(tester);
      expect(find.text('Server card'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await settleBoard(tester);
      fixture.requests.clear();
      await _tick(tester);
      expect(fixture.requests, isEmpty);
    });
  });

  testWidgets(
    'removing one owner preserves the other and release never notifies',
    (tester) async {
      await _using(tester, (fixture) async {
        final first = Object();
        final second = Object();
        fixture.session.setVisibleBoard(first, 1);
        fixture.session.setVisibleBoard(second, 1);
        await settleBoard(tester);
        expect(
          fixture.requests.where((p) => p.endsWith('/stacks')),
          hasLength(1),
        );
        var callbacks = 0;
        fixture.session.addListener(() => callbacks++);
        fixture.requests.clear();
        fixture.session.setVisibleBoard(first, null);
        expect(callbacks, 0);
        await _tick(tester);
        expect(
          fixture.requests.where((p) => p.endsWith('/stacks')),
          hasLength(1),
        );
        fixture.requests.clear();
        callbacks = 0;
        fixture.session.setVisibleBoard(second, null);
        expect(callbacks, 0);
        await _tick(tester);
        expect(fixture.requests, isEmpty);
        expect(callbacks, 0);
        fixture.session.setVisibleBoard(first, 1);
        fixture.session.setVisibleBoard(first, null);
        await settleBoard(tester);
        expect(fixture.requests, isEmpty);
        expect(callbacks, 0);
      });
    },
  );

  testWidgets(
    'changing account releases the old session and rebinds card streams',
    (tester) async {
      await _using(tester, (old) async {
        await _using(tester, (next) async {
          await tester.pumpWidget(boardTestApp(old.card()));
          await settleBoard(tester);
          expect(find.text('Server card'), findsOneWidget);
          next.title = 'Card in another account';
          await tester.pumpWidget(boardTestApp(next.card()));
          await settleBoard(tester);
          expect(find.text('Card in another account'), findsOneWidget);
          expect(find.text('Server card'), findsNothing);
          old.requests.clear();
          next.requests.clear();
          await _tick(tester);
          expect(old.requests, isEmpty);
          expect(
            next.requests.where((p) => p.endsWith('/stacks')),
            hasLength(1),
          );
        });
      });
    },
  );

  testWidgets('changing the detail board moves polling and its cached stream', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.pumpWidget(boardTestApp(fixture.card()));
      await settleBoard(tester);
      await boardModel(
        tester,
        fixture.data.db.saveBoards(
          fixture.data.account.id,
          fixture.data.account.generation,
          [fixture.boardData(1), fixture.boardData(2)],
          null,
        ),
      );
      fixture.title = 'Moved card';
      await tester.pumpWidget(boardTestApp(fixture.card(boardId: 2)));
      await settleBoard(tester);
      expect(find.text('Board 2'), findsOneWidget);
      expect(find.text('Moved card'), findsOneWidget);
      fixture.requests.clear();
      fixture.title = 'Updated after move';
      await _tick(tester);
      expect(find.text('Updated after move'), findsOneWidget);
      expect(fixture.requests.any((p) => p.contains('/boards/1')), isFalse);
      expect(
        fixture.requests.where((p) => p.endsWith('/boards/2/stacks')),
        hasLength(1),
      );
    });
  });
}
