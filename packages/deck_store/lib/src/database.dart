import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

part 'database.g.dart';
part 'writes.dart';
part 'editor_drafts.dart';
part 'views.dart';
part 'structure_writes.dart';
part 'card_actions.dart';
part 'comments.dart';
part 'board_metadata.dart';
part 'attachments.dart';
part 'board_access.dart';
part 'board_clones.dart';

const attachmentKinds = {
  'uploadAttachment',
  'linkAttachment',
  'deleteAttachment',
  'restoreAttachment',
};

const boardMetadataKinds = {
  'createLabel',
  'updateLabel',
  'deleteLabel',
  'createAcl',
  'updateAcl',
  'deleteAcl',
};

class StoredAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get server => text()();
  TextColumn get loginName => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get certificateFingerprint => text().nullable()();
  DateTimeColumn get syncNotBefore => dateTime().nullable()();
  TextColumn get credentialRef => text().unique()();
  TextColumn get state => text().withDefault(const Constant('active'))();
  IntColumn get generation => integer().withDefault(const Constant(1))();
  TextColumn get capabilities => text().nullable()();
  IntColumn get contentEpoch => integer().withDefault(const Constant(0))();
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

class PendingWrites extends Table {
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text()();
  IntColumn get boardId => integer()();
  IntColumn get stackId => integer()();
  IntColumn get cardId => integer().nullable()();
  TextColumn get proposal => text()();
  TextColumn get base => text().nullable()();
  TextColumn get remote => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('queued'))();
  TextColumn get error => text().nullable()();
}

class SyncLeases extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get owner => text()();
  DateTimeColumn get expires => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {accountId};
}

class EditorDrafts extends Table {
  TextColumn get kind => text().withDefault(const Constant('card'))();
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  TextColumn get draftKey => text()();
  IntColumn get boardId => integer()();
  IntColumn get stackId => integer()();
  IntColumn get cardId => integer().nullable()();
  TextColumn get payload => text()();
  TextColumn get base => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, draftKey};
}

class StoredComments extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get cardId => integer()();
  IntColumn get remoteId => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, remoteId};
}

class StoredAttachments extends Table {
  TextColumn get accountId =>
      text().references(StoredAccounts, #id, onDelete: KeyAction.cascade)();
  IntColumn get boardId => integer()();
  IntColumn get cardId => integer()();
  TextColumn get type => text()();
  IntColumn get remoteId => integer()();
  TextColumn get payload => text()();
  @override
  Set<Column<Object>> get primaryKey => {accountId, cardId, type, remoteId};
}

@DriftDatabase(
  tables: [
    StoredAccounts,
    StoredBoards,
    StoredStacks,
    StoredCards,
    SyncCheckpoints,
    PendingWrites,
    SyncLeases,
    EditorDrafts,
    StoredComments,
    StoredAttachments,
  ],
)
class DeckDatabase extends _$DeckDatabase {
  DeckDatabase(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 9) {
        await m.addColumn(storedAccounts, storedAccounts.syncNotBefore);
      }
      if (from < 8) await m.createTable(storedAttachments);
      if (from < 2) {
        await m.createTable(pendingWrites);
        await m.createTable(syncLeases);
      }
      if (from < 3) {
        await m.addColumn(storedAccounts, storedAccounts.contentEpoch);
      }
      if (from < 4) await m.createTable(editorDrafts);
      if (from < 5) {
        await m.addColumn(storedAccounts, storedAccounts.capabilities);
      }
      if (from < 6) {
        await m.addColumn(storedAccounts, storedAccounts.userId);
        if (from >= 4) {
          await m.addColumn(editorDrafts, editorDrafts.kind);
        }
        await m.createTable(storedComments);
      }
      if (from < 7) {
        await m.addColumn(
          storedAccounts,
          storedAccounts.certificateFingerprint,
        );
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<List<StoredAccount>> accounts() => select(storedAccounts).get();
  Future<StoredAccount?> account(String id) =>
      (select(storedAccounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<bool> accepts(String accountId, int generation) async {
    final current = await account(accountId);
    return current?.state == 'active' && current?.generation == generation;
  }

  Future<void> saveUserIdentity(StoredAccount account, String userId) =>
      transaction(() async {
        if (!await accepts(account.id, account.generation)) return;
        final current = (await this.account(account.id))!;
        if (current.userId != null && current.userId != userId) {
          throw StateError('identity_mismatch');
        }
        await (update(storedAccounts)..where((a) => a.id.equals(account.id)))
            .write(StoredAccountsCompanion(userId: Value(userId)));
      });

  Future<void> saveBoard(
    StoredAccount account,
    DeckBoard board,
    int contentEpoch,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation) ||
        (await this.account(account.id))?.contentEpoch != contentEpoch) {
      return;
    }
    if (!board.permissions.read) {
      await revokeBoardAccess(account, board.id);
      return;
    }
    await into(storedBoards).insertOnConflictUpdate(
      StoredBoardsCompanion.insert(
        accountId: account.id,
        remoteId: board.id,
        payload: jsonEncode(board.raw),
      ),
    );
    if (!board.permissions.read || board.deletedAt != 0) {
      await (delete(storedAttachments)..where(
            (a) => a.accountId.equals(account.id) & a.boardId.equals(board.id),
          ))
          .go();
    }
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
    String? etag, {
    int? contentEpoch,
  }) => transaction(() async {
    if (!await accepts(accountId, generation)) return;
    if (contentEpoch != null &&
        (await account(accountId))?.contentEpoch != contentEpoch) {
      return;
    }
    final ids = boards
        .where((b) => b.permissions.read)
        .map((b) => b.id)
        .toSet();
    final readableIds = boards
        .where((board) => board.permissions.read && board.deletedAt == 0)
        .map((board) => board.id);
    await (delete(storedAttachments)..where(
          (a) => a.accountId.equals(accountId) & a.boardId.isNotIn(readableIds),
        ))
        .go();
    final previous = await (select(
      storedBoards,
    )..where((b) => b.accountId.equals(accountId))).get();
    final currentAccount = (await account(accountId))!;
    for (final missing in previous.where((b) => !ids.contains(b.remoteId))) {
      await revokeBoardAccess(currentAccount, missing.remoteId);
    }
    await (delete(
      storedBoards,
    )..where((b) => b.accountId.equals(accountId))).go();
    for (final board in boards.where((b) => b.permissions.read)) {
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
    String? etag, {
    int? contentEpoch,
  }) => transaction(() async {
    if (!await accepts(accountId, generation)) return;
    if (contentEpoch != null &&
        (await account(accountId))?.contentEpoch != contentEpoch) {
      return;
    }
    await (delete(storedCards)..where(
          (c) => c.accountId.equals(accountId) & c.boardId.equals(boardId),
        ))
        .go();
    await (delete(storedStacks)..where(
          (s) => s.accountId.equals(accountId) & s.boardId.equals(boardId),
        ))
        .go();
    for (final stack in stacks) {
      if (stack.boardId != boardId) {
        throw const FormatException('stack_board_mismatch');
      }
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
        if (card.stackId != stack.id) {
          throw const FormatException('card_stack_mismatch');
        }
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
