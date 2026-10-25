import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_view.dart';
import 'package:nextclouddeck/features/structure_editor.dart';
import 'package:nextclouddeck/l10n/app_localizations.dart';
import 'package:nextclouddeck/main.dart';

import 'board_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  setUp(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null),
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null),
  );

  for (final variant in [
    (size: const Size(375, 760), scale: 1.0),
    (size: const Size(740, 360), scale: 2.0),
  ]) {
    testWidgets(
      'owner column actions fit ${variant.size} at ${variant.scale}',
      (tester) async {
        final fixture = (await tester.runAsync(
          () => BoardFixture.create(
            counts: [0],
            manage: true,
            supportsDoneColumn: true,
          ),
        ))!;
        final preferences = AppPreferences(store: MemoryBoardPreferences());
        await preferences.setLanguage(AppLanguage.cs);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = variant.size;
        tester.platformDispatcher.textScaleFactorTestValue = variant.scale;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appPreferencesProvider.overrideWith((_) => preferences),
              ],
              child: OwnDeckApp(
                home: BoardScreen(
                  session: fixture.session,
                  board: fixture.board,
                ),
              ),
            ),
          );
          await settleBoard(tester);
          expect(tester.takeException(), isNull);
          final actions = find.byType(StackActions);
          final text = AppLocalizations.of(tester.element(actions))!;
          final menu = find.byTooltip(text.stackActions);
          expect(menu.hitTestable(), findsOneWidget);
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(find.text(text.editStack), findsOneWidget);
          expect(find.text(text.deleteStack), findsOneWidget);
          expect(find.text(text.setDoneColumn), findsOneWidget);
          await tester.tap(find.text(text.setDoneColumn));
          await tester.pumpAndSettle();
          expect(find.text(text.setDoneColumnQuestion), findsOneWidget);
          expect(
            find.widgetWithText(FilledButton, text.save).hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await boardModel(tester, fixture.close());
        }
      },
    );
  }
}
