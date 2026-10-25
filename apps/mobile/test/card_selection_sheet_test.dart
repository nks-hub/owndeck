import 'dart:async';
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
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/card_selection_sheet.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

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

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

class _Fixture {
  final database = DeckDatabase(NativeDatabase.memory());
  late final StoredAccount account;
  late final DeckSession session;
  bool canEdit = true;
  final requests = <http.Request>[];
  final firstMutationWrites = <PendingWrite>[];
  final confirmed = <String>[];
  final labels = <JsonObject>[
    {'id': 11, 'title': 'Urgent', 'color': 'dc2626'},
    {'id': 12, 'title': 'Review', 'color': '2563eb'},
  ];
  final users = <JsonObject>[
    {'uid': 'alice', 'displayname': 'Alice'},
    {'uid': 'bob', 'displayname': 'Bob'},
  ];
  final remoteLabels = <JsonObject>[];
  final remoteUsers = <JsonObject>[];

  DeckBoard get board => DeckBoard.fromJson({
    'id': 1,
    'title': 'Project A',
    'color': '008080',
    'archived': false,
    'deletedAt': 0,
    'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': canEdit},
    'labels': labels,
    'users': users,
  });

  DeckCard get card => DeckCard.fromJson({
    'id': 8,
    'stackId': 2,
    'title': 'Task A',
    'description': 'Description',
    'order': 0,
    'type': 'plain',
    'owner': 'demo',
    'archived': false,
    'labels': remoteLabels.toList(),
    'assignedUsers': remoteUsers.toList(),
    'dependentCards': [],
  });

  JsonObject get stack => {
    'id': 2,
    'boardId': 1,
    'title': 'In progress',
    'order': 0,
    'cards': [card.raw],
  };

  Future<void> initialize() async {
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'demo',
        appPassword: 'test-password',
      ),
    );
    await database.saveBoards(account.id, account.generation, [board], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stack),
    ], null);
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'demo',
        appPassword: 'test-password',
        transport: MockClient((request) async {
          requests.add(request);
          final path = request.url.path;
          if (request.method == 'PUT') {
            if (firstMutationWrites.isEmpty) {
              firstMutationWrites.addAll(await database.writesFor(account.id));
            }
            final body = object(jsonDecode(request.body));
            if (path.endsWith('/assignLabel')) {
              final id = body['labelId'];
              remoteLabels.add(
                labels.singleWhere((label) => label['id'] == id),
              );
              confirmed.add('label:$id');
            } else if (path.endsWith('/removeLabel')) {
              final id = body['labelId'];
              remoteLabels.removeWhere((label) => label['id'] == id);
              confirmed.add('remove-label:$id');
            } else if (path.endsWith('/assignUser')) {
              final id = body['userId'];
              remoteUsers.add({
                'type': 0,
                'participant': users.singleWhere((user) => user['uid'] == id),
              });
              confirmed.add('user:$id');
            } else if (path.endsWith('/unassignUser')) {
              final id = body['userId'];
              final type = body['type'];
              remoteUsers.removeWhere(
                (assignment) =>
                    (assignment['participant'] as Map)['uid'] == id &&
                    assignment['type'] == type,
              );
              confirmed.add('remove-user:$id');
            } else {
              throw StateError('unexpected_mutation');
            }
            return _json({});
          }
          expect(request.method, 'GET');
          if (path.endsWith('/cards/8')) return _json(card.raw);
          if (path.endsWith('/stacks/2')) return _json(stack);
          if (path.endsWith('/stacks/archived')) return _json([]);
          if (path.endsWith('/stacks')) return _json([stack]);
          if (path.endsWith('/boards/1')) return _json(board.raw);
          if (path.endsWith('/capabilities')) {
            return _json({
              'ocs': {
                'meta': {'status': 'ok', 'statuscode': 200},
                'data': {
                  'capabilities': {
                    'deck': {
                      'version': '1.19.1',
                      'apiVersions': ['1.1'],
                      'canCreateBoards': true,
                    },
                  },
                },
              },
            });
          }
          throw StateError('unexpected_read');
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  }

  Future<void> revokeEdit() async {
    canEdit = false;
    await database.saveBoards(account.id, account.generation, [board], null);
  }

  Future<void> seedPriorMembership({bool named = true}) async {
    remoteLabels.add({
      'id': 33,
      'title': named ? 'Previous label' : {'internal': 'opaque-label'},
      'color': '008080',
    });
    remoteUsers.add({
      'type': 0,
      'participant': {
        'uid': 'previous-user',
        if (named) 'displayname': 'Former teammate',
      },
    });
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson(stack),
    ], null);
  }
}

