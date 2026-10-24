import 'dart:convert';

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

  test(
    '429 preserves the queue and its pause survives a new sync instance',
    () async {
      var posts = 0;
      await expectLater(
        sync(
          MockClient((request) async {
            if (request.method == 'GET') {
              return json(board(1, 'Board', edit: true).raw);
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
            return json(board(1, 'Board', edit: true).raw);
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
            return json(board(1, 'Board', edit: true).raw);
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
