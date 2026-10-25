import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/card_description.dart';

import 'test_support.dart';

class _Vault implements CredentialVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String reference) async => values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      values[reference] = password;
  @override
  Future<void> delete(String reference) async => values.remove(reference);
  @override
  Future<Set<String>> references() async => values.keys.toSet();
}

const _description =
    '<input type="checkbox" checked>\n\n'
    '🧪 Intro\n\n- [ ] First\n- [x] Second\n\n'
    '```markdown\n- [ ] Code only\n```\n';

class _Fixture {
  final database = DeckDatabase(NativeDatabase.memory());
  late final StoredAccount account;
  late final DeckSession session;
  late final DeckBoard board;
  final requests = <http.Request>[];
  final queuedBeforePut = <JsonObject>[];
  JsonObject remoteCard = {
    'id': 8,
    'stackId': 2,
    'title': 'Original title',
    'description': _description,
    'type': 'plain',
    'order': 0,
    'owner': 'user',
    'archived': false,
    'deletedAt': 0,
    'duedate': '2026-11-01T12:00:00.000Z',
    'labels': [],
    'assignedUsers': [],
  };
  DeckCard get card => DeckCard.fromJson(remoteCard);
  JsonObject get stack => {
    'id': 2,
    'boardId': 1,
    'title': 'Column',
    'order': 0,
    'cards': [remoteCard],
  };

  Future<void> initialize() async {
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
      userId: 'user',
    );
    board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Board',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
    });
    await database.saveBoards(account.id, account.generation, [board], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stack),
    ], null);
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          requests.add(request);
          expect(request.url.host, 'cloud.example.com');
          final path = request.url.path;
          if (path.endsWith('/cloud/capabilities')) {
            return _json({
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': {
                  'capabilities': {
                    'deck': {
                      'version': '1.18.5',
                      'apiVersions': ['1.1'],
                      'canCreateBoards': true,
                    },
                  },
                },
              },
            });
          }
          if (request.method == 'PUT' && path.endsWith('/cards/8')) {
            expect(path, '/ocs/v2.php/apps/deck/api/v1.0/cards/8');
            final writes = await database.writesFor(account.id);
            expect(writes, hasLength(1));
            expect(writes.single.kind, 'updateCard');
            queuedBeforePut.add(object(jsonDecode(writes.single.proposal)));
            final body = object(jsonDecode(request.body));
            expect(body['archived'], isNull);
            expect(body['deletedAt'], isNull);
            remoteCard = {
              ...remoteCard,
              for (final field in body.entries)
                if (field.key != 'boardId' &&
                    (!{'archived', 'deletedAt'}.contains(field.key) ||
                        field.value != null))
                  field.key: field.value,
            };
            return _json({
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': remoteCard,
              },
            });
          }
          expect(request.method, 'GET');
          if (path.endsWith('/cards/8')) return _json(remoteCard);
          if (path.endsWith('/stacks/2')) return _json(stack);
          if (path.endsWith('/stacks/archived')) return _json([]);
          if (path.endsWith('/stacks')) return _json([stack]);
          if (path.endsWith('/boards/1')) return _json(board.raw);
          throw StateError('unexpected_request');
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  }
}

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 250; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (ready()) return;
  }
  expect(
    ready(),
    isTrue,
    reason: 'The queued description change did not settle.',
  );
}

Future<void> _using(
  WidgetTester tester,
  Future<void> Function(_Fixture) action,
) async {
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(connectivity, (_) async => null);
  final fixture = (await tester.runAsync(() async {
    final fixture = _Fixture();
    await fixture.initialize();
    return fixture;
  }))!;
  addTearDown(() async {
    await fixture.database.close();
    messenger.setMockMethodCallHandler(connectivity, null);
  });
  try {
    await action(fixture);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.session.dispose();
    await tester.pumpAndSettle();
  }
}

Widget _descriptionWidget(
  _Fixture fixture,
  DeckCard card, {
  bool canEdit = true,
}) => CardDescription(
  session: fixture.session,
  boardId: 1,
  card: card,
  canEdit: canEdit,
  openLink: (_) {},
);

void main() {
  testWidgets(
    'task on/off persists through outbox and readback without HTML index shift',
    (tester) async {
      await _using(tester, (fixture) async {
        final stream = fixture.database.watchCard(fixture.account.id, 1, 8);
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StreamBuilder<DeckCard?>(
                  stream: stream,
                  initialData: fixture.card,
                  builder: (_, snapshot) =>
                      _descriptionWidget(fixture, snapshot.data!),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Checkbox), findsNWidgets(2));
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).first).value,
          isFalse,
        );
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).last).value,
          isTrue,
        );
        final checked = _description.replaceFirst('- [ ] First', '- [x] First');
        await tester.tap(find.byType(Checkbox).first);
        await _until(
          tester,
          () =>
              fixture.remoteCard['description'] == checked &&
              !fixture.session.loading('board:1'),
        );
        expect(fixture.queuedBeforePut.single['description'], checked);
        expect(fixture.remoteCard['title'], 'Original title');
        expect(fixture.remoteCard['duedate'], '2026-11-01T12:00:00.000Z');
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).first).value,
          isTrue,
        );
        expect(
          await tester.runAsync(
            () => fixture.database.writesFor(fixture.account.id),
          ),
          isEmpty,
        );
        await tester.tap(find.byType(Checkbox).first);
        await _until(
          tester,
          () =>
              fixture.queuedBeforePut.length == 2 &&
              fixture.remoteCard['description'] == _description &&
              !fixture.session.loading('board:1'),
        );
        expect(fixture.queuedBeforePut.last['description'], _description);
        expect(
          fixture.requests.where((request) => request.method == 'PUT'),
          hasLength(2),
        );
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('read-only description disables tasks and produces no writes', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: _descriptionWidget(fixture, fixture.card, canEdit: false),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final checkbox in tester.widgetList<Checkbox>(
        find.byType(Checkbox),
      )) {
        expect(checkbox.onChanged, isNull);
      }
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(
        await tester.runAsync(
          () => fixture.database.writesFor(fixture.account.id),
        ),
        isEmpty,
      );
      expect(fixture.requests, isEmpty);
    });
  });

  testWidgets('a stale description cannot replace a newer cached description', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      final original = fixture.card;
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(body: _descriptionWidget(fixture, original)),
        ),
      );
      await tester.pumpAndSettle();
      fixture.remoteCard = {
        ...fixture.remoteCard,
        'description': '- [ ] New server work',
      };
      await tester.runAsync(
        () => fixture.database.saveStacks(
          fixture.account.id,
          fixture.account.generation,
          1,
          [DeckStack.fromJson(fixture.stack)],
          null,
        ),
      );
      await tester.tap(find.byType(Checkbox).first);
      await _until(tester, () => find.byType(SnackBar).evaluate().isNotEmpty);
      expect(
        await tester.runAsync(
          () => fixture.database.writesFor(fixture.account.id),
        ),
        isEmpty,
      );
      final current = await tester.runAsync(
        () => fixture.database.watchCard(fixture.account.id, 1, 8).first,
      );
      expect(current?.description, '- [ ] New server work');
      expect(fixture.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
