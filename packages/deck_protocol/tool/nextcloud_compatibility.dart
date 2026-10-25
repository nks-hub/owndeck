import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:deck_protocol/deck_protocol.dart';
import 'package:http/http.dart' as http;

const cloneFlags = [
  'withCards',
  'withAssignments',
  'withLabels',
  'withDueDate',
  'moveCardsToLeftStack',
  'restoreArchivedCards',
];

final class CheckFailure implements Exception {
  const CheckFailure(this.code);
  final String code;
}

void require(bool condition, String code) {
  if (!condition) throw CheckFailure(code);
}

String participant(Object? value) {
  if (value is String) return value;
  final json = object(value);
  return stringField(json, json.containsKey('uid') ? 'uid' : 'id');
}

List<String> labels(Object? value) => objects(
  value ?? <Object?>[],
).map((item) => '${item['title']}|${item['color']}').toList()..sort();

List<String> assignments(DeckCard card) => objects(
  card.raw['assignedUsers'] ?? <Object?>[],
).map((item) => participant(item['participant'])).toList()..sort();

List<String> acl(DeckBoard board) =>
    objects(board.raw['acl'] ?? <Object?>[])
        .map(
          (item) => jsonEncode([
            item['type'],
            participant(item['participant']),
            item['permissionEdit'],
            item['permissionShare'],
            item['permissionManage'],
          ]),
        )
        .toList()
      ..sort();

String? instant(Object? value) => value == null
    ? null
    : DateTime.parse(value as String).toUtc().toIso8601String();

final class TracedClient extends http.BaseClient {
  TracedClient(this.inner, this.requests);
  final http.Client inner;
  final List<JsonObject> requests;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final isClone = request.url.path.endsWith('/clone');
    JsonObject? observation;
    if (isClone) {
      require(request is http.Request, 'unexpected_clone_request_type');
      final options = object(jsonDecode((request as http.Request).body));
      require(
        options.keys.toSet().containsAll(cloneFlags) &&
            options.length == cloneFlags.length,
        'unexpected_clone_flags',
      );
      observation = {
        'method': request.method,
        'authorizationScheme': request.headers['Authorization']
            ?.split(' ')
            .first,
        'hasCookie': request.headers.containsKey('Cookie'),
        'hasCsrfHeader': request.headers.containsKey('requesttoken'),
        'hasQuery': request.url.hasQuery,
        'ocsApiRequest': request.headers['OCS-APIRequest'],
        'options': options,
      };
      require(
        observation['authorizationScheme'] == 'Basic' &&
            observation['hasCookie'] == false &&
            observation['hasCsrfHeader'] == false &&
            observation['hasQuery'] == false &&
            observation['ocsApiRequest'] == 'true',
        'non_native_clone_authentication',
      );
      requests.add(observation);
    }
    final response = await inner.send(request);
    if (observation == null) return response;
    final bytes = await response.stream.toBytes();
    observation.addAll({
      'httpStatus': response.statusCode,
      'csrfIndicated': utf8
          .decode(bytes, allowMalformed: true)
          .toLowerCase()
          .contains('csrf'),
    });
    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      contentLength: bytes.length,
      request: request,
    );
  }

  @override
  void close() => inner.close();
}

final class CompatibilityProbe {
  CompatibilityProbe(this.config, this.directory, this.mode) {
    final base = ServerBase.parse(stringField(config, 'server'));
    require(
      {'127.0.0.1', 'localhost'}.contains(base.uri.host),
      'loopback_fixture_required',
    );
    require(config['deckVersion'] == '1.19.1', 'unexpected_deck_fixture');
    final actors = object(config['actors']);
    for (final role in ['owner', 'reader']) {
      final actor = object(actors[role]);
      require(actor['uid'] == 'qa-$role', 'unexpected_actor');
      final transport = TracedClient(
        CertificateHttpClient(
          server: base.uri,
          fingerprint: stringField(config, 'fingerprint'),
        ),
        requests,
      );
      transports.add(transport);
      clients[role] = DeckClient(
        base: base,
        loginName: stringField(actor, 'uid'),
        appPassword: stringField(actor, 'appPassword'),
        transport: transport,
      );
    }
  }

