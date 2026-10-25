import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

DeckAttachment attachment(String type, {String name = 'file.txt'}) =>
    DeckAttachment.fromJson({
      'id': 7,
      'type': type,
      'cardId': 8,
      'data': name,
      'lastModified': 10,
      'deletedAt': 0,
    });
http.Response json(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  late DeckDatabase database;
  late AccountRepository accounts;
  late StoredAccount account;
  setUp(() async {
    database = DeckDatabase(NativeDatabase.memory());
    accounts = AccountRepository(database, MemoryVault());
    account = await accounts.add(credentials('user'));
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board', edit: true),
    ], null);
  });
  tearDown(() => database.close());

  test(
    'a missing board clears attachments and rejects a late listing',
    () async {
      await database.saveAttachments(account, 1, 8, [attachment('file')], 0);
      await database.saveBoards(account.id, account.generation, [], null);
      expect(await database.watchAttachments(account.id, 8).first, isEmpty);
      await database.saveAttachments(account, 1, 8, [attachment('file')], 0);
      expect(await database.watchAttachments(account.id, 8).first, isEmpty);
    },
  );

  DeckSync sync(
    http.Client transport, {
    Future<AttachmentUploadSource> Function(String)? readUpload,
  }) => DeckSync(
    database,
    account,
    DeckClient(
      base: ServerBase.parse(account.server),
      loginName: account.loginName,
      appPassword: 'test-password',
      transport: transport,
    ),
    readUpload: readUpload,
  );

  Future<http.Response> reads(http.Request request) async {
    if (request.url.path.endsWith('/boards/1')) {
      return json(board(1, 'Board', edit: true).raw);
    }
    if (request.url.path.endsWith('/cards/8')) return json(cardJson());
    if (request.url.path.endsWith('/stacks/2')) {
      return json({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [],
      });
    }
    throw StateError('unexpected_request');
  }

  test(
    'an unavailable staged file blocks the upload before any POST',
    () async {
      await database.queueAttachment(account, 1, 2, 8, 'uploadAttachment', {
        'uploadId': 'test-upload',
        'name': 'file.txt',
      });
      var uploads = 0;
      await sync(
        MockClient((request) async {
          if (request.method == 'POST') uploads++;
          return reads(request);
        }),
        readUpload: (_) async => throw const FileSystemException('unavailable'),
      ).run();
      expect((await database.writesFor(account.id)).single.state, 'blocked');
      expect(uploads, 0);
    },
  );

  test(
    'closing while preparing the file leaves an unsent upload queued',
    () async {
      await database.queueAttachment(account, 1, 2, 8, 'uploadAttachment', {
        'uploadId': 'test-upload',
        'name': 'file.txt',
      });
      final preparing = Completer<void>();
      final ready = Completer<AttachmentUploadSource>();
      var uploads = 0;
      final sender = sync(
        MockClient((request) async {
          if (request.method == 'POST') uploads++;
          return reads(request);
        }),
        readUpload: (_) {
          preparing.complete();
          return ready.future;
        },
      );
      final running = sender.run();
      await preparing.future;
      sender.close();
      ready.complete(
        AttachmentUploadSource(
          filename: 'file.txt',
          mime: 'text/plain',
          length: 0,
          bytes: const Stream.empty(),
        ),
      );
      await running;
      expect((await database.writesFor(account.id)).single.state, 'queued');
      expect(uploads, 0);
    },
  );

  test(
    'cache keys include account and attachment type, and removal rejects late results',
    () async {
      final other = await accounts.add(credentials('other'));
      await database.saveBoards(other.id, other.generation, [
        board(1, 'Other board'),
      ], null);
      await database.saveAttachments(account, 1, 8, [
        attachment('file'),
        attachment('deck_file'),
      ], 0);
      await database.saveAttachments(other, 1, 8, [
        attachment('file', name: 'other.txt'),
      ], 0);
      expect((await database.watchAttachments(account.id, 8).first).length, 2);
      await accounts.remove(account.id);
      await database.saveAttachments(account, 1, 8, [attachment('file')], 0);
      expect(await database.watchAttachments(account.id, 8).first, isEmpty);
      expect(
        (await database.watchAttachments(other.id, 8).first).single.name,
        'other.txt',
      );
    },
  );

  test(
    'a confirmed share waits for read-back without posting it twice',
    () async {
      await database.queueAttachment(account, 1, 2, 8, 'linkAttachment', {
        'segments': ['Reports', 'file.txt'],
      });
      var shares = 0;
      var available = false;
      final api = sync(
        MockClient((request) async {
          if (request.method == 'POST') {
            shares++;
            expect(jsonDecode(request.body)['shareWith'], '8');
            return json({
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': {'id': 7},
              },
            });
          }
          if (request.url.path.endsWith('/attachments')) {
            return available
                ? json([attachment('file').raw])
                : http.Response('', 503);
          }
          return reads(request);
        }),
      );
      await api.run();
      expect((await database.writesFor(account.id)).single.state, 'applied');
      available = true;
      await api.run();
      expect(shares, 1);
      expect(await database.writesFor(account.id), isEmpty);
      expect(
        (await database.watchAttachments(account.id, 8).first).single.id,
        7,
      );
      await database.saveAttachments(account, 1, 8, [], 0);
      expect(
        (await database.watchAttachments(account.id, 8).first).single.id,
        7,
      );
    },
  );

  test('lost upload response stays uncertain across sync restart', () async {
    await database.queueAttachment(account, 1, 2, 8, 'uploadAttachment', {
      'uploadId': 'test-upload',
      'name': 'file.txt',
    });
    var uploads = 0;
    http.Client transport() => MockClient((request) async {
      if (request.method == 'POST') {
        uploads++;
        throw http.ClientException('lost_response');
      }
      return reads(request);
    });
    Future<AttachmentUploadSource> source(String id) async =>
        AttachmentUploadSource(
          filename: 'file.txt',
          mime: 'text/plain',
          length: 3,
          bytes: Stream.value([1, 2, 3]),
        );
    await sync(transport(), readUpload: source).run();
    expect((await database.writesFor(account.id)).single.state, 'uncertain');
    await sync(transport(), readUpload: source).run();
    expect(uploads, 1);
  });

  test('changed attachment is preserved for a conflict decision', () async {
    await database.queueAttachment(
      account,
      1,
      2,
      8,
      'deleteAttachment',
      {},
      original: attachment('file'),
    );
    var deletes = 0;
    await sync(
      MockClient((request) async {
        if (request.method == 'DELETE') deletes++;
        if (request.url.path.endsWith('/attachments')) {
          return json([attachment('file', name: 'renamed.txt').raw]);
        }
        return reads(request);
      }),
    ).run();
    expect((await database.writesFor(account.id)).single.state, 'conflict');
    expect(deletes, 0);
  });

  test(
    'current server permissions block a previously queued attachment',
    () async {
      await database.queueAttachment(account, 1, 2, 8, 'linkAttachment', {
        'segments': ['file.txt'],
      });
      var requests = 0;
      await sync(
        MockClient((request) async {
          requests++;
          expect(request.method, 'GET');
          return json(board(1, 'Board').raw);
        }),
      ).run();
      expect(requests, 1);
      expect((await database.writesFor(account.id)).single.state, 'blocked');
    },
  );

  test('read-only accounts cannot queue attachments or cloud links', () async {
    await database.saveBoards(account.id, account.generation, [
      board(1, 'Board'),
    ], null);
    await expectLater(
      database.queueAttachment(account, 1, 2, 8, 'linkAttachment', {
        'segments': ['file.txt'],
      }),
      throwsStateError,
    );
    expect(await database.writesFor(account.id), isEmpty);
  });
}
