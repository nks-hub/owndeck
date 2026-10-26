import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/data/session.dart';
import 'package:nextclouddeck/features/structure_editor.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';

void main() {
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'structure fields and actions stay reachable above a landscape keyboard at $scale text',
      (tester) async {
        tester.view.physicalSize = const Size(846, 412);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24);
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
          tester.view.resetViewInsets();
        });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(connectivity, (_) async => null);
        final database = DeckDatabase(NativeDatabase.memory());
        const account = StoredAccount(
          id: 'account',
          server: 'https://cloud.example.com/',
          loginName: 'user',
          credentialRef: 'test-vault',
          state: 'active',
          generation: 1,
          contentEpoch: 0,
          selected: true,
        );
        final session = (await tester.runAsync(() async {
          await database.accounts();
          return DeckSession(
            database,
            account,
            DeckClient(
              base: ServerBase.parse(account.server),
              loginName: 'user',
              appPassword: 'test-password',
              transport: MockClient((_) async => http.Response('', 500)),
            ),
          );
        }))!;
        try {
          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('cs'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => editStructure(context, session),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final fields = find.byType(TextField);
          await tester.ensureVisible(fields.first);
          await tester.pumpAndSettle();
          expect(fields.first.hitTestable(), findsOneWidget);
          await tester.enterText(fields.first, 'Board');
          await tester.pumpAndSettle();
          expect(fields, findsOneWidget);
          final color = find.byTooltip('Modrá');
          await tester.ensureVisible(color);
          await tester.pumpAndSettle();
          expect(color.hitTestable(), findsOneWidget);
          await tester.tap(color);
          expect(find.text('008080'), findsNothing);
          await tester.ensureVisible(find.text('Zrušit'));
          await tester.pumpAndSettle();
          expect(find.text('Zrušit').hitTestable(), findsOneWidget);
          await tester.tap(find.text('Zrušit'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async {
            session.dispose();
            await database.close();
          });
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(connectivity, null);
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  }
}
