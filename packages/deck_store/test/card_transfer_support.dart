import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixtures.dart';

JsonObject richCard(int id, int stackId, int order) => {
  ...cardJson(id: id),
  'stackId': stackId,
  'order': order,
  'owner': 'owner',
  'title': 'Card $id',
  'deletedAt': 0,
  'startdate': '2030-01-01T10:00:00Z',
  'duedate': '2030-01-02T12:00:00Z',
  'color': '336699',
  'done': null,
  'labels': <JsonObject>[],
  'assignedUsers': [
    {
      'participant': {'uid': 'user'},
      'type': 0,
    },
  ],
  'commentsCount': 2,
  'attachmentCount': 1,
  'dependentCards': [99],
};

final class TransferServer {
  final cards = <int, JsonObject>{
    8: richCard(8, 2, 0),
    9: richCard(9, 4, 0),
    10: richCard(10, 4, 1),
  };
  final labels = <int, List<JsonObject>>{
    1: [
      {'id': 5, 'title': 'Common', 'color': '008080'},
      {'id': 6, 'title': 'Source only', 'color': '336699'},
    ],
    3: [
      {'id': 50, 'title': 'Common', 'color': '008080'},
      {'id': 51, 'title': 'Other', 'color': 'ff8800'},
    ],
  };
  final stackBoards = <int, int>{2: 1, 4: 3, 6: 3};
  var sourceRead = true,
      sourceEdit = true,
      targetRead = true,
      targetEdit = true,
      targetManage = true;
  var sourceDone = false,
      targetDone = false,
      sourceExternal = false,
      targetExternal = false;
  var failTransferRead = false,
      failPositionRead = false,
      loseTransferResponse = false,
      losePositionResponse = false;
  var malformedTarget = false, badTransferReceipt = false;
  var transfers = 0,
      positions = 0,
      crossBoardReorders = 0,
      comments = 0,
      createdCards = 0;
  var nextCard = 20, nextBoard = 5, nextStack = 7, nextLabel = 52;
  Future<void> Function()? afterTransfer;
  final transferBodies = <JsonObject>[];
  JsonObject? lastComment;

