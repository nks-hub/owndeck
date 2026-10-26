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
import 'package:nextclouddeck/features/share_text.dart';
import 'package:nextclouddeck/features/structure_editor.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

final class _Vault implements CredentialVault {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase db;
  late DeckSession session;
  late DeckBoard board;
  late DeckCard card;
  late TextSharer original;
  final shared = <({String text, String? subject})>[];

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    db = DeckDatabase(NativeDatabase.memory());
    final account = await AccountRepository(db, _Vault()).add(
      LoginCredentials(
        server: ServerBase.parse('https://cloud.example.com'),
        loginName: 'user',
        appPassword: 'test-password',
      ),
    );
    board = DeckBoard.fromJson({
      'id': 1,
      'title': 'Project',
      'color': '008080',
      'archived': false,
      'deletedAt': 0,
      'permissions': {'PERMISSION_READ': true, 'PERMISSION_MANAGE': true},
    });
    card = DeckCard.fromJson({
      'id': 8,
      'stackId': 2,
      'title': 'Write report',
      'description': 'Chapter one\n\nChapter two',
      'order': 0,
      'type': 'plain',
      'owner': 'user',
      'archived': false,
      'duedate': '2026-11-03T09:30:00+00:00',
      'labels': [
        {'id': 1, 'title': 'Urgent', 'color': 'ff0000'},
        {'id': 2, 'title': 'Docs', 'color': '00ff00'},
      ],
      'dependentCards': [],
    });
    await db.saveBoards(account.id, account.generation, [board], null);
    await db.saveStacks(account.id, account.generation, 1, [
      DeckStack.fromJson({
        'id': 2,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'isDoneColumn': false,
        'cards': [card.raw],
      }),
    ], null);
    session = DeckSession(
      db,
      account,
      DeckClient(
        base: ServerBase.parse(account.server),
        loginName: account.loginName,
        appPassword: 'test-password',
        transport: MockClient((_) async => http.Response('', 503)),
      ),
    );
    shared.clear();
    original = textSharer;
    textSharer = (text, {subject}) async =>
        shared.add((text: text, subject: subject));
  });
  tearDown(() async {
    textSharer = original;
    session.dispose();
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Widget app(Widget home) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('card detail shares title, due date, labels, description, link', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(CardScreen(session: session, board: board, card: card)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share card'));
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    final lines = shared.single.text.split('\n');
    expect(lines.first, 'Write report');
    expect(lines[1], startsWith('Due: '));
    expect(lines[2], 'Labels: Urgent, Docs');
    expect(shared.single.text, contains('Chapter one\n\nChapter two'));
    expect(
      lines.last,
      'https://cloud.example.com/index.php/apps/deck/board/1/card/8',
    );
    expect(shared.single.subject, 'Write report');
    expect(shared.single.text, isNot(contains('test-password')));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('board actions share the board link', (tester) async {
    await tester.pumpWidget(
      app(Scaffold(body: BoardActions(session: session, board: board))),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share board link'));
    await tester.pumpAndSettle();
    expect(shared.single.text, 'https://cloud.example.com/index.php/apps/deck/board/1');
    expect(shared.single.subject, 'Project');
  });

  testWidgets('a failing share sheet shows a message instead of throwing', (
    tester,
  ) async {
    textSharer = (text, {subject}) async => throw PlatformException(code: 'x');
    await tester.pumpWidget(
      app(Scaffold(body: BoardActions(session: session, board: board))),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share board link'));
    await tester.pumpAndSettle();
    expect(find.text('Sharing failed.'), findsOneWidget);
  });
}
