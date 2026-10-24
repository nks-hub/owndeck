import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

JsonObject commentJson(
  int id, {
  String actor = 'uid-1',
  String message = 'Original',
}) => {
  'id': id,
  'objectId': 8,
  'message': message,
  'actorId': actor,
  'actorType': 'users',
  'creationDateTime': '2026-10-24T12:00:00Z',
};
http.Response reply(Object? data, {bool ocs = false}) => http.Response(
  jsonEncode(
    ocs
        ? {
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': data,
            },
          }
        : data,
  ),
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
    ).add(credentials('login-alias'), userId: 'uid-1');
    await db.saveBoards(account.id, account.generation, [
      board(1, 'Read only'),
    ], null);
  });
  tearDown(() => db.close());

  DeckSync sync(Future<http.Response> Function(http.Request) callback) =>
      DeckSync(
        db,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'test-password',
          transport: MockClient(callback),
        ),
      );

  test('a reader may comment and the server UID controls authorship', () async {
    await db.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    var posts = 0;
    await sync((request) async {
      if (request.url.path.endsWith('/boards/1')) {
        return reply(board(1, 'Read only').raw);
      }
      if (request.url.path.endsWith('/cloud/user')) {
        return reply({'id': 'uid-1'}, ocs: true);
      }
      posts++;
      return reply(commentJson(10, message: 'Hello'), ocs: true);
    }).run();
    expect(posts, 1);
    expect(await db.writesFor(account.id), isEmpty);
    expect(
      (await db.watchComments(account.id, 8).first).single.actorId,
      'uid-1',
    );
  });

  test('another author cannot be edited or deleted locally', () async {
    final other = DeckComment.fromJson(commentJson(10, actor: 'other'));
    await expectLater(
      db.queueComment(account, 1, 2, 8, 'updateComment', {
        'message': 'Changed',
      }, original: other),
      throwsStateError,
    );
    await expectLater(
      db.queueComment(account, 1, 2, 8, 'deleteComment', {}, original: other),
      throwsStateError,
    );
  });

  test(
    'uncertain comment creation is not repeated and its text survives',
    () async {
      await db.queueComment(account, 1, 2, 8, 'createComment', {
        'message': 'Keep this',
      });
      var posts = 0;
      final engine = sync((request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return reply(board(1, 'Read only').raw);
        }
        if (request.url.path.endsWith('/cloud/user')) {
          return reply({'id': 'uid-1'}, ocs: true);
        }
        posts++;
        throw http.ClientException('lost reply');
      });
      await engine.run();
      await engine.run();
      expect(posts, 1);
      expect((await db.writesFor(account.id)).single.state, 'uncertain');
      expect(
        (await db.watchComments(account.id, 8).first).single.message,
        'Keep this',
      );
    },
  );

  test(
    'reply waits for a local parent comment and sends its confirmed id',
    () async {
      await db.queueComment(account, 1, 2, 8, 'createComment', {
        'message': 'Parent',
      });
      final parent = (await db.watchComments(account.id, 8).first).single;
      await db.queueComment(account, 1, 2, 8, 'createComment', {
        'message': 'Reply',
        'parentId': parent.id,
        'replyTo': parent.raw,
      });
      final parents = <Object?>[];
      await sync((request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return reply(board(1, 'Read only').raw);
        }
        if (request.url.path.endsWith('/cloud/user')) {
          return reply({'id': 'uid-1'}, ocs: true);
        }
        final body = object(jsonDecode(request.body));
        parents.add(body['parentId']);
        return reply(
          commentJson(99 + parents.length, message: body['message'] as String),
          ocs: true,
        );
      }).run();
      expect(parents, [0, 100]);
      expect((await db.watchComments(account.id, 8).first).length, 2);
    },
  );

  test(
    'concurrent edit retains the remote and local comment messages',
    () async {
      await db.queueComment(account, 1, 2, 8, 'updateComment', {
        'message': 'Local',
      }, original: DeckComment.fromJson(commentJson(10)));
      var puts = 0;
      await sync((request) async {
        if (request.method == 'PUT') puts++;
        if (request.url.path.endsWith('/boards/1')) {
          return reply(board(1, 'Read only').raw);
        }
        if (request.url.path.endsWith('/cloud/user')) {
          return reply({'id': 'uid-1'}, ocs: true);
        }
        return reply([commentJson(10, message: 'Remote')], ocs: true);
      }).run();
      final conflict = (await db.writesFor(account.id)).single;
      expect(conflict.state, 'conflict');
      expect(object(jsonDecode(conflict.remote!))['message'], 'Remote');
      expect(puts, 0);
    },
  );

  test(
    'publishing a comment draft removes it only after the write is queued',
    () async {
      await db.saveCommentDraft(account, 'comment:8:new', 1, 2, 8, 'Draft');
      await expectLater(
        db.publishCommentDraft(account, 'comment:8:new', 1, 2, 8, ''),
        throwsFormatException,
      );
      expect(await db.editorDraft(account.id, 'comment:8:new'), isNotNull);
      await db.publishCommentDraft(account, 'comment:8:new', 1, 2, 8, 'Draft');
      expect(await db.editorDraft(account.id, 'comment:8:new'), isNull);
      expect((await db.writesFor(account.id)).single.kind, 'createComment');
    },
  );
}
