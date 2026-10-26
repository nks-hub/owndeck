import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late DeckDatabase database;
  late StoredAccount account;
  late _Server server;
  late DeckSync sync;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    server = _Server();
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(server.stack(2)),
      DeckStack.fromJson(server.stack(3)),
    ], null);
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
  Future<void> queue(JsonObject proposal) => database.queueCardAction(
    account,
    1,
    DeckCard.fromJson(server.cards[8]!),
    'moveCard',
    {'stackId': 3, ...proposal},
  );

  test(
    'before-card intent follows a server insertion instead of its preview index',
    () async {
      await queue({'order': 0, 'anchorCardId': 9, 'before': true});
      server.cards[9]!['order'] = 1;
      server.cards[10] = {...cardJson(id: 10), 'stackId': 3, 'order': 0};
      await sync.run();
      expect(server.ordered(3).map((c) => c['id']), [10, 8, 9]);
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.stackView(
          account.id,
          1,
        )).singleWhere((s) => s.id == 3).cards.map((c) => c.id),
        [10, 8, 9],
      );
    },
  );

  test(
    'end intent uses complete current cards after a partial cache',
    () async {
      await queue({'order': 1, 'anchorCardId': null, 'before': false});
      server.cards[10] = {...cardJson(id: 10), 'stackId': 3, 'order': 1};
      server.cards[11] = {...cardJson(id: 11), 'stackId': 3, 'order': 2};
      await sync.run();
      expect(server.ordered(3).map((c) => c['id']), [9, 10, 11, 8]);
      expect(server.puts, 1);
    },
  );

  test('a removed anchor blocks without sending a reorder', () async {
    await queue({'order': 0, 'anchorCardId': 9, 'before': true});
    server.cards.remove(9);
    await sync.run();
    expect(server.puts, 0);
    expect(server.cards[8]!['stackId'], 2);
    expect(
      (await database.writesFor(account.id)).single.error,
      'invalid_destination',
    );
  });

  test(
    'old numeric move entries keep their original absolute position',
    () async {
      await queue({'order': 0});
      server.cards[9]!['order'] = 1;
      server.cards[10] = {...cardJson(id: 10), 'stackId': 3, 'order': 0};
      await sync.run();
      expect(server.ordered(3).map((c) => c['id']), [8, 10, 9]);
      expect(await database.writesFor(account.id), isEmpty);
    },
  );
  test(
    'an already achieved placement is confirmed without another mutation',
    () async {
      await queue({'anchorCardId': 9, 'before': true});
      server.cards[8]!['stackId'] = 3;
      server.cards[8]!['order'] = 0;
      server.cards[9]!['order'] = 1;
      await sync.run();
      expect(server.puts, 0);
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.stackView(
          account.id,
          1,
        )).singleWhere((s) => s.id == 3).cards.map((c) => c.id),
        [8, 9],
      );
    },
  );

  test(
    'a target moved out of this board is not used for a cross-board reorder',
    () async {
      await queue({'anchorCardId': null, 'before': false});
      server.targetInBoard = false;
      await sync.run();
      expect(server.puts, 0);
      expect(server.cards[8]!['stackId'], 2);
      expect(
        (await database.writesFor(account.id)).single.error,
        'invalid_destination',
      );
    },
  );

  test(
    'failed sibling read-back retries GET only after an accepted move',
    () async {
      await queue({'anchorCardId': null, 'before': false});
      server.failReadback = true;
      await sync.run();
      await sync.run();
      expect(server.puts, 1);
      expect((await database.writesFor(account.id)).single.state, 'applied');
      server.failReadback = false;
      await sync.run();
      expect(server.puts, 1);
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.stackView(
          account.id,
          1,
        )).singleWhere((s) => s.id == 3).cards.map((c) => c.id),
        [9, 8],
      );
    },
  );

  for (final change in ['delete', 'move']) {
    test(
      'a $change between accepted context and sibling reads resolves on retry',
      () async {
        await queue({'anchorCardId': null, 'before': false});
        server.changeDuringReadback = change;
        await sync.run();
        expect((await database.writesFor(account.id)).single.state, 'applied');
        expect(server.puts, 1);
        await sync.run();
        expect(await database.writesFor(account.id), isEmpty);
        expect(server.puts, 1);
        final local = (await database.stackView(
          account.id,
          1,
        )).expand((s) => s.cards);
        expect(local.any((c) => c.id == 8), isFalse);
        if (change == 'move') {
          expect(
            (await database.stackView(account.id, 3)).single.cards.single.id,
            8,
          );
        }
      },
    );
  }
}

class _Server {
  final cards = <int, JsonObject>{
    8: cardJson(),
    9: {...cardJson(id: 9), 'stackId': 3},
  };
  var puts = 0;
  var targetInBoard = true, failReadback = false;
  String? changeDuringReadback;
  List<JsonObject> ordered(int id) =>
      cards.values.where((c) => c['stackId'] == id).toList()
        ..sort((a, b) => (a['order']! as int).compareTo(b['order']! as int));
  JsonObject stack(int id) => {
    'id': id,
    'boardId': id == 4 ? 3 : 1,
    'title': 'Column',
    'order': id - 2,
    'isDoneColumn': false,
    'cards': ordered(id),
  };
  http.Response reply(Object value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'PUT') {
      puts++;
      final body = object(jsonDecode(request.body));
      final target = intField(body, 'stackId');
      final other = ordered(target).where((c) => c['id'] != 8).toList();
      other.insert(intField(body, 'order').clamp(0, other.length), cards[8]!);
      cards[8]!['stackId'] = target;
      for (var i = 0; i < other.length; i++) {
        other[i]['order'] = i;
      }
      return reply(
        path.contains('/ocs/')
            ? {
                'ocs': {
                  'meta': {'status': 'ok', 'statuscode': 200},
                  'data': other,
                },
              }
            : other,
      );
    }
    if (path.endsWith('/boards/1')) {
      return reply(board(1, 'Board', edit: true).raw);
    }
    if (path.endsWith('/boards/3')) {
      return reply(board(3, 'Other board', edit: true).raw);
    }
    if (path.endsWith('/stacks/archived')) return reply([]);
    if (path.endsWith('/stacks')) {
      if (puts > 0 && failReadback) return http.Response('', 503);
      if (puts > 0 && changeDuringReadback != null) {
        if (changeDuringReadback == 'delete') {
          cards.remove(8);
        } else {
          cards[8]!['stackId'] = 4;
        }
        changeDuringReadback = null;
      }
      if (path.contains('/boards/3/')) return reply([stack(4)]);
      return reply([stack(2), if (targetInBoard) stack(3)]);
    }
    if (path.endsWith('/stacks/2')) return reply(stack(2));
    if (path.endsWith('/stacks/3')) return reply(stack(3));
    if (path.endsWith('/stacks/4')) return reply(stack(4));
    if (path.endsWith('/cards/8')) {
      return cards[8] == null ? http.Response('', 404) : reply(cards[8]!);
    }
    throw StateError('unexpected_request');
  }
}
