import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

http.Response reply(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);
Object ocs(Object? data) => {
  'ocs': {
    'meta': {'status': 'ok', 'statuscode': 200},
    'data': data,
  },
};
DeckBoard sourceBoard({bool manage = false}) => DeckBoard.fromJson({
  ...board(1, 'Source', edit: manage).raw,
  'permissions': {
    'PERMISSION_READ': true,
    'PERMISSION_EDIT': manage,
    'PERMISSION_MANAGE': manage,
  },
});
DeckStack column(
  int id,
  int boardId,
  List<JsonObject> cards, {
  bool done = false,
}) => DeckStack.fromJson({
  'id': id,
  'boardId': boardId,
  'title': 'Column',
  'order': id,
  'isDoneColumn': done,
  'cards': cards,
});

void main() {
  late DeckDatabase database;
  late StoredAccount account;
  late DeckCard source;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    source = DeckCard.fromJson({...cardJson(), 'dependentCards': []});
    await database.saveBoards(account.id, account.generation, [
      sourceBoard(),
      board(3, 'Destination', edit: true),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      column(2, 1, [source.raw]),
    ], null);
    await database.saveStacks(account.id, account.generation, 3, [
      column(4, 3, []),
    ], null);
  });
  tearDown(() => database.close());
  DeckSync engine(Future<http.Response> Function(http.Request) request) =>
      DeckSync(
        database,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'test-password',
          transport: MockClient(request),
        ),
      );
  Future<void> copy() => database.queueCardAction(
    account,
    1,
    source,
    'cloneCard',
    {'title': source.title, 'destinationBoardId': 3, 'destinationStackId': 4},
  );

  test(
    'read-only source can be copied into an editable board and read-back never repeats POST',
    () async {
      await copy();
      var posts = 0;
      var readable = false;
      final sync = engine((request) async {
        if (request.method == 'POST') {
          posts++;
          return reply({...source.raw, 'id': 20, 'stackId': 4});
        }
        if (request.url.path.endsWith('/boards/1')) {
          return reply(sourceBoard().raw);
        }
        if (request.url.path.endsWith('/boards/3')) {
          return reply(board(3, 'Destination', edit: true).raw);
        }
        if (request.url.path.endsWith('/stacks/4')) {
          return reply(column(4, 3, []).raw);
        }
        if (request.url.path.endsWith('/cards/20')) {
          return readable
              ? reply({...source.raw, 'id': 20, 'stackId': 4})
              : http.Response('', 503);
        }
        return reply(source.raw);
      });
      await sync.run();
      expect((await database.writesFor(account.id)).single.state, 'applied');
      readable = true;
      await sync.run();
      expect(posts, 1);
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.stackView(account.id, 1)).single.cards.single.id,
        8,
      );
      expect(
        (await database.stackView(account.id, 3)).single.cards.single.id,
        20,
      );
    },
  );

  test(
    'lost clone response is uncertain and cannot be automatically replayed',
    () async {
      await copy();
      var posts = 0;
      final sync = engine((request) async {
        if (request.method == 'POST') {
          posts++;
          throw http.ClientException('lost_response');
        }
        if (request.url.path.endsWith('/boards/1')) {
          return reply(sourceBoard().raw);
        }
        if (request.url.path.endsWith('/boards/3')) {
          return reply(board(3, 'Destination', edit: true).raw);
        }
        if (request.url.path.endsWith('/stacks/4')) {
          return reply(column(4, 3, []).raw);
        }
        return reply(source.raw);
      });
      await sync.run();
      await sync.run();
      expect(posts, 1);
      expect((await database.writesFor(account.id)).single.state, 'uncertain');
    },
  );

  test('revoked destination rights block a queued copy before POST', () async {
    await copy();
    var posts = 0;
    await engine((request) async {
      if (request.method == 'POST') posts++;
      if (request.url.path.endsWith('/boards/1')) {
        return reply(sourceBoard().raw);
      }
      if (request.url.path.endsWith('/boards/3')) {
        return reply(board(3, 'Destination').raw);
      }
      if (request.url.path.endsWith('/stacks/4')) {
        return reply(column(4, 3, []).raw);
      }
      return reply(source.raw);
    }).run();
    expect(posts, 0);
    expect((await database.writesFor(account.id)).single.state, 'blocked');
  });

  test(
    'a deleted destination column cannot receive a copy after it was queued',
    () async {
      await copy();
      var posts = 0;
      await engine((request) async {
        if (request.method == 'POST') posts++;
        if (request.url.path.endsWith('/boards/1')) {
          return reply(sourceBoard().raw);
        }
        if (request.url.path.endsWith('/boards/3')) {
          return reply(board(3, 'Destination', edit: true).raw);
        }
        if (request.url.path.endsWith('/stacks/4')) {
          return reply({...column(4, 3, []).raw, 'deletedAt': 123});
        }
        return reply(source.raw);
      }).run();
      expect(posts, 0);
      expect((await database.writesFor(account.id)).single.state, 'blocked');
    },
  );

  test(
    'a destination already queued for deletion is refused locally',
    () async {
      final target = DeckBoard.fromJson({
        ...board(3, 'Destination', edit: true).raw,
        'permissions': {
          'PERMISSION_READ': true,
          'PERMISSION_EDIT': true,
          'PERMISSION_MANAGE': true,
        },
      });
      await database.saveBoards(account.id, account.generation, [
        sourceBoard(),
        target,
      ], null);
      await database.queueStructure(
        account,
        'deleteStack',
        {},
        boardId: 3,
        stackId: 4,
        base: column(4, 3, []).raw,
      );
      await expectLater(copy(), throwsStateError);
      expect((await database.writesFor(account.id)).single.kind, 'deleteStack');
    },
  );

  test(
    'a new linked card resolves before its relationship is posted',
    () async {
      await database.saveBoards(account.id, account.generation, [
        sourceBoard(manage: true),
        board(3, 'Destination', edit: true),
      ], null);
      final id = await database.saveCardDraft(account, 3, 4, {
        'title': 'Target',
      });
      final creation = (await database.writesFor(
        account.id,
      )).singleWhere((write) => write.id == id);
      await database.queueCardAction(account, 1, source, 'addCardLink', {
        'dependentBoardId': 3,
        'dependentStackId': 4,
        'dependentCardId': -creation.sequence,
      });
      var linked = false;
      var links = 0;
      await engine((request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return reply(sourceBoard(manage: true).raw);
        }
        if (request.url.path.endsWith('/boards/3')) {
          return reply(board(3, 'Destination', edit: true).raw);
        }
        if (request.method == 'POST' && request.url.path.endsWith('/cards')) {
          return reply({...cardJson(id: 30), 'stackId': 4});
        }
        if (request.url.path.endsWith('/cards/30')) {
          return reply({...cardJson(id: 30), 'stackId': 4});
        }
        if (request.url.path.endsWith('/stacks/2')) {
          return reply(column(2, 1, []).raw);
        }
        if (request.url.path.endsWith('/stacks/4')) {
          return reply(column(4, 3, []).raw);
        }
        if (request.method == 'POST') {
          expect(request.url.path, endsWith('/cards/8/dependentCards/30'));
          links++;
          linked = true;
        }
        return reply({
          ...source.raw,
          'dependentCards': linked ? [30] : [],
        });
      }).run();
      expect(links, 1);
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.stackView(
          account.id,
          1,
        )).single.cards.single.dependentCards,
        [30],
      );
    },
  );

  test(
    'discarding a pending target blocks its link without a request',
    () async {
      await database.saveBoards(account.id, account.generation, [
        sourceBoard(manage: true),
        board(3, 'Destination', edit: true),
      ], null);
      final id = await database.saveCardDraft(account, 3, 4, {
        'title': 'Target',
      });
      final creation = (await database.writesFor(
        account.id,
      )).singleWhere((write) => write.id == id);
      await database.queueCardAction(account, 1, source, 'addCardLink', {
        'dependentBoardId': 3,
        'dependentStackId': 4,
        'dependentCardId': -creation.sequence,
      });
      await database.decideWrite(account.id, id, discard: true);
      var requests = 0;
      await engine((_) async {
        requests++;
        return http.Response('', 500);
      }).run();
      expect(requests, 0);
      expect((await database.writesFor(account.id)).single.state, 'blocked');
    },
  );

  test(
    'done-column read-back updates every column and retains archived cards',
    () async {
      final active = {...source.raw, 'done': null};
      final archived = {
        ...source.raw,
        'id': 10,
        'archived': true,
        'done': null,
      };
      final initial = column(2, 1, [active, archived]);
      await database.saveBoards(account.id, account.generation, [
        sourceBoard(manage: true),
      ], null);
      await database.saveStacks(account.id, account.generation, 1, [
        initial,
        column(5, 1, [], done: true),
      ], null);
      await database.queueStructure(
        account,
        'setDoneStack',
        {'isDone': true},
        boardId: 1,
        stackId: 2,
        base: initial.raw,
      );
      var puts = 0;
      var applied = false;
      var failReadback = true;
      final sync = engine((request) async {
        if (request.method == 'PUT') {
          puts++;
          applied = true;
          return reply(ocs([]));
        }
        if (request.url.path.endsWith('/boards/1')) {
          return reply(sourceBoard(manage: true).raw);
        }
        if (request.url.path.endsWith('/stacks/2')) return reply(initial.raw);
        if (failReadback && applied) return http.Response('', 503);
        if (request.url.path.endsWith('/archived')) {
          return reply([
            column(2, 1, [archived], done: applied).raw,
          ]);
        }
        return reply([
          column(2, 1, [
            {...active, 'done': applied ? '2026-01-01T12:00:00Z' : null},
          ], done: applied).raw,
          column(5, 1, [], done: !applied).raw,
        ]);
      });
      await sync.run();
      expect((await database.writesFor(account.id)).single.state, 'applied');
      failReadback = false;
      await sync.run();
      final stacks = await database.stackView(account.id, 1);
      expect(puts, 1);
      expect(await database.writesFor(account.id), isEmpty);
      expect(stacks.first.isDoneColumn, isTrue);
      expect(stacks.last.isDoneColumn, isFalse);
      expect(stacks.first.cards.length, 2);
      expect(
        stacks.first.cards.firstWhere((card) => !card.archived).raw['done'],
        isNotNull,
      );
    },
  );

  test(
    'a successful HTTP response cannot confirm an ignored done-column request',
    () async {
      await database.saveBoards(account.id, account.generation, [
        sourceBoard(manage: true),
      ], null);
      final initial = column(2, 1, [source.raw]);
      await database.queueStructure(
        account,
        'setDoneStack',
        {'isDone': true},
        boardId: 1,
        stackId: 2,
        base: initial.raw,
      );
      var puts = 0;
      final sync = engine((request) async {
        if (request.method == 'PUT') {
          puts++;
          return reply(ocs([]));
        }
        if (request.url.path.endsWith('/boards/1')) {
          return reply(sourceBoard(manage: true).raw);
        }
        if (request.url.path.endsWith('/stacks/2')) return reply(initial.raw);
        return reply(
          request.url.path.endsWith('/archived') ? [] : [initial.raw],
        );
      });
      await sync.run();
      await sync.run();
      expect(puts, 1);
      expect((await database.writesFor(account.id)).single.state, 'applied');
    },
  );
}
