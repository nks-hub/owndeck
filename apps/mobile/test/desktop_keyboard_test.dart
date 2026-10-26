import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/boards.dart';
import 'package:nextclouddeck/features/card_detail.dart';

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

  Future<void> withBoard(
    WidgetTester tester,
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [3, 2]),
    ))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.pumpWidget(
        boardTestApp(
          BoardScreen(session: fixture.session, board: fixture.board),
          preferences: AppPreferences(store: MemoryBoardPreferences()),
        ),
      );
      await settleBoard(tester);
      await body();
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
      debugDefaultTargetPlatformOverride = null;
    }
  }

  FocusNode cardFocus(WidgetTester tester, int id) => tester
      .widget<InkWell>(
        find
            .descendant(of: boardTile(id), matching: find.byType(InkWell))
            .first,
      )
      .focusNode!;

  Future<void> chord(
    WidgetTester tester,
    TargetPlatform platform,
    LogicalKeyboardKey key,
  ) async {
    final modifier = platform == TargetPlatform.macOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(modifier);
    await tester.pump(const Duration(milliseconds: 400));
  }

  for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
    final name = platform == TargetPlatform.macOS ? 'Cmd' : 'Ctrl';

    testWidgets('$name+N opens the quick add sheet', (tester) async {
      await withBoard(tester, platform, () async {
        expect(find.byType(BottomSheet), findsNothing);
        await chord(tester, platform, LogicalKeyboardKey.keyN);
        expect(find.byType(BottomSheet), findsOneWidget);
      });
    });

    testWidgets('$name+F focuses the board search', (tester) async {
      await withBoard(tester, platform, () async {
        final field = find.descendant(
          of: find.byKey(const ValueKey('board-card-search')),
          matching: find.byType(EditableText),
        );
        expect(tester.widget<EditableText>(field).focusNode.hasFocus, isFalse);
        await chord(tester, platform, LogicalKeyboardKey.keyF);
        expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
      });
    });

    testWidgets('the opposite modifier does nothing on $platform', (
      tester,
    ) async {
      await withBoard(tester, platform, () async {
        final other = platform == TargetPlatform.macOS
            ? TargetPlatform.windows
            : TargetPlatform.macOS;
        await chord(tester, other, LogicalKeyboardKey.keyN);
        expect(find.byType(BottomSheet), findsNothing);
      });
    });

    testWidgets('Esc clears the card selection on $platform', (tester) async {
      await withBoard(tester, platform, () async {
        await tester.tap(boardTile(100), buttons: kSecondaryMouseButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Select card'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byTooltip('Cancel selection'), findsOneWidget);
        cardFocus(tester, 101).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byTooltip('Cancel selection'), findsNothing);
      });
    });

    testWidgets('Enter opens the focused card and Esc closes it on $platform', (
      tester,
    ) async {
      await withBoard(tester, platform, () async {
        cardFocus(tester, 101).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(CardScreen), findsOneWidget);
        expect(find.text('Card 101'), findsWidgets);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(CardScreen), findsNothing);
      });
    });

    testWidgets('arrow keys move the focus between cards on $platform', (
      tester,
    ) async {
      await withBoard(tester, platform, () async {
        cardFocus(tester, 100).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(cardFocus(tester, 101).hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(cardFocus(tester, 100).hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(cardFocus(tester, 1100).hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(cardFocus(tester, 100).hasPrimaryFocus, isTrue);
      });
    });
  }
}
