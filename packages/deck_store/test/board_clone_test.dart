import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

const _options = BoardCloneOptions(
  withCards: true,
  withLabels: true,
  withDueDate: true,
);
const _proposal = {
  'title': 'Source',
  'withCards': true,
  'withAssignments': false,
  'withLabels': true,
  'withDueDate': true,
  'moveCardsToLeftStack': false,
  'restoreArchivedCards': false,
};

http.Response _json(Object? value, {int status = 200}) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _capabilities({String version = '1.19.1', bool create = true}) =>
    _json({
      'ocs': {
        'meta': {'status': 'ok', 'statuscode': 200},
        'data': {
          'capabilities': {
            'deck': {
              'version': version,
              'apiVersions': ['1.1'],
              'canCreateBoards': create,
            },
          },
        },
      },
    });

void main() {
  late DeckDatabase db;
  late StoredAccount account;
  late DeckBoard source;
  late DeckBoard created;
  late List<http.Request> requests;

  Future<void> capabilities({String version = '1.19.1', bool create = true}) =>
      db.saveCapabilities(
        account,
        DeckCapabilities(
          version: version,
          apiVersion: '1.1',
          canCreateBoards: create,
        ),
      );

  setUp(() async {
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'));
    source = board(1, 'Source');
    created = board(20, 'Read back copy', edit: true);
    requests = [];
    await capabilities();
    await db.saveBoards(account.id, account.generation, [source], null);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [cardJson()],
      }),
    ], null);
  });
  tearDown(() => db.close());

  DeckSync engine({Future<http.Response> Function(http.Request)? override}) {
    final transport = MockClient((request) async {
      requests.add(request);
      if (override != null) return override(request);
      if (request.url.path.endsWith('/capabilities')) return _capabilities();
      if (request.method == 'POST') {
        expect(request.url.path, endsWith('/boards/1/clone'));
        return _json({...created.raw, 'title': 'Accepted copy'});
      }
      if (request.url.path.endsWith('/boards/1')) return _json(source.raw);
      if (request.url.path.endsWith('/boards/20')) return _json(created.raw);
      throw StateError('unexpected_request');
    });
    final sync = DeckSync(
      db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: transport,
      ),
    );
    addTearDown(() {
      sync.close();
      transport.close();
    });
    return sync;
  }

  Future<PendingWrite> cloneWrite() => (db.select(
    db.pendingWrites,
  )..where((row) => row.kind.equals('boardClone'))).getSingle();

  Future<void> sourceUnchanged() async {
    final boards = await db.boardView(account.id);
    expect(boards.singleWhere((item) => item.id == 1).raw, source.raw);
    final card = (await db.stackView(account.id, 1)).single.cards.single;
    expect(card.id, 8);
    expect(card.description, 'Original');
    expect(
      requests.where((r) => r.method == 'PUT' || r.method == 'DELETE'),
      isEmpty,
    );
  }

  test('read-only source clones without updating the original board', () async {
    expect(source.permissions.edit, isFalse);
    expect(source.permissions.manage, isFalse);
    await db.queueBoardClone(account, 1, _options);
    final queued = await cloneWrite();
    expect(queued.kind, 'boardClone');
    expect(queued.state, 'queued');
    expect(jsonDecode(queued.proposal), _proposal);
    expect((await db.boardView(account.id)).map((b) => b.id), [1]);
    await engine().run();
    final confirmed = await cloneWrite();
    expect(confirmed.state, 'confirmed');
    expect(jsonDecode(confirmed.proposal), _proposal);
    expect(await db.writesFor(account.id), isEmpty);
    final copied = (await db.boardView(
      account.id,
    )).singleWhere((b) => b.id == 20);
    expect(copied.title, 'Read back copy');
    final mutations = requests.where((r) => r.method != 'GET').toList();
    expect(mutations.length, 1);
    expect(mutations.single.method, 'POST');
    expect(mutations.single.url.path, endsWith('/api/v1.1/boards/1/clone'));
    expect(jsonDecode(mutations.single.body), {..._proposal}..remove('title'));
    await sourceUnchanged();
  });

  test(
    'accepted receipt is persisted before GET and retries only GET',
    () async {
      await db.queueBoardClone(account, 1, _options);
      var readable = false;
      var sawApplied = false;
      final first = engine(
        override: (request) async {
          if (request.url.path.endsWith('/capabilities')) {
            return _capabilities();
          }
          if (request.method == 'POST') return _json(created.raw);
          if (request.url.path.endsWith('/boards/1')) return _json(source.raw);
          expect(request.url.path, endsWith('/boards/20'));
          final receipt = await cloneWrite();
          expect(receipt.state, 'applied');
          expect(
            object(object(jsonDecode(receipt.remote!))['createdBoard'])['id'],
            20,
          );
          sawApplied = true;
          return readable ? _json(created.raw) : http.Response('', 503);
        },
      );
      await first.run();
      expect(sawApplied, isTrue);
      expect((await cloneWrite()).state, 'applied');
      expect(jsonDecode((await cloneWrite()).proposal), _proposal);
      expect((await db.boardView(account.id)).map((b) => b.id), [1]);
      final checkpoint = requests.length;
      readable = true;
      await engine().run();
      expect((await cloneWrite()).state, 'confirmed');
      expect(requests.where((r) => r.method == 'POST').length, 1);
      expect(
        requests.skip(checkpoint).map((r) => '${r.method} ${r.url.path}'),
        ['GET /nextcloud/index.php/apps/deck/api/v1.1/boards/20'],
      );
      await sourceUnchanged();
    },
  );

  test(
    'lost POST response stays uncertain with the original proposal',
    () async {
      await db.queueBoardClone(account, 1, _options);
      final sync = engine(
        override: (request) async {
          if (request.url.path.endsWith('/capabilities')) {
            return _capabilities();
          }
          if (request.method == 'POST') {
            throw http.ClientException('lost_response');
          }
          return _json(source.raw);
        },
      );
      await sync.run();
      await sync.run();
      final write = await cloneWrite();
      expect(write.state, 'uncertain');
      expect(jsonDecode(write.proposal), _proposal);
      expect(requests.where((r) => r.method == 'POST').length, 1);
      expect((await db.boardView(account.id)).map((b) => b.id), [1]);
      await sourceUnchanged();
    },
  );

  for (final version in ['1.18.5', 'unknown']) {
    test('local version $version cannot queue a board clone', () async {
      await capabilities(version: version);
      await expectLater(
        db.queueBoardClone(account, 1, _options),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'reason',
            'unsupported_operation',
          ),
        ),
      );
      expect(await db.writesFor(account.id), isEmpty);
      await sourceUnchanged();
    });
  }

  test('local canCreateBoards denial cannot queue a clone', () async {
    await capabilities(create: false);
    await expectLater(
      db.queueBoardClone(account, 1, _options),
      throwsStateError,
    );
    expect(await db.writesFor(account.id), isEmpty);
    await sourceUnchanged();
  });

  test('local source read denial cannot queue a clone', () async {
    await db.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        ...source.raw,
        'permissions': {'PERMISSION_READ': false},
      }),
    ], null);
    await expectLater(
      db.queueBoardClone(account, 1, _options),
      throwsStateError,
    );
    expect(await db.writesFor(account.id), isEmpty);
  });

  for (final denial in ['version', 'create', 'source']) {
    test(
      'fresh $denial denial prevents POST and retains the proposal',
      () async {
        await db.queueBoardClone(account, 1, _options);
        await engine(
          override: (request) async {
            if (request.url.path.endsWith('/capabilities')) {
              return _capabilities(
                version: denial == 'version' ? '1.18.5' : '1.19.1',
                create: denial != 'create',
              );
            }
            return _json({
              ...source.raw,
              'permissions': {'PERMISSION_READ': false},
            });
          },
        ).run();
        expect(requests.every((r) => r.method == 'GET'), isTrue);
        final write = await cloneWrite();
        expect(write.state, 'blocked');
        expect(jsonDecode(write.proposal), _proposal);
        if (denial != 'source') await sourceUnchanged();
      },
    );
  }

  test(
    'source pending work blocks cloning without replacing that work',
    () async {
      await db.saveBoards(account.id, account.generation, [
        board(1, 'Source', edit: true),
      ], null);
      await db.saveCardDraft(account, 1, 2, {'title': 'Unsent source work'});
      await expectLater(
        db.queueBoardClone(account, 1, _options),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'reason',
            'pending_decision',
          ),
        ),
      );
      final writes = await db.writesFor(account.id);
      expect(writes.length, 1);
      expect(writes.single.kind, 'createCard');
      expect(
        object(jsonDecode(writes.single.proposal))['title'],
        'Unsent source work',
      );
    },
  );

  test(
    'pending work on another board does not block cloning the source',
    () async {
      await db.saveBoards(account.id, account.generation, [
        source,
        board(3, 'Other', edit: true),
      ], null);
      await db.saveCardDraft(account, 3, 4, {'title': 'Other pending work'});
      await db.queueBoardClone(account, 1, _options);
      expect((await cloneWrite()).state, 'queued');
      expect((await db.writesFor(account.id)).map((w) => w.kind), [
        'createCard',
        'boardClone',
      ]);
    },
  );

  for (final status in [403, 404]) {
    test(
      'post-ack $status confirms without caching or touching the source',
      () async {
        await db.queueBoardClone(account, 1, _options);
        final sync = engine(
          override: (request) async {
            if (request.url.path.endsWith('/capabilities')) {
              return _capabilities();
            }
            if (request.method == 'POST') return _json(created.raw);
            if (request.url.path.endsWith('/boards/1')) {
              return _json(source.raw);
            }
            return http.Response('', status);
          },
        );
        await sync.run();
        await sync.run();
        final write = await cloneWrite();
        expect(write.state, 'confirmed');
        expect(jsonDecode(write.proposal), _proposal);
        expect(await db.writesFor(account.id), isEmpty);
        expect((await db.boardView(account.id)).map((b) => b.id), [1]);
        expect(requests.where((r) => r.method == 'POST').length, 1);
        await sourceUnchanged();
      },
    );
  }

  test(
    'stale readback epoch cannot import a copy or replay its POST',
    () async {
      await db.queueBoardClone(account, 1, _options);
      var invalidate = true;
      final sync = engine(
        override: (request) async {
          if (request.url.path.endsWith('/capabilities')) {
            return _capabilities();
          }
          if (request.method == 'POST') return _json(created.raw);
          if (request.url.path.endsWith('/boards/1')) return _json(source.raw);
          if (invalidate) {
            invalidate = false;
            await db.invalidateMutation(account.id, 1);
          }
          return _json(created.raw);
        },
      );
      await sync.run();
      expect((await cloneWrite()).state, 'applied');
      expect(jsonDecode((await cloneWrite()).proposal), _proposal);
      expect((await db.boardView(account.id)).map((b) => b.id), [1]);
      await sync.run();
      expect((await cloneWrite()).state, 'confirmed');
      expect(requests.where((r) => r.method == 'POST').length, 1);
      expect(
        (await db.boardView(account.id)).map((b) => b.id),
        containsAll([1, 20]),
      );
      await sourceUnchanged();
    },
  );
}