  final JsonObject config;
  final Directory directory;
  final String mode;
  final requests = <JsonObject>[];
  final checks = <JsonObject>[];
  final clients = <String, DeckClient>{};
  final transports = <http.Client>[];
  final observations = <String, Object?>{};
  final clonedBoards = <int>[];
  int? sourceId;
  int? shareId;
  DeckBoard? source;
  List<DeckStack> sourceStacks = [];
  String phase = 'setup';
  DeckClient get owner => clients['owner']!;
  DeckClient get reader => clients['reader']!;

  Future<void> save({String status = 'running'}) =>
      File('${directory.path}/$mode.json').writeAsString(
        jsonEncode({
          'sourceRevision': Platform.environment['GITHUB_SHA'],
          'dartVersion': Platform.version,
          'deckVersion': config['deckVersion'],
          'status': status,
          'phase': phase,
          'checks': checks,
          'cloneRequests': requests,
          'observations': observations,
        }),
        flush: true,
      );

  Future<void> check(String name, Future<void> Function() operation) async {
    phase = name;
    await save();
    try {
      await operation();
      checks.add({'name': name, 'status': 'passed'});
    } catch (error) {
      checks.add({
        'name': name,
        'status': 'failed',
        'errorType': error.runtimeType.toString(),
        if (error is CheckFailure) 'code': error.code,
        if (error is DeckException) ...{
          'code': error.code,
          'httpStatus': error.status,
          'uncertain': error.uncertain,
        },
      });
      await save(status: 'failed');
      rethrow;
    }
    await save();
  }

  Future<DeckBoard> readBoard(DeckClient client, int id) async =>
      DeckBoard.fromJson(
        object((await client.rest('GET', ['boards', '$id'])).data),
      );

  Future<DeckCard> readCard(
    DeckClient client,
    int boardId,
    int stackId,
    int id,
  ) async => DeckCard.fromJson(
    object(
      (await client.rest('GET', [
        'boards',
        '$boardId',
        'stacks',
        '$stackId',
        'cards',
        '$id',
      ])).data,
    ),
  );

  Future<int> denied(Future<Object?> Function() operation) async {
    try {
      await operation();
    } on DeckException catch (error) {
      require(error.status == 403 && !error.uncertain, 'unexpected_denial');
      return error.status!;
    }
    throw const CheckFailure('mutation_was_not_denied');
  }

  Future<void> authenticate() async {
    for (final entry in clients.entries) {
      require(
        await entry.value.currentUserId() == 'qa-${entry.key}',
        'wrong_authenticated_user',
      );
      final capabilities = await entry.value.capabilities();
      require(
        capabilities.version == '1.19.1' && capabilities.apiVersion == '1.1',
        'runtime_version_mismatch',
      );
    }
  }

