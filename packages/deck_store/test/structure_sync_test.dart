import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

JsonObject boardJson({
  String title = 'Board',
  bool manage = true,
  bool archived = false,
}) => {
  ...board(10, title, edit: true).raw,
  'archived': archived,
  'permissions': {
    'PERMISSION_READ': true,
    'PERMISSION_EDIT': true,
    'PERMISSION_MANAGE': manage,
  },
};

http.Response reply(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  late DeckDatabase db;
  late StoredAccount account;
  const capabilities = DeckCapabilities(
    version: '1.19.1',
    apiVersion: '1.1',
    canCreateBoards: true,
  );
  setUp(() async {
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'));
    await db.saveCapabilities(account, capabilities);
  });
  tearDown(() => db.close());

  DeckSync sync(Future<http.Response> Function(http.Request) request) =>
      DeckSync(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: 'user',
          appPassword: 'test-password',
          transport: MockClient(request),
        ),
      );

  test(
    'offline hierarchy sends parent creations before children and resolves aliases',
    () async {
      final boardId = await db.queueStructure(account, 'createBoard', {
        'title': 'Board',
        'color': '008080',
      });
      final stackId = await db.queueStructure(account, 'createStack', {
        'title': 'Todo',
        'order': 0,
      }, boardId: boardId);
      await db.saveCardDraft(account, boardId, stackId, {
        'title': 'Task',
        'description': 'Saved locally',
      });
      expect(
        (await db.watchStacks(account.id, boardId).first)
            .single
            .cards
            .single
            .title,
        'Task',
      );
      final posted = <String>[];
      final createdStack = {
        'id': 20,
        'boardId': 10,
        'title': 'Todo',
        'order': 0,
      };
      final createdCard = {
        'id': 30,
        'stackId': 20,
        'title': 'Task',
        'description': 'Saved locally',
        'order': 999,
        'archived': false,
        'type': 'plain',
        'owner': 'user',
      };
      await sync((request) async {
        final path = request.url.path;
        if (request.method == 'POST') {
          posted.add(path);
          if (path.endsWith('/boards')) return reply(boardJson());
          if (path.endsWith('/stacks')) {
            return reply(createdStack);
          }
          return reply(createdCard);
        }
        if (path.endsWith('/stacks/20')) return reply(createdStack);
        if (path.endsWith('/cards/30')) return reply(createdCard);
        if (path.endsWith('/capabilities')) {
          return reply({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': {
                'capabilities': {
                  'deck': {
                    'version': '1.19.1',
                    'apiVersions': ['1.1'],
                    'canCreateBoards': true,
                  },
                },
              },
            },
          });
        }
        return reply(boardJson());
      }).run();
      expect(posted, [
        '/nextcloud/index.php/apps/deck/api/v1.1/boards',
        '/nextcloud/index.php/apps/deck/api/v1.1/boards/10/stacks',
        '/nextcloud/index.php/apps/deck/api/v1.1/boards/10/stacks/20/cards',
      ]);
      expect(await db.writesFor(account.id), isEmpty);
      expect(
        (await db.watchStacks(account.id, boardId).first)
            .single
            .cards
            .single
            .id,
        30,
      );
    },
  );

  test('edit permission alone cannot manage columns', () async {
    await db.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson(boardJson(manage: false)),
    ], null);
    await expectLater(
      db.queueStructure(account, 'createStack', {
        'title': 'Column',
        'order': 0,
      }, boardId: 10),
      throwsStateError,
    );
    expect(await db.writesFor(account.id), isEmpty);
  });

  test('archiving preserves a title changed on the server', () async {
    final original = DeckBoard.fromJson(boardJson(title: 'Old title'));
    await db.saveBoards(account.id, account.generation, [original], null);
    await db.queueStructure(
      account,
      'updateBoard',
      {'archived': true},
      boardId: 10,
      base: original.raw,
    );
    JsonObject? sent;
    await sync((request) async {
      if (request.method == 'PUT') {
        sent = object(jsonDecode(request.body));
        return reply(boardJson(title: 'New title', archived: true));
      }
      return reply(boardJson(title: 'New title'));
    }).run();
    expect(sent, {'title': 'New title', 'color': '008080', 'archived': true});
    expect((await db.watchBoards(account.id).first).single.archived, isTrue);
  });

  test(
    'a lost parent creation response never sends children to a guessed id',
    () async {
      final boardId = await db.queueStructure(account, 'createBoard', {
        'title': 'Board',
        'color': '008080',
      });
      await db.queueStructure(account, 'createStack', {
        'title': 'Column',
        'order': 0,
      }, boardId: boardId);
      var posts = 0;
      final engine = sync((request) async {
        if (request.method == 'POST') {
          posts++;
          throw http.ClientException('lost response');
        }
        return reply({
          'ocs': {
            'meta': {'status': 'ok', 'statuscode': 200},
            'data': {
              'capabilities': {
                'deck': {
                  'version': '1.19.1',
                  'apiVersions': ['1.1'],
                  'canCreateBoards': true,
                },
              },
            },
          },
        });
      });
      await engine.run();
      await engine.run();
      expect(posts, 1);
      expect((await db.writesFor(account.id)).map((w) => w.state).toList(), [
        'uncertain',
        'queued',
      ]);
    },
  );

  test(
    'discarded parent blocks its child while retaining the local text',
    () async {
      final boardId = await db.queueStructure(account, 'createBoard', {
        'title': 'Board',
        'color': '008080',
      });
      await db.queueStructure(account, 'createStack', {
        'title': 'Keep this',
        'order': 0,
      }, boardId: boardId);
      final parent = (await db.writesFor(account.id)).first;
      await db.decideWrite(account.id, parent.id, discard: true);
      var requests = 0;
      await sync((_) async {
        requests++;
        return reply({});
      }).run();
      final child = (await db.writesFor(account.id)).single;
      expect(child.state, 'blocked');
      expect(child.error, 'dependency_unavailable');
      expect(object(jsonDecode(child.proposal))['title'], 'Keep this');
      expect(requests, 0);
    },
  );
}
