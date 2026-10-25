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
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [server.card],
      }),
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

  for (final change in ['delete', 'archive']) {
    test('update does not undo a concurrent $change after its GET', () async {
      final original = DeckCard.fromJson({...server.card});
      final id = await database.saveCardDraft(account, 1, 2, {
        'description': 'My edit',
      }, original: original);
      await database.saveEditorDraft(account, 'backup', 1, 2, {
        'description': 'My saved draft',
      }, original);
      server.concurrentChange = change;
      await sync.run();
      await sync.run();
      if (change == 'delete') {
        expect(server.card['deletedAt'], 10);
        expect(server.card['description'], 'Original');
        expect((await database.writesFor(account.id)).single.state, 'blocked');
      } else {
        expect(server.card['archived'], isTrue);
        expect(server.card['description'], 'My edit');
        expect(await database.writesFor(account.id), isEmpty);
      }
      expect(server.restPuts, 0);
      expect(server.puts, 1);
      final write = (await database.select(database.pendingWrites).get())
          .singleWhere((w) => w.id == id);
      expect(jsonDecode(write.proposal)['description'], 'My edit');
      expect(
        (await database.editorDraft(account.id, 'backup'))!.payload,
        contains('My saved draft'),
      );
    });
  }

  test(
    'full safe update preserves current dates, owner, type, done and color',
    () async {
      final original = DeckCard.fromJson({...server.card});
      await database.saveCardDraft(account, 1, 2, {
        'description': 'My edit',
      }, original: original);
      server.card['duedate'] = '2031-01-02T12:00:00Z';
      final preserved = {...server.card};
      await sync.run();
      expect(server.restPuts, 0);
      for (final field in [
        'owner',
        'type',
        'duedate',
        'startdate',
        'color',
        'done',
      ]) {
        expect(server.card[field], preserved[field], reason: field);
      }
      expect(server.card['description'], 'My edit');
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test('an already deleted response is blocked before mutation', () async {
    final original = DeckCard.fromJson({...server.card});
    await database.saveCardDraft(account, 1, 2, {
      'description': 'My edit',
    }, original: original);
    server.card['deletedAt'] = 10;
    await sync.run();
    expect(server.card['deletedAt'], 10);
    expect(server.puts, 0);
    expect((await database.writesFor(account.id)).single.state, 'blocked');
  });

  test('a mismatched card response cannot update a different card', () async {
    await database.saveCardDraft(account, 1, 2, {
      'description': 'My edit',
    }, original: DeckCard.fromJson({...server.card}));
    server.card['id'] = 99;
    await sync.run();
    expect(server.puts, 0);
    expect((await database.writesFor(account.id)).single.state, 'blocked');
  });

  test('a changed column remains a resolvable conflict', () async {
    await database.saveCardDraft(account, 1, 2, {
      'description': 'My edit',
    }, original: DeckCard.fromJson({...server.card}));
    server.card['stackId'] = 4;
    await sync.run();
    final pending = (await database.writesFor(account.id)).single;
    expect(pending.state, 'conflict');
    expect(pending.stackId, 4);
    expect(server.puts, 0);
    await database.decideWrite(
      account.id,
      pending.id,
      discard: false,
      acceptRemoteBase: true,
    );
    await sync.run();
    expect(await database.writesFor(account.id), isEmpty);
    expect(server.card['stackId'], 4);
    expect(server.card['description'], 'My edit');
  });

  test(
    'a cross-board move cannot reuse the old board edit permission',
    () async {
      await database.saveCardDraft(account, 1, 2, {
        'description': 'My edit',
      }, original: DeckCard.fromJson({...server.card}));
      server.card['stackId'] = 4;
      server.currentStackBoard = 3;
      server.targetEditable = false;
      await sync.run();
      final pending = (await database.writesFor(account.id)).single;
      expect(pending.state, 'conflict');
      expect(pending.boardId, 3);
      await database.decideWrite(
        account.id,
        pending.id,
        discard: false,
        acceptRemoteBase: true,
      );
      await sync.run();
      expect(server.puts, 0);
      expect(
        (await database.writesFor(account.id)).single.error,
        'permission_denied',
      );
      expect(server.card['description'], 'Original');
    },
  );
}

final class _Server {
  final JsonObject card = {
    ...cardJson(),
    'owner': 'owner',
    'type': 'plain',
    'deletedAt': 0,
    'duedate': '2030-02-03T15:30:00Z',
    'startdate': '2030-02-01T10:00:00Z',
    'color': '008080',
    'done': '2030-02-02T12:00:00Z',
  };
  String? concurrentChange;
  var firstRead = true;
  var puts = 0;
  var restPuts = 0;
  var currentStackBoard = 1;
  var targetEditable = true;
  http.Response json(Object? value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );
  Future<http.Response> handle(http.Request request) async {
    if (request.method == 'PUT') {
      puts++;
      final body = (jsonDecode(request.body) as Map).cast<String, Object?>();
      final ocs = request.url.path.contains('/ocs/');
      if (!ocs) restPuts++;
      final deletedAt = ocs ? body['deletedAt'] : 0;
      if (card['deletedAt'] != 0 && deletedAt != 0) {
        return http.Response('', 403);
      }
      if (deletedAt != null) card['deletedAt'] = deletedAt;
      if (body['archived'] != null) card['archived'] = body['archived'];
      for (final key in [
        'title',
        'description',
        'owner',
        'type',
        'order',
        'duedate',
        'startdate',
        'color',
        'done',
      ]) {
        if (body.containsKey(key)) card[key] = body[key];
      }
      return json(
        ocs
            ? {
                'ocs': {
                  'meta': {'status': 'ok', 'statuscode': 200},
                  'data': card,
                },
              }
            : card,
      );
    }
    if (request.url.path.endsWith('/boards/1') ||
        request.url.path.endsWith('/boards/3')) {
      final id = request.url.path.endsWith('/3') ? 3 : 1;
      return json(board(id, 'Board', edit: id == 1 || targetEditable).raw);
    }
    if (request.url.path.endsWith('/stacks/2') ||
        request.url.path.endsWith('/stacks/4')) {
      return json({
        'id': int.parse(request.url.pathSegments.last),
        'boardId': currentStackBoard,
        'title': 'Column',
        'order': 0,
        'cards': [],
      });
    }
    if (request.url.path.endsWith('/cards/8')) {
      final snapshot = {...card};
      if (firstRead) {
        firstRead = false;
        if (concurrentChange == 'delete') card['deletedAt'] = 10;
        if (concurrentChange == 'archive') card['archived'] = true;
      }
      return json(snapshot);
    }
    throw StateError('unexpected_request');
  }
}
