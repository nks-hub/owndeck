import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/attachment_files.dart';
import 'package:nextclouddeck/data/session.dart';

final class _Vault implements CredentialVault {
  final _values = <String, String>{};
  @override
  Future<String?> read(String reference) async => _values[reference];
  @override
  Future<void> write(String reference, String password) async {
    _values[reference] = password;
  }

  @override
  Future<void> delete(String reference) async => _values.remove(reference);
  @override
  Future<Set<String>> references() async => _values.keys.toSet();
}

DeckAttachment attachment(int modified) => DeckAttachment.fromJson({
  'id': 7,
  'cardId': 8,
  'type': 'file',
  'data': 'report.txt',
  'lastModified': modified,
  'deletedAt': 0,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late Directory root;
  late AttachmentFiles files;
  late DeckDatabase database;
  late AccountRepository accounts;
  late StoredAccount account;
  DeckSession? session;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    root = await Directory.systemTemp.createTemp('owndeck-session-files-test-');
    files = AttachmentFiles(root);
    database = DeckDatabase(NativeDatabase.memory());
    accounts = AccountRepository(
      database,
      _Vault(),
      clearFiles: files.removeAccount,
    );
    account = await accounts.add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        'id': 1,
        'title': 'Board',
        'color': '008080',
        'archived': false,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
      }),
    ], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [
          {
            'id': 8,
            'stackId': 2,
            'title': 'Card',
            'description': '',
            'order': 0,
          },
        ],
      }),
    ], null);
  });
  tearDown(() async {
    session?.dispose();
    session = null;
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
    if (await root.exists()) await root.delete(recursive: true);
  });

  DeckSession connect(
    http.Client transport, {
    Future<void> Function()? onAuthenticationRequired,
  }) => session = DeckSession(
    database,
    account,
    DeckClient(
      base: ServerBase.parse(account.server),
      loginName: account.loginName,
      appPassword: 'test-password',
      transport: transport,
    ),
    files: () async => files,
    onAuthenticationRequired: onAuthenticationRequired,
  );

  Future<DeckStack> seedPrivateContent() async {
    final board = (await database.boardView(account.id)).single;
    await database.saveBoards(account.id, account.generation, [
      board,
      DeckBoard.fromJson({...board.raw, 'id': 3, 'title': 'Other board'}),
    ], null);
    DeckStack stack(int boardId, int stackId, int cardId) =>
        DeckStack.fromJson({
          'id': stackId,
          'boardId': boardId,
          'title': 'Column',
          'order': 0,
          'cards': [
            {
              'id': cardId,
              'stackId': stackId,
              'title': 'Server task',
              'description': 'Server content',
              'order': 0,
            },
          ],
        });
    final first = stack(1, 2, 8);
    await database.saveStacks(account.id, account.generation, 1, [first], null);
    await database.saveStacks(account.id, account.generation, 3, [
      stack(3, 4, 9),
    ], null);
    for (final cardId in [8, 9]) {
      await database.saveComments(account, cardId, [
        DeckComment.fromJson({
          'id': cardId,
          'objectId': cardId,
          'actorId': 'other',
          'actorType': 'users',
          'message': 'Server comment',
          'creationDateTime': '2026-10-24T12:00:00Z',
        }),
      ], 0);
    }
    await database.saveAttachments(account, 1, 8, [attachment(10)], 0);
    await files.cache(account.id, 1, attachment(10), [1, 2]);
    await database.saveEditorDraft(account, 'draft', 1, 2, {
      'title': 'My draft',
      'description': 'Keep my text',
    }, first.cards.single);
    return first;
  }

  for (final status in [403, 404]) {
    test(
      'board $status removes server cache but preserves local work',
      () async {
        final stack = await seedPrivateContent();
        await database.saveCardDraft(account, 1, 2, {
          'description': 'Pending text',
        }, original: stack.cards.single);
        final active = connect(
          MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.path, endsWith('/boards/1'));
            return http.Response(
              '{}',
              status,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        final oldEpoch = (await database.account(account.id))!.contentEpoch;
        await active.refreshStacks(1);
        expect((active.error('board:1') as DeckException).status, status);
        expect((await database.boardView(account.id)).map((b) => b.id), [3]);
        expect(await database.stackView(account.id, 1), isEmpty);
        expect(await database.watchComments(account.id, 8).first, isEmpty);
        expect(await database.watchComments(account.id, 9).first, hasLength(1));
        expect(await database.attachmentsFor(account.id, 8), isEmpty);
        expect(await files.cached(account.id, 1, attachment(10)), isNull);
        expect(
          jsonDecode(
            (await database.editorDraft(account.id, 'draft'))!.payload,
          ),
          {'title': 'My draft', 'description': 'Keep my text'},
        );
        final write = (await database.writesFor(account.id)).single;
        expect(write.state, 'blocked');
        expect(jsonDecode(write.proposal)['description'], 'Pending text');
        await database.saveStacks(
          account.id,
          account.generation,
          1,
          [stack],
          null,
          contentEpoch: oldEpoch,
        );
        expect(await database.select(database.storedCards).get(), hasLength(1));
      },
    );
  }

  test('unreachable board keeps its offline copy and drafts', () async {
    await seedPrivateContent();
    final active = connect(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await active.refreshStacks(1);
    expect(await database.stackView(account.id, 1), hasLength(1));
    expect(await database.watchComments(account.id, 8).first, hasLength(1));
    expect(await files.cached(account.id, 1, attachment(10)), isNotNull);
    expect(await database.editorDraft(account.id, 'draft'), isNotNull);
  });

  test(
    'a missing card cannot keep or reuse files from its readable board',
    () async {
      await seedPrivateContent();
      final board = (await database.boardView(account.id)).first;
      final active = connect(
        MockClient(
          (request) async => http.Response(
            jsonEncode(request.url.path.endsWith('/boards/1') ? board.raw : []),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      await active.refreshStacks(1);
      expect(
        (await database.boardView(account.id)).any((b) => b.id == 1),
        isTrue,
      );
      expect(await files.cached(account.id, 1, attachment(10)), isNull);
      await expectLater(
        active.downloadAttachment(1, 2, attachment(10)),
        throwsStateError,
      );
    },
  );

  test('revoking a board preserves the user file waiting for upload', () async {
    final active = connect(MockClient((_) async => http.Response('', 403)));
    await active.uploadAttachment(
      1,
      2,
      8,
      name: 'local.txt',
      mime: 'text/plain',
      bytes: Stream.value([7, 8, 9]),
    );
    await active.refreshStacks(1);
    final write = (await database.writesFor(account.id)).single;
    expect(write.state, 'blocked');
    final staged = await files.readUpload(
      account.id,
      jsonDecode(write.proposal)['uploadId'] as String,
    );
    expect(await staged.bytes.expand((chunk) => chunk).toList(), [7, 8, 9]);
  });

  test(
    'a forbidden stack endpoint alone does not revoke a readable board',
    () async {
      await seedPrivateContent();
      final board = (await database.boardView(account.id)).first;
      var boardReads = 0;
      final active = connect(
        MockClient((request) async {
          if (request.url.path.endsWith('/boards/1')) {
            boardReads++;
            return http.Response(
              jsonEncode(board.raw),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('', 403);
        }),
      );
      await active.refreshStacks(1);
      expect(boardReads, 2);
      expect(await database.stackView(account.id, 1), hasLength(1));
      expect(await files.cached(account.id, 1, attachment(10)), isNotNull);
    },
  );

  test('late board denial cannot revoke a reauthenticated account', () async {
    await seedPrivateContent();
    final requested = Completer<void>();
    final response = Completer<http.Response>();
    final active = connect(
      MockClient((_) {
        requested.complete();
        return response.future;
      }),
    );
    final refresh = active.refreshStacks(1);
    await requested.future;
    await accounts.add(
      LoginCredentials(
        server: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'replacement-test-password',
      ),
    );
    response.complete(http.Response('', 403));
    await refresh;
    expect(await database.stackView(account.id, 1), hasLength(1));
    expect(await files.cached(account.id, 1, attachment(10)), isNotNull);
  });

  test(
    'queued changes resume in the foreground without an open board',
    () async {
      final binding = WidgetsBinding.instance;
      final previous = binding.lifecycleState;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final board = (await database.boardView(account.id)).single.raw;
      await database.saveCardDraft(account, 1, 2, {'title': 'Pending'});
      var posts = 0;
      final settled = Completer<void>();
      http.Response response(Object data, {bool ocs = false}) => http.Response(
        jsonEncode(
          ocs
              ? {
                  'ocs': {
                    'meta': {'status': 'ok', 'statuscode': 200},
                    'data': data,
                  },
                }
              : data,
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/cloud/user')) {
          return response({'id': 'user'}, ocs: true);
        }
        if (request.url.path.endsWith('/cloud/capabilities')) {
          return response({
            'capabilities': {
              'deck': {
                'version': '1.18.5',
                'apiVersions': ['1.1'],
                'canCreateBoards': true,
              },
            },
          }, ocs: true);
        }
        if (request.method == 'POST' ||
            request.url.path.endsWith('/boards/1/stacks/2/cards/8')) {
          if (request.method == 'POST') posts++;
          return response({
            'id': 8,
            'stackId': 2,
            'title': 'Pending',
            'description': '',
            'type': 'plain',
            'order': 0,
            'owner': 'user',
            'archived': false,
          });
        }
        if (request.url.path.endsWith('/boards/1/stacks/2')) {
          return response({
            'id': 2,
            'boardId': 1,
            'title': 'Column',
            'order': 0,
            'cards': [],
          });
        }
        return response(
          request.url.path.endsWith('/boards/1') ? board : [board],
        );
      });
      final active = session = DeckSession(
        database,
        account,
        DeckClient(
          base: ServerBase.parse(account.server),
          loginName: account.loginName,
          appPassword: 'test-password',
          transport: transport,
        ),
        pollInterval: const Duration(milliseconds: 20),
      );
      void changed() {
        if (posts == 1 && !active.loading('boards') && !settled.isCompleted) {
          settled.complete();
        }
      }

      active.addListener(changed);
      try {
        await settled.future.timeout(const Duration(seconds: 5));
        expect(posts, 1);
        expect(await database.writesFor(account.id), isEmpty);
      } finally {
        active.removeListener(changed);
        active.dispose();
        session = null;
        if (previous != null) binding.handleAppLifecycleStateChanged(previous);
      }
    },
  );

  test(
    'HTTP 401 requests reauthentication and stops further calls from that session',
    () async {
      var requests = 0;
      var callbacks = 0;
      final active = connect(
        MockClient((_) async {
          requests++;
          return http.Response('', 401);
        }),
        onAuthenticationRequired: () async {
          callbacks++;
          await accounts.requireAuthentication(account);
        },
      );
      await active.refreshBoards();
      expect(callbacks, 1);
      expect((await database.account(account.id))!.state, 'reauthRequired');
      await active.refreshBoards();
      expect(requests, 1);
      expect(
        (await database.watchBoards(account.id).first).single.title,
        'Board',
      );
    },
  );

  for (final operation in ['dav', 'download']) {
    test(
      '$operation persists backoff before the session is recreated',
      () async {
        var requests = 0;
        Future<void> request(DeckSession session) async {
          if (operation == 'dav') {
            await session.cloudFiles([]);
          } else {
            await session.downloadAttachment(1, 2, attachment(10));
          }
        }

        final first = connect(
          MockClient((request) async {
            requests++;
            if (request.url.path.endsWith('/cloud/user')) {
              return http.Response(
                jsonEncode({
                  'ocs': {
                    'meta': {'status': 'ok', 'statuscode': 200},
                    'data': {'id': 'user'},
                  },
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
            return http.Response('', 429, headers: {'retry-after': '120'});
          }),
        );
        await expectLater(request(first), throwsA(isA<DeckException>()));
        expect((await database.account(account.id))!.syncNotBefore, isNotNull);
        first.dispose();
        final before = requests;
        final next = connect(
          MockClient((_) async {
            requests++;
            return http.Response('', 500);
          }),
        );
        await expectLater(
          request(next),
          throwsA(isA<DeckException>().having((e) => e.status, 'status', 429)),
        );
        expect(requests, before);
      },
    );
  }

  test(
    'a stale attachment GET cannot prune a newer locally confirmed file',
    () async {
      final requested = Completer<void>();
      final response = Completer<http.Response>();
      final active = connect(
        MockClient((request) {
          expect(
            request.url.path,
            endsWith('/boards/1/stacks/2/cards/8/attachments'),
          );
          requested.complete();
          return response.future;
        }),
      );
      await database.saveAttachments(account, 1, 8, [attachment(10)], 0);
      await files.cache(account.id, 1, attachment(10), [1]);
      final refresh = active.refreshAttachments(1, 2, 8);
      await requested.future;
      await database.invalidateMutation(account.id, 1);
      final epoch = (await database.account(account.id))!.contentEpoch;
      await database.saveAttachments(account, 1, 8, [attachment(11)], epoch);
      await files.cache(account.id, 1, attachment(11), [2]);
      response.complete(
        http.Response(
          jsonEncode([attachment(10).raw]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await refresh;
      expect(active.error('attachments:8'), isNull);
      expect(
        (await database.attachmentsFor(account.id, 8)).single.modified,
        11,
      );
      expect(
        await (await files.cached(
          account.id,
          1,
          attachment(11),
        ))!.readAsBytes(),
        [2],
      );
      expect(await files.cached(account.id, 1, attachment(10)), isNull);
    },
  );

  test('a late download cannot recreate files after account removal', () async {
    final requested = Completer<void>();
    final response = Completer<http.Response>();
    final active = connect(
      MockClient((_) {
        requested.complete();
        return response.future;
      }),
    );
    await files.cache(account.id, 1, attachment(10), [1]);
    final download = active.downloadAttachment(1, 2, attachment(10));
    final rejected = expectLater(download, throwsStateError);
    await requested.future;
    await accounts.remove(account.id);
    response.complete(http.Response.bytes([2], 200));
    await rejected;
    expect(await Directory('${root.path}/${account.id}').exists(), isFalse);
  });

  test('a network failure can use an explicitly marked cached copy', () async {
    final active = connect(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await files.cache(account.id, 1, attachment(10), [1, 2]);
    final downloaded = await active.downloadAttachment(1, 2, attachment(10));
    expect(downloaded.offline, isTrue);
    expect(await downloaded.file.readAsBytes(), [1, 2]);
  });

  test(
    'a server permission denial removes the cached copy instead of using it',
    () async {
      final active = connect(MockClient((_) async => http.Response('', 403)));
      await files.cache(account.id, 1, attachment(10), [1, 2]);
      await expectLater(
        active.downloadAttachment(1, 2, attachment(10)),
        throwsA(
          isA<DeckException>().having((error) => error.status, 'status', 403),
        ),
      );
      expect(await files.cached(account.id, 1, attachment(10)), isNull);
    },
  );
}
