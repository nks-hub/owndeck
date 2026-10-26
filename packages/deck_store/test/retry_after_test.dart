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

void main() {
  late DeckDatabase database;
  late StoredAccount account;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
    await database.saveCardDraft(account, 1, 2, {'title': 'Deferred'});
  });
  tearDown(() => database.close());

  test(
    'persisting a deadline rounds up instead of shortening the server pause',
    () async {
      final until = DateTime.utc(2030, 1, 1, 12, 0, 0, 0, 900);
      await database.deferSync(account, until);
      expect(
        (await database.account(account.id))!.syncNotBefore!.toUtc(),
        DateTime.utc(2030, 1, 1, 12, 0, 1),
      );
    },
  );

  test(
    'the pause and queued card survive closing and reopening the database',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'owndeck-backoff-test-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final path = File('${folder.path}/store.sqlite');
      final original = DeckDatabase(NativeDatabase(path));
      late StoredAccount stored;
      try {
        stored = await AccountRepository(
          original,
          MemoryVault(),
        ).add(credentials('disk-user'));
        await original.saveBoards(stored.id, stored.generation, [
          board(1, 'Board', edit: true),
        ], null);
        await original.saveCardDraft(stored, 1, 2, {'title': 'Pending'});
        await original.deferSync(
          stored,
          DateTime.now().add(const Duration(minutes: 2)),
        );
      } finally {
        await original.close();
      }
      final reopened = DeckDatabase(NativeDatabase(path));
      try {
        final restored = (await reopened.account(stored.id))!;
        var requests = 0;
        final client = DeckClient(
          base: ServerBase.parse(restored.server),
          loginName: restored.loginName,
          appPassword: 'test-password',
          transport: MockClient((_) async {
            requests++;
            return http.Response('', 500);
          }),
        );
        await DeckSync(reopened, restored, client).run();
        expect(requests, 0);
        expect((await reopened.writesFor(stored.id)).single.state, 'queued');
        expect(restored.syncNotBefore!.isAfter(DateTime.now()), isTrue);
      } finally {
        await reopened.close();
      }
    },
  );

  DeckSync sync(http.Client transport) => DeckSync(
    database,
    account,
    DeckClient(
      base: ServerBase.parse(account.server),
      loginName: account.loginName,
      appPassword: 'test-password',
      transport: transport,
    ),
  );
  http.Response json(Object data) => http.Response(
    jsonEncode(data),
    200,
    headers: {'content-type': 'application/json'},
  );
  http.Response readFixture(http.Request request) {
    if (request.url.path.endsWith('/boards/1')) {
      return json(board(1, 'Board', edit: true).raw);
    }
    if (request.url.path.endsWith('/stacks/2')) {
      return json({
        'id': 2,
        'boardId': 1,
        'title': 'Todo',
        'order': 0,
        'cards': [],
      });
    }
    throw StateError('Unexpected read: ${request.url.path}');
  }

  test(
    '429 preserves the queue and its pause survives a new sync instance',
    () async {
      var posts = 0;
      await expectLater(
        sync(
          MockClient((request) async {
            if (request.method == 'GET') {
              return readFixture(request);
            }
            posts++;
            return http.Response('', 429, headers: {'retry-after': '120'});
          }),
        ).run(),
        throwsA(isA<DeckException>()),
      );
      expect(posts, 1);
      expect((await database.writesFor(account.id)).single.state, 'queued');
      expect(
        (await database.account(
          account.id,
        ))!.syncNotBefore!.isAfter(DateTime.now()),
        isTrue,
      );

      var requests = 0;
      await sync(
        MockClient((_) async {
          requests++;
          return http.Response('', 500);
        }),
      ).run();
      expect(requests, 0);

      await (database.update(
        database.storedAccounts,
      )..where((a) => a.id.equals(account.id))).write(
        StoredAccountsCompanion(
          syncNotBefore: Value(
            DateTime.now().subtract(const Duration(seconds: 1)),
          ),
        ),
      );
      await sync(
        MockClient((request) async {
          if (request.method == 'GET') {
            if (request.url.path.endsWith('/cards/9')) {
              return json(cardJson(id: 9));
            }
            return readFixture(request);
          }
          posts++;
          return json(cardJson(id: 9));
        }),
      ).run();
      expect(posts, 2);
      expect(await database.writesFor(account.id), isEmpty);
    },
  );

  test(
    '503 before a mutation defers without changing the queued draft',
    () async {
      await expectLater(
        sync(
          MockClient((request) async {
            expect(request.method, 'GET');
            return http.Response('', 503, headers: {'retry-after': '120'});
          }),
        ).run(),
        throwsA(isA<DeckException>()),
      );
      expect((await database.writesFor(account.id)).single.state, 'queued');
      expect((await database.account(account.id))!.syncNotBefore, isNotNull);
    },
  );

  test(
    '503 after a POST is never converted into an automatically retryable write',
    () async {
      var posts = 0;
      await sync(
        MockClient((request) async {
          if (request.method == 'GET') {
            return readFixture(request);
          }
          posts++;
          return http.Response('', 503, headers: {'retry-after': '120'});
        }),
      ).run();
      expect((await database.writesFor(account.id)).single.state, 'uncertain');
      expect((await database.account(account.id))!.syncNotBefore, isNotNull);
      await sync(
        MockClient((_) async {
          posts++;
          return http.Response('', 500);
        }),
      ).run();
      expect(posts, 1);
    },
  );
}
