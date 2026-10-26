import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late Directory folder;
  late DeckDatabase db;
  late StoredAccount account;
  late MemoryVault vault;
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('owndeck-draft-test-');
    db = DeckDatabase(NativeDatabase(File('${folder.path}/test.sqlite')));
    vault = MemoryVault();
    account = await AccountRepository(db, vault).add(credentials('user'));
  });
  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });

  test(
    'draft survives reopening the database without creating a server write',
    () async {
      await db.saveEditorDraft(account, '1:2:new', 1, 2, {
        'title': '',
        'description': 'Rozepsaný text',
        'duedate': null,
        'completed': false,
      }, null);
      await db.close();
      db = DeckDatabase(NativeDatabase(File('${folder.path}/test.sqlite')));
      final draft = (await db.editorDraft(account.id, '1:2:new'))!;
      expect(
        object(jsonDecode(draft.payload))['description'],
        'Rozepsaný text',
      );
      expect(await db.writesFor(account.id), isEmpty);
    },
  );

  test(
    'publishing atomically replaces editor draft with a queued write',
    () async {
      await db.saveBoards(account.id, account.generation, [
        board(1, 'Board', edit: true),
      ], null);
      await db.saveEditorDraft(account, '1:2:new', 1, 2, {
        'title': 'Draft',
        'description': 'Text',
      }, null);
      await db.publishEditorDraft(account, '1:2:new', 1, 2, {
        'title': 'Draft',
        'description': 'Text',
      }, null);
      expect(await db.editorDraft(account.id, '1:2:new'), isNull);
      expect(
        object(
          jsonDecode((await db.writesFor(account.id)).single.proposal),
        )['description'],
        'Text',
      );
    },
  );

  test('publishing without edit permission preserves the draft', () async {
    await db.saveBoards(account.id, account.generation, [
      board(1, 'Board'),
    ], null);
    await db.saveEditorDraft(account, '1:2:new', 1, 2, {
      'title': 'Draft',
      'description': 'Keep this',
    }, null);
    await expectLater(
      db.publishEditorDraft(account, '1:2:new', 1, 2, {'title': 'Draft'}, null),
      throwsStateError,
    );
    expect(await db.editorDraft(account.id, '1:2:new'), isNotNull);
    expect(await db.writesFor(account.id), isEmpty);
  });

  test(
    'account removal deletes its drafts and rejects a delayed autosave',
    () async {
      await db.saveEditorDraft(account, '1:2:new', 1, 2, {
        'title': 'Draft',
      }, null);
      await AccountRepository(db, vault).remove(account.id);
      await expectLater(
        db.saveEditorDraft(account, '1:2:new', 1, 2, {'title': 'Late'}, null),
        throwsStateError,
      );
      expect(await db.watchEditorDrafts(account.id).first, isEmpty);
    },
  );

  test('a signed-out draft is stored for a reauthentication account only', () async {
    await AccountRepository(db, vault).requireAuthentication(account);
    await db.saveSignedOutDraft(account.id, 'share:1', 0, 0, {'title': 'T'});
    final draft = (await db.editorDraft(account.id, 'share:1'))!;
    expect(object(jsonDecode(draft.payload))['title'], 'T');
    expect(await db.writesFor(account.id), isEmpty);
    expect(
      () => db.saveSignedOutDraft('missing', 'share:2', 0, 0, {}),
      throwsStateError,
    );
  });
}
