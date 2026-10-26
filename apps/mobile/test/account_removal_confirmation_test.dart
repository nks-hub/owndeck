import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/accounts.dart';
import 'package:nextclouddeck/features/accounts.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'removal warns about unsent work and shared passwords while Cancel preserves both',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      const channel = MethodChannel(
        'dev.fluttercommunity.plus/connectivity_status',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async => null);
      final requests = <http.Request>[];
      final fixture = (await tester.runAsync(() async {
        final database = DeckDatabase(NativeDatabase.memory());
        final accounts = Accounts(
          database: database,
          transportFactory: (_, _) => MockClient((request) async {
            requests.add(request);
            return http.Response('', 401);
          }),
        );
        await accounts.ready;
        await accounts.add(
          LoginCredentials(
            server: ServerBase.parse('https://cloud.example.com'),
            loginName: 'demo',
            appPassword: 'test-password',
          ),
        );
        await database.saveEditorDraft(accounts.selected!, 'draft', 1, 2, {
          'title': 'Only saved here',
        }, null);
        return (database: database, accounts: accounts);
      }))!;
      final database = fixture.database;
      final accounts = fixture.accounts;
      final container = ProviderContainer(
        overrides: [accountsProvider.overrideWith((_) => accounts)],
      );
      container.read(accountsProvider);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(700, 360);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      try {
        final accountId = accounts.selected!.id;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: const AccountsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Remove account'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('drafts and unsent changes'),
          findsOneWidget,
        );
        final warning = find.textContaining(
          'Other apps or devices using the same password',
        );
        expect(warning, findsOneWidget);
        await tester.ensureVisible(warning);
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(FilledButton, 'Remove').hitTestable(),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextButton, 'Cancel').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(accounts.selected!.id, accountId);
        final draft = await tester.runAsync(
          () => database.editorDraft(accountId, 'draft'),
        );
        expect(jsonDecode(draft!.payload)['title'], 'Only saved here');
        expect(requests, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          container.dispose();
          await database.close();
        });
        messenger.setMockMethodCallHandler(channel, null);
      }
    },
  );
}
