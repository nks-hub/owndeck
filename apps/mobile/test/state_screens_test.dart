import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/drafts.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/pending.dart';
import 'package:nextclouddeck/features/settings.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

class _Preferences implements AppPreferenceStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _Fixture {
  final database = DeckDatabase(NativeDatabase.memory());
  late final StoredAccount account;
  late final DeckSession session;
  late final DeckBoard board;
  late final DeckCard card;
  final requests = <http.Request>[];

  Future<void> initialize() async {
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'demo',
        appPassword: 'test-password',
      ),
    );
    board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Project A',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
    });
    card = DeckCard.fromJson({
      'id': 8,
      'stackId': 2,
      'title': 'Task A',
      'description': 'Original text',
      'order': 0,
      'type': 'plain',
      'owner': 'demo',
      'archived': false,
      'duedate': '2030-02-03T12:00:00.000Z',
      'startdate': null,
      'done': null,
      'color': '008080',
    });
    await database.saveBoards(account.id, account.generation, [board], null);
    await database.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'In progress',
        'order': 0,
        'cards': [card.raw],
      }),
    ], null);
    await database.deferSync(
      account,
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'demo',
        appPassword: 'test-password',
        transport: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{}',
            503,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
      pollInterval: const Duration(hours: 1),
    );
  }

  Future<PendingWrite> write(String state) async {
    final id = await database.saveCardDraft(account, 1, 2, {
      'title': 'My task',
      'description': 'My words',
      'duedate': null,
      'color': 'abcdef',
      'done': null,
    }, original: card);
    await (database.update(
      database.pendingWrites,
    )..where((row) => row.id.equals(id))).write(
      PendingWritesCompanion(
        state: Value(state),
        remote: Value(
          jsonEncode({
            ...card.raw,
            'title': 'Server task',
            'description': 'Server words',
            'color': 'fedcba',
            'done': '2030-02-03T13:00:00.000Z',
          }),
        ),
      ),
    );
    return (await database.writesFor(account.id)).single;
  }
}

Widget _app(Widget home, {String language = 'en', double scale = 1}) =>
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
  for (var i = 0; i < 150; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
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
    final fixture = _Fixture();
    await fixture.initialize();
    return fixture;
  }))!;
  tester.view.physicalSize = const Size(1100, 2200);
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

