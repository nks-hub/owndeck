import 'dart:convert';

import 'dart:io';

import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';import 'package:test/test.dart';

void main() {
  for (var version = 1; version < 9; version++) {
    test(
      'upgrade from schema $version preserves accounts and local work',
      () async {
        final db = DeckDatabase(
          NativeDatabase.memory(
            setup: (database) {
              for (final statement in _schema(version)) {
                database.execute(statement);
              }
              database.execute(
                '''INSERT INTO stored_accounts
              (id, server, login_name, credential_ref)
              VALUES ('account', 'https://cloud.example.com', 'user', 'vault-key')''',
              );
              database.execute('''INSERT INTO stored_boards VALUES
              ('account', 1, '{"id":1,"title":"Board"}')''');
              database.execute(
                '''INSERT INTO stored_stacks VALUES
              ('account', 2, 1, 0, '{"id":2,"boardId":1,"title":"Todo","order":0}')''',
              );
              database.execute(
                '''INSERT INTO stored_cards VALUES
              ('account', 8, 1, 2, 0, '{"id":8,"stackId":2,"title":"Task"}')''',
              );
              if (version >= 2) {
                database.execute('''INSERT INTO pending_writes
                (id, account_id, kind, board_id, stack_id, card_id, proposal)
                VALUES ('queued', 'account', 'updateCard', 1, 2, 8,
                        '{"description":"Pending change"}')''');
              }
              if (version >= 4) {
                database.execute('''INSERT INTO editor_drafts
                (account_id, draft_key, board_id, stack_id, card_id, payload, updated_at)
                VALUES ('account', 'draft', 1, 2, 8,
                        '{"description":"Unsent text"}', 1700000000)''');
              }
              database.execute('PRAGMA user_version = $version');
            },
          ),
        );
        addTearDown(db.close);

        final account = (await db.accounts()).single;
        expect(account.credentialRef, 'vault-key');
        expect(account.state, 'active');
        expect(account.syncNotBefore, isNull);
        expect((await db.select(db.storedCards).get()).single.remoteId, 8);
        final writes = await db.writesFor(account.id);
        if (version >= 2) {
          expect(writes.single.id, 'queued');
          expect(jsonDecode(writes.single.proposal), {
            'description': 'Pending change',
          });
        } else {
          expect(writes, isEmpty);
        }
        if (version >= 4) {
          final draft = (await db.editorDraft(account.id, 'draft'))!;
          expect(draft.kind, 'card');
          expect(jsonDecode(draft.payload), {'description': 'Unsent text'});
        }
        await db.saveEditorDraft(account, 'after-upgrade', 1, 2, {
          'title': 'New draft',
        }, null);
        expect(
          (await db.editorDraft(account.id, 'after-upgrade'))!.kind,
          'card',
        );
        expect(
          await db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        expect(
          (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
            'user_version',
          ),
          9,
        );
      },
    );
  }

  test('failed upgrade rolls back and a later open succeeds (B51)', () async {
    final dir = Directory.systemTemp.createTempSync('deck_migration');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/deck.sqlite');
    // The setup argument is a sqlite3 Database, which this package does not
    // depend on directly.
    List<String> columns(dynamic database) => [
      for (final row in database.select('PRAGMA table_info(stored_accounts)'))
        row['name'] as String,
    ];
    var afterFailure = <String>[];

    final broken = DeckDatabase(
      NativeDatabase(
        file,
        setup: (database) {
          for (final statement in _schema(5)) {
            database.execute(statement);
          }
          // A later step (adding user_id) collides with this column.
          database.execute('ALTER TABLE stored_accounts ADD COLUMN user_id TEXT');
          database.execute('PRAGMA user_version = 5');
        },
      ),
    );
    await expectLater(broken.accounts(), throwsA(anything));
    await broken.close();

    final fixed = DeckDatabase(
      NativeDatabase(
        file,
        setup: (database) {
          if (afterFailure.isNotEmpty) return;
          afterFailure = columns(database);
          database.execute('ALTER TABLE stored_accounts DROP COLUMN user_id');
        },
      ),
    );
    addTearDown(fixed.close);
    expect(afterFailure, isNot(contains('sync_not_before')));
    expect(await fixed.accounts(), isEmpty);
    expect(
      (await fixed.customSelect('PRAGMA user_version').getSingle()).read<int>(
        'user_version',
      ),
      9,
    );
  });
}

// Frozen schema boundaries: 916be36 (v1), d18676c (v3), 88e46b7 (v4),
// 84f3c30 (v5), 1c25446 (v6), c5866ce (v7), 1943986 (v8).
List<String> _schema(int version) {
  const account = '''account_id TEXT NOT NULL
    REFERENCES stored_accounts(id) ON DELETE CASCADE''';
  return [
    '''CREATE TABLE stored_accounts (
      id TEXT NOT NULL PRIMARY KEY, server TEXT NOT NULL,
      login_name TEXT NOT NULL, credential_ref TEXT NOT NULL UNIQUE,
      state TEXT NOT NULL DEFAULT 'active', generation INTEGER NOT NULL DEFAULT 1,
      selected INTEGER NOT NULL DEFAULT 0,
      ${version >= 3 ? 'content_epoch INTEGER NOT NULL DEFAULT 0,' : ''}
      ${version >= 5 ? 'capabilities TEXT,' : ''}
      ${version >= 6 ? 'user_id TEXT,' : ''}
      ${version >= 7 ? 'certificate_fingerprint TEXT,' : ''}
      UNIQUE(server, login_name))''',
    '''CREATE TABLE stored_boards ($account, remote_id INTEGER NOT NULL,
      payload TEXT NOT NULL, PRIMARY KEY(account_id, remote_id))''',
    '''CREATE TABLE stored_stacks ($account, remote_id INTEGER NOT NULL,
      board_id INTEGER NOT NULL, position INTEGER NOT NULL,
      payload TEXT NOT NULL, PRIMARY KEY(account_id, remote_id))''',
    '''CREATE TABLE stored_cards ($account, remote_id INTEGER NOT NULL,
      board_id INTEGER NOT NULL, stack_id INTEGER NOT NULL,
      position INTEGER NOT NULL, payload TEXT NOT NULL,
      PRIMARY KEY(account_id, remote_id))''',
    '''CREATE TABLE sync_checkpoints ($account, scope TEXT NOT NULL,
      etag TEXT, fetched_at INTEGER NOT NULL, PRIMARY KEY(account_id, scope))''',
    if (version >= 2) ...[
      '''CREATE TABLE pending_writes (
        sequence INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE,
        $account, kind TEXT NOT NULL, board_id INTEGER NOT NULL,
        stack_id INTEGER NOT NULL, card_id INTEGER, proposal TEXT NOT NULL,
        base TEXT, remote TEXT, state TEXT NOT NULL DEFAULT 'queued', error TEXT)''',
      '''CREATE TABLE sync_leases ($account PRIMARY KEY,
        owner TEXT NOT NULL, expires INTEGER NOT NULL)''',
    ],
    if (version >= 4)
      '''CREATE TABLE editor_drafts (
        ${version >= 6 ? "kind TEXT NOT NULL DEFAULT 'card'," : ''}
        $account, draft_key TEXT NOT NULL, board_id INTEGER NOT NULL,
        stack_id INTEGER NOT NULL, card_id INTEGER, payload TEXT NOT NULL,
        base TEXT, updated_at INTEGER NOT NULL, PRIMARY KEY(account_id, draft_key))''',
    if (version >= 6)
      '''CREATE TABLE stored_comments ($account, card_id INTEGER NOT NULL,
        remote_id INTEGER NOT NULL, payload TEXT NOT NULL,
        PRIMARY KEY(account_id, remote_id))''',
    if (version >= 8)
      '''CREATE TABLE stored_attachments ($account, board_id INTEGER NOT NULL,
        card_id INTEGER NOT NULL, type TEXT NOT NULL, remote_id INTEGER NOT NULL,
        payload TEXT NOT NULL, PRIMARY KEY(account_id, card_id, type, remote_id))''',
  ];
}
