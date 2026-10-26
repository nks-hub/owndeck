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
    await database.saveUserIdentity(account, 'user');
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
      board(3, 'Other board', edit: true),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [cardJson(), cardJson(id: 9)],
      }),
    ], null);
    server = _Server();
    sync = DeckSync(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient(server.handle),
      ),
      readUpload: (_) async => AttachmentUploadSource(
        filename: 'report.txt',
        mime: 'text/plain',
        length: 3,
        bytes: Stream.value([1, 2, 3]),
      ),
    );
  });
  tearDown(() async {
    sync.close();
    await database.close();
  });

  Future<String> queue(String kind) => database.queueAttachment(
    account,
    1,
    2,
    8,
    kind,
    kind == 'linkAttachment'
        ? {
            'segments': ['report.txt'],
          }
        : {'uploadId': 'staged', 'name': 'report.txt'},
  );

  Future<void> queueEdit() => database.queueComment(
    account,
    1,
    2,
    8,
    'createComment',
    {'message': 'My later text'},
  );

  Future<PendingWrite> storedWrite(String id) async =>
      (await database.select(database.pendingWrites).get()).singleWhere(
        (w) => w.id == id,
      );

  for (final kind in ['linkAttachment', 'uploadAttachment']) {
    test(
      '$kind missing after acceptance confirms without a second POST',
      () async {
        server.mode = 'missing';
        final id = await queue(kind);
        await queueEdit();
        await sync.run();
        await sync.run();
        expect(server.posts, 1);
        expect(server.commentPosts, 1);
        expect((await storedWrite(id)).state, 'confirmed');
        expect(await database.writesFor(account.id), isEmpty);
        expect(await database.attachmentsFor(account.id, 8), isEmpty);
      },
    );
  }

  for (final code in [403, 404]) {
    test(
      'accepted attachment on unavailable card $code preserves later work',
      () async {
        server.mode = 'card-$code';
        final id = await queue('linkAttachment');
        await queueEdit();
        await sync.run();
        await sync.run();
        expect(server.posts, 1);
        expect(server.commentPosts, 0);
        expect((await storedWrite(id)).state, 'confirmed');
        final pending = (await database.writesFor(account.id)).single;
        expect(pending.kind, 'createComment');
        expect(pending.state, 'blocked');
        expect(jsonDecode(pending.proposal)['message'], 'My later text');
        expect(
          (await database.stackView(
            account.id,
            1,
          )).single.cards.map((c) => c.id),
          [9],
        );
        expect(await database.boardView(account.id), hasLength(2));
      },
    );
  }

  test(
    'accepted attachment with revoked board cannot keep server cache',
    () async {
      server.mode = 'board-403';
      final id = await queue('linkAttachment');
      await queueEdit();
      await sync.run();
      expect((await storedWrite(id)).state, 'confirmed');
      expect(server.posts, 1);
      expect(await database.stackView(account.id, 1), isEmpty);
      expect((await database.boardView(account.id)).map((b) => b.id), [3]);
      final pending = (await database.writesFor(account.id)).single;
      expect(pending.state, 'blocked');
      expect(jsonDecode(pending.proposal)['message'], 'My later text');
    },
  );

  test(
    'accepted attachment follows the real card location after a move',
    () async {
      server.mode = 'moved';
      final id = await queue('linkAttachment');
      await sync.run();
      await sync.run();
      expect((await storedWrite(id)).state, 'confirmed');
      expect(server.posts, 1);
      expect(
        server.attachmentPaths,
        everyElement(endsWith('/boards/3/stacks/4/cards/8/attachments')),
      );
      final cached =
          (await database.select(database.storedAttachments).get()).single;
      expect(cached.boardId, 3);
      expect(
        (await database.stackView(account.id, 3)).single.cards.single.id,
        8,
      );
      expect(
        (await database.stackView(account.id, 1)).single.cards.map((c) => c.id),
        [9],
      );
    },
  );

  for (final code in [401, 503]) {
    test('read-back $code remains applied and retries only reading', () async {
      server.mode = 'read-$code';
      final id = await queue('linkAttachment');
      await sync.run();
      expect((await storedWrite(id)).state, 'applied');
      expect(await database.boardView(account.id), hasLength(2));
      server.mode = 'present';
      await sync.run();
      expect((await storedWrite(id)).state, 'confirmed');
      expect(server.posts, 1);
    });
  }
}

final class _Server {
  var mode = 'present';
  var accepted = false;
  var posts = 0;
  var commentPosts = 0;
  var description = 'Original';
  final attachmentPaths = <String>[];

  http.Response json(Object? value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (path.endsWith('/cloud/user')) {
      return json({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200},
          'data': {'id': 'user'},
        },
      });
    }
    if (request.method == 'POST' && path.endsWith('/comments')) {
      commentPosts++;
      return json({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200},
          'data': {
            'id': 20,
            'objectId': 8,
            'actorId': 'user',
            'actorType': 'users',
            'message': 'My later text',
            'creationDateTime': '2030-01-01T00:00:00Z',
          },
        },
      });
    }
    if (request.method == 'POST') {
      posts++;
      accepted = true;
      return path.endsWith('/attachments')
          ? json(attachment)
          : json({
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': {'id': 7},
              },
            });
    }
    if (path.endsWith('/boards/1') || path.endsWith('/boards/3')) {
      if (accepted && mode == 'board-403') return http.Response('', 403);
      final id = path.endsWith('/3') ? 3 : 1;
      return json(board(id, 'Board', edit: true).raw);
    }
    if (path.endsWith('/stacks/2') || path.endsWith('/stacks/4')) {
      final moved = accepted && mode == 'moved';
      return json({
        'id': moved ? 4 : 2,
        'boardId': moved ? 3 : 1,
        'title': 'Column',
        'order': 0,
        'cards': [],
      });
    }
    if (path.endsWith('/cards/8')) {
      if (accepted && (mode.startsWith('card-') || mode.startsWith('read-'))) {
        return http.Response(
          '{}',
          int.parse(mode.split('-').last),
          headers: {'content-type': 'application/json'},
        );
      }
      return json({
        ...cardJson(description: description),
        if (accepted && mode == 'moved') 'stackId': 4,
      });
    }
    if (path.endsWith('/attachments')) {
      attachmentPaths.add(path);
      if (mode == 'board-403') return http.Response('', 403);
      if (mode.startsWith('card-') || mode.startsWith('read-')) {
        return http.Response(
          '{}',
          int.parse(mode.split('-').last),
          headers: {'content-type': 'application/json'},
        );
      }
      return json(mode == 'missing' ? [] : [attachment]);
    }
    throw StateError('unexpected_request');
  }

  JsonObject get attachment => {
    'id': 7,
    'type': 'file',
    'cardId': 8,
    'data': 'report.txt',
    'deletedAt': 0,
    'lastModified': 10,
  };
}
