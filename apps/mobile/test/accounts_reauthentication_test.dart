import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/accounts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  late DeckDatabase database;
  late Accounts accounts;
  LoginCredentials credentials(String user) => LoginCredentials(
    server: ServerBase.parse('https://cloud.example.com'),
    loginName: user,
    appPassword: 'test-password',
  );

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    database = DeckDatabase(NativeDatabase.memory());
    accounts = Accounts(
      database: database,
      transportFactory: (_, _) =>
          MockClient((_) async => http.Response('', 401)),
    );
    await accounts.ready;
    await accounts.add(credentials('first'));
  });
  tearDown(() async {
    accounts.dispose();
    await database.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  test(
    'expired current account does not tear down another account login in progress',
    () async {
      final first = accounts.session!;
      accounts.beginOnboarding();
      await first.refreshBoards();
      expect(identical(accounts.session, first), isTrue);
      expect(
        (await database.account(first.account.id))!.state,
        'reauthRequired',
      );
      await accounts.endOnboarding();
      expect(accounts.session, isNull);
      expect(accounts.selected!.state, 'reauthRequired');
    },
  );

  test(
    'finishing the new account keeps it selected after an old token expires',
    () async {
      final first = accounts.session!;
      accounts.beginOnboarding();
      await first.refreshBoards();
      await accounts.add(credentials('second'));
      final second = accounts.session!;
      await accounts.endOnboarding();
      expect(identical(accounts.session, second), isTrue);
      expect(accounts.selected!.loginName, 'second');
      expect(accounts.selected!.state, 'active');
      expect(
        (await database.account(first.account.id))!.state,
        'reauthRequired',
      );
    },
  );
}
