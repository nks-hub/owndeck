import 'dart:async';
import 'dart:io';
import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/board_card_tile.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

class _Vault implements CredentialVault {
  final _values = <String, String>{};
  @override
  Future<String?> read(String reference) async => _values[reference];
  @override
  Future<void> write(String reference, String password) async =>
      _values[reference] = password;
  @override
  Future<void> delete(String reference) async => _values.remove(reference);
  @override
  Future<Set<String>> references() async => _values.keys.toSet();
}

class MemoryBoardPreferences implements AppPreferenceStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class BoardFixture {
  BoardFixture(this.db, this.account, this.session, this.board, this.stacks);
  final DeckDatabase db;
  final StoredAccount account;
  final DeckSession session;
  final DeckBoard board;
  final List<DeckStack> stacks;

  static Future<BoardFixture> create({
    List<int> counts = const [3, 0],
    bool editable = true,
    bool archivedLeading = false,
    bool manage = false,
    bool supportsDoneColumn = false,
  }) async {
    final db = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(db, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    final board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Board',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {
        'PERMISSION_READ': true,
        'PERMISSION_EDIT': editable,
        'PERMISSION_MANAGE': manage,
      },
    });
    DeckCard card(int id, int stack, int order, {bool archived = false}) =>
        DeckCard.fromJson({
          'id': id,
          'stackId': stack,
          'title': archived ? 'Archived card' : 'Card $id',
          'description': 'Description $id',
          'order': order,
          'type': 'plain',
          'owner': 'user',
          'archived': archived,
          'deletedAt': 0,
        });
    final stacks = [
      for (var column = 0; column < counts.length; column++)
        DeckStack.fromJson({
          'id': 10 + column,
          'boardId': 1,
          'title': 'Column ${column + 1}',
          'order': column,
          if (supportsDoneColumn) 'isDoneColumn': false,
          'cards': [
            if (archivedLeading && column == 0)
              card(99, 10, 0, archived: true).raw,
            for (var index = 0; index < counts[column]; index++)
              card(
                100 + column * 1000 + index,
                10 + column,
                index + (archivedLeading && column == 0 ? 1 : 0),
              ).raw,
          ],
        }),
    ];
    await db.saveBoards(account.id, account.generation, [board], null);
    await db.saveStacks(account.id, account.generation, 1, stacks, null);
    final session = DeckSession(
      db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: 'user',
        appPassword: 'test-password',
        transport: MockClient(
          (_) async => throw const SocketException('offline'),
        ),
      ),
      pollInterval: const Duration(hours: 1),
    );
    return BoardFixture(db, account, session, board, stacks);
  }

  Future<void> close() async {
    session.dispose();
    await db.close();
  }
}

Widget boardTestApp(
  Widget home, {
  AppPreferences? preferences,
  double scale = 1,
}) {
  final content = MaterialApp(
    locale: const Locale('en'),
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
  return ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWith(
        (ref) => preferences ?? AppPreferences(store: MemoryBoardPreferences()),
      ),
    ],
    child: content,
  );
}

Future<void> settleBoard(WidgetTester tester) async {
  for (var index = 0; index < 10; index++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
}

Future<T> boardModel<T>(WidgetTester tester, Future<T> operation) async {
  var done = false;
  unawaited(
    operation.then<void>(
      (_) {
        done = true;
      },
      onError: (Object _, StackTrace _) {
        done = true;
      },
    ),
  );
  for (var index = 0; index < 100 && !done; index++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(
    done,
    isTrue,
    reason: 'Database work did not complete while pumping its widget zone.',
  );
  return operation;
}

Finder boardTile(int id) => find.byWidgetPredicate(
  (widget) => widget is BoardCardTile && widget.card.id == id,
);

Future<void> dragBoardCard(
  WidgetTester tester,
  int id,
  Offset destination,
) async {
  final pointer = await tester.startGesture(
    tester.getCenter(find.byKey(ValueKey(('drag-card', id)))),
  );
  await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
  await pointer.moveTo(destination);
  await tester.pump(const Duration(milliseconds: 32));
  await pointer.up();
  await settleBoard(tester);
}