  Future<void> fixture() async {
    final created = DeckBoard.fromJson(
      object(
        (await owner.rest(
          'POST',
          ['boards'],
          body: {
            'title': 'Compatibility ${config['runId']}',
            'color': '336699',
          },
        )).data,
      ),
    );
    sourceId = created.id;
    await File(
      '${directory.path}/fixture.json',
    ).writeAsString(jsonEncode({'boardId': sourceId}), flush: true);
    final stackIds = <int>[];
    for (final (order, name) in [(0, 'First'), (1, 'Second')]) {
      final result = object(
        (await owner.rest(
          'POST',
          ['boards', '$sourceId', 'stacks'],
          body: {'title': name, 'order': order},
        )).data,
      );
      stackIds.add(intField(result, 'id'));
    }
    final share = object(
      (await owner.rest(
        'POST',
        ['boards', '$sourceId', 'acl'],
        body: {
          'type': 0,
          'participant': 'qa-reader',
          'permissionEdit': false,
          'permissionShare': false,
          'permissionManage': false,
        },
      )).data,
    );
    shareId = intField(share, 'id');
    final label = object(
      (await owner.rest(
        'POST',
        ['boards', '$sourceId', 'labels'],
        body: {'title': 'Fixture label', 'color': '2255aa'},
      )).data,
    );
    const due = '2030-01-15T12:00:00Z';
    const start = '2030-01-14T10:00:00Z';
    final active = DeckCard.fromJson(
      object(
        (await owner.rest(
          'POST',
          ['boards', '$sourceId', 'stacks', '${stackIds[0]}', 'cards'],
          body: {
            'title': 'Active card',
            'description': 'Fixture description',
            'type': 'plain',
            'order': 0,
            'duedate': due,
            'startdate': start,
            'color': '336699',
          },
        )).data,
      ),
    );
    final path = [
      'boards',
      '$sourceId',
      'stacks',
      '${stackIds[0]}',
      'cards',
      '${active.id}',
    ];
    await check('extended_fields_create_update_clear', () async {
      var card = await readCard(owner, sourceId!, stackIds[0], active.id);
      require(
        instant(card.raw['startdate']) == instant(start) &&
            card.rgbColor == 0x336699,
        'extended_create_mismatch',
      );
      await owner.rest(
        'PUT',
        path,
        body: card.updateBody({
          'startdate': '2030-01-13T09:00:00Z',
          'color': 'aabbcc',
        }),
      );
      card = await readCard(owner, sourceId!, stackIds[0], active.id);
      require(
        instant(card.raw['startdate']) == instant('2030-01-13T09:00:00Z') &&
            card.rgbColor == 0xaabbcc,
        'extended_update_mismatch',
      );
      await owner.rest(
        'PUT',
        path,
        body: card.updateBody({'startdate': null, 'color': null}),
      );
      card = await readCard(owner, sourceId!, stackIds[0], active.id);
      require(
        card.raw['startdate'] == null &&
            card.raw['color'] == null &&
            instant(card.raw['duedate']) == instant(due),
        'extended_clear_mismatch',
      );
      await owner.rest(
        'PUT',
        path,
        body: card.updateBody({'startdate': start, 'color': '336699'}),
      );
    });
    await owner.rest(
      'PUT',
      [...path, 'assignLabel'],
      body: {'labelId': label['id']},
    );
    await owner.rest(
      'PUT',
      [...path, 'assignUser'],
      body: {'userId': 'qa-reader', 'type': 0},
    );
    final archived = DeckCard.fromJson(
      object(
        (await owner.rest(
          'POST',
          ['boards', '$sourceId', 'stacks', '${stackIds[1]}', 'cards'],
          body: {
            'title': 'Archived card',
            'description': 'Archived fixture',
            'type': 'plain',
            'order': 0,
            'duedate': '2030-02-01T12:00:00Z',
          },
        )).data,
      ),
    );
    await owner.rest('PUT', [
      'boards',
      '$sourceId',
      'stacks',
      '${stackIds[1]}',
      'cards',
      '${archived.id}',
      'archive',
    ]);
    await owner.ocs(
      'POST',
      ['apps', 'deck', 'api', 'v1.0', 'cards', '${active.id}', 'comments'],
      body: {'message': 'Fixture comment', 'parentId': 0},
    );
    final bytes = utf8.encode('Owned compatibility fixture');
    await owner.uploadAttachment(
      sourceId!,
      stackIds[0],
      active.id,
      filename: 'fixture.txt',
      mime: 'text/plain',
      length: bytes.length,
      bytes: Stream.value(bytes),
    );
    source = await readBoard(owner, sourceId!);
    sourceStacks = await owner.doneStackState(sourceId!);
    require(
      sourceStacks.length == 2 &&
          sourceStacks.expand((s) => s.cards).length == 2,
      'source_card_count',
    );
    final permissions = (await readBoard(reader, sourceId!)).permissions;
    require(
      permissions.read &&
          !permissions.edit &&
          !permissions.manage &&
          !permissions.share,
      'reader_not_read_only',
    );
    require(
      (await owner.capabilities()).canCreateBoards &&
          (await reader.capabilities()).canCreateBoards,
      'initial_creation_disabled',
    );
  }

