import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

http.Response reply(Object? body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

DeckStack column(int id, int boardId, List<DeckCard> cards) =>
    DeckStack.fromJson({
      'id': id,
      'boardId': boardId,
      'title': 'Column',
      'order': 0,
      'cards': cards.map((card) => card.raw).toList(),
    });

final class CardServer {
  var accepted = false;
  var readbackStatus = 503;
  var stackId = 3;
  var boardId = 1;
  var archived = false;
  var readable = true;
  var boardStatus = 200;
  int? wrongCardId;
  int? wrongStackId;
  int? wrongBoardId;
  List<int> links = [];
  final mutations = <String>[];
  Future<void> Function()? onContextRead;
  Future<void> Function()? onMutation;

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.pathSegments;
    if (request.method != 'GET') {
      mutations.add(request.url.path);
      accepted = true;
      await onMutation?.call();
      if (path.last == 'archive') archived = true;
      if (path.last == 'clone') {
        return reply({...cardJson(id: 20), 'stackId': 4});
      }
      if (request.url.path.contains('/ocs/') && path.last == 'reorder') {
        return reply({
          'ocs': {
            'meta': {'status': 'ok', 'statuscode': 200},
            'data': [],
          },
        });
      }
      return reply([]);
    }
    if (path[path.length - 2] == 'cards') {
      final id = int.parse(path.last);
      if (id == 9) return reply(cardJson(id: 9));
      if (accepted && readbackStatus != 200) {
        return http.Response('', readbackStatus);
      }
      return reply({
        ...cardJson(id: wrongCardId ?? id),
        'stackId': accepted ? stackId : 2,
        'archived': archived,
        'dependentCards': links,
      });
    }
    if (path.last == 'stacks' || path.last == 'archived') {
      final parentIndex = path.lastIndexOf('boards');
      final requested = int.parse(path[parentIndex + 1]);
      final wantArchived = path.last == 'archived';
      final scopes = <int, int>{
        2: 1,
        3: 1,
        4: 3,
        if (accepted) stackId: boardId,
      };
      final currentStack = accepted ? stackId : 2;
      return reply([
        for (final entry in scopes.entries)
          if (entry.value == requested &&
              (!wantArchived || archived && entry.key == currentStack))
            column(entry.key, entry.value, [
              if (!wantArchived && entry.key == 2)
                DeckCard.fromJson(cardJson(id: 9)),
              if (entry.key == currentStack && archived == wantArchived)
                DeckCard.fromJson({
                  ...cardJson(),
                  'stackId': currentStack,
                  'archived': archived,
                  'dependentCards': links,
                }),
            ]).raw,
      ]);
    }
    if (path[path.length - 2] == 'stacks') {
      final id = int.parse(path.last);
      return reply(
        column(
          wrongStackId ?? id,
          accepted
              ? boardId
              : id == 4
              ? 3
              : 1,
          [],
        ).raw,
      );
    }
    if (path[path.length - 2] == 'boards') {
      final id = int.parse(path.last);
      if (accepted && readbackStatus == 200) {
        await onContextRead?.call();
        if (boardStatus != 200) return http.Response('', boardStatus);
      }
      return reply({
        ...board(wrongBoardId ?? id, 'Board', edit: true).raw,
        if (!readable)
          'permissions': {'PERMISSION_READ': false, 'PERMISSION_EDIT': false},
      });
    }
    throw StateError(
      'Unexpected request: ${request.method} ${request.url.path}',
    );
  }
}

