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
import 'package:nextclouddeck/l10n/app_localizations.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late StoredAccount account;
  late DeckSession session;
  final paths = <String>[];

  setUp(() async {
    paths.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    account = await AccountRepository(database, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'login-alias',
        appPassword: 'test-password',
      ),
      userId: 'canonical-user',
    );
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response('', 503);
        }),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  testWidgets('a Deck card link in a description opens natively, not in the browser', (
    tester,
  ) async {
    final board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Project',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
    });
    final card = DeckCard.fromJson({
      'id': 3,
      'stackId': 2,
      'title': 'Linking card',
      'description': '[Other card](https://cloud.example.com/apps/deck/board/7/card/9)',
      'type': 'plain',
      'owner': 'u',
      'order': 1,
      'archived': false,
      'done': null,
    });
    await tester.runAsync(() async {
      await database.saveBoards(account.id, account.generation, [board], null);
      await database.saveStacks(account.id, account.generation, 1, [
        DeckStack.fromJson({
          'id': 2,
          'boardId': 1,
          'title': 'Planning',
          'order': 0,
          'cards': [card.raw],
        }),
      ], null);
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CardScreen(session: session, board: board, card: card),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other card', findRichText: true));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(paths.any((path) => path.endsWith('/boards/7')), isTrue);
    expect(find.text('The browser could not be opened.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
