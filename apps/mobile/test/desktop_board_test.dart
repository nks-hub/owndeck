import 'package:deck_store/deck_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_drag.dart';
import 'package:nextclouddeck/features/boards.dart';

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
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(connectivity, null);
  });

  Future<void> withBoard(
    WidgetTester tester,
    TargetPlatform platform,
    Future<void> Function(BoardFixture fixture) body, {
    bool manage = false,
    bool editable = true,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(manage: manage, editable: editable),
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
      await body(fixture);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
      debugDefaultTargetPlatformOverride = null;
    }
  }

  Offset endOfSecondColumn(WidgetTester tester, BoardFixture fixture) =>
      tester.getCenter(
        find.byKey(
          boardDropKey(
            fixture.account.id,
            fixture.account.generation,
            1,
            11,
            null,
          ),
        ),
      );

  Future<int> dragWrites(
    WidgetTester tester,
    BoardFixture fixture, {
    required PointerDeviceKind kind,
    required bool longPress,
  }) async {
    final pointer = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey(('drag-card', 100)))),
      kind: kind,
    );
    if (longPress) {
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    }
    await pointer.moveTo(endOfSecondColumn(tester, fixture));
    await tester.pump(const Duration(milliseconds: 32));
    await pointer.up();
    await settleBoard(tester);
    final writes = await boardModel(
      tester,
      fixture.db.writesFor(fixture.account.id),
    );
    return writes.where((write) => write.kind == 'moveCard').length;
  }

  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    testWidgets('mouse drags a card between columns on $platform without a '
        'long press', (tester) async {
      await withBoard(tester, platform, (fixture) async {
        expect(
          await dragWrites(
            tester,
            fixture,
            kind: PointerDeviceKind.mouse,
            longPress: false,
          ),
          1,
        );
      });
    });

    testWidgets('touch on $platform still needs a long press', (tester) async {
      await withBoard(tester, platform, (fixture) async {
        expect(
          await dragWrites(
            tester,
            fixture,
            kind: PointerDeviceKind.touch,
            longPress: false,
          ),
          0,
        );
        expect(
          await dragWrites(
            tester,
            fixture,
            kind: PointerDeviceKind.touch,
            longPress: true,
          ),
          1,
        );
      });
    });
  }

  testWidgets('mobile keeps the long press for every pointer', (tester) async {
    await withBoard(tester, TargetPlatform.android, (fixture) async {
      expect(
        await dragWrites(
          tester,
          fixture,
          kind: PointerDeviceKind.mouse,
          longPress: false,
        ),
        0,
      );
    });
  });

  testWidgets('hovering a card shows the click cursor', (tester) async {
    await withBoard(tester, TargetPlatform.windows, (fixture) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(
        tester.getTopLeft(boardTile(100)) + const Offset(40, 20),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
    });
  });

  testWidgets('right click on a card opens its actions', (tester) async {
    await withBoard(tester, TargetPlatform.windows, (fixture) async {
      await tester.tap(boardTile(100), buttons: kSecondaryMouseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      for (final label in [
        'Move card',
        'Labels',
        'Archive',
        'Delete card',
        'Select card',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      await tester.tap(find.text('Archive'));
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.writesFor(fixture.account.id),
      );
      expect(writes.single.kind, 'archiveCard');
    });
  });

  testWidgets('right click on a read-only card offers no changes', (
    tester,
  ) async {
    await withBoard(tester, TargetPlatform.macOS, editable: false, (
      fixture,
    ) async {
      await tester.tap(boardTile(100), buttons: kSecondaryMouseButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Move card'), findsNothing);
      expect(find.text('Delete card'), findsNothing);
      expect(find.text('Archive'), findsNothing);
    });
  });

  testWidgets('right click on a column heading follows the manage permission', (
    tester,
  ) async {
    await withBoard(tester, TargetPlatform.windows, manage: true, (
      fixture,
    ) async {
      await tester.tap(
        find.text('Column 1 (3)'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Edit column'), findsOneWidget);
      expect(find.text('Delete column'), findsOneWidget);
    });
    await withBoard(tester, TargetPlatform.windows, (fixture) async {
      await tester.tap(
        find.text('Column 1 (3)'),
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Edit column'), findsNothing);
    });
  });
}
