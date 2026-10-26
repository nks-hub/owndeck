import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;

final class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String k) async => values[k];
  @override
  Future<void> write(String k, String v) async {
    values[k] = v;
  }

  @override
  Future<void> delete(String k) async {
    values.remove(k);
  }

  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

final class _MoveTransport extends http.BaseClient {
  _MoveTransport(this.inner, this.cardId);
  final http.Client inner;
  final int cardId;
  final mutations = <String>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'PUT' &&
        (request.url.path.endsWith('/cards/$cardId') ||
            request.url.path.contains('/cards/$cardId/'))) {
      mutations.add(
        request.url.path.contains('/ocs/')
            ? request.url.path.endsWith('/reorder')
                  ? 'ocs-reorder'
                  : 'ocs-update'
            : 'rest-update',
      );
    }
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}

final class _ProbeFailure implements Exception {
  const _ProbeFailure(this.code);
  final String code;
}

void check(bool ok, String code) {
  if (!ok) throw _ProbeFailure(code);
}

Future<void> main(List<String> args) async {
  try {
    check(args.length == 3, 'config_report_and_revision_required');
    await runTransferProbe(args);
  } catch (error) {
    final reason = error is _ProbeFailure ? error.code : error.runtimeType;
    stderr.writeln('Transfer probe failed: $reason');
    exitCode = 1;
  }
}