Widget _app(Widget home, {double scale = 1, String language = 'en'}) =>
    MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    );

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 200; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (ready()) return;
  }
  expect(ready(), isTrue);
}

Future<void> _using(
  WidgetTester tester,
  Future<void> Function(_Fixture) body,
) async {
  const channel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (_) async => null);
  final fixture = (await tester.runAsync(() async {
    final value = _Fixture();
    await value.initialize();
    return value;
  }))!;
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    messenger.setMockMethodCallHandler(channel, null);
    await fixture.database.close();
  });
  try {
    await body(fixture);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.session.dispose();
    await tester.pumpAndSettle();
  }
}

Future<void> _open(
  WidgetTester tester,
  _Fixture fixture,
  String action, {
  int optionCount = 2,
}) async {
  await tester.pumpWidget(
    _app(
      CardScreen(
        session: fixture.session,
        board: fixture.board,
        card: fixture.card,
      ),
    ),
  );
  await _until(
    tester,
    () => find.widgetWithText(TextButton, action).evaluate().isNotEmpty,
  );
  await tester.ensureVisible(find.widgetWithText(TextButton, action));
  await tester.tap(find.widgetWithText(TextButton, action));
  await tester.pumpAndSettle();
  expect(find.byType(CheckboxListTile), findsNWidgets(optionCount));
}

