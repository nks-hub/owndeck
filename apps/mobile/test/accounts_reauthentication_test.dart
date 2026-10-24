import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/accounts.dart';
import 'package:nextclouddeck/features/accounts.dart';

import 'test_support.dart';

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

  testWidgets('discarding the parent navigator releases the onboarding guard', (
    tester,
  ) async {
    final visible = ValueNotifier(true);
    final changed = Completer<void>();
    void observe() {
      if (accounts.session == null && !changed.isCompleted) changed.complete();
    }

    accounts.addListener(observe);
    try {
      await tester.pumpWidget(
        ProviderScope(
          child: localizedTestApp(
            home: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, show, _) => show
                  ? Navigator(
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          body: TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AccountLoginScreen(accounts: accounts),
                              ),
                            ),
                            child: const Text('begin'),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('begin'));
      await tester.pumpAndSettle();
      final first = accounts.session!;
      await tester.runAsync(first.refreshBoards);
      expect(identical(accounts.session, first), isTrue);
      visible.value = false;
      await tester.pump();
      await tester.runAsync(
        () => changed.future.timeout(const Duration(seconds: 5)),
      );
      await tester.pumpAndSettle();
      expect(accounts.session, isNull);
      expect(accounts.selected!.state, 'reauthRequired');
    } finally {
      accounts.removeListener(observe);
      await tester.pumpWidget(const SizedBox());
      visible.dispose();
    }
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