void main() {
  testWidgets('pending toolbar badge names its action and remains accessible', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.runAsync(() => fixture.write('queued'));
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appPreferencesProvider.overrideWith(
                (ref) => AppPreferences(store: _Preferences()),
              ),
            ],
            child: _app(BoardsScreen(session: fixture.session)),
          ),
        );
        await _until(
          tester,
          () => find.byIcon(Icons.cloud_sync_outlined).evaluate().isNotEmpty,
        );
        final button = find.ancestor(
          of: find.byIcon(Icons.cloud_sync_outlined),
          matching: find.byType(IconButton),
        );
        final node = tester.getSemantics(button);
        final data = node.getSemanticsData();
        expect(data.label, contains('Pending changes'));
        expect(data.label, contains('1'));
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        tester.binding.performSemanticsAction(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            nodeId: node.id,
            viewId: tester.view.viewId,
          ),
        );
        await _until(
          tester,
          () => find.byType(PendingScreen).evaluate().isNotEmpty,
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  for (final entry in {
    'invalid_destination':
        'This destination has changed or is no longer available. Refresh and choose again.',
    'card_archived': 'This card is archived. Restore it before editing.',
    'attachment_missing':
        'This attachment is no longer available. Refresh the attachments.',
    'invalid_response':
        'The server returned a response this app cannot safely use.',
    'invalid_attachment': 'This file cannot be uploaded. Choose it again.',
    'identity_mismatch':
        'The server answered for a different item than this change targets. Discard the change or try again.',
    'server_private_payload':
        'This change cannot be sent. Check access and content.',
  }.entries) {
    testWidgets(
      'blocked change explains ${entry.key} without exposing raw errors',
      (tester) async {
        await _using(tester, (fixture) async {
          await tester.runAsync(() async {
            final write = await fixture.write('blocked');
            await (fixture.database.update(fixture.database.pendingWrites)
                  ..where((row) => row.id.equals(write.id)))
                .write(PendingWritesCompanion(error: Value(entry.key)));
          });
          await tester.pumpWidget(
            _app(PendingScreen(session: fixture.session)),
          );
          await _until(
            tester,
            () => find.text('My task').evaluate().isNotEmpty,
          );
          expect(find.text(entry.value), findsOneWidget);
          expect(find.textContaining(entry.key), findsNothing);
          expect(fixture.requests, isEmpty);
        });
      },
    );
  }

  testWidgets(
    'revoked access keeps the uncertain result of an in-flight write visible',
    (tester) async {
      await _using(tester, (fixture) async {
        await tester.runAsync(() async {
          await fixture.write('sending');
          await fixture.database.revokeBoardAccess(fixture.account, 1);
        });
        await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
        await _until(tester, () => find.text('My task').evaluate().isNotEmpty);
        expect(
          find.text(
            'The server may have accepted this change. Check the server before retrying.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('You no longer have access to this content.'),
          findsNothing,
        );
        expect(
          (await tester.runAsync(
            () => fixture.database.writesFor(fixture.account.id),
          ))!.single.state,
          'uncertain',
        );
      });
    },
  );

  testWidgets(
    'metadata conflicts show named permissions and colors without identifiers',
    (tester) async {
      await _using(tester, (fixture) async {
        await tester.runAsync(() async {
          final acl = <String, Object?>{
            'id': 90,
            'participant': {'uid': 'internal-user-42', 'displayname': 'Alice'},
            'permissionRead': true,
            'permissionEdit': false,
            'permissionShare': false,
            'permissionManage': false,
          };
          await fixture.database
              .into(fixture.database.pendingWrites)
              .insert(
                PendingWritesCompanion.insert(
                  id: 'acl-write',
                  accountId: fixture.account.id,
                  kind: 'updateAcl',
                  boardId: 1,
                  stackId: 0,
                  state: const Value('conflict'),
                  proposal: jsonEncode({
                    'aclId': 90,
                    'permissionEdit': true,
                    'permissionShare': true,
                  }),
                  base: Value(jsonEncode(acl)),
                  remote: Value(jsonEncode({...acl, 'permissionManage': true})),
                ),
              );
          await fixture.database
              .into(fixture.database.pendingWrites)
              .insert(
                PendingWritesCompanion.insert(
                  id: 'label-write',
                  accountId: fixture.account.id,
                  kind: 'updateLabel',
                  boardId: 1,
                  stackId: 0,
                  state: const Value('conflict'),
                  proposal: jsonEncode({
                    'labelId': 71,
                    'title': 'Ready',
                    'color': '2563eb',
                  }),
                  base: Value(
                    jsonEncode({
                      'id': 71,
                      'title': 'Important',
                      'color': '008080',
                    }),
                  ),
                  remote: Value(
                    jsonEncode({
                      'id': 71,
                      'title': 'Important',
                      'color': 'dc2626',
                    }),
                  ),
                ),
              );
        });
        await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
        await _until(tester, () => find.text('Alice').evaluate().isNotEmpty);
        expect(find.text('Alice'), findsNWidgets(2));
        expect(find.text('Allowed'), findsWidgets);
        expect(find.text('Not allowed'), findsWidgets);
        expect(find.byTooltip('Different values'), findsWidgets);
        expect(find.textContaining('internal-user-42'), findsNothing);
        expect(find.textContaining('permissionEdit'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Blue'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Blue'), findsOneWidget);
        expect(find.text('Red'), findsOneWidget);
        expect(find.textContaining('2563eb'), findsNothing);
        expect(find.textContaining('dc2626'), findsNothing);
      });
    },
  );

  testWidgets('pending screen counts unsent changes in both languages', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.runAsync(() async {
        await fixture.write('queued');
        await fixture.database
            .into(fixture.database.pendingWrites)
            .insert(
              PendingWritesCompanion.insert(
                id: 'second-write',
                accountId: fixture.account.id,
                kind: 'updateBoard',
                boardId: 1,
                stackId: 0,
                state: const Value('conflict'),
                proposal: jsonEncode({'title': 'New title'}),
              ),
            );
      });
      await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
      await _until(tester, () => find.text('My task').evaluate().isNotEmpty);
      expect(find.text('2 unsent changes'), findsOneWidget);
      await tester.pumpWidget(
        _app(PendingScreen(session: fixture.session), language: 'cs'),
      );
      await _until(
        tester,
        () => find.text('2 neodeslané změny').evaluate().isNotEmpty,
      );
    });
  });

  testWidgets('card detail names the state and counts pending changes', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.runAsync(() async {
        await fixture.write('uncertain');
        await fixture.database
            .into(fixture.database.pendingWrites)
            .insert(
              PendingWritesCompanion.insert(
                id: 'second-card-write',
                accountId: fixture.account.id,
                kind: 'archiveCard',
                boardId: 1,
                stackId: 2,
                cardId: const Value(8),
                state: const Value('uncertain'),
                proposal: jsonEncode({}),
              ),
            );
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWith(
              (ref) => AppPreferences(store: _Preferences()),
            ),
          ],
          child: _app(
            CardScreen(
              session: fixture.session,
              board: fixture.board,
              card: fixture.card,
            ),
          ),
        ),
      );
      await _until(
        tester,
        () => find.text('Check the result').evaluate().isNotEmpty,
      );
      await _until(
        tester,
        () => find.textContaining('2 unsent changes.').evaluate().isNotEmpty,
      );
      expect(find.text('Pending changes'), findsNothing);
    });
  });

  testWidgets('empty group does not claim other queued work was confirmed', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      await tester.runAsync(() => fixture.write('queued'));
      await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
      await _until(tester, () => find.text('My task').evaluate().isNotEmpty);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Conflicts'));
      await tester.pump();
      expect(find.text('There are no changes in this group.'), findsOneWidget);
      expect(find.text('All changes have been confirmed.'), findsNothing);
      await tester.tap(find.widgetWithText(OutlinedButton, 'All changes'));
      await tester.pump();
      expect(find.text('My task'), findsOneWidget);
    });
  });

  testWidgets(
    'conflict compares explicit cleared values and color swatches without hex',
    (tester) async {
      await _using(tester, (fixture) async {
        await tester.runAsync(() => fixture.write('conflict'));
        await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
        await _until(
          tester,
          () => find.text('Server words').evaluate().isNotEmpty,
        );
        expect(find.text('My words'), findsOneWidget);
        expect(find.text('Not set'), findsWidgets);
        expect(find.text('Not completed'), findsOneWidget);
        expect(find.text('Custom color'), findsNWidgets(2));
        expect(find.textContaining('abcdef'), findsNothing);
        expect(find.textContaining('fedcba'), findsNothing);
        expect(find.byTooltip('Different values'), findsWidgets);
        final colors = tester
            .widgetList<Container>(find.byType(Container))
            .map((widget) => widget.decoration)
            .whereType<BoxDecoration>()
            .map((box) => box.color);
        expect(
          colors,
          containsAll([const Color(0xffabcdef), const Color(0xfffedcba)]),
        );
      });
    },
  );

  testWidgets('keep server version discards only the selected local conflict', (
    tester,
  ) async {
    await _using(tester, (fixture) async {
      final write = (await tester.runAsync(() => fixture.write('conflict')))!;
      await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
      await _until(
        tester,
        () => find.text('Keep the server version').evaluate().isNotEmpty,
      );
      await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Keep the server version'),
      );
      await tester.tap(
        find.widgetWithText(TextButton, 'Keep the server version'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Only this local change will be discarded. Nothing will be changed on the server.',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await _until(
        tester,
        () =>
            find.text('All changes have been confirmed.').evaluate().isNotEmpty,
      );
      final persisted = (await tester.runAsync(
        () => (fixture.database.select(
          fixture.database.pendingWrites,
        )..where((row) => row.id.equals(write.id))).getSingle(),
      ))!;
      expect(persisted.state, 'discarded');
      expect(persisted.proposal, write.proposal);
      expect(
        fixture.requests.where((request) => request.method != 'GET'),
        isEmpty,
      );
    });
  });

  testWidgets(
    'uncertain retry keeps the duplicate warning and cancel leaves the operation intact',
    (tester) async {
      await _using(tester, (fixture) async {
        final write = (await tester.runAsync(
          () => fixture.write('uncertain'),
        ))!;
        await tester.pumpWidget(_app(PendingScreen(session: fixture.session)));
        await _until(
          tester,
          () => find.text('Send again').evaluate().isNotEmpty,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Send again'));
        await tester.pumpAndSettle();
        expect(
          find.text('Retrying may create a duplicate item. Send again?'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        final unchanged = (await tester.runAsync(
          () => fixture.database.writesFor(fixture.account.id),
        ))!.single;
        expect(unchanged.state, 'uncertain');
        expect(unchanged.proposal, write.proposal);
        expect(fixture.requests, isEmpty);
      });
    },
  );

  testWidgets(
    'comment drafts show their real text and location then hide revoked context',
    (tester) async {
      await _using(tester, (fixture) async {
        await tester.runAsync(
          () => fixture.database.saveCommentDraft(
            fixture.account,
            'comment',
            1,
            2,
            8,
            'My unfinished comment',
          ),
        );
        await tester.pumpWidget(_app(DraftsScreen(session: fixture.session)));
        await _until(
          tester,
          () => find
              .text('Project A › In progress › Task A')
              .evaluate()
              .isNotEmpty,
        );
        expect(find.text('My unfinished comment'), findsOneWidget);
        expect(find.textContaining('Comment draft ·'), findsOneWidget);
        await tester.runAsync(
          () => fixture.database.revokeBoardAccess(fixture.account, 1),
        );
        await _until(
          tester,
          () => find
              .text('Original location is no longer available')
              .evaluate()
              .isNotEmpty,
        );
        expect(find.textContaining('Project A'), findsNothing);
        expect(find.text('My unfinished comment'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'pending and draft screens stay scrollable at 200 percent landscape',
    (tester) async {
      await _using(tester, (fixture) async {
        tester.view.physicalSize = const Size(640, 360);
        await tester.runAsync(() async {
          await fixture.write('conflict');
          await fixture.database.saveCommentDraft(
            fixture.account,
            'comment',
            1,
            2,
            8,
            'Delší rozepsaný komentář, který musí zůstat čitelný.',
          );
        });
        await tester.pumpWidget(
          _app(
            PendingScreen(session: fixture.session),
            language: 'cs',
            scale: 2,
          ),
        );
        await _until(
          tester,
          () => find.text('Všechny změny').evaluate().isNotEmpty,
        );
        await tester.scrollUntilVisible(
          find.text('Použít moje změny'),
          240,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 50,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(
            DraftsScreen(session: fixture.session),
            language: 'cs',
            scale: 2,
          ),
        );
        await _until(
          tester,
          () => find.textContaining('Delší rozepsaný').evaluate().isNotEmpty,
        );
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('settings choices remain available at 200 percent Czech text', (
    tester,
  ) async {
    final preferences = AppPreferences(store: _Preferences());
    await preferences.load();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWith((ref) => preferences),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'OwnDeck',
              packageName: 'com.example.test',
              version: '1.2.3',
              buildNumber: '4',
            ),
          ),
        ],
        child: _app(
          const Scaffold(body: SettingsView()),
          language: 'cs',
          scale: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tmavý').last);
    await tester.pumpAndSettle();
    expect(preferences.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });
}
