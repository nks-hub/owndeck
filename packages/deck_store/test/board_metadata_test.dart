import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

JsonObject metadataBoard({
  bool manage = true,
  bool share = true,
  List<JsonObject> labels = const [],
  List<JsonObject> acl = const [],
}) => {
  ...board(1, 'Board', edit: true).raw,
  'labels': labels,
  'acl': acl,
  'permissions': {
    'PERMISSION_READ': true,
    'PERMISSION_EDIT': true,
    'PERMISSION_MANAGE': manage,
    'PERMISSION_SHARE': share,
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
  setUp(() async {
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'));
    await db.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson(metadataBoard()),
    ], null);
  });
  tearDown(() => db.close());

  DeckSync engine(Future<http.Response> Function(http.Request) callback) =>
      DeckSync(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: 'user',
          appPassword: 'test-password',
          transport: MockClient(callback),
        ),
      );

  test(
    'a sharer may add a read-only ACL but cannot delete it or grant management',
    () async {
      await db.saveBoards(account.id, account.generation, [
        DeckBoard.fromJson(metadataBoard(manage: false)),
      ], null);
      await db.queueBoardMetadata(account, 1, 'createAcl', {
        'type': 0,
        'participant': 'other',
        'permissionEdit': false,
        'permissionShare': false,
        'permissionManage': false,
      });
      await expectLater(
        db.queueBoardMetadata(account, 1, 'createAcl', {
          'type': 0,
          'participant': 'third',
          'permissionEdit': false,
          'permissionShare': false,
          'permissionManage': true,
        }),
        throwsStateError,
      );
      await expectLater(
        db.queueBoardMetadata(account, 1, 'deleteAcl', {}, original: {'id': 4}),
        throwsStateError,
      );
      expect((await db.writesFor(account.id)).length, 1);
    },
  );

  test(
    'fresh permission loss prevents granting management from an old snapshot',
    () async {
      await db.queueBoardMetadata(account, 1, 'createAcl', {
        'type': 0,
        'participant': 'other',
        'permissionEdit': false,
        'permissionShare': false,
        'permissionManage': true,
      });
      var writes = 0;
      await engine((request) async {
        if (request.method != 'GET') writes++;
        return reply(metadataBoard(manage: false));
      }).run();
      expect(writes, 0);
      expect((await db.writesFor(account.id)).single.state, 'blocked');
    },
  );

  test(
    'accepted share creation retries only read-back after disconnection',
    () async {
      await db.queueBoardMetadata(account, 1, 'createAcl', {
        'type': 0,
        'participant': 'other',
        'permissionEdit': false,
        'permissionShare': false,
        'permissionManage': false,
      });
      final acl = {
        'id': 4,
        'boardId': 1,
        'type': 0,
        'participant': {'uid': 'other'},
        'permissionEdit': false,
        'permissionShare': false,
        'permissionManage': false,
      };
      var posts = 0;
      var offline = true;
      final sync = engine((request) async {
        if (request.method == 'POST') {
          posts++;
          return reply(acl);
        }
        if (posts > 0 && offline) throw http.ClientException('offline');
        return reply(metadataBoard(acl: posts > 0 ? [acl] : []));
      });
      await sync.run();
      expect((await db.writesFor(account.id)).single.state, 'applied');
      offline = false;
      await sync.run();
      expect(posts, 1);
      expect(await db.writesFor(account.id), isEmpty);
      expect((await db.boardView(account.id)).single.raw['acl'], [acl]);
    },
  );

  test(
    'removing own access confirms the write and removes the cached board',
    () async {
      final acl = {
        'id': 4,
        'type': 0,
        'participant': {'uid': 'user'},
        'permissionEdit': true,
        'permissionShare': true,
        'permissionManage': true,
      };
      await db.saveBoards(account.id, account.generation, [
        DeckBoard.fromJson(metadataBoard(acl: [acl])),
      ], null);
      await db.saveEditorDraft(account, '1:2:new', 1, 2, {
        'title': 'Preserved',
        'description': 'Local',
      }, null);
      await db.queueBoardMetadata(account, 1, 'deleteAcl', {}, original: acl);
      var deleted = false;
      await engine((request) async {
        if (request.method == 'DELETE') {
          deleted = true;
          return reply(acl);
        }
        return deleted
            ? http.Response('', 403)
            : reply(metadataBoard(acl: [acl]));
      }).run();
      expect(await db.writesFor(account.id), isEmpty);
      expect(await db.boardView(account.id), isEmpty);
      expect(await db.editorDraft(account.id, '1:2:new'), isNotNull);
    },
  );

  test('label rename preserves a color changed by another client', () async {
    final original = {'id': 7, 'boardId': 1, 'title': 'Old', 'color': '008080'};
    await db.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson(metadataBoard(labels: [original])),
    ], null);
    await db.queueBoardMetadata(account, 1, 'updateLabel', {
      'title': 'New',
    }, original: original);
    JsonObject? sent;
    await engine((request) async {
      if (request.method == 'PUT') {
        sent = object(jsonDecode(request.body));
        return reply({...original, ...sent!});
      }
      return reply(
        metadataBoard(
          labels: [
            {
              ...original,
              'title': sent == null ? 'Old' : 'New',
              'color': 'ff0000',
            },
          ],
        ),
      );
    }).run();
    expect(sent, {'title': 'New', 'color': 'ff0000'});
    expect(await db.writesFor(account.id), isEmpty);
  });

  test(
    'creating a label resolves its local id before assigning it to a card',
    () async {
      await db.saveStacks(account.id, account.generation, 1, [
        DeckStack.fromJson({
          'id': 2,
          'boardId': 1,
          'title': 'Todo',
          'order': 0,
          'cards': [cardJson()],
        }),
      ], null);
      await db.queueBoardMetadata(account, 1, 'createLabel', {
        'title': 'Work',
        'color': '008080',
      });
      final localLabel = objects(
        (await db.boardView(account.id)).single.raw['labels'],
      ).single;
      await db.queueCardAction(
        account,
        1,
        DeckCard.fromJson(cardJson()),
        'assignLabel',
        {'labelId': localLabel['id'], 'label': localLabel},
      );
      final remoteLabel = {
        'id': 7,
        'boardId': 1,
        'title': 'Work',
        'color': '008080',
      };
      var labelCreated = false;
      var assigned = false;
      Object? sentId;
      await engine((request) async {
        if (request.method == 'POST') {
          labelCreated = true;
          return reply(remoteLabel);
        }
        if (request.method == 'PUT') {
          assigned = true;
          sentId = object(jsonDecode(request.body))['labelId'];
          return reply(cardJson());
        }
        if (request.url.path.endsWith('/boards/1')) {
          return reply(
            metadataBoard(labels: labelCreated ? [remoteLabel] : []),
          );
        }
        return reply({
          ...cardJson(),
          'labels': assigned ? [remoteLabel] : [],
        });
      }).run();
      expect(sentId, 7);
      expect(await db.writesFor(account.id), isEmpty);
    },
  );
}
