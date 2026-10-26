import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

http.Response reply(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  late DeckDatabase db;
  late StoredAccount account;
  late DeckCard card;
  setUp(() async {
    db = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(
      db,
      MemoryVault(),
    ).add(credentials('user'));
    card = DeckCard.fromJson(cardJson());
    await db.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Todo',
        'order': 0,
        'cards': [card.raw],
      }),
      DeckStack.fromJson({
        'id': 3,
        'boardId': 1,
        'title': 'Doing',
        'order': 1,
        'cards': [],
      }),
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
          transport: MockClient((request) async {
            final path = request.url.pathSegments;
            if (request.method == 'GET' &&
                path[path.length - 2] == 'stacks' &&
                int.tryParse(path.last) != null) {
              final id = int.parse(path.last);
              expect([2, 3], contains(id));
              return reply({
                'id': id,
                'boardId': 1,
                'title': 'Column',
                'order': id - 2,
                'cards': [],
              });
            }
            return callback(request);
          }),
        ),
      );

  test(
    'pending move positions count active cards without moving archived cards',
    () async {
      await db.saveStacks(account.id, account.generation, 1, [
        DeckStack.fromJson({
          'id': 2,
          'boardId': 1,
          'title': 'Source',
          'order': 0,
          'cards': [card.raw],
        }),
        DeckStack.fromJson({
          'id': 3,
          'boardId': 1,
          'title': 'Target',
          'order': 1,
          'cards': [
            {...cardJson(id: 9), 'stackId': 3, 'archived': true, 'order': 0},
            {...cardJson(id: 10), 'stackId': 3, 'order': 0},
            {...cardJson(id: 11), 'stackId': 3, 'order': 1},
          ],
        }),
      ], null);
      await db.queueCardAction(account, 1, card, 'moveCard', {
        'stackId': 3,
        'order': 1,
      });
      final target = (await db.stackView(account.id, 1)).last;
      final active = target.cards.where((item) => !item.archived);
      expect(active.map((item) => item.id), [10, 8, 11]);
      expect(active.map((item) => item.order), [0, 1, 2]);
      expect(target.cards.singleWhere((item) => item.id == 9).order, 0);
    },
  );

  test(
    'move uses the OCS destination scope and confirms complete stack order',
    () async {
      await db.queueCardAction(account, 1, card, 'moveCard', {
        'stackId': 3,
        'order': 0,
      });
      var moved = false;
      String? mutationPath;
      JsonObject? sent;
      await engine((request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return reply(board(1, 'Board', edit: true).raw);
        }
        if (request.method == 'PUT') {
          mutationPath = request.url.path;
          sent = object(jsonDecode(request.body));
          moved = true;
          return reply({
            'ocs': {
              'meta': {'status': 'ok', 'statuscode': 200},
              'data': [
                {...card.raw, 'stackId': 3},
              ],
            },
          });
        }
        if (request.url.path.endsWith('/stacks/archived')) return reply([]);
        if (request.url.path.endsWith('/stacks')) {
          return reply([
            {
              'id': 2,
              'boardId': 1,
              'title': 'Todo',
              'order': 0,
              'cards': moved ? [] : [card.raw],
            },
            {
              'id': 3,
              'boardId': 1,
              'title': 'Doing',
              'order': 1,
              'cards': moved
                  ? [
                      {...card.raw, 'stackId': 3},
                    ]
                  : [],
            },
          ]);
        }
        return reply({...card.raw, 'stackId': moved ? 3 : 2});
      }).run();
      expect(
        mutationPath,
        '/nextcloud/ocs/v2.php/apps/deck/api/v1.0/cards/8/reorder',
      );
      expect(sent, {'boardId': 1, 'stackId': 3, 'order': 0});
      expect(await db.writesFor(account.id), isEmpty);
      final stacks = await db.stackView(account.id, 1);
      expect(stacks.first.cards, isEmpty);
      expect(stacks.last.cards.single.id, 8);
    },
  );

  test(
    'read-back failure after accepted label assignment retries only GET',
    () async {
      final label = {'id': 5, 'title': 'Work', 'color': '008080'};
      await db.queueCardAction(account, 1, card, 'assignLabel', {
        'labelId': 5,
        'label': label,
      });
      var mutations = 0;
      var failReadback = true;
      final sync = engine((request) async {
        if (request.url.path.endsWith('/boards/1')) {
          return reply(board(1, 'Board', edit: true).raw);
        }
        if (request.method == 'PUT') {
          mutations++;
          return reply(card.raw);
        }
        if (mutations > 0 && failReadback) {
          throw http.ClientException('offline');
        }
        return reply({
          ...card.raw,
          'labels': mutations > 0 ? [label] : [],
        });
      });
      await sync.run();
      final applied = (await db.writesFor(account.id)).single;
      expect(applied.state, 'applied');
      await expectLater(
        db.decideWrite(account.id, applied.id, discard: false),
        throwsStateError,
      );
      failReadback = false;
      await sync.run();
      expect(mutations, 1);
      expect(await db.writesFor(account.id), isEmpty);
      expect((await db.watchCard(account.id, 1, 8).first)!.raw['labels'], [
        label,
      ]);
    },
  );

  test(
    'unresolved earlier edit prevents a later move of the same card',
    () async {
      await db.saveCardDraft(account, 1, 2, {
        'description': 'Local',
      }, original: card);
      await db.queueCardAction(account, 1, card, 'moveCard', {
        'stackId': 3,
        'order': 0,
      });
      var mutations = 0;
      await engine((request) async {
        if (request.method != 'GET') mutations++;
        return reply(
          request.url.path.endsWith('/boards/1')
              ? board(1, 'Board', edit: true).raw
              : cardJson(description: 'Remote'),
        );
      }).run();
      expect((await db.writesFor(account.id)).map((w) => w.state).toList(), [
        'conflict',
        'queued',
      ]);
      expect(mutations, 0);
    },
  );

  test('assignment entity response does not replace the cached card', () async {
    final user = {'uid': 'other', 'displayname': 'Other user'};
    await db.queueCardAction(account, 1, card, 'assignUser', {
      'userId': 'other',
      'type': 0,
      'user': user,
    });
    var assigned = false;
    await engine((request) async {
      if (request.url.path.endsWith('/boards/1')) {
        return reply(board(1, 'Board', edit: true).raw);
      }
      if (request.method == 'PUT') {
        assigned = true;
        return reply({'id': 99, 'cardId': 8, 'participant': user, 'type': 0});
      }
      return reply({
        ...card.raw,
        'assignedUsers': assigned
            ? [
                {'participant': user, 'type': 0},
              ]
            : [],
      });
    }).run();
    expect(await db.writesFor(account.id), isEmpty);
    final actual = (await db.watchCard(account.id, 1, 8).first)!;
    expect(actual.id, 8);
    expect(actual.title, 'Task');
    expect(actual.raw['assignedUsers'], [
      {'participant': user, 'type': 0},
    ]);
  });

  test('group and team assignments send their participant type', () async {
    final group = {'uid': 'alice', 'displayname': 'Team group'};
    for (final type in [1, 7]) {
      await db.queueCardAction(account, 1, card, 'assignUser', {
        'userId': 'alice',
        'type': type,
        'user': group,
      });
    }
    final bodies = <Object?>[];
    await engine((request) async {
      if (request.url.path.endsWith('/boards/1')) {
        return reply(board(1, 'Board', edit: true).raw);
      }
      if (request.method == 'PUT') {
        expect(request.url.path, endsWith('/cards/8/assignUser'));
        bodies.add(jsonDecode(request.body));
        return reply({'id': 99, 'cardId': 8, 'participant': group});
      }
      return reply(card.raw);
    }).run();
    expect(bodies, [
      {'userId': 'alice', 'type': 1},
      {'userId': 'alice', 'type': 7},
    ]);
    expect(await db.writesFor(account.id), isEmpty);
  });

  test('deletion pauses when another client changed the description', () async {
    await db.queueCardAction(account, 1, card, 'deleteCard', {});
    var deletes = 0;
    await engine((request) async {
      if (request.method == 'DELETE') deletes++;
      return reply(
        request.url.path.endsWith('/boards/1')
            ? board(1, 'Board', edit: true).raw
            : cardJson(description: 'Changed elsewhere'),
      );
    }).run();
    expect((await db.writesFor(account.id)).single.state, 'conflict');
    expect(deletes, 0);
  });
}
