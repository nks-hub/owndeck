import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

http.Response response(Object? json) => http.Response(
  jsonEncode(json),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  late DeckDatabase db;
  late StoredAccount account;
  setUp(() async {
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'));
    await db.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Todo',
        'order': 0,
        'cards': [cardJson()],
      }),
    ], null);
  });
  tearDown(() => db.close());

  DeckSync engine(Future<http.Response> Function(http.Request) handle) =>
      DeckSync(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: 'user',
          appPassword: 'test-password',
          transport: MockClient(handle),
        ),
      );

  test(
    'draft edits coalesce while preserving the original conflict base',
    () async {
      final original = DeckCard.fromJson(cardJson());
      final id = await db.saveCardDraft(account, 1, 2, {
        'description': 'First edit',
      }, original: original);
      await db.saveCardDraft(account, 1, 2, {
        'description': 'Final edit',
      }, original: original);
      final writes = await db.writesFor(account.id);
      expect(writes.single.id, id);
      expect(
        object(jsonDecode(writes.single.base!))['description'],
        'Original',
      );
      expect(
        (await db.watchStacks(account.id, 1).first)
            .single
            .cards
            .single
            .description,
        'Final edit',
      );
    },
  );

  test(
    'lost POST response is uncertain and is not automatically replayed',
    () async {
      await db.saveCardDraft(account, 1, 2, {
        'title': 'New task',
        'description': 'Draft',
      });
      var posts = 0;
      final sync = engine((request) async {
        if (request.method == 'GET') {
          if (request.url.path.endsWith('/stacks/2')) {
            return response({
              'id': 2,
              'boardId': 1,
              'title': 'Todo',
              'order': 0,
              'cards': [cardJson()],
            });
          }
          return response(board(1, 'Board', edit: true).raw);
        }
        posts++;
        throw http.ClientException('response lost');
      });
      await sync.run();
      expect((await db.writesFor(account.id)).single.state, 'uncertain');
      await sync.run();
      expect(posts, 1);
      final cards = (await db.watchStacks(account.id, 1).first).single.cards;
      expect(cards.singleWhere((c) => c.id < 0).description, 'Draft');
    },
  );

  test(
    'concurrent description change keeps both versions and sends no PUT',
    () async {
      await db.saveCardDraft(account, 1, 2, {
        'description': 'Local',
      }, original: DeckCard.fromJson(cardJson()));
      var puts = 0;
      final sync = engine((request) async {
        if (request.method == 'PUT') puts++;
        if (request.url.path.endsWith('/stacks/2')) {
          return response({
            'id': 2,
            'boardId': 1,
            'title': 'Todo',
            'order': 0,
            'cards': [],
          });
        }
        return response(
          request.url.path.endsWith('/boards/1')
              ? board(1, 'Board', edit: true).raw
              : cardJson(description: 'Remote'),
        );
      });
      await sync.run();
      final write = (await db.writesFor(account.id)).single;
      expect(write.state, 'conflict');
      expect(object(jsonDecode(write.remote!))['description'], 'Remote');
      expect(object(jsonDecode(write.proposal))['description'], 'Local');
      expect(puts, 0);
    },
  );

  test(
    'successful write advances content epoch and rejects an older snapshot',
    () async {
      await db.saveCardDraft(account, 1, 2, {
        'description': 'Local',
      }, original: DeckCard.fromJson(cardJson()));
      var serverCard = cardJson();
      final sync = engine((request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return response(board(1, 'Board', edit: true).raw);
        }
        if (request.method == 'PUT') {
          serverCard = cardJson(description: 'Local');
          return response({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': serverCard,
            },
          });
        }
        if (request.url.path.endsWith('/stacks/2')) {
          return response({
            'id': 2,
            'boardId': 1,
            'title': 'Todo',
            'order': 0,
            'cards': [serverCard],
          });
        }
        return response(serverCard);
      });
      await sync.run();
      expect(await db.writesFor(account.id), isEmpty);
      await db.saveStacks(
        account.id,
        account.generation,
        1,
        [],
        null,
        contentEpoch: 0,
      );
      expect(
        (await db.watchStacks(account.id, 1).first)
            .single
            .cards
            .single
            .description,
        'Local',
      );
    },
  );

  test('draft merged during the board read is sent, not lost (B46)', () async {
    final original = DeckCard.fromJson(cardJson());
    await db.saveCardDraft(account, 1, 2, {
      'description': 'A',
    }, original: original);
    var serverCard = cardJson();
    var boardReads = 0;
    final puts = <String>[];
    final sync = engine((request) async {
      if (request.url.path.endsWith('/boards/1')) {
        if (boardReads++ == 0) {
          await db.saveCardDraft(account, 1, 2, {
            'description': 'B',
          }, original: original);
        }
        return response(board(1, 'Board', edit: true).raw);
      }
      if (request.method == 'PUT') {
        puts.add(request.body);
        serverCard = cardJson(description: 'B');
        return response({
          'ocs': {
            'meta': {'status': 'ok', 'statuscode': 200},
            'data': serverCard,
          },
        });
      }
      if (request.url.path.endsWith('/stacks/2')) {
        return response({
          'id': 2,
          'boardId': 1,
          'title': 'Todo',
          'order': 0,
          'cards': [serverCard],
        });
      }
      return response(serverCard);
    });
    await sync.run();
    expect(puts, isNotEmpty);
    expect(puts.last, contains('"B"'));
    expect(await db.writesFor(account.id), isEmpty);
  });

  test('HTML 404 keeps the write queued and the cache intact (B52)', () async {
    await db.saveCardDraft(account, 1, 2, {
      'description': 'Local',
    }, original: DeckCard.fromJson(cardJson()));
    final sync = engine(
      (request) async => http.Response(
        '<html>Not Found</html>',
        404,
        headers: {'content-type': 'text/html'},
      ),
    );
    await expectLater(
      sync.run(),
      throwsA(
        isA<DeckException>().having((e) => e.code, 'code', 'deck_unavailable'),
      ),
    );
    expect((await db.writesFor(account.id)).single.state, 'queued');
    expect(
      (await db.watchStacks(account.id, 1).first).single.cards,
      isNotEmpty,
    );
  });

  test('JSON 404 from Deck still revokes the board', () async {
    await db.saveCardDraft(account, 1, 2, {
      'description': 'Local',
    }, original: DeckCard.fromJson(cardJson()));
    await engine(
      (request) async => http.Response(
        '{"message":"Not found"}',
        404,
        headers: {'content-type': 'application/json'},
      ),
    ).run();
    expect((await db.writesFor(account.id)).single.state, isNot('queued'));
  });

  test('restart recovers a sending operation without replaying it', () async {
    final id = await db.saveCardDraft(account, 1, 2, {'title': 'New'});
    expect(await db.acquireLease(account, 'old-worker'), isTrue);
    expect(await db.startWrite(account, 'old-worker', id), isTrue);
    await db.releaseLease(account.id, 'old-worker');
    var requests = 0;
    await engine((_) async {
      requests++;
      return response({});
    }).run();
    expect((await db.writesFor(account.id)).single.state, 'uncertain');
    expect(requests, 0);
  });

  test('permission loss blocks the write before mutation', () async {
    await db.saveCardDraft(account, 1, 2, {'title': 'New'});
    var mutations = 0;
    await engine((request) async {
      if (request.method != 'GET') mutations++;
      return response(board(1, 'Board', edit: false).raw);
    }).run();
    expect((await db.writesFor(account.id)).single.state, 'blocked');
    expect(mutations, 0);
  });
}
