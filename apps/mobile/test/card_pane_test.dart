import 'package:deck_store/deck_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/card_pane.dart';

import 'board_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  setUp(
    () => messenger.setMockMethodCallHandler(connectivity, (_) async => null),
  );
  tearDown(() => messenger.setMockMethodCallHandler(connectivity, null));

  Future<void> withShell(
    WidgetTester tester,
    TargetPlatform platform,
    double width,
    Future<void> Function(BoardFixture fixture) body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3, 2], manage: true),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.pumpWidget(
        boardTestApp(
          BoardsScreen(session: fixture.session),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
        ),
      );
      await settleBoard(tester);
      await body(fixture);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
      debugDefaultTargetPlatformOverride = null;
    }
  }

  for (final width in [720.0, 1024.0, 1440.0, 1920.0]) {
    final wide = width >= cardPaneMinWidth;
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      testWidgets(
        '${wide ? 'pane' : 'pages'} at ${width.toInt()} px on $platform',
        (tester) async {
          await withShell(tester, platform, width, (fixture) async {
            await tester.tap(find.text('Board'));
            await settleBoard(tester);
            expect(find.text('Card 100'), findsOneWidget);
            await tester.tap(find.text('Card 100'));
            await settleBoard(tester);
            expect(find.byType(CardScreen), findsOneWidget);
            if (wide) {
              // The board and the card are on screen together.
              expect(find.text('Card 101'), findsOneWidget);
              expect(find.byTooltip('Close'), findsOneWidget);
              await tester.tap(find.text('Card 101'));
              await settleBoard(tester);
              expect(find.byType(CardScreen), findsOneWidget);
              expect(
                tester.widget<CardScreen>(find.byType(CardScreen)).card.id,
                101,
              );
              await tester.tap(find.byTooltip('Close'));
              await settleBoard(tester);
            } else {
              await tester.pump(const Duration(seconds: 1));
              expect(find.text('Card 101'), findsNothing);
              await tester.binding.handlePopRoute();
              await tester.pump();
              await tester.pump(const Duration(seconds: 1));
              await settleBoard(tester);
            }
            expect(find.byType(CardScreen), findsNothing);
            expect(find.text('Card 101'), findsOneWidget);
          });
        },
      );
    }
  }

  testWidgets('mobile platforms never use the pane', (tester) async {
    await withShell(tester, TargetPlatform.android, 1920, (fixture) async {
      await tester.tap(find.text('Board'));
      await settleBoard(tester);
      await tester.tap(find.text('Card 100'));
      await settleBoard(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CardScreen), findsOneWidget);
      expect(find.text('Card 101'), findsNothing);
    });
  });

  testWidgets('a card link and Esc drive the same pane', (tester) async {
    await withShell(tester, TargetPlatform.windows, 1440, (fixture) async {
      await tester.tap(find.text('Board'));
      await settleBoard(tester);
      final card = fixture.stacks.first.cards.last;
      CardPaneController.active!.show(fixture.session, fixture.board, card);
      await settleBoard(tester);
      expect(
        tester.widget<CardScreen>(find.byType(CardScreen)).card.id,
        card.id,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleBoard(tester);
      expect(find.byType(CardScreen), findsNothing);
    });
  });

  testWidgets('archiving the open card keeps the pane in step', (tester) async {
    await withShell(tester, TargetPlatform.windows, 1440, (fixture) async {
      await tester.tap(find.text('Board'));
      await settleBoard(tester);
      await tester.tap(find.text('Card 100'));
      await settleBoard(tester);
      await tester.tap(boardTile(100), buttons: kSecondaryMouseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Archive'));
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(writes.single.kind, 'archiveCard');
      expect(find.byType(CardScreen), findsOneWidget);
    });
  });
}
