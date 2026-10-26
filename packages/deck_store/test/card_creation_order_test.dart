import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

class _Fixture {
  final database = DeckDatabase(NativeDatabase.memory());
  final parent = board(1, 'Board', edit: true);
  final remote = <JsonObject>[
    {...cardJson(), 'title': 'Existing task', 'order': 1000},
  ];
  late StoredAccount account;
  late DeckSync sync;
  late MockClient transport;
  Future<void> Function()? beforeReadStack;
  int stackBoardId = 1;
  int posts = 0;
  int puts = 0;

  DeckStack column(List<JsonObject> cards) => DeckStack.fromJson({
    'id': 2,
    'boardId': stackBoardId,
    'title': 'Column',
    'order': 0,
    'cards': cards,
  });

  Future<void> initialize({int cachedOrder = 1000}) async {
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    await database.saveBoards(account.id, account.generation, [parent], null);
    await database.saveStacks(account.id, account.generation, 1, [
      column([
        {...remote.first, 'order': cachedOrder},
      ]),
    ], null);
    transport = MockClient(_respond);
    sync = DeckSync(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'user',
        appPassword: 'test-password',
        transport: transport,
      ),
    );
  }

  Future<String> create(String title, {int? order}) => database.saveCardDraft(
    account,
    1,
    2,
    {'title': title, 'order': ?order},
  );

  Future<List<DeckCard>> visible() async =>
      (await database.stackView(account.id, 1)).single.cards;

  Future<void> refresh() => database.saveStacks(
    account.id,
    account.generation,
    1,
    [column(remote)],
    null,
  );

  http.Response _reply(Object value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> _respond(http.Request request) async {
    final path = request.url.path;
    if (request.method == 'POST' && path.endsWith('/stacks/2/cards')) {
      posts++;
      final created = {
        ...cardJson(id: 8 + posts),
        ...object(jsonDecode(request.body)),
      };
      remote.add(created);
      return _reply(created);
    }
    if (request.method == 'PUT' && path.endsWith('/cards/8')) {
      puts++;
      remote[0] = {...remote.first, ...object(jsonDecode(request.body))};
      return _reply({
        'ocs': {
          'meta': {'status': 'ok', 'statuscode': 200},
          'data': remote.first,
        },
      });
    }
    if (request.method == 'GET') {
      if (path.endsWith('/boards/1')) return _reply(parent.raw);
      if (path.endsWith('/stacks/2')) {
        final before = beforeReadStack;
        beforeReadStack = null;
        await before?.call();
        return _reply(column(remote).raw);
      }
      if (path.endsWith('/stacks')) return _reply([column(remote).raw]);
      final cardId = int.tryParse(path.split('/').last);
      final card = remote.where((card) => card['id'] == cardId).firstOrNull;
      if (card != null && path.contains('/cards/')) return _reply(card);
    }
    throw StateError('Unexpected ${request.method} $path');
  }

  Future<void> close() async {
    sync.close();
    transport.close();
    await database.close();
  }
}

void main() {
  late _Fixture fixture;
  setUp(() => fixture = _Fixture());
  tearDown(() => fixture.close());

  for (final cachedOrder in [0, 1000]) {
    test(
      'new card stays last after syncing a column cached at $cachedOrder',
      () async {
        await fixture.initialize(cachedOrder: cachedOrder);
        await fixture.create('New task');
        expect((await fixture.visible()).map((c) => c.title), [
          'Existing task',
          'New task',
        ]);
        await fixture.sync.run();
        expect(fixture.posts, 1);
        expect(await fixture.database.writesFor(fixture.account.id), isEmpty);
        await fixture.refresh();
        expect((await fixture.visible()).map((c) => c.title), [
          'Existing task',
          'New task',
        ]);
      },
    );
  }

  test(
    'queued creates keep the same distinct order before and after sync',
    () async {
      await fixture.initialize();
      await fixture.create('First new task');
      await fixture.create('Second new task');
      expect((await fixture.visible()).map((c) => c.order), [1000, 1001, 1002]);
      await fixture.sync.run();
      expect(fixture.posts, 2);
      await fixture.refresh();
      expect((await fixture.visible()).map((c) => c.order), [1000, 1001, 1002]);
    },
  );

  for (final update in [false, true]) {
    test(
      '${update ? 'update' : 'create'} cannot resume after another worker recovered and discarded it',
      () async {
        await fixture.initialize();
        final write = update
            ? await fixture.database.saveCardDraft(fixture.account, 1, 2, {
                'title': 'Changed title',
              }, original: DeckCard.fromJson(fixture.remote.first))
            : await fixture.create('New task');
        fixture.beforeReadStack = () async {
          await fixture.database
              .update(fixture.database.syncLeases)
              .write(SyncLeasesCompanion(expires: Value(DateTime.utc(2000))));
          expect(
            await fixture.database.acquireLease(
              fixture.account,
              'other-worker',
            ),
            isTrue,
          );
          await fixture.database.recoverWrites(fixture.account, 'other-worker');
          await fixture.database.decideWrite(
            fixture.account.id,
            write,
            discard: true,
          );
          await fixture.database.releaseLease(
            fixture.account.id,
            'other-worker',
          );
        };
        await fixture.sync.run();
        expect(fixture.posts, 0);
        expect(fixture.puts, 0);
        expect(await fixture.database.writesFor(fixture.account.id), isEmpty);
        expect(fixture.remote.single['title'], 'Existing task');
      },
    );
  }

  test('failed preflight remains queued without any POST', () async {
    await fixture.initialize();
    await fixture.create('New task');
    fixture.beforeReadStack = () async => throw http.ClientException('offline');
    await expectLater(fixture.sync.run(), throwsA(isA<DeckException>()));
    expect(fixture.posts, 0);
    expect(
      (await fixture.database.writesFor(fixture.account.id)).single.state,
      'queued',
    );
  });

  test(
    'a stack belonging to another board blocks creation before POST',
    () async {
      await fixture.initialize();
      await fixture.create('New task');
      fixture.stackBoardId = 7;
      await fixture.sync.run();
      expect(fixture.posts, 0);
      final write = (await fixture.database.writesFor(
        fixture.account.id,
      )).single;
      expect(write.state, 'blocked');
      expect(write.error, 'invalid_destination');
    },
  );

  test('an explicit nondefault order is preserved', () async {
    await fixture.initialize();
    await fixture.create('Positioned task', order: 2);
    await fixture.sync.run();
    expect(fixture.posts, 1);
    expect(fixture.remote.last['order'], 2);
  });
}
