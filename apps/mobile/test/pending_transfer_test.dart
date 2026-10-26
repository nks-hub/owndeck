import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/pending.dart';

import 'board_test_support.dart';

const _moved = 'The card has moved. Its position is still being confirmed.';
const _retry =
    'Check the card on the server before sending the remaining change again.';

Future<void> _using(
  WidgetTester tester,
  String state,
  Future<void> Function(BoardFixture fixture, PendingWrite write) run, {
  bool accepted = true,
  bool awaitingTransferReadback = false,
  Future<http.Response> Function(http.Request)? handle,
}) async {
  var fixture = (await tester.runAsync(
    () => BoardFixture.create(counts: [1]),
  ))!;
  if (handle != null) {
    fixture.session.dispose();
    fixture = BoardFixture(
      fixture.db,
      fixture.account,
      DeckSession(
        fixture.db,
        fixture.account,
        DeckClient(
          base: ServerBase.parse(fixture.account.server),
          loginName: fixture.account.loginName,
          appPassword: 'test-password',
          transport: MockClient(handle),
        ),
        pollInterval: const Duration(hours: 1),
      ),
      fixture.board,
      fixture.stacks,
    );
  }
  final write = (await tester.runAsync(() async {
    if (handle == null) {
      await fixture.db.deferSync(
        fixture.account,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
    }
    final destination = DeckBoard.fromJson({
      ...fixture.board.raw,
      'id': 2,
      'title': 'Destination board',
    });
    final card = fixture.stacks.first.cards.first;
    final transferred = DeckCard.fromJson({...card.raw, 'stackId': 20});
    await fixture.db.saveBoards(
      fixture.account.id,
      fixture.account.generation,
      [fixture.board, destination],
      null,
    );
    await fixture.db.saveStacks(
      fixture.account.id,
      fixture.account.generation,
      2,
      [
        DeckStack.fromJson({
          'id': 20,
          'boardId': 2,
          'title': 'Ready',
          'order': 0,
          'cards': [if (accepted) transferred.raw],
        }),
      ],
      null,
    );
    final receipt = {
      'phase': 'transfer',
      'sourceBoardId': 1,
      'sourceStackId': 10,
      'boardId': 2,
      'stackId': 20,
      'cardId': 100,
      'acceptedCard': transferred.raw,
      'beforeCard': card.raw,
    };
    await fixture.db
        .into(fixture.db.pendingWrites)
        .insert(
          PendingWritesCompanion.insert(
            id: 'transfer-write',
            accountId: fixture.account.id,
            kind: 'cardTransfer',
            boardId: accepted && !awaitingTransferReadback ? 2 : 1,
            stackId: accepted && !awaitingTransferReadback ? 20 : 10,
            cardId: const Value(100),
            state: Value(state),
            error: Value(state == 'blocked' ? 'permission_denied' : null),
            proposal: jsonEncode({
              'phase': accepted && !awaitingTransferReadback
                  ? 'position'
                  : 'transfer',
              'title': card.title,
              'destinationBoardId': 2,
              'destinationStackId': 20,
              'anchorCardId': null,
              'before': false,
              if (accepted && !awaitingTransferReadback)
                'transferReceipt': receipt,
            }),
            base: Value(jsonEncode(accepted ? transferred.raw : card.raw)),
            remote: Value(
              accepted
                  ? jsonEncode(
                      awaitingTransferReadback ? receipt : transferred.raw,
                    )
                  : null,
            ),
          ),
        );
    return (await fixture.db.writesFor(fixture.account.id)).single;
  }))!;
  try {
    await tester.pumpWidget(
      boardTestApp(PendingScreen(session: fixture.session)),
    );
    await settleBoard(tester);
    await run(fixture, write);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await settleBoard(tester);
    await tester.runAsync(fixture.close);
  }
}

void _noInternalData() {
  for (final value in [
    'cardTransfer',
    'transferReceipt',
    'destinationBoardId',
    'destinationStackId',
    'sourceStackId',
    'anchorCardId',
  ]) {
    expect(find.textContaining(value), findsNothing);
  }
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ),
  );
  await settleBoard(tester);
}

class _Server {
  final requests = <http.Request>[];