Future<void> runTransferProbe(List<String> args) async {
  check(
    Platform.isLinux &&
        Platform.environment['GITHUB_ACTIONS'] == 'true' &&
        Platform.environment['COMPAT_RUNNER_ENV'] == 'github-hosted' &&
        Platform.environment['GITHUB_REPOSITORY'] == 'nks-hub/owndeck' &&
        Platform.environment['GITHUB_EVENT_NAME'] == 'workflow_dispatch' &&
        RegExp(r'^[a-f0-9]{40}$').hasMatch(args[2]) &&
        args[2] == Platform.environment['GITHUB_SHA'],
    'owned_manual_ci_required',
  );
  final config = object(jsonDecode(await File(args[0]).readAsString()));
  final out = Directory(args[1]);
  await out.create(recursive: true);
  final ledgerFile = File('${File(args[0]).parent.path}/transfer-ledger.json');
  check(!await ledgerFile.exists(), 'existing_run_ledger');
  final actors = object(config['actors']);
  final owner = object(actors['owner']);
  final actor = object(actors['reader']);
  final server = ServerBase.parse(stringField(config, 'server'));
  final clients = <http.Client>[];
  check(
    {'127.0.0.1', 'localhost'}.contains(server.uri.host),
    'loopback_fixture_required',
  );
  check(config['deckVersion'] == '1.19.1', 'unexpected_deck_fixture');
  check(
    owner['uid'] == 'qa-owner' && actor['uid'] == 'qa-reader',
    'unexpected_fixture_actor',
  );
  http.Client createTransport() => CertificateHttpClient(
    server: server.uri,
    fingerprint: stringField(config, 'fingerprint'),
  );
  DeckClient api(JsonObject identity, [http.Client? overrideTransport]) {
    final httpClient = overrideTransport ?? createTransport();
    clients.add(httpClient);
    return DeckClient(
      base: server,
      loginName: stringField(identity, 'uid'),
      appPassword: stringField(identity, 'appPassword'),
      transport: httpClient,
    );
  }

  final direct = api(owner);
  final boards = <int>[];
  final cards = <int>[];
  final files = <String>[];
  final unresolvedUploads = <String>{};
  final title = 'OwnDeck transfer test ${DateTime.now().toUtc().microsecondsSinceEpoch}';
  final report = <String, Object?>{
    'sourceRevision': args[2],
    'uiE2E': false,
    'transport': 'production DeckClient and DeckSync over HTTPS',
    'checks': <String, Object?>{},
  };
  Future<void> ledger() => ledgerFile.writeAsString(
    jsonEncode({
      'title': title,
      'boards': boards,
      'cards': cards,
      'files': files,
    }),
  );
  Future<DeckBoard> readBoard(DeckClient client, int id) async =>
      DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '$id'])).data),
      );
  Future<DeckBoard> createBoard(String suffix) async {
    final board = DeckBoard.fromJson(
      object(
        (await direct.rest(
          'POST',
          ['boards'],
          body: {'title': '$title $suffix', 'color': '008080'},
        )).data,
      ),
    );
    boards.add(board.id);
    await ledger();
    return board;
  }

  Future<DeckStack> createStack(int boardId) async => DeckStack.fromJson(
    object(
      (await direct.rest(
        'POST',
        ['boards', '$boardId', 'stacks'],
        body: {'title': 'Probe', 'order': 0},
      )).data,
    ),
  );
  Future<DeckCard> createCard(
    int boardId,
    int stackId,
    String name,
    int order,
  ) async {
    final card = DeckCard.fromJson(
      object(
        (await direct.rest(
          'POST',
          ['boards', '$boardId', 'stacks', '$stackId', 'cards'],
          body: {
            'title': name,
            'description': 'Preserved body',
            'type': 'plain',
            'order': order,
            'duedate': '2030-02-03T15:30:00Z',
            'startdate': '2030-02-01T10:00:00Z',
            'color': '336699',
          },
        )).data,
      ),
    );
    cards.add(card.id);
    await ledger();
    return card;
  }

  var failed = false;
  try {
    await ledger();
    check(await direct.currentUserId() == owner['uid'], 'wrong_owner');
    report['deckVersion'] = (await direct.capabilities()).version;
    final caps = object(
      (await direct.ocs('GET', ['cloud', 'capabilities'])).data,
    );
    report['nextcloudVersion'] = object(caps['version'])['string'];
    for (final manage in [true, false]) {
      report['phase'] = 'fixtures_manage_$manage';
      final source = await createBoard('source $manage');
      final target = await createBoard('target $manage');
      final sourceStack = await createStack(source.id);
      final targetStack = await createStack(target.id);
      if (!manage) {
        for (final id in [source.id, target.id]) {
          await direct.rest(
            'POST',
            ['boards', '$id', 'acl'],
            body: {
              'type': 0,
              'participant': actor['uid'],
              'permissionEdit': true,
              'permissionShare': false,
              'permissionManage': false,
            },
          );
        }
      }
      final sourceLabels = <int>[];
      for (final name in ['Shared label', 'Missing target label']) {
        final label = object(
          (await direct.rest(
            'POST',
            ['boards', '${source.id}', 'labels'],
            body: {'title': name, 'color': '336699'},
          )).data,
        );
        sourceLabels.add(intField(label, 'id'));
      }
      final targetLabel = object(
        (await direct.rest(
          'POST',
          ['boards', '${target.id}', 'labels'],
          body: {'title': 'Shared label', 'color': '993366'},
        )).data,
      );
      final card = await createCard(
        source.id,
        sourceStack.id,
        'Transfer $manage',
        0,
      );
      final left = await createCard(target.id, targetStack.id, 'Left', 0);
      final right = await createCard(target.id, targetStack.id, 'Right', 1);
      final path = [
        'boards',
        '${source.id}',
        'stacks',
        '${sourceStack.id}',
        'cards',
        '${card.id}',
      ];
      for (final labelId in sourceLabels) {
        await direct.rest(
          'PUT',
          [...path, 'assignLabel'],
          body: {'labelId': labelId},
        );
      }
      await direct.rest(
        'PUT',
        [...path, 'assignUser'],
        body: {'userId': owner['uid'], 'type': 0},
      );
      final comment = object(
        (await direct.ocs(
          'POST',
          ['apps', 'deck', 'api', 'v1.0', 'cards', '${card.id}', 'comments'],
          body: {'message': 'Preserved transfer comment', 'parentId': 0},
        )).data,
      );
      final filename =
          'transfer-${card.id}-${DateTime.now().toUtc().microsecondsSinceEpoch}.txt';
      final bytes = utf8.encode('OwnDeck transfer attachment ${card.id}\n');
      report['pendingUploadName'] = filename;
      unresolvedUploads.add(filename);
      await File(
        '${File(args[0]).parent.path}/transfer-upload-intent.json',
      ).writeAsString(jsonEncode({'name': filename, 'cardId': card.id}));
      final uploaded = await direct.uploadAttachment(
        source.id,
        sourceStack.id,
        card.id,
        filename: filename,
        mime: 'text/plain',
        length: bytes.length,
        bytes: Stream.value(bytes),
      );
      final attachment = (await direct.attachments(
        source.id,
        sourceStack.id,
        card.id,
      )).singleWhere((a) => a.id == uploaded.id);
      final filePath = attachment.path;
      check(
        filePath != null && filePath.split('/').last == filename,
        'invalid_probe_file_path',
      );
      files.add(filePath!);
      unresolvedUploads.remove(filename);
      await ledger();
      report['phase'] = 'read_fixture_after_upload';
      var original = DeckCard.fromJson(
        object((await direct.rest('GET', path)).data),
      );
      report['phase'] = 'set_done_after_upload';
      await direct.updateCardSafely(
        CardUpdateRequest.fromCard(
          original,
          boardId: source.id,
          changes: {'done': '2030-02-02T12:00:00Z'},
        ),
      );
      report['phase'] = 'read_updated_fixture';
      original = DeckCard.fromJson(
        object((await direct.rest('GET', path)).data),
      );
      final identity = manage ? owner : actor;
      final transport = _MoveTransport(createTransport(), card.id);
      final movingClient = api(identity, transport);
      report['phase'] = 'read_mover_identity';
      check(
        await movingClient.currentUserId() == identity['uid'],
        'wrong_mover',
      );
      final db = DeckDatabase(NativeDatabase.memory());
      final account = await AccountRepository(db, _Vault()).add(
        LoginCredentials(
          server: server,
          loginName: stringField(identity, 'uid'),
          appPassword: stringField(identity, 'appPassword'),
        ),
      );
      final sync = DeckSync(db, account, movingClient);
      try {
        report['phase'] = 'cache_capabilities';
        await db.saveCapabilities(account, await movingClient.capabilities());
        report['phase'] = 'cache_boards';
        final sourceNow = await readBoard(movingClient, source.id);
        final targetNow = await readBoard(movingClient, target.id);
        check(
          sourceNow.permissions.edit && targetNow.permissions.edit,
          'missing_edit',
        );
        check(targetNow.permissions.manage == manage, 'unexpected_manage');
        await db.saveBoards(account.id, account.generation, [
          sourceNow,
          targetNow,
        ], null);
        report['phase'] = 'cache_stacks';
        for (final board in [sourceNow, targetNow]) {
          await db.saveStacks(
            account.id,
            account.generation,
            board.id,
            await movingClient.doneStackState(board.id),
            null,
          );
        }
        await db.queueCardTransfer(
          account,
          source.id,
          original,
          destinationBoardId: target.id,
          destinationStackId: targetStack.id,
          anchorCardId: right.id,
          before: true,
        );
        report['phase'] = 'sync_manage_$manage';
        await sync.run();
        await sync.run();
        final writes = await db.writesFor(account.id);
        report['pending'] = writes
            .map((w) => {'kind': w.kind, 'state': w.state, 'error': w.error})
            .toList();
        check(writes.isEmpty, 'transfer_not_confirmed');
        check(
          jsonEncode(transport.mutations) ==
              jsonEncode(['ocs-update', 'ocs-reorder']),
          'wrong_mutations',
        );
        final after = DeckCard.fromJson(
          object(
            (await direct.rest('GET', [
              'boards',
              '${target.id}',
              'stacks',
              '${targetStack.id}',
              'cards',
              '${card.id}',
            ])).data,
          ),
        );
        check(
          after.id == original.id && after.stackId == targetStack.id,
          'identity_changed',
        );
        for (final field in [
          'title',
          'description',
          'type',
          'duedate',
          'startdate',
          'color',
          'done',
        ]) {
          check(
            jsonEncode(after.raw[field]) == jsonEncode(original.raw[field]),
            'field_changed_$field',
          );
        }
        Object? ownerId(Object? value) => value is String
            ? value
            : value is Map
            ? value['uid']
            : null;
        check(
          ownerId(after.raw['owner']) == ownerId(original.raw['owner']),
          'owner_changed',
        );
        check(
          jsonEncode(after.raw['assignedUsers']) ==
              jsonEncode(original.raw['assignedUsers']),
          'assignments_changed',
        );
        final labels = (after.raw['labels'] as List).map(object).toList();
        check(
          labels.any((l) => l['id'] == targetLabel['id']),
          'shared_label_not_mapped',
        );
        check(
          labels.any((l) => l['title'] == 'Missing target label') == manage,
          'missing_label_policy',
        );
        check(
          !labels.any((l) => sourceLabels.contains(l['id'])),
          'source_label_retained',
        );
        final comments = <DeckComment>[];
        await for (final page in movingClient.commentPages(card.id)) {
          comments.addAll(page);
        }
        check(
          comments.any(
            (c) =>
                c.id == comment['id'] &&
                c.message == 'Preserved transfer comment',
          ),
          'comment_lost',
        );
        final attachments = await movingClient.attachments(
          target.id,
          targetStack.id,
          card.id,
        );
        final kept = attachments.singleWhere((a) => a.id == attachment.id);
        final downloaded = await movingClient.downloadAttachment(
          target.id,
          targetStack.id,
          kept,
        );
        check(
          base64Encode(downloaded) == base64Encode(bytes),
          'attachment_changed',
        );
        final stacks = await movingClient.doneStackState(target.id);
        final ordered =
            stacks
                .singleWhere((s) => s.id == targetStack.id)
                .cards
                .where((c) => !c.archived)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        check(
          jsonEncode(ordered.map((c) => c.id).toList()) ==
              jsonEncode([left.id, card.id, right.id]),
          'wrong_position',
        );
        check(
          !(await movingClient.doneStackState(
            source.id,
          )).expand((s) => s.cards).any((c) => c.id == card.id),
          'duplicate_source',
        );
        (report['checks'] as Map<String, Object?>)['manage_$manage'] = {
          'passed': true,
          'mutations': transport.mutations,
          'sameIdentity': true,
          'metadata': true,
          'labelMigration': true,
          'assignments': true,
          'comments': true,
          'attachmentBytes': bytes.length,
          'attachmentExactBytes': true,
          'positionBeforeAnchor': true,
        };
        print(jsonEncode({'case': 'manage_$manage', 'passed': true}));
      } finally {
        sync.close();
        await db.close();
      }
    }
    report['status'] = 'passed';
  } catch (error) {
    failed = true;
    report['status'] = 'failed';
    report['failure'] = error is DeckException
        ? {
            'code': error.code,
            'status': error.status,
            'uncertain': error.uncertain,
          }
        : error is _ProbeFailure
        ? error.code
        : error.runtimeType.toString();
  } finally {
    final cleanup = <String, Object?>{};
    final httpClient = createTransport();
    try {
      final auth = {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('${owner['uid']}:${owner['appPassword']}'))}',
      };
      for (final path in files) {
        try {
          final uri = server.endpoint([
            'remote.php',
            'dav',
            'files',
            stringField(owner, 'uid'),
            ...path.split('/').where((p) => p.isNotEmpty),
          ]);
          final deleted = await httpClient
              .delete(uri, headers: auth)
              .timeout(const Duration(seconds: 30));
          final absent = await httpClient
              .head(uri, headers: auth)
              .timeout(const Duration(seconds: 30));
          cleanup['file-${files.indexOf(path)}'] =
              {204, 404}.contains(deleted.statusCode) &&
              absent.statusCode == 404;
        } catch (_) {
          cleanup['file-${files.indexOf(path)}'] = false;
        }
      }
    } finally {
      httpClient.close();
    }
    for (final id in boards) {
      try {
        await direct.rest('DELETE', ['boards', '$id']);
        cleanup['board-$id'] = !(await direct.boards()).any(
          (b) => b.id == id && b.deletedAt == 0,
        );
      } catch (_) {
        cleanup['board-$id'] = false;
      }
    }
    report['cleanup'] = cleanup;
    report['unresolvedUploads'] = unresolvedUploads.length;
    report['cleanupVerified'] =
        boards.isNotEmpty &&
        unresolvedUploads.isEmpty &&
        cleanup.values.every((v) => v == true);
    if (report['cleanupVerified'] != true) {
      failed = true;
      report['status'] = 'failed';
    }
    try {
      await File(
        '${out.path}/transfer.json',
      ).writeAsString(JsonEncoder.withIndent('  ').convert(report));
    } finally {
      for (final client in clients) {
        client.close();
      }
    }
  }
  print(
    jsonEncode({
      'status': report['status'],
      'cleanupVerified': report['cleanupVerified'],
    }),
  );
  if (failed) exitCode = 1;
}