void main() {
  late DeckDatabase database;
  late StoredAccount account;
  late DeckCard card;
  late CardServer server;
  late DeckSync sync;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    card = DeckCard.fromJson({...cardJson(), 'dependentCards': []});
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
      board(3, 'Destination', edit: true),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      column(2, 1, [card, DeckCard.fromJson(cardJson(id: 9))]),
      column(3, 1, []),
    ], null);
    await database.saveStacks(account.id, account.generation, 3, [
      column(4, 3, []),
    ], null);
    server = CardServer();
    sync = DeckSync(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient(server.handle),
      ),
    );
  });
  tearDown(() async {
    sync.close();
    await database.close();
  });

  Future<void> acceptedMove() async {
    await database.queueCardAction(account, 1, card, 'moveCard', {
      'stackId': 3,
      'order': 0,
    });
    await sync.run();
    expect((await database.writesFor(account.id)).single.state, 'applied');
    expect(server.mutations, hasLength(1));
  }

  Future<void> queuedText() async {
    await database
        .into(database.pendingWrites)
        .insert(
          PendingWritesCompanion.insert(
            id: 'next-text',
            accountId: account.id,
            kind: 'updateCard',
            boardId: 1,
            stackId: 2,
            cardId: const Value(8),
            proposal: jsonEncode({'description': 'My pending text'}),
            base: Value(jsonEncode(card.raw)),
          ),
        );
    await database.saveEditorDraft(account, 'draft', 1, 2, {
      'description': 'My unsent draft',
    }, card);
  }

  test(
    'accepted move reconciles a later move and unblocks a following action',
    () async {
      await acceptedMove();
      await database.queueCardAction(account, 1, card, 'archiveCard', {});
      server.readbackStatus = 200;
      server.stackId = 5;
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        server.mutations.where((path) => path.endsWith('/reorder')),
        hasLength(1),
      );
      expect(
        server.mutations.where((path) => path.endsWith('/archive')),
        hasLength(1),
      );
      final row = (await database.select(database.storedCards).get())
          .firstWhere((row) => row.remoteId == 8);
      expect(row.boardId, 1);
      expect(row.stackId, 5);
      expect(jsonDecode(row.payload)['archived'], isTrue);
    },
  );

  for (final sameStack in [false, true]) {
    test(
      'accepted action reconciles cross-board context, same stack: $sameStack',
      () async {
        await acceptedMove();
        await queuedText();
        server.readbackStatus = 200;
        server.stackId = sameStack ? 3 : 5;
        server.boardId = 4;
        await sync.run();
        expect(server.mutations, hasLength(1));
        final pending = await database.writesFor(account.id);
        expect(pending, hasLength(1));
        expect(pending.single.id, 'next-text');
        expect(pending.single.state, 'conflict');
        expect(pending.single.boardId, 4);
        expect(
          jsonDecode(pending.single.proposal)['description'],
          'My pending text',
        );
        final row = (await database.select(database.storedCards).get())
            .firstWhere((row) => row.remoteId == 8);
        expect(row.boardId, 4);
        expect(row.stackId, server.stackId);
        expect(
          (await database.stackView(
            account.id,
            1,
          )).expand((s) => s.cards).where((c) => c.id == 8),
          isEmpty,
        );
        expect(
          (await database.editorDraft(account.id, 'draft'))!.payload,
          contains('My unsent draft'),
        );
      },
    );
  }

  test(
    'a link changed by another client does not strand an accepted link action',
    () async {
      await database.queueCardAction(account, 1, card, 'addCardLink', {
        'dependentCardId': 9,
        'dependentBoardId': 1,
        'dependentStackId': 2,
      });
      await sync.run();
      expect((await database.writesFor(account.id)).single.state, 'applied');
      server.readbackStatus = 200;
      server.stackId = 2;
      server.links = [];
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect(server.mutations, hasLength(1));
      expect(
        (await database.watchCard(account.id, 1, 8).first)!.dependentCards,
        isEmpty,
      );
    },
  );

  for (final status in [403, 404]) {
    test(
      'accepted action closes without cache when read-back returns $status',
      () async {
        await acceptedMove();
        await queuedText();
        server.readbackStatus = status;
        await sync.run();
        expect(server.mutations, hasLength(1));
        final pending = await database.writesFor(account.id);
        expect(pending, hasLength(1));
        expect(pending.single.id, 'next-text');
        expect(pending.single.state, 'blocked');
        expect(
          jsonDecode(pending.single.proposal)['description'],
          'My pending text',
        );
        expect(
          (await database.boardView(account.id)).any((board) => board.id == 1),
          isTrue,
        );
        expect(
          (await database.select(database.storedCards).get()).any(
            (row) => row.remoteId == 9,
          ),
          isTrue,
        );
        expect(
          (await database.select(database.storedCards).get()).where(
            (r) => r.remoteId == 8,
          ),
          isEmpty,
        );
        expect(
          (await database.editorDraft(account.id, 'draft'))!.payload,
          contains('My unsent draft'),
        );
      },
    );
  }

  for (final status in [401, 429, 503]) {
    test(
      'transient or authentication read-back failure $status preserves the receipt',
      () async {
        await acceptedMove();
        server.readbackStatus = status;
        await sync.run();
        expect(server.mutations, hasLength(1));
        expect((await database.writesFor(account.id)).single.state, 'applied');
      },
    );
  }

  test('mismatched card or context identities never enter the cache', () async {
    await acceptedMove();
    server.readbackStatus = 200;
    server.wrongCardId = 80;
    await sync.run();
    server.wrongCardId = null;
    server.wrongStackId = 50;
    await sync.run();
    server.wrongStackId = null;
    server.wrongBoardId = 40;
    await sync.run();
    expect((await database.writesFor(account.id)).single.state, 'applied');
    expect(
      (await database.select(database.storedCards).get()).any(
        (r) => r.remoteId == 80,
      ),
      isFalse,
    );
    expect(
      (await database.select(database.storedBoards).get()).any(
        (r) => r.remoteId == 40,
      ),
      isFalse,
    );
    server.wrongBoardId = null;
    for (final invalidStack in [0, -5]) {
      server.stackId = invalidStack;
      await sync.run();
      expect((await database.writesFor(account.id)).single.state, 'applied');
      expect(
        (await database.select(database.storedStacks).get()).any(
          (row) => row.remoteId <= 0,
        ),
        isFalse,
      );
    }
    server.stackId = 3;
    await sync.run();
    expect(await database.writesFor(account.id), isEmpty);
    expect(server.mutations, hasLength(1));
  });

  test(
    'late read-back cannot restore cache after access invalidation',
    () async {
      await acceptedMove();
      server.readbackStatus = 200;
      server.onContextRead = () async {
        await database.customStatement(
          'DELETE FROM stored_cards WHERE remote_id = 8',
        );
        await database.customStatement(
          'DELETE FROM stored_boards WHERE remote_id = 1',
        );
        await database.invalidateMutation(account.id, 1);
      };
      await sync.run();
      expect(
        (await database.select(database.storedBoards).get()).any(
          (r) => r.remoteId == 1,
        ),
        isFalse,
      );
      expect(
        (await database.select(database.storedCards).get()).any(
          (r) => r.remoteId == 8,
        ),
        isFalse,
      );
      expect((await database.writesFor(account.id)).single.state, 'applied');
      server.readbackStatus = 403;
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect(server.mutations, hasLength(1));
    },
  );

  test(
    'unavailable copied card confirms the copy without deleting its source',
    () async {
      await database.queueCardAction(account, 1, card, 'cloneCard', {
        'destinationBoardId': 3,
        'destinationStackId': 4,
      });
      await sync.run();
      expect((await database.writesFor(account.id)).single.state, 'applied');
      server.readbackStatus = 404;
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.watchCard(account.id, 1, 8).first)!.title,
        card.title,
      );
      expect(server.mutations, hasLength(1));
    },
  );

  test(
    'copied card follows its current board without moving its source',
    () async {
      await database.queueCardAction(account, 1, card, 'cloneCard', {
        'destinationBoardId': 3,
        'destinationStackId': 4,
      });
      await sync.run();
      server.readbackStatus = 200;
      server.stackId = 5;
      server.boardId = 4;
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect((await database.watchCard(account.id, 1, 8).first)!.stackId, 2);
      expect((await database.watchCard(account.id, 4, 20).first)!.stackId, 5);
      expect(server.mutations, hasLength(1));
    },
  );

  test(
    'unreadable current board does not reimport a card after accepted move',
    () async {
      await acceptedMove();
      server.readbackStatus = 200;
      server.boardId = 4;
      server.readable = false;
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.select(database.storedCards).get()).where(
          (row) => row.remoteId == 8,
        ),
        isEmpty,
      );
      expect(
        (await database.select(database.storedBoards).get()).where(
          (row) => row.remoteId == 4,
        ),
        isEmpty,
      );
      expect(server.mutations, hasLength(1));
    },
  );

  test(
    'accepted deletion recovered after revocation needs no resource read-back',
    () async {
      await database.queueCardAction(account, 1, card, 'deleteCard', {});
      final pending = (await database.writesFor(account.id)).single;
      expect(await database.acquireLease(account, 'previous-run'), isTrue);
      expect(
        await database.startWrite(account, 'previous-run', pending.id),
        isTrue,
      );
      await database.markApplied(account, 'previous-run', pending, {
        'boardId': 1,
        'stackId': 2,
        'cardId': 8,
        'deleted': {...card.raw, 'deletedAt': 100},
      });
      await database.releaseLease(account.id, 'previous-run');
      await database.customStatement(
        'DELETE FROM stored_boards WHERE remote_id = 1',
      );
      await database.invalidateMutation(account.id, 1);
      await sync.run();
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.select(database.storedCards).get()).where(
          (row) => row.remoteId == 8,
        ),
        isEmpty,
      );
      expect(server.mutations, isEmpty);
    },
  );

  for (final status in [403, 404]) {
    test(
      'HTTP acknowledgement survives access invalidation during sending ($status)',
      () async {
        await database.queueCardAction(account, 1, card, 'moveCard', {
          'stackId': 3,
          'order': 0,
        });
        await queuedText();
        server.readbackStatus = status;
        server.onMutation = () async {
          await database.customStatement(
            'DELETE FROM stored_boards WHERE remote_id = 1',
          );
          await database.customStatement(
            'DELETE FROM stored_cards WHERE remote_id = 8',
          );
          await database.invalidateMutation(account.id, 1);
          await (database.update(
            database.pendingWrites,
          )..where((row) => row.state.equals('sending'))).write(
            PendingWritesCompanion(
              state: const Value('uncertain'),
              error: Value(status == 403 ? 'permission_denied' : 'not_found'),
            ),
          );
        };
        await sync.run();
        await sync.run();
        expect(server.mutations, hasLength(1));
        final pending = await database.writesFor(account.id);
        expect(pending.single.id, 'next-text');
        expect(pending.single.state, 'blocked');
        expect(pending.single.proposal, contains('My pending text'));
        expect(
          (await database.select(database.storedCards).get()).where(
            (row) => row.remoteId == 8,
          ),
          isEmpty,
        );
      },
    );
  }

  test(
    'an unrelated uncertain state cannot be changed by a late acknowledgement',
    () async {
      await database.queueCardAction(account, 1, card, 'moveCard', {
        'stackId': 3,
        'order': 0,
      });
      server.onMutation = () async {
        await (database.update(
          database.pendingWrites,
        )..where((row) => row.state.equals('sending'))).write(
          const PendingWritesCompanion(
            state: Value('uncertain'),
            error: Value('interrupted_write'),
          ),
        );
      };
      await sync.run();
      await sync.run();
      final pending = (await database.writesFor(account.id)).single;
      expect(pending.state, 'uncertain');
      expect(pending.error, 'interrupted_write');
      expect(pending.remote, isNull);
      expect(server.mutations, hasLength(1));
    },
  );

  test(
    'unavailable accepted creation still resolves dependent local IDs',
    () async {
      final id = await database.saveCardDraft(account, 1, 2, {
        'title': 'Created',
      });
      final creation = (await database.writesFor(account.id)).single;
      final local = DeckCard.fromJson({...card.raw, 'id': -creation.sequence});
      await database.queueCardAction(account, 1, local, 'archiveCard', {});
      expect(await database.acquireLease(account, 'previous-run'), isTrue);
      expect(await database.startWrite(account, 'previous-run', id), isTrue);
      final accepted = {...card.raw, 'id': 20, 'title': 'Created'};
      await database.markApplied(account, 'previous-run', creation, {
        'boardId': 1,
        'stackId': 2,
        'cardId': 20,
        'acceptedCard': accepted,
      });
      await database.releaseLease(account.id, 'previous-run');
      server.accepted = true;
      server.readbackStatus = 403;
      await sync.run();
      expect(
        await database.resolveId(account.id, -creation.sequence, 'createCard'),
        20,
      );
      final pending = (await database.writesFor(account.id)).single;
      expect(pending.kind, 'archiveCard');
      expect(pending.state, 'blocked');
      expect(server.mutations, isEmpty);
      expect(
        (await database.select(database.storedCards).get()).where(
          (row) => row.remoteId == 20,
        ),
        isEmpty,
      );
    },
  );

  for (final denial in ['403', '404', 'read=false']) {
    test(
      'known current board denial $denial revokes that entire board only',
      () async {
        await database.saveBoard(
          account,
          board(4, 'Other board', edit: true),
          (await database.account(account.id))!.contentEpoch,
        );
        await database.saveStacks(account.id, account.generation, 4, [
          column(6, 4, [
            DeckCard.fromJson({...cardJson(id: 21), 'stackId': 6}),
          ]),
        ], null);
        await database.saveEditorDraft(account, 'other-board-draft', 4, 6, {
          'description': 'Keep my text',
        }, null);
        await acceptedMove();
        server.readbackStatus = 200;
        server.stackId = 5;
        server.boardId = 4;
        server.boardStatus = int.tryParse(denial) ?? 200;
        server.readable = denial != 'read=false';
        await sync.run();
        expect(await database.writesFor(account.id), isEmpty);
        final boards = await database.boardView(account.id);
        expect(boards.any((board) => board.id == 4), isFalse);
        expect(boards.any((board) => board.id == 1), isTrue);
        final cards = await database.select(database.storedCards).get();
        expect(
          cards.any((row) => row.remoteId == 8 || row.remoteId == 21),
          isFalse,
        );
        expect(cards.any((row) => row.remoteId == 9), isTrue);
        expect(
          (await database.editorDraft(
            account.id,
            'other-board-draft',
          ))!.payload,
          contains('Keep my text'),
        );
        expect(server.mutations, hasLength(1));
      },
    );
  }
}
