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
      DeckBoard.fromJson(server.board),
    ], null);
    await database.saveStacks(
      account.id,
      account.generation,
      1,
      server.stacks.map(DeckStack.fromJson).toList(),
      null,
    );
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

  test(
    'a newer explicit placement follows the original legacy order and keeps rename',
    () async {
      await database.queueStructure(
        account,
        'updateStack',
        {'title': 'Renamed', 'order': 0},
        boardId: 1,
        stackId: 12,
        base: {...server.stacks.last},
      );
      await database.queueStackReorder(account, 1, 12);
      await sync.run();
      expect(server.stacks.map((s) => s['id']), [10, 11, 12]);
      expect(server.stacks.last['title'], 'Renamed');
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test('a local creation retains the newer explicit placement', () async {
    final localId = await database.queueStructure(account, 'createStack', {
      'title': 'New',
      'order': 0,
    }, boardId: 1);
    await database.queueStackReorder(account, 1, localId);
    await sync.run();
    expect(server.stacks.map((s) => s['id']), [10, 11, 12, 13]);
    expect(server.stacks.last['title'], 'New');
    expect(await database.writesFor(account.id), isEmpty);
  });

  test(
    'resolved local aliases keep legacy and explicit intents in their original order',
    () async {
      final localId = await database.queueStructure(account, 'createStack', {
        'title': 'New',
      }, boardId: 1);
      await sync.run();
      final remoteId = await database.resolveId(
        account.id,
        localId,
        'createStack',
      );
      await database.queueStructure(
        account,
        'updateStack',
        {'title': 'Renamed', 'order': 0},
        boardId: 1,
        stackId: localId,
        base: {...server.stacks.last},
      );
      await database.queueStackReorder(account, 1, remoteId!);
      await sync.run();
      expect(server.stacks.map((s) => s['id']), [10, 11, 12, 13]);
      expect(server.stacks.last['title'], 'Renamed');
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test(
    'legacy and explicit placement of different stacks preserve user ordering',
    () async {
      await database.queueStructure(
        account,
        'updateStack',
        {'order': 0},
        boardId: 1,
        stackId: 12,
        base: {...server.stacks.last},
      );
      await database.queueStackReorder(account, 1, 10);
      await sync.run();
      expect(server.stacks.map((s) => s['id']), [12, 11, 10]);
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test(
    'legacy updateStack order uses normalization, not a lone REST order',
    () async {
      await database.queueStructure(
        account,
        'updateStack',
        {'order': 0},
        boardId: 1,
        stackId: 12,
        base: server.stacks.last,
      );
      await sync.run();
      expect(server.stacks.map((s) => s['id']), [12, 10, 11]);
      expect(server.stacks.map((s) => s['order']), [0, 1, 2]);
      expect(server.reorders, 1);
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test(
    'anchor placement is projected and normalizes all server siblings',
    () async {
      await database.queueStackReorder(
        account,
        1,
        12,
        anchorStackId: 10,
        before: true,
      );
      final projected = await database.stackView(account.id, 1);
      expect(projected.map((s) => s.id), [12, 10, 11]);
      expect(projected.map((s) => s.order), [0, 1, 2]);
      await sync.run();
      expect(server.stacks.map((s) => s['id']), [12, 10, 11]);
      expect(server.reorders, 1);
      expect(server.restUpdates, 0);
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test(
    'start, end and multiple queued reorders use their actual siblings',
    () async {
      await database.queueStackReorder(account, 1, 12, before: true);
      await database.queueStackReorder(account, 1, 10);
      expect((await database.stackView(account.id, 1)).map((s) => s.id), [
        12,
        11,
        10,
      ]);
      await sync.run();
      expect(server.stacks.map((s) => s['id']), [12, 11, 10]);
      expect(server.reorders, 2);
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test('new local stack is created before its requested move', () async {
    final id = await database.queueStructure(account, 'createStack', {
      'title': 'New column',
    }, boardId: 1);
    await database.queueStackReorder(account, 1, id, before: true);
    expect((await database.stackView(account.id, 1)).first.id, id);
    await sync.run();
    expect(server.stacks.map((s) => s['id']), [13, 10, 11, 12]);
    expect(server.stacks.map((s) => s['order']), [0, 1, 2, 3]);
    expect(server.reorders, 1);
    expect(await database.writesFor(account.id), isEmpty);
  });

  test('accepted reorder retries only GET after failed read-back', () async {
    await database.queueStackReorder(account, 1, 12, before: true);
    server.readbackFails = true;
    await sync.run();
    expect((await database.writesFor(account.id)).single.state, 'applied');
    expect(server.reorders, 1);
    server.readbackFails = false;
    await sync.run();
    expect(server.reorders, 1);
    expect(await database.writesFor(account.id), isEmpty);
    expect((await database.stackView(account.id, 1)).first.id, 12);
  });

  test(
    'lost reorder response remains uncertain without a second PUT',
    () async {
      await database.queueStackReorder(account, 1, 12, before: true);
      server.loseReorderResponse = true;
      await sync.run();
      await sync.run();
      expect(server.reorders, 1);
      expect((await database.writesFor(account.id)).single.state, 'uncertain');
    },
  );

  test(
    'removed anchor and lost manage permission never move another stack',
    () async {
      await database.queueStackReorder(account, 1, 12, anchorStackId: 11);
      server.stacks.removeWhere((s) => s['id'] == 11);
      await sync.run();
      final blocked = (await database.writesFor(account.id)).single;
      expect(blocked.error, 'invalid_destination');
      expect(blocked.state, 'blocked');
      expect(server.reorders, 0);
      await database.decideWrite(account.id, blocked.id, discard: true);
      await database.queueStackReorder(account, 1, 12, before: true);
      server.manage = false;
      await sync.run();
      expect(
        (await database.writesFor(account.id)).single.error,
        'permission_denied',
      );
      expect(server.reorders, 0);
    },
  );

  test('unchanged placement does not send a redundant reorder', () async {
    await database.queueStackReorder(account, 1, 12);
    await sync.run();
    expect(server.reorders, 0);
    expect(await database.writesFor(account.id), isEmpty);
  });

  test(
    'legacy numeric intent conflicts with a different server move',
    () async {
      await database.queueStructure(
        account,
        'updateStack',
        {'order': 0},
        boardId: 1,
        stackId: 12,
        base: {...server.stacks.last},
      );
      final moved = server.stacks.removeLast();
      server.stacks.insert(1, moved);
      for (var i = 0; i < server.stacks.length; i++) {
        server.stacks[i]['order'] = i;
      }
      await sync.run();
      final pending = (await database.writesFor(account.id)).single;
      expect(pending.kind, 'stackReorder');
      expect(pending.state, 'conflict');
      expect(jsonDecode(pending.remote!)['order'], 1);
      expect(server.reorders, 0);
    },
  );
}

final class _Server {
  final stacks = <JsonObject>[
    for (var i = 0; i < 3; i++)
      {
        'id': 10 + i,
        'boardId': 1,
        'title': 'Column $i',
        'order': i,
        'cards': [],
      },
  ];
  var reorders = 0;
  var restUpdates = 0;
  var readbackFails = false;
  var loseReorderResponse = false;
  var manage = true;
  JsonObject get board => {
    'id': 1,
    'title': 'Board',
    'color': '008080',
    'archived': false,
    'deletedAt': 0,
    'permissions': {
      'PERMISSION_READ': true,
      'PERMISSION_EDIT': true,
      'PERMISSION_MANAGE': manage,
    },
  };
  http.Response json(Object? value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );
  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (path.endsWith('/boards/1')) return json(board);
    if (request.method == 'PUT' && path.endsWith('/reorder')) {
      reorders++;
      final id = int.parse(request.url.pathSegments.reversed.skip(1).first);
      final body = jsonDecode(request.body) as Map;
      final entry = stacks.singleWhere((s) => s['id'] == id);
      stacks.remove(entry);
      stacks.insert(body['order'] as int, entry);
      for (var i = 0; i < stacks.length; i++) {
        stacks[i]['order'] = i;
      }
      if (loseReorderResponse) throw http.ClientException('lost_response');
      return json({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200},
          'data': {for (final stack in stacks) '${stack['order']}': stack},
        },
      });
    }
    if (path.endsWith('/stacks/archived')) return json([]);
    if (path.endsWith('/stacks')) {
      if (request.method == 'POST') {
        final data = jsonDecode(request.body) as Map<String, dynamic>;
        final created = <String, Object?>{
          'id': 13,
          'boardId': 1,
          'cards': [],
          ...data,
        };
        stacks.add(created);
        return json(created);
      }
      if (reorders > 0 && readbackFails) return http.Response('', 503);
      return json(stacks);
    }
    final id = int.parse(request.url.pathSegments.last);
    final entry = stacks.singleWhere((s) => s['id'] == id);
    if (request.method == 'PUT') {
      restUpdates++;
      entry.addAll((jsonDecode(request.body) as Map).cast<String, Object?>());
    }
    return json(entry);
  }
}