  String sourceFingerprint(DeckBoard board, List<DeckStack> stacks) => sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'title': board.title,
            'color': board.color,
            'acl': acl(board),
            'labels': labels(board.raw['labels']),
            'stacks': [
              for (final stack in stacks)
                {
                  'title': stack.title,
                  'order': stack.order,
                  'cards': [
                    for (final card in stack.cards)
                      {
                        'title': card.title,
                        'description': card.description,
                        'archived': card.archived,
                        'due': instant(card.raw['duedate']),
                        'start': instant(card.raw['startdate']),
                        'color': card.raw['color'],
                        'labels': labels(card.raw['labels']),
                        'assignments': assignments(card),
                      },
                  ],
                },
            ],
          }),
        ),
      )
      .toString();

  Future<void> cloneAndCheck(
    String name,
    String role,
    Set<String> enabled,
  ) => check(name, () async {
    final client = clients[role]!;
    final options = <String, Object?>{
      for (final flag in cloneFlags) flag: enabled.contains(flag),
    };
    final copied = DeckBoard.fromJson(
      object(
        (await client.rest('POST', [
          'boards',
          '$sourceId',
          'clone',
        ], body: options)).data,
      ),
    );
    require(copied.id > 0 && copied.id != sourceId, 'invalid_clone_identity');
    clonedBoards.add(copied.id);
    final board = await readBoard(client, copied.id);
    require(
      participant(board.raw['owner']) == 'qa-$role' &&
          board.permissions.read &&
          board.permissions.manage,
      'clone_owner_or_permissions',
    );
    require(
      board.color == source!.color && board.title.startsWith(source!.title),
      'clone_board_fields',
    );
    require(
      jsonEncode(acl(board)) == jsonEncode(acl(source!)),
      'clone_acl_mismatch',
    );
    require(
      jsonEncode(labels(board.raw['labels'])) ==
          jsonEncode(labels(source!.raw['labels'])),
      'clone_label_definitions',
    );
    final stacks = await client.doneStackState(board.id);
    require(stacks.length == sourceStacks.length, 'clone_stack_count');
    require(
      jsonEncode(stacks.map((s) => [s.title, s.order]).toList()) ==
          jsonEncode(sourceStacks.map((s) => [s.title, s.order]).toList()),
      'clone_stack_structure',
    );
    final sourceCards = {
      for (final stack in sourceStacks)
        for (final card in stack.cards) card.title: card,
    };
    final cards = [for (final stack in stacks) ...stack.cards];
    require(
      cards.length == (enabled.contains('withCards') ? sourceCards.length : 0),
      'clone_card_count',
    );
    for (final card in cards) {
      final original = sourceCards[card.title];
      require(
        original != null && card.id != original.id,
        'clone_card_identity',
      );
      require(
        card.description == original!.description,
        'clone_card_description',
      );
      require(
        card.archived ==
            (enabled.contains('restoreArchivedCards')
                ? false
                : original.archived),
        'clone_archive_flag',
      );
      require(
        instant(card.raw['duedate']) ==
            (enabled.contains('withDueDate')
                ? instant(original.raw['duedate'])
                : null),
        'clone_due_flag',
      );
      require(
        jsonEncode(assignments(card)) ==
            jsonEncode(
              enabled.contains('withAssignments') ? assignments(original) : [],
            ),
        'clone_assignment_flag',
      );
      require(
        jsonEncode(labels(card.raw['labels'])) ==
            jsonEncode(
              enabled.contains('withLabels')
                  ? labels(original.raw['labels'])
                  : [],
            ),
        'clone_label_flag',
      );
      final actualStack = stacks.singleWhere((s) => s.id == card.stackId);
      final originalStack = sourceStacks.singleWhere(
        (s) => s.id == original.stackId,
      );
      require(
        actualStack.title ==
            (enabled.contains('moveCardsToLeftStack')
                ? stacks.first.title
                : originalStack.title),
        'clone_stack_flag',
      );
      final clonedLabelIds = objects(
        board.raw['labels'],
      ).map((label) => label['id']).toSet();
      require(
        objects(
          card.raw['labels'] ?? <Object?>[],
        ).every((label) => clonedLabelIds.contains(label['id'])),
        'clone_label_identity',
      );
      if (name == 'all_flags' || role == 'reader') {
        final comments = <DeckComment>[];
        await for (final page in client.commentPages(card.id)) {
          comments.addAll(page);
        }
        require(
          comments.isEmpty &&
              (await client.attachments(
                board.id,
                card.stackId,
                card.id,
              )).isEmpty,
          'comments_or_files_copied',
        );
      }
      if (name == 'all_flags' && card.title == 'Active card') {
        observations['extraFieldsAfterClone'] = {
          'sourceStartdate': original.raw['startdate'],
          'clonedStartdate': card.raw['startdate'],
          'sourceColor': original.raw['color'],
          'clonedColor': card.raw['color'],
        };
      }
    }
  });

  Future<void> clones() async {
    await check('app_password_authentication', authenticate);
    await fixture();
    final before = sourceFingerprint(source!, sourceStacks);
    await cloneAndCheck('empty_copy_keeps_acl_labels_and_columns', 'owner', {});
    await cloneAndCheck('cards_without_optional_metadata', 'owner', {
      'withCards',
    });
    for (final flag in cloneFlags.skip(1)) {
      await cloneAndCheck(flag, 'owner', {'withCards', flag});
    }
    await cloneAndCheck('all_flags', 'owner', cloneFlags.toSet());
    await cloneAndCheck('read_only_source_clone', 'reader', cloneFlags.toSet());
    await check('source_not_changed_by_cloning', () async {
      require(
        sourceFingerprint(
              await readBoard(owner, sourceId!),
              await owner.doneStackState(sourceId!),
            ) ==
            before,
        'source_modified',
      );
    });
    await check('missing_read_permission_denies_clone', () async {
      await owner.rest('DELETE', ['boards', '$sourceId', 'acl', '$shareId']);
      require(
        (await reader.capabilities()).canCreateBoards,
        'creation_policy_changed',
      );
      observations['missingReadStatus'] = await denied(
        () => reader.rest(
          'POST',
          ['boards', '$sourceId', 'clone'],
          body: {for (final flag in cloneFlags) flag: false},
        ),
      );
      await owner.rest(
        'POST',
        ['boards', '$sourceId', 'acl'],
        body: {
          'type': 0,
          'participant': 'qa-reader',
          'permissionEdit': false,
          'permissionShare': false,
          'permissionManage': false,
        },
      );
    });
    observations['createdCloneCount'] = clonedBoards.length;
    observations['aclCopiedEvenWithoutCards'] = true;
    observations['labelDefinitionsCopiedEvenWithoutCardLabels'] = true;
    observations['commentsAndFilesCopied'] = false;
  }

  Future<void> creationDenied() async {
    await check('app_password_authentication', authenticate);
    final fixture = object(
      jsonDecode(await File('${directory.path}/fixture.json').readAsString()),
    );
    sourceId = intField(fixture, 'boardId');
    await check('can_create_false_is_enforced_by_server', () async {
      require(
        !(await reader.capabilities()).canCreateBoards &&
            (await owner.capabilities()).canCreateBoards,
        'creation_policy_not_applied',
      );
      require(
        (await readBoard(reader, sourceId!)).permissions.read,
        'reader_source_access_lost',
      );
      final before = (await reader.boards()).map((board) => board.id).toList()
        ..sort();
      observations['deniedStatus'] = await denied(
        () => reader.rest(
          'POST',
          ['boards', '$sourceId', 'clone'],
          body: {for (final flag in cloneFlags) flag: false},
        ),
      );
      final after = (await reader.boards()).map((board) => board.id).toList()
        ..sort();
      require(
        jsonEncode(before) == jsonEncode(after),
        'denied_clone_created_board',
      );
    });
  }

  Future<bool> run() async {
    try {
      await save();
      if (mode == 'clone') {
        await clones();
      } else if (mode == 'creation-denied') {
        await creationDenied();
      } else {
        throw const CheckFailure('unknown_mode');
      }
      phase = 'complete';
      await save(status: 'passed');
      return true;
    } catch (error) {
      observations['fatalType'] = error.runtimeType.toString();
      if (error is CheckFailure) observations['fatalCode'] = error.code;
      if (error is DeckException) {
        observations.addAll({
          'fatalCode': error.code,
          'httpStatus': error.status,
        });
      }
      await save(status: 'failed');
      return false;
    } finally {
      for (final transport in transports) {
        transport.close();
      }
    }
  }
}

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length != 3) {
      throw const CheckFailure('config_report_and_mode_required');
    }
    final config = object(jsonDecode(await File(arguments[0]).readAsString()));
    final probe = CompatibilityProbe(
      config,
      Directory(arguments[1]),
      arguments[2],
    );
    if (!await probe.run()) exitCode = 1;
  } catch (error) {
    stderr.writeln('Compatibility probe failed: ${error.runtimeType}');
    exitCode = 1;
  }
}
