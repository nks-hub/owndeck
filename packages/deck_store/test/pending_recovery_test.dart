import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
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

JsonObject stackJson(int id, List<JsonObject> cards) => {
  'id': id,
  'boardId': 1,
  'title': 'Column $id',
  'order': id,
  'cards': cards,
};

JsonObject commentJson(int id, String message) => {
  'id': id,
  'objectId': 8,
  'message': message,
  'actorId': 'uid-1',
  'actorType': 'users',
  'creationDateTime': '2030-01-01T00:00:00Z',
};

void main() {
  late DeckDatabase db;
  late StoredAccount account;
  late DeckCard card;

  Future<void> seed(DeckDatabase database, {int cardStack = 2}) async {
    card = DeckCard.fromJson({...cardJson(), 'stackId': cardStack});
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stackJson(2, [if (cardStack == 2) card.raw])),
      DeckStack.fromJson(stackJson(3, [if (cardStack == 3) card.raw])),
    ], null);
  }

  DeckSync engine(
    Future<http.Response> Function(http.Request) callback, {
    DeckDatabase? database,
    StoredAccount? who,
    Future<AttachmentUploadSource> Function(String)? readUpload,
  }) => DeckSync(
    database ?? db,
    who ?? account,
    DeckClient(
      base: ServerBase.parse(account.server),
      loginName: account.loginName,
      appPassword: 'test-password',
      transport: MockClient(callback),
    ),
    readUpload: readUpload,
  );

  setUp(() async {
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'), userId: 'uid-1');
    await seed(db);
  });
  tearDown(() => db.close());

  test(
    'an applied write cannot be discarded and keeps its dependents (B59)',
    () async {
      await db.saveCardDraft(account, 1, 2, {'title': 'New'});
      final creation = (await db.writesFor(account.id)).single;
      await db.queueComment(
        account,
        1,
        2,
        -creation.sequence,
        'createComment',
        {'message': 'Hello'},
      );
      expect(await db.acquireLease(account, 'owner'), isTrue);
      expect(await db.startWrite(account, 'owner', creation.id), isTrue);
      await db.markApplied(account, 'owner', creation, {
        'boardId': 1,
        'stackId': 2,
        'cardId': 30,
        'acceptedCard': {...cardJson(id: 30), 'title': 'New'},
      });
      await expectLater(
        db.decideWrite(account.id, creation.id, discard: true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'already_applied',
          ),
        ),
      );
      final comment = (await db.writesFor(
        account.id,
      )).singleWhere((w) => w.kind == 'createComment');
      expect(comment.state, 'queued');
      expect(await db.dependencyUnavailable(comment), isFalse);
    },
  );

  test('an attachment follows a card that changed column (B61)', () async {
    await db.queueAttachment(account, 1, 2, 8, 'uploadAttachment', {
      'uploadId': 'upload',
      'name': 'file.txt',
      'mime': 'text/plain',
      'length': 3,
    });
    final uploaded = {
      'id': 7,
      'type': 'file',
      'cardId': 8,
      'data': 'file.txt',
      'lastModified': 10,
      'deletedAt': 0,
      'extendedData': {'filesize': 3},
    };
    final posts = <String>[];
    await engine(
      (request) async {
        final path = request.url.path;
        if (path.endsWith('/boards/1')) {
          return json(board(1, 'Board', edit: true).raw);
        }
        if (request.method == 'POST') {
          posts.add(path);
          return json(uploaded);
        }
        if (path.endsWith('/attachments')) return json([uploaded]);
        if (path.endsWith('/cards/8')) {
          return json({...cardJson(), 'stackId': 3});
        }
        if (path.endsWith('/stacks/3')) {
          return json(stackJson(3, [card.raw]));
        }
        throw StateError('unexpected_request ${request.url}');
      },
      readUpload: (_) async => AttachmentUploadSource(
        filename: 'file.txt',
        mime: 'text/plain',
        length: 3,
        bytes: Stream.value([1, 2, 3]),
      ),
    ).run();
    expect(posts.single, contains('/stacks/3/cards/8/attachments'));
    expect(await db.writesFor(account.id), isEmpty);
  });

  test('a colleague moving the card keeps queued comments (B63)', () async {
    await db.queueComment(account, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stackJson(2, [])),
      DeckStack.fromJson(
        stackJson(3, [
          {...cardJson(), 'stackId': 3},
        ]),
      ),
    ], null);
    final queued = (await db.writesFor(account.id)).single;
    expect(queued.state, 'queued');
    expect(queued.stackId, 3);
    var posts = 0;
    await engine((request) async {
      if (request.url.path.endsWith('/boards/1')) {
        return json(board(1, 'Board', edit: true).raw);
      }
      if (request.url.path.endsWith('/cloud/user')) return ocs({'id': 'uid-1'});
      posts++;
      return ocs(commentJson(10, 'Hello'));
    }).run();
    expect(posts, 1);
    expect(await db.writesFor(account.id), isEmpty);
  });

  test('a move inside the board keeps a queued edit (B63)', () async {
    await db.saveCardDraft(account, 1, 2, {
      'description': 'Local',
    }, original: card);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stackJson(2, [])),
      DeckStack.fromJson(
        stackJson(3, [
          {...cardJson(), 'stackId': 3},
        ]),
      ),
    ], null);
    final queued = (await db.writesFor(account.id)).single;
    expect(queued.state, 'queued');
    expect(queued.stackId, 3);
  });

  test('a lease left by a dead process does not block sending (B64)', () async {
    final dir = Directory.systemTemp.createTempSync('owndeck_lease');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/deck.sqlite');
    final first = DeckDatabase(NativeDatabase(file));
    final owner = await AccountRepository(
      first,
      MemoryVault(),
    ).add(credentials('user'), userId: 'uid-1');
    account = owner;
    await seed(first);
    await first.queueComment(owner, 1, 2, 8, 'createComment', {
      'message': 'Hello',
    });
    await first.queueComment(owner, 1, 2, 8, 'createComment', {
      'message': 'Lost',
    });
    final lost = (await first.writesFor(owner.id)).last;
    await (first.update(first.pendingWrites)
          ..where((w) => w.id.equals(lost.id)))
        .write(const PendingWritesCompanion(state: Value('sending')));
    await first
        .into(first.syncLeases)
        .insert(
          SyncLeasesCompanion.insert(
            accountId: owner.id,
            owner: 'dead',
            expires: DateTime.now().toUtc().add(const Duration(minutes: 2)),
          ),
        );
    await first.close();

    final second = DeckDatabase(NativeDatabase(file));
    addTearDown(second.close);
    var posts = 0;
    await engine(
      (request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return json(board(1, 'Board', edit: true).raw);
        }
        if (request.url.path.endsWith('/cloud/user')) {
          return ocs({'id': 'uid-1'});
        }
        posts++;
        return ocs(commentJson(10, 'Hello'));
      },
      database: second,
      who: (await second.accounts()).single,
    ).run();
    expect(posts, 1);
    final rest = await second.writesFor(owner.id);
    expect(rest.single.id, lost.id);
    expect(rest.single.state, 'uncertain');
  });

  test(
    'a stale move result requeues the move instead of leaving it sending (B65)',
    () async {
      await db.queueCardAction(account, 1, card, 'moveCard', {
        'stackId': 3,
        'order': 0,
      });
      await engine((request) async {
        final path = request.url.path;
        if (path.endsWith('/boards/1')) {
          return json(board(1, 'Board', edit: true).raw);
        }
        if (path.endsWith('/stacks/archived')) return json([]);
        if (path.endsWith('/stacks')) {
          await (db.update(db.storedAccounts)
                ..where((a) => a.id.equals(account.id)))
              .write(const StoredAccountsCompanion(contentEpoch: Value(9)));
          return json([stackJson(2, []), stackJson(3, [])]);
        }
        if (path.endsWith('/stacks/2')) return json(stackJson(2, [card.raw]));
        return json(card.raw);
      }).run();
      final write = (await db.writesFor(account.id)).single;
      expect(write.state, 'queued');
      expect(write.error, 'stale_response');
    },
  );

  test(
    'losing the lease before an attachment POST requeues it (B65)',
    () async {
      await db.queueAttachment(account, 1, 2, 8, 'linkAttachment', {
        'segments': ['Reports', 'file.txt'],
      });
      var posts = 0;
      await engine((request) async {
        final path = request.url.path;
        if (request.method == 'POST') posts++;
        if (path.endsWith('/boards/1')) {
          return json(board(1, 'Board', edit: true).raw);
        }
        if (path.endsWith('/cards/8')) {
          await db
              .into(db.syncLeases)
              .insertOnConflictUpdate(
                SyncLeasesCompanion.insert(
                  accountId: account.id,
                  owner: 'other',
                  expires: DateTime.now().toUtc().add(
                    const Duration(minutes: 2),
                  ),
                ),
              );
          return json(card.raw);
        }
        if (path.endsWith('/stacks/2')) return json(stackJson(2, [card.raw]));
        throw StateError('unexpected_request ${request.url}');
      }).run();
      expect(posts, 0);
      final write = (await db.writesFor(account.id)).single;
      expect(write.state, 'queued');
      expect(write.error, 'stale_response');
    },
  );
}
