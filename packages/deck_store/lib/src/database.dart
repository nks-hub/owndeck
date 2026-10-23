import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:drift/drift.dart';

part 'database.g.dart';

class StoredAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get server => text()();
  TextColumn get loginName => text()();
  TextColumn get credentialRef => text().unique()();
  TextColumn get state => text().withDefault(const Constant('active'))();
  IntColumn get generation => integer().withDefault(const Constant(1))();
  BoolColumn get selected => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {server, loginName},
  ];
}

class StoredBoards extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get remoteId => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, remoteId};
}

class StoredStacks extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get remoteId => integer()();
  IntColumn get boardId => integer()();
  IntColumn get position => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, remoteId};
}

class StoredCards extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get remoteId => integer()();
  IntColumn get boardId => integer()();
  IntColumn get stackId => integer()();
  IntColumn get position => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, remoteId};
}

class SyncCheckpoints extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get scope => text()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, scope};
}

@DriftDatabase(
  tables: [
    StoredAccounts,
    StoredBoards,
    StoredStacks,
    StoredCards,
    SyncCheckpoints,
  ],
)
class DeckDatabase extends _$DeckDatabase {
  DeckDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<List<StoredAccount>> accounts() => select(storedAccounts).get();
  Future<StoredAccount?> account(String id) =>
      (select(storedAccounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<bool> accepts(String accountId, int generation) async {
    final current = await account(accountId);
    return current?.state == 'active' && current?.generation == generation;
  }

  Stream<List<DeckBoard>> watchBoards(String accountId) =>
      (select(
        storedBoards,
      )..where((b) => b.accountId.equals(accountId))).watch().map(
        (rows) => rows
            .map((r) => DeckBoard.fromJson(object(jsonDecode(r.payload))))
            .toList(),
      );

  Stream<List<DeckStack>> watchStacks(String accountId, int boardId) =>
      customSelect(
        '''SELECT s.remote_id, s.payload AS stack_json, c.payload AS card_json
       FROM stored_stacks s LEFT JOIN stored_cards c
       ON c.account_id = s.account_id AND c.stack_id = s.remote_id AND c.board_id = s.board_id
       WHERE s.account_id = ? AND s.board_id = ?
       ORDER BY s.position, s.remote_id, c.position, c.remote_id''',
        variables: [Variable(accountId), Variable(boardId)],
        readsFrom: {storedStacks, storedCards},
      ).watch().map((rows) {
        final stacks = <int, JsonObject>{};
        for (final row in rows) {
          final stack = stacks.putIfAbsent(
            row.read<int>('remote_id'),
            () => {
              ...object(jsonDecode(row.read<String>('stack_json'))),
              'cards': <JsonObject>[],
            },
          );
          final card = row.readNullable<String>('card_json');
          if (card != null)
            (stack['cards'] as List<JsonObject>).add(object(jsonDecode(card)));
        }
        return stacks.values.map(DeckStack.fromJson).toList();
      });

  Future<SyncCheckpoint?> checkpoint(String accountId, String scope) =>
      (select(syncCheckpoints)..where(
            (c) => c.accountId.equals(accountId) & c.scope.equals(scope),
          ))
          .getSingleOrNull();

  Future<void> saveBoards(
    String accountId,
    int generation,
    List<DeckBoard> boards,
    String? etag,
  ) => transaction(() async {
    if (!await accepts(accountId, generation)) return;
    final ids = boards.map((b) => b.id).toSet();
    final previous = await (select(
      storedBoards,
    )..where((b) => b.accountId.equals(accountId))).get();
    for (final missing in previous.where((b) => !ids.contains(b.remoteId))) {
      await (delete(storedCards)..where(
            (c) =>
                c.accountId.equals(accountId) &
                c.boardId.equals(missing.remoteId),
          ))
          .go();
      await (delete(storedStacks)..where(
            (s) =>
                s.accountId.equals(accountId) &
                s.boardId.equals(missing.remoteId),
          ))
          .go();
      await (delete(syncCheckpoints)..where(
            (c) =>
                c.accountId.equals(accountId) &
                c.scope.equals('board:${missing.remoteId}'),
          ))
          .go();
    }
    await (delete(
      storedBoards,
    )..where((b) => b.accountId.equals(accountId))).go();
    for (final board in boards) {
      await into(storedBoards).insert(
        StoredBoardsCompanion.insert(
          accountId: accountId,
          remoteId: board.id,
          payload: jsonEncode(board.raw),
        ),
      );
    }
    await _checkpoint(accountId, 'boards', etag);
  });

  Future<void> saveStacks(
    String accountId,
    int generation,
    int boardId,
    List<DeckStack> stacks,
    String? etag,
  ) => transaction(() async {
    if (!await accepts(accountId, generation)) return;
    await (delete(storedCards)..where(
          (c) => c.accountId.equals(accountId) & c.boardId.equals(boardId),
        ))
        .go();
    await (delete(storedStacks)..where(
          (s) => s.accountId.equals(accountId) & s.boardId.equals(boardId),
        ))
        .go();
    for (final stack in stacks) {
      if (stack.boardId != boardId)
        throw const FormatException('stack_board_mismatch');
      await into(storedStacks).insert(
        StoredStacksCompanion.insert(
          accountId: accountId,
          remoteId: stack.id,
          boardId: boardId,
          position: stack.order,
          payload: jsonEncode({...stack.raw, 'cards': <Object?>[]}),
        ),
      );
      for (final card in stack.cards) {
        if (card.stackId != stack.id)
          throw const FormatException('card_stack_mismatch');
        await into(storedCards).insert(
          StoredCardsCompanion.insert(
            accountId: accountId,
            remoteId: card.id,
            boardId: boardId,
            stackId: stack.id,
            position: card.order,
            payload: jsonEncode(card.raw),
          ),
        );
      }
    }
    await _checkpoint(accountId, 'board:$boardId', etag);
  });

  Future<void> _checkpoint(String accountId, String scope, String? etag) =>
      into(syncCheckpoints).insertOnConflictUpdate(
        SyncCheckpointsCompanion.insert(
          accountId: accountId,
          scope: scope,
          etag: Value(etag),
          fetchedAt: DateTime.now().toUtc(),
        ),
      );
}