  Map<String, Object?> board(int id) => {
    'id': id,
    'title': id == 1 ? 'Source board' : 'Destination board',
    'color': '008080',
    'archived': false,
    'deletedAt': 0,
    'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
  };
  Map<String, Object?> card(int id, int order) => {
    'id': id,
    'stackId': 20,
    'title': 'Card $id',
    'description': '',
    'order': order,
    'type': 'plain',
    'owner': 'user',
    'archived': false,
    'deletedAt': 0,
  };
  Map<String, Object?> stack(int boardId) => {
    'id': boardId * 10,
    'boardId': boardId,
    'title': 'Ready',
    'order': 0,
    'cards': [
      if (boardId == 2) ...[card(100, 0), card(101, 1)],
    ],
  };
  http.Response response(Object value, {bool ocs = false}) => http.Response(
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
    requests.add(request);
    if (request.method != 'GET') throw const SocketException('response lost');
    final path = request.url.path;
    if (path.endsWith('/cloud/capabilities')) {
      return response({
        'capabilities': {
          'deck': {
            'version': '1.19.1',
            'apiVersions': ['1.1'],
            'canCreateBoards': true,
          },
        },
      }, ocs: true);
    }
    final boardId = path.contains('/boards/1') ? 1 : 2;
    if (path.endsWith('/boards/$boardId')) return response(board(boardId));
    if (path.endsWith('/stacks/archived')) return response([]);
    if (path.endsWith('/stacks')) return response([stack(boardId)]);
    if (path.endsWith('/stacks/20')) return response(stack(2));
    if (path.endsWith('/cards/100')) return response(card(100, 0));
    return http.Response('', 404);
  }
}

