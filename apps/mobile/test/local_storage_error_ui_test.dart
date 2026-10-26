import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/quick_add_card.dart';

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

  testWidgets(
    'database read failure does not suggest unlocking credential storage',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await boardModel(
          tester,
          fixture.db.customStatement('DROP TABLE stored_boards'),
        );
        await tester.pumpWidget(
          boardTestApp(
            BoardsScreen(session: fixture.session),
            preferences: AppPreferences(store: MemoryBoardPreferences()),
          ),
        );
        await settleBoard(tester);
        expect(
          find.text(
            'Saved data could not be read on this device. Try opening this screen again.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Unlock the device'), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'quick draft failure explains local saving and Cancel keeps typed text',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await boardModel(
          tester,
          fixture.db.customStatement(
            "CREATE TRIGGER fail_draft BEFORE INSERT ON editor_drafts BEGIN SELECT RAISE(ABORT, 'private storage detail'); END",
          ),
        );
        await tester.pumpWidget(
          boardTestApp(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showQuickAddCard(
                    context,
                    fixture.session,
                    board: fixture.board,
                    stackId: 10,
                  ),
                  child: const Text('Open composer'),
                ),
              ),
            ),
            preferences: AppPreferences(store: MemoryBoardPreferences()),
          ),
        );
        await tester.tap(find.text('Open composer'));
        await settleBoard(tester);
        await tester.enterText(find.byType(TextField).first, 'Keep this draft');
        await tester.pump(const Duration(milliseconds: 600));
        await settleBoard(tester);
        expect(
          find.text('Changes could not be saved on this device. Try again.'),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await settleBoard(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('Unlock the device'), findsNothing);
        expect(find.textContaining('private storage detail'), findsNothing);
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await settleBoard(tester);
        expect(find.text('Keep this draft'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );
}
