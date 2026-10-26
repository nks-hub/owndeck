part of 'database.dart';

extension DeckEditorDrafts on DeckDatabase {
  Future<EditorDraft?> editorDraft(String accountId, String key) =>
      (select(editorDrafts)..where(
            (d) => d.accountId.equals(accountId) & d.draftKey.equals(key),
          ))
          .getSingleOrNull();

  Stream<List<EditorDraft>> watchEditorDrafts(String accountId) =>
      (select(editorDrafts)
            ..where((d) => d.accountId.equals(accountId))
            ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
          .watch();

  Future<void> saveEditorDraft(
    StoredAccount account,
    String key,
    int boardId,
    int stackId,
    JsonObject payload,
    DeckCard? original,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    await into(editorDrafts).insertOnConflictUpdate(
      EditorDraftsCompanion.insert(
        accountId: account.id,
        draftKey: key,
        boardId: boardId,
        stackId: stackId,
        cardId: Value(original?.id),
        payload: jsonEncode(payload),
        base: Value(original == null ? null : jsonEncode(original.raw)),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  });

  /// Stores text received while the account is signed out; no server write is involved.
  Future<void> saveSignedOutDraft(
    String accountId,
    String key,
    int boardId,
    int stackId,
    JsonObject payload,
  ) => transaction(() async {
    final current = await account(accountId);
    if (current == null ||
        (current.state != 'active' && current.state != 'reauthRequired')) {
      throw StateError('account_unavailable');
    }
    await into(editorDrafts).insertOnConflictUpdate(
      EditorDraftsCompanion.insert(
        accountId: accountId,
        draftKey: key,
        boardId: boardId,
        stackId: stackId,
        payload: jsonEncode(payload),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  });

  Future<void> deleteEditorDraft(String accountId, String key) async {
    await (delete(
          editorDrafts,
        )..where((d) => d.accountId.equals(accountId) & d.draftKey.equals(key)))
        .go();
  }

  Future<void> publishEditorDraft(
    StoredAccount account,
    String key,
    int boardId,
    int stackId,
    JsonObject changes,
    DeckCard? original,
  ) => transaction(() async {
    if (!await accepts(account.id, account.generation)) {
      throw StateError('account_unavailable');
    }
    if (changes.isNotEmpty) {
      await saveCardDraft(
        account,
        boardId,
        stackId,
        changes,
        original: original,
      );
    }
    await deleteEditorDraft(account.id, key);
  });
}