  TransferServer() {
    cards[8]!['labels'] = labels[1]!.map((l) => {...l}).toList();
  }
  JsonObject boardData(int id) => {
    ...board(id, 'Board $id', edit: id == 1 ? sourceEdit : targetEdit).raw,
    'externalId': (id == 1 ? sourceExternal : targetExternal) ? 100 : null,
    'permissions': {
      'PERMISSION_READ': id == 1 ? sourceRead : targetRead,
      'PERMISSION_EDIT': id == 1 ? sourceEdit : targetEdit,
      'PERMISSION_MANAGE': id == 1 || targetManage,
    },
    'labels': labels[id] ?? <JsonObject>[],
  };
  List<JsonObject> ordered(int stackId, {bool archived = false}) =>
      cards.values
          .where(
            (c) =>
                c['stackId'] == stackId &&
                c['archived'] == archived &&
                c['deletedAt'] == 0,
          )
          .toList()
        ..sort((a, b) => (a['order']! as int).compareTo(b['order']! as int));
  JsonObject stackData(int id, {bool? archived}) => {
    'id': id,
    'boardId': malformedTarget && id == 4 ? 1 : stackBoards[id],
    'title': 'Column $id',
    'order': id,
    'isDoneColumn': id == 2 ? sourceDone : id == 4 && targetDone,
    'cards': archived == null
        ? [...ordered(id), ...ordered(id, archived: true)]
        : ordered(id, archived: archived),
  };
  http.Response json(Object? value) => http.Response(
    jsonEncode(value),
    200,
    headers: {'content-type': 'application/json'},
  );
  http.Response ocs(Object? value) => json({
    'ocs': {
      'meta': {'status': 'ok', 'statuscode': 200},
      'data': value,
    },
  });
  int? _idAt(List<String> path, String name) {
    final i = path.lastIndexOf(name);
    return i >= 0 && i + 1 < path.length ? int.tryParse(path[i + 1]) : null;
  }

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    final segments = request.url.pathSegments;
    final cardId = _idAt(segments, 'cards');
    final boardId = _idAt(segments, 'boards');
    final stackId = _idAt(segments, 'stacks');
    if (path.endsWith('/capabilities')) {
      return ocs({
        'capabilities': {
          'deck': {
            'version': '1.18.5',
            'apiVersions': ['1.1'],
            'canCreateBoards': true,
          },
        },
      });
    }
    if (path.endsWith('/cloud/user')) return ocs({'id': 'user'});
    if (request.method == 'POST' && path.endsWith('/comments')) {
      comments++;
      lastComment = object(jsonDecode(request.body));
      return ocs({
        'id': 100 + comments,
        'objectId': cardId,
        'actorId': 'user',
        'actorType': 'users',
        'message': lastComment!['message'],
        'creationDateTime': '2030-01-01T00:00:00Z',
      });
    }
    if (request.method == 'POST' && path.endsWith('/boards')) {
      final id = nextBoard++;
      labels[id] = [];
      return json({...boardData(id), ...object(jsonDecode(request.body))});
    }
    if (request.method == 'POST' && path.endsWith('/stacks')) {
      final id = nextStack++;
      stackBoards[id] = boardId!;
      return json({...stackData(id), ...object(jsonDecode(request.body))});
    }
    if (request.method == 'POST' && path.endsWith('/cards')) {
      final id = nextCard++;
      createdCards++;
      cards[id] = {
        ...richCard(id, stackId!, 0),
        ...object(jsonDecode(request.body)),
      };
      return json(cards[id]);
    }
    if (request.method == 'PUT' && path.endsWith('/reorder')) {
      positions++;
      final data = object(jsonDecode(request.body));
      final target = intField(data, 'stackId');
      final moving = cards[cardId]!;
      final previous = moving['stackId']! as int;
      if (stackBoards[previous] != stackBoards[target]) crossBoardReorders++;
      final other = ordered(target).where((c) => c['id'] != cardId).toList();
      other.insert(intField(data, 'order').clamp(0, other.length), moving);
      moving['stackId'] = target;
      if (previous != target) {
        if (target == 4 && targetDone) {
          moving['done'] = '2030-01-01T00:00:00Z';
        } else if (previous == 4 && targetDone || previous == 2 && sourceDone) {
          moving['done'] = null;
        }
      }
      for (var i = 0; i < other.length; i++) {
        other[i]['order'] = i;
      }
      if (losePositionResponse) {
        throw http.ClientException('lost_position_response');
      }
      return path.contains('/ocs/') ? ocs(other) : json(other);
    }
    if (request.method == 'PUT' &&
        path.contains('/ocs/') &&
        cardId != null &&
        segments.last == '$cardId') {
      final data = object(jsonDecode(request.body));
      if (data['id'] != cardId) return http.Response('', 400);
      final card = cards[cardId]!;
      if (card['deletedAt'] != 0 && data['deletedAt'] != 0) {
        return http.Response('', 403);
      }
      final previousBoard = stackBoards[card['stackId']];
      final next = intField(data, 'stackId');
      final destination = stackBoards[next]!;
      transferBodies.add(data);
      transfers++;
      for (final field in [
        'title',
        'description',
        'type',
        'owner',
        'order',
        'stackId',
        'duedate',
        'startdate',
        'color',
        'done',
      ]) {
        if (data.containsKey(field)) card[field] = data[field];
      }
      if (data['archived'] != null) card['archived'] = data['archived'];
      if (data['deletedAt'] != null) card['deletedAt'] = data['deletedAt'];
      if (previousBoard != destination) {
        final migrated = <JsonObject>[];
        for (final label in (card['labels'] as List).cast<JsonObject>()) {
          var match = labels[destination]!
              .where((l) => l['title'] == label['title'])
              .firstOrNull;
          if (match == null && targetManage) {
            match = {...label, 'id': nextLabel++};
            labels[destination]!.add(match);
          }
          if (match != null) migrated.add(match);
        }
        card['labels'] = migrated;
      }
      final response = ocs({...card, if (badTransferReceipt) 'id': 999});
      await afterTransfer?.call();
      if (loseTransferResponse) {
        throw http.ClientException('lost_transfer_response');
      }
      return response;
    }
    if (request.method == 'PUT' && path.endsWith('/assignLabel')) {
      final id = intField(object(jsonDecode(request.body)), 'labelId');
      final actualBoard = stackBoards[cards[cardId]!['stackId']]!;
      final label = labels[actualBoard]!
          .where((l) => l['id'] == id)
          .firstOrNull;
      if (label == null) return http.Response('', 400);
      cards[cardId]!['labels'] = [...(cards[cardId]!['labels'] as List), label];
      return json(cards[cardId]);
    }
    if (boardId != null && segments.last == '$boardId') {
      if (boardId == 1 ? !sourceRead : !targetRead) {
        return http.Response('', 403);
      }
      return json(boardData(boardId));
    }
    if (cardId != null) {
      final card = cards[cardId];
      if (card == null || card['deletedAt'] != 0) return http.Response('', 404);
      final actualBoard = stackBoards[card['stackId']];
      if (actualBoard == 1 ? !sourceRead : !targetRead) {
        return http.Response('', 403);
      }
      if (transfers > 0 && positions == 0 && failTransferRead ||
          positions > 0 && failPositionRead) {
        return http.Response('', 503);
      }
      return json(card);
    }
    if (stackId != null) return json(stackData(stackId));
    if (boardId != null &&
        (path.endsWith('/stacks') || path.endsWith('/archived'))) {
      final archived = path.endsWith('/archived');
      return json([
        for (final id in stackBoards.keys)
          if (stackBoards[id] == boardId) stackData(id, archived: archived),
      ]);
    }
    throw StateError('unexpected_request');
  }
}

final class TransferFixture {
  TransferFixture({DeckDatabase? database, TransferServer? server})
    : database = database ?? DeckDatabase(NativeDatabase.memory()),
      server = server ?? TransferServer();
  final DeckDatabase database;
  final TransferServer server;
  late StoredAccount account;
  late DeckSync sync;
  DeckClient client() => DeckClient(
    base: ServerBase.parse(account.server),
    loginName: account.loginName,
    appPassword: 'test-password',
    transport: MockClient(server.handle),
  );
  Future<void> initialize() async {
    account = await AccountRepository(
      database,
      MemoryVault(),
    ).add(credentials('user'));
    await database.saveUserIdentity(account, 'user');
    await database.saveCapabilities(
      account,
      const DeckCapabilities(
        version: '1.18.5',
        apiVersion: '1.1',
        canCreateBoards: true,
      ),
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson(server.boardData(1)),
      DeckBoard.fromJson(server.boardData(3)),
    ], null);
    for (final boardId in [1, 3]) {
      await database.saveStacks(account.id, account.generation, boardId, [
        for (final id in server.stackBoards.keys)
          if (server.stackBoards[id] == boardId)
            DeckStack.fromJson(server.stackData(id)),
      ], null);
    }
    sync = DeckSync(database, account, client());
  }

  Future<void> queue({int? anchor = 9, bool before = false}) =>
      database.queueCardTransfer(
        account,
        1,
        DeckCard.fromJson(server.cards[8]!),
        destinationBoardId: 3,
        destinationStackId: 4,
        anchorCardId: anchor,
        before: before,
      );
  Future<void> close() async {
    sync.close();
    await database.close();
  }
}
