import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/search.dart';
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
  late AccountRepository accounts;
  late StoredAccount account;
  late DeckSession session;
  var requests = 0;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    accounts = AccountRepository(database, _Vault());
    account = await accounts.add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'login-alias',
        appPassword: 'test-password',
      ),
      userId: 'canonical-user',
    );
    await database.saveBoards(account.id, account.generation, [
      DeckBoard.fromJson({
        'id': 1,
        'title': 'Project',
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
        'title': 'Planning',
        'order': 0,
        'cards': [
          for (var id = 1; id <= 2; id++)
            {
              'id': id,
              'stackId': 2,
              'title': id == 1 ? 'Alpha card' : 'Beta card',
              'description': '',
              'type': 'plain',
              'owner': 'login-alias',
              'order': id,
              'archived': false,
              'done': null,
              'assignedUsers': [
                {
                  'type': 0,
                  'participant': {
                    'uid': id == 1 ? 'login-alias' : 'canonical-user',
                  },
                },
              ],
            },
        ],
      }),
    ], null);
    requests = 0;
    session = DeckSession(
      database,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((_) async {
          requests++;
          throw StateError('local_search_must_not_request_network');
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

  Widget app({bool mineOnly = false, double textScale = 1}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: CardSearchScreen(session: session, mineOnly: mineOnly),
  );

  testWidgets(
    'typing replaces old results and keeps input focus without a network request',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('Saved cards'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('card-search-query')),
        'alpha',
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text('Alpha card'), findsOneWidget);
      expect(find.text('Beta card'), findsNothing);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(
        find.byKey(const Key('card-search-query')),
        'beta',
      );
      await tester.pump();
      expect(find.text('Alpha card'), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text('Beta card'), findsOneWidget);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'my tasks opens the assigned card in the existing detail screen',
    (tester) async {
      await tester.pumpWidget(app(mineOnly: true));
      await tester.pumpAndSettle();
      expect(find.text('Alpha card'), findsNothing);
      await tester.ensureVisible(find.text('Beta card'));
      await tester.tap(find.text('Beta card'));
      await tester.pumpAndSettle();
      expect(find.byType(CardScreen), findsOneWidget);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'filters remain usable with double-size text on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(textScale: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('search-filter-menu')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Include archived'),
        120,
        scrollable: find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.text('Include archived'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