void main() {
  testWidgets(
    'removing an old group preserves the assignment type when a user has the same identifier',
    (tester) async {
      await _using(tester, (fixture) async {
        await tester.runAsync(() async {
          fixture.remoteUsers.add({
            'type': 1,
            'participant': {'uid': 'alice', 'displayname': 'Previous team'},
          });
          await fixture.database.saveStacks(
            fixture.account.id,
            fixture.account.generation,
            1,
            [DeckStack.fromJson(fixture.stack)],
            null,
          );
        });
        await _open(tester, fixture, 'Assignees', optionCount: 3);
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'Previous team'),
              )
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<CheckboxListTile>(
                find.widgetWithText(CheckboxListTile, 'Alice'),
              )
              .value,
          isFalse,
        );
        await tester.tap(
          find.widgetWithText(CheckboxListTile, 'Previous team'),
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Alice'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Done'));
        await _until(
          tester,
          () =>
              fixture.confirmed.length == 2 &&
              find.byType(CheckboxListTile).evaluate().isEmpty &&
              !fixture.session.loading('board:1'),
        );
        final remove = fixture.requests.singleWhere(
          (request) => request.url.path.endsWith('/unassignUser'),
        );
        final add = fixture.requests.singleWhere(
          (request) => request.url.path.endsWith('/assignUser'),
        );
        expect(object(jsonDecode(remove.body)), {'userId': 'alice', 'type': 1});
        expect(object(jsonDecode(add.body)), {'userId': 'alice', 'type': 0});
        expect(fixture.remoteUsers.single['type'], 0);
        expect(
          (await tester.runAsync(
            () => fixture.database.writesFor(fixture.account.id),
          ))!,
          isEmpty,
        );
      });
    },
  );

  for (final action in ['Labels', 'Assignees']) {
    testWidgets(
      '$action can keep or remove assignments from the previous board',
      (tester) async {
        await _using(tester, (fixture) async {
          await tester.runAsync(fixture.seedPriorMembership);
          final outsider = action == 'Labels'
              ? 'Previous label'
              : 'Former teammate';
          final available = action == 'Labels' ? 'Urgent' : 'Alice';
          await _open(tester, fixture, action, optionCount: 3);
          final oldOption = find.widgetWithText(CheckboxListTile, outsider);
          expect(tester.widget<CheckboxListTile>(oldOption).value, isTrue);
          await tester.tap(oldOption);
          await tester.pump();
          await tester.tap(oldOption);
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Done'));
          await _until(
            tester,
            () =>
                find.byType(CheckboxListTile).evaluate().isEmpty &&
                !fixture.session.loading('board:1'),
          );
          expect(
            fixture.requests.where((request) => request.method != 'GET'),
            isEmpty,
          );
          expect(
            (await tester.runAsync(
              () => fixture.database.writesFor(fixture.account.id),
            ))!,
            isEmpty,
          );
          await tester.tap(find.widgetWithText(TextButton, action));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(CheckboxListTile, outsider));
          await tester.pump();
          await tester.tap(find.widgetWithText(CheckboxListTile, available));
          await tester.pump();
          await tester.tap(find.widgetWithText(FilledButton, 'Done'));
          await _until(
            tester,
            () =>
                fixture.confirmed.length == 2 &&
                find.byType(CheckboxListTile).evaluate().isEmpty &&
                !fixture.session.loading('board:1'),
          );
          expect(fixture.firstMutationWrites, hasLength(2));
          expect(
            fixture.firstMutationWrites.map((write) => write.kind),
            unorderedEquals(
              action == 'Labels'
                  ? ['assignLabel', 'removeLabel']
                  : ['assignUser', 'unassignUser'],
            ),
          );
          expect(
            (await tester.runAsync(
              () => fixture.database.writesFor(fixture.account.id),
            ))!,
            isEmpty,
          );
          final assignments = action == 'Labels'
              ? fixture.remoteLabels
              : fixture.remoteUsers;
          expect(assignments, hasLength(1));
          if (action == 'Labels') {
            expect(assignments.single['id'], 11);
          } else {
            expect((assignments.single['participant'] as Map)['uid'], 'alice');
          }
          final mutations = fixture.requests
              .where((request) => request.method != 'GET')
              .toList();
          expect(mutations, hasLength(2));
          expect(
            mutations
                .where(
                  (request) => request.url.path.endsWith(
                    action == 'Labels' ? '/assignLabel' : '/assignUser',
                  ),
                )
                .map(
                  (request) => object(
                    jsonDecode(request.body),
                  )[action == 'Labels' ? 'labelId' : 'userId'],
                ),
            [action == 'Labels' ? 11 : 'alice'],
          );
          await tester.tap(find.widgetWithText(TextButton, action));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(CheckboxListTile, outsider), findsNothing);
          expect(find.byType(CheckboxListTile), findsNWidgets(2));
        });
      },
    );
  }

  testWidgets('unnamed prior assignments do not expose internal identifiers', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.runAsync(() => fixture.seedPriorMembership(named: false));
      await _open(tester, fixture, 'Assignees', optionCount: 3);
      expect(find.widgetWithText(CheckboxListTile, 'User'), findsOneWidget);
      expect(
        find.widgetWithText(CheckboxListTile, 'previous-user'),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Labels'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(CheckboxListTile, 'Unnamed label'),
        findsOneWidget,
      );
      expect(find.widgetWithText(CheckboxListTile, '33'), findsNothing);
      expect(find.textContaining('opaque-label'), findsNothing);
      expect(fixture.requests, isEmpty);
    });
  });

  for (final action in ['Labels', 'Assignees']) {
    testWidgets(
      '$action keeps two choices open until Done and persists both before sending',
      (tester) async {
        await _using(tester, (fixture) async {
          await _open(tester, fixture, action);
          final names = action == 'Labels'
              ? ['Urgent', 'Review']
              : ['Alice', 'Bob'];
          for (final name in names) {
            await tester.tap(find.widgetWithText(CheckboxListTile, name));
            await tester.pump();
            expect(find.byType(CheckboxListTile), findsNWidgets(2));
            expect(
              (await tester.runAsync(
                () => fixture.database.writesFor(fixture.account.id),
              ))!,
              isEmpty,
            );
          }
          expect(
            tester
                .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
                .every((tile) => tile.value == true),
            isTrue,
          );
          await tester.tap(find.widgetWithText(FilledButton, 'Done'));
          try {
            await _until(
              tester,
              () =>
                  fixture.confirmed.length == 2 &&
                  find.byType(CheckboxListTile).evaluate().isEmpty &&
                  !fixture.session.loading('board:1'),
            );
          } catch (_) {
            final pending = (await tester.runAsync(
              () => fixture.database.writesFor(fixture.account.id),
            ))!;
            debugPrint(
              jsonEncode({
                'confirmed': fixture.confirmed,
                'sheetRows': find.byType(CheckboxListTile).evaluate().length,
                'requests': fixture.requests
                    .map((r) => '${r.method} ${r.url.path}')
                    .toList(),
                'pending': pending
                    .map(
                      (w) => {
                        'kind': w.kind,
                        'state': w.state,
                        'error': w.error,
                      },
                    )
                    .toList(),
                'sessionError': fixture.session.error('board:1')?.toString(),
              }),
            );
            rethrow;
          }
          await tester.pumpAndSettle();
          expect(fixture.firstMutationWrites, hasLength(2));
          expect(
            fixture.firstMutationWrites.map((write) => write.kind),
            everyElement(action == 'Labels' ? 'assignLabel' : 'assignUser'),
          );
          expect(
            fixture.requests.where((request) => request.method == 'PUT'),
            hasLength(2),
          );
          expect(
            (await tester.runAsync(
              () => fixture.database.writesFor(fixture.account.id),
            ))!,
            isEmpty,
          );
          final saved = (await tester.runAsync(
            () => fixture.database.stackView(fixture.account.id, 1),
          ))!.single.cards.single;
          if (action == 'Labels') {
            expect(
              (saved.raw['labels'] as List).map(
                (label) => (label as Map)['id'],
              ),
              unorderedEquals([11, 12]),
            );
            expect(find.text('Urgent'), findsWidgets);
            expect(find.text('Review'), findsWidgets);
          } else {
            expect(
              (saved.raw['assignedUsers'] as List).map(
                (value) => ((value as Map)['participant'] as Map)['uid'],
              ),
              unorderedEquals(['alice', 'bob']),
            );
            expect(find.text('Alice +1'), findsOneWidget);
          }
        });
      },
    );
  }

  testWidgets(
    'revoked edit permission keeps selected choices and queues no partial change',
    (tester) async {
      await _using(tester, (fixture) async {
        await _open(tester, fixture, 'Labels');
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Urgent'));
        await tester.pump();
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Review'));
        await tester.pump();
        await tester.runAsync(fixture.revokeEdit);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Done'));
        await _until(
          tester,
          () => find
              .text('You no longer have access to this content.')
              .evaluate()
              .isNotEmpty,
        );
        expect(find.byType(CheckboxListTile), findsNWidgets(2));
        expect(
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .every((tile) => tile.value == true),
          isTrue,
        );
        expect(
          (await tester.runAsync(
            () => fixture.database.writesFor(fixture.account.id),
          ))!,
          isEmpty,
        );
        expect(
          fixture.requests.where((request) => request.method != 'GET'),
          isEmpty,
        );
        expect(find.textContaining('permission_denied'), findsNothing);
      });
    },
  );

  testWidgets('Cancel dismisses the selection without creating any write', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await _open(tester, fixture, 'Assignees');
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Alice'));
      await tester.pump();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Bob'));
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(
        (await tester.runAsync(
          () => fixture.database.writesFor(fixture.account.id),
        ))!,
        isEmpty,
      );
      expect(fixture.requests, isEmpty);
    });
  });

  testWidgets(
    'saving blocks barrier drag and system Back then shows the transaction error',
    (tester) async {
      final gate = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCardSelection(
                  context,
                  title: 'Choose labels',
                  emptyMessage: 'Empty',
                  options: const {'one': 'One', 'two': 'Two'},
                  selected: const {},
                  onSave: (selected) async {
                    calls++;
                    await gate.future;
                  },
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'One'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Done'));
      await tester.pump();
      expect(calls, 1);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.drag(find.text('Choose labels'), const Offset(0, 250));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Choose labels'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Cancel'))
            .onPressed,
        isNull,
      );
      gate.completeError(StateError('permission_denied'));
      await tester.pumpAndSettle();
      expect(
        find.text('You no longer have access to this content.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'One'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'Done stays reachable at 200 percent landscape with long option labels',
    (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      Set<String>? saved;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showCardSelection(
                  context,
                  title: 'Přiřazení lidí',
                  emptyMessage: 'Prázdné',
                  options: const {
                    'one': 'První člověk s delším jménem',
                    'two': 'Druhý člověk s delším jménem',
                  },
                  selected: const {},
                  onSave: (selected) async {
                    saved = selected;
                  },
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          scale: 2,
          language: 'cs',
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final checkbox = find.descendant(
        of: find.widgetWithText(
          CheckboxListTile,
          'První člověk s delším jménem',
        ),
        matching: find.byType(Checkbox),
      );
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      expect(checkbox.hitTestable(), findsOneWidget);
      await tester.tap(checkbox);
      await tester.pump();
      expect(tester.widget<Checkbox>(checkbox).value, isTrue);
      expect(
        find.widgetWithText(FilledButton, 'Hotovo').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Hotovo'));
      await tester.pumpAndSettle();
      expect(saved, {'one'});
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
