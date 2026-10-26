import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/comment_editor.dart';
import 'package:nextclouddeck/features/comments.dart';
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

  setUp(() async {
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
        transport: MockClient((_) async => http.Response('', 503)),
      ),
    );
  });
  tearDown(() async {
    session.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  Widget app(Widget home) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('typing @ offers board participants and inserts the user id', (
    tester,
  ) async {
    await tester.runAsync(
      () => database.saveBoards(account.id, account.generation, [
        DeckBoard.fromJson({
          'id': 1,
          'title': 'Project',
          'color': '008080',
          'archived': false,
          'deletedAt': 0,
          'permissions': {'PERMISSION_READ': true, 'PERMISSION_EDIT': true},
          'users': [
            {'uid': 'alice', 'displayname': 'Alice A'},
            {'uid': 'Jan Novak', 'displayname': 'Jan N'},
            {'uid': 'bob', 'displayname': 'Bob B'},
          ],
        }),
      ], null),
    );
    await tester.pumpWidget(
      app(CommentEditor(session: session, boardId: 1, stackId: 2, cardId: 3)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    final field = find.byType(TextField);

    await tester.enterText(field, 'Hello @al');
    await tester.pump();
    expect(find.text('Alice A'), findsOneWidget);
    expect(find.text('Bob B'), findsNothing);
    await tester.tap(find.text('Alice A'));
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, 'Hello @alice ');
    expect(find.text('Alice A'), findsNothing);

    await tester.enterText(field, '@jan');
    await tester.pump();
    await tester.tap(find.text('Jan N'));
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, '@"Jan Novak" ');

    await tester.enterText(field, 'mail me@example.com');
    await tester.pump();
    expect(find.byIcon(Icons.alternate_email), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  });

  testWidgets('mentions are highlighted with the server display name', (
    tester,
  ) async {
    final comment = DeckComment.fromJson({
      'id': 1,
      'objectId': 3,
      'message': 'Ping @alice, not me@example.com',
      'actorId': 'bob',
      'actorType': 'users',
      'creationDateTime': '2026-10-24T12:00:00Z',
      'mentions': [
        {
          'mentionId': 'alice',
          'mentionType': 'user',
          'mentionDisplayName': 'Alice A',
        },
      ],
    });
    late TextSpan span;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            span = mentionSpan(context, comment);
            return Text.rich(span);
          },
        ),
      ),
    );
    final parts = span.children!.cast<TextSpan>();
    final highlighted = parts.where((p) => p.style != null).toList();
    expect(highlighted.map((p) => p.text), ['@Alice A']);
    expect(highlighted.single.style!.fontWeight, FontWeight.w600);
    expect(
      parts.map((p) => p.text).join(),
      'Ping @Alice A, not me@example.com',
    );
  });
}