Future<void> _settleReads(WidgetTester tester, DeckSession session) async {
  for (var attempt = 0; attempt < 15; attempt++) {
    await settleBoard(tester);
    if (!session.loading('board:1') && !session.loading('board:2')) return;
  }
  fail('The transfer decision did not finish refreshing its boards.');
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

  testWidgets(
    'queued transfer shows destination names without claiming it moved',
    (tester) async {
      await _using(tester, 'queued', (fixture, write) async {
        expect(find.text('Move card'), findsOneWidget);
        expect(find.textContaining('Destination board'), findsOneWidget);
        expect(find.textContaining('Ready'), findsOneWidget);
        expect(find.text(_moved), findsNothing);
        _noInternalData();
      }, accepted: false);
    },
  );

  for (final state in ['blocked', 'uncertain', 'conflict']) {
    testWidgets(
      '$state positioning retry preserves accepted transfer and phase',
      (tester) async {
        await _using(tester, state, (fixture, write) async {
          expect(find.text('Move card'), findsOneWidget);
          expect(find.text(_moved), findsOneWidget);
          expect(find.textContaining('Ready'), findsOneWidget);
          _noInternalData();
          await tester.ensureVisible(
            find.widgetWithText(FilledButton, 'Retry'),
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
          await tester.pumpAndSettle();
          expect(find.text(_retry), findsOneWidget);
          await _confirm(tester);
          final updated = await boardModel(
            tester,
            fixture.db.writesFor(fixture.account.id),
          );
          expect(updated.single.state, 'queued');
          expect(updated.single.proposal, write.proposal);
          final proposal = jsonDecode(updated.single.proposal) as Map;
          expect(proposal['phase'], 'position');
          expect(proposal['transferReceipt'], isA<Map>());
          expect(updated.single.boardId, 2);
        });
      },
    );
  }

  testWidgets(
    'accepted transfer awaiting readback is already described as moved',
    (tester) async {
      await _using(tester, 'applied', (fixture, write) async {
        expect(find.text(_moved), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Retry'), findsNothing);
        _noInternalData();
      }, awaitingTransferReadback: true);
    },
  );

  testWidgets(
    'discarding remaining positioning keeps the card in its destination',
    (tester) async {
      await _using(tester, 'blocked', (fixture, write) async {
        await tester.ensureVisible(
          find.widgetWithText(TextButton, 'Discard local change'),
        );
        await tester.tap(
          find.widgetWithText(TextButton, 'Discard local change'),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Only this local change will be discarded. Nothing will be changed on the server.',
          ),
          findsOneWidget,
        );
        await _confirm(tester);
        final row = await boardModel(
          tester,
          (fixture.db.select(
            fixture.db.pendingWrites,
          )..where((row) => row.id.equals(write.id))).getSingle(),
        );
        expect(row.state, 'discarded');
        expect(row.proposal, write.proposal);
        final card = await boardModel(
          tester,
          fixture.db.watchCard(fixture.account.id, 2, 100).first,
        );
        expect(card!.stackId, 20);
      });
    },
  );

  testWidgets(
    'destination names survive confirmed local board and column creation',
    (tester) async {
      await _using(tester, 'queued', (fixture, transfer) async {
        final db = fixture.db;
        late int localBoard;
        late int localStack;
        await boardModel(tester, () async {
          final boardSequence = await db
              .into(db.pendingWrites)
              .insert(
                PendingWritesCompanion.insert(
                  id: 'create-board',
                  accountId: fixture.account.id,
                  kind: 'createBoard',
                  boardId: 0,
                  stackId: 0,
                  proposal: jsonEncode({
                    'title': 'Local destination',
                    'color': '008080',
                  }),
                ),
              );
          localBoard = -boardSequence;
          final stackSequence = await db
              .into(db.pendingWrites)
              .insert(
                PendingWritesCompanion.insert(
                  id: 'create-stack',
                  accountId: fixture.account.id,
                  kind: 'createStack',
                  boardId: localBoard,
                  stackId: 0,
                  proposal: jsonEncode({'title': 'Local column', 'order': 0}),
                ),
              );
          localStack = -stackSequence;
          await (db.update(
            db.pendingWrites,
          )..where((row) => row.id.equals(transfer.id))).write(
            PendingWritesCompanion(
              proposal: Value(
                jsonEncode({
                  ...jsonDecode(transfer.proposal) as Map<String, dynamic>,
                  'destinationBoardId': localBoard,
                  'destinationStackId': localStack,
                }),
              ),
            ),
          );
        }());
        await settleBoard(tester);
        expect(find.text('Board: Local destination'), findsOneWidget);
        expect(find.text('Destination column: Local column'), findsOneWidget);
        await boardModel(tester, () async {
          for (final item in [('create-board', 2), ('create-stack', 20)]) {
            await (db.update(
              db.pendingWrites,
            )..where((row) => row.id.equals(item.$1))).write(
              PendingWritesCompanion(
                state: const Value('confirmed'),
                remote: Value(jsonEncode({'id': item.$2})),
              ),
            );
          }
        }());
        await settleBoard(tester);
        expect(find.text('Board: Destination board'), findsOneWidget);
        expect(find.text('Destination column: Ready'), findsOneWidget);
        _noInternalData();
      }, accepted: false);
    },
  );

  testWidgets(
    'discard after accepted transfer reads both boards without sending other work',
    (tester) async {
      final server = _Server();
      await _using(
        tester,
        'applied',
        (fixture, write) async {
          await boardModel(
            tester,
            fixture.db
                .into(fixture.db.pendingWrites)
                .insert(
                  PendingWritesCompanion.insert(
                    id: 'unrelated-create',
                    accountId: fixture.account.id,
                    kind: 'createBoard',
                    boardId: 0,
                    stackId: 0,
                    proposal: jsonEncode({
                      'title': 'Another board',
                      'color': '008080',
                    }),
                  ),
                ),
          );
          await settleBoard(tester);
          await tester.tap(
            find.widgetWithText(TextButton, 'Discard local change').first,
          );
          await tester.pumpAndSettle();
          await _confirm(tester);
          await _settleReads(tester, fixture.session);
          expect(
            server.requests.where((request) => request.method != 'GET'),
            isEmpty,
          );
          for (final id in [1, 2]) {
            expect(
              server.requests.where(
                (r) => r.url.path.endsWith('/boards/$id/stacks'),
              ),
              hasLength(1),
            );
          }
          final source = await boardModel(
            tester,
            fixture.db.stackView(fixture.account.id, 1),
          );
          final target = await boardModel(
            tester,
            fixture.db.stackView(fixture.account.id, 2),
          );
          expect(source.single.cards, isEmpty);
          expect(target.single.cards.any((card) => card.id == 100), isTrue);
          final unrelated = await boardModel(
            tester,
            (fixture.db.select(
              fixture.db.pendingWrites,
            )..where((row) => row.id.equals('unrelated-create'))).getSingle(),
          );
          expect(unrelated.state, 'queued');
        },
        awaitingTransferReadback: true,
        handle: server.handle,
      );
    },
  );

  testWidgets(
    'position retry sends reorder once then refreshes source and destination',
    (tester) async {
      final server = _Server();
      await _using(tester, 'blocked', (fixture, write) async {
        await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
        await tester.pumpAndSettle();
        await _confirm(tester);
        await _settleReads(tester, fixture.session);
        final mutations = server.requests
            .where((request) => request.method != 'GET')
            .toList();
        expect(mutations, hasLength(1));
        expect(mutations.single.url.path, endsWith('/cards/100/reorder'));
        expect(
          server.requests.where((r) => r.url.path.endsWith('/boards/1/stacks')),
          hasLength(1),
        );
        expect(
          server.requests.any((r) => r.url.path.endsWith('/boards/2/stacks')),
          isTrue,
        );
        final row = await boardModel(
          tester,
          (fixture.db.select(
            fixture.db.pendingWrites,
          )..where((row) => row.id.equals(write.id))).getSingle(),
        );
        expect(row.state, 'uncertain');
        expect(jsonDecode(row.proposal)['phase'], 'position');
      }, handle: server.handle);
    },
  );
}
