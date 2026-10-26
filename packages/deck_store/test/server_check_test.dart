import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

http.Response json(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response ocs(Object? data) => json({
  'ocs': {
    'meta': {'status': 'ok', 'statuscode': 200},
    'data': data,
  },
});

const future = 4000000000;

void main() {
  late DeckDatabase db;
  late StoredAccount account;
  late DeckSync sync;
  late List<JsonObject> serverCards;
  late List<JsonObject> serverComments;
  late List<JsonObject> serverAttachments;

  JsonObject stack() => {
    'id': 2,
    'boardId': 1,
    'title': 'Column',
    'order': 0,
    'cards': serverCards,
  };

  Future<http.Response> server(http.Request request) async {
    final path = request.url.path;
    if (path.endsWith('/boards/1')) {
      return json(board(1, 'Board', edit: true).raw);
    }
    if (path.endsWith('/cloud/user')) return ocs({'id': 'uid-1'});
    if (request.method == 'POST') throw http.ClientException('lost_response');
    if (path.endsWith('/comments')) return ocs(serverComments);
    if (path.endsWith('/attachments')) return json(serverAttachments);
    if (path.endsWith('/stacks/2')) return json(stack());
    final card = serverCards
        .where((c) => path.endsWith('/cards/${c['id']}'))
        .firstOrNull;
    if (card != null) return json(card);
    throw StateError('unexpected_request ${request.url}');
  }

  setUp(() async {
    serverCards = [];
    serverComments = [];
    serverAttachments = [];
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'), userId: 'uid-1');
    await db.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({...stack(), 'cards': <JsonObject>[]}),
    ], null);
    sync = DeckSync(
      db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient(server),
      ),
      readUpload: (_) async => AttachmentUploadSource(
        filename: 'file.txt',
        mime: 'text/plain',
        length: 3,
        bytes: Stream.value([1, 2, 3]),
      ),
    );
  });
  tearDown(() => db.close());

  Future<void> sendLost() async {
    await sync.run();
    final write = (await db.writesFor(account.id)).single;
    expect(write.state, 'uncertain');
    expect(write.sentAt, isNotNull);
  }

  Future<void> expectMatched() async {
    expect(
      await sync.checkServer((await db.writesFor(account.id)).single.id),
      isTrue,
    );
    expect(await db.writesFor(account.id), isEmpty);
  }

  Future<void> expectMissing() async {
    final id = (await db.writesFor(account.id)).single.id;
    expect(await sync.checkServer(id), isFalse);
    expect((await db.writesFor(account.id)).single.state, 'uncertain');
  }

  JsonObject comment(int createdYear) => {
    'id': 50,
    'objectId': 8,
    'message': 'Hello',
    'actorId': 'uid-1',
    'actorType': 'users',
    'creationDateTime': '$createdYear-01-01T00:00:00Z',
  };

  group('comment', () {
    setUp(() async {
      await db.queueComment(account, 1, 2, 8, 'createComment', {
        'message': 'Hello',
      });
      await sendLost();
      serverCards = [cardJson()];
    });
    test('found on the server is confirmed', () async {
      serverComments = [comment(2999)];
      await expectMatched();
      expect((await db.watchComments(account.id, 8).first).single.id, 50);
    });
    test('not found stays uncertain', () async {
      serverComments = [comment(2000)];
      await expectMissing();
    });
  });

  group('card creation', () {
    JsonObject created(int createdAt, {String title = 'New'}) => {
      ...cardJson(id: 30),
      'title': title,
      'createdAt': createdAt,
    };
    setUp(() async {
      await db.saveCardDraft(account, 1, 2, {'title': 'New'});
      await sendLost();
    });
    test('found in the column is confirmed', () async {
      serverCards = [created(future)];
      await expectMatched();
    });
    test('an older card with the same title is not a match', () async {
      serverCards = [created(1000)];
      await expectMissing();
    });
    test('another title is not a match', () async {
      serverCards = [created(future, title: 'Other')];
      await expectMissing();
    });
  });

  group('attachments', () {
    JsonObject item({int size = 3, int createdAt = future}) => {
      'id': 7,
      'type': 'file',
      'cardId': 8,
      'data': 'file.txt',
      'lastModified': 10,
      'createdAt': createdAt,
      'deletedAt': 0,
      'extendedData': {'filesize': size},
    };
    setUp(() => serverCards = [cardJson()]);
    test('upload with the same name and size is confirmed', () async {
      await db.queueAttachment(account, 1, 2, 8, 'uploadAttachment', {
        'uploadId': 'upload',
        'name': 'file.txt',
        'mime': 'text/plain',
        'length': 3,
      });
      await sendLost();
      serverAttachments = [item()];
      await expectMatched();
      expect((await db.watchAttachments(account.id, 8).first).single.id, 7);
    });
    test('upload of another size is not a match', () async {
      await db.queueAttachment(account, 1, 2, 8, 'uploadAttachment', {
        'uploadId': 'upload',
        'name': 'file.txt',
        'mime': 'text/plain',
        'length': 3,
      });
      await sendLost();
      serverAttachments = [item(size: 4)];
      await expectMissing();
    });
    test('link with the same name is confirmed', () async {
      await db.queueAttachment(account, 1, 2, 8, 'linkAttachment', {
        'segments': ['Reports', 'file.txt'],
        'name': 'file.txt',
      });
      await sendLost();
      serverAttachments = [item()];
      await expectMatched();
    });
    test('link older than the send is not a match', () async {
      await db.queueAttachment(account, 1, 2, 8, 'linkAttachment', {
        'segments': ['Reports', 'file.txt'],
        'name': 'file.txt',
      });
      await sendLost();
      serverAttachments = [item(createdAt: 1000)];
      await expectMissing();
    });
  });

  test('only creating POSTs carry the duplicate warning', () {
    for (final kind in ['createCard', 'createComment', 'uploadAttachment']) {
      expect(duplicateRiskKinds, contains(kind));
    }
    for (final kind in [
      'updateCard',
      'moveCard',
      'stackReorder',
      'deleteCard',
    ]) {
      expect(duplicateRiskKinds, isNot(contains(kind)));
    }
  });
}
