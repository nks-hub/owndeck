import 'dart:convert';

import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/structure_editor.dart';

import 'board_test_support.dart';

Rect _semanticRect(SemanticsNode node) {
  var transform = Matrix4.identity();
  SemanticsNode? current = node;
  while (current != null) {
    if (current.transform != null) transform = current.transform! * transform;
    current = current.parent;
  }
  return MatrixUtils.transformRect(transform, node.rect);
}

void main() {
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );

  Future<void> scenario(
    WidgetTester tester,
    Size size,
    double scale,
    Future<void> Function(BoardFixture) check,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    final semantics = tester.ensureSemantics();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
    final fixture = (await tester.runAsync(
      () => BoardFixture.create(counts: [1, 0, 0], manage: true),
    ))!;
    try {
      await tester.pumpWidget(
        boardTestApp(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => editStructure(
                  context,
                  fixture.session,
                  board: fixture.board,
                  stack: fixture.stacks.last,
                  column: true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
          scale: scale,
        ),
      );
      await tester.tap(find.text('Open'));
      await settleBoard(tester);
      await check(fixture);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await boardModel(tester, fixture.close());
      semantics.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewInsets();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(connectivity, null);
    }
  }

  testWidgets(
    'keyboard visibility preserves portrait controls and text focus',
    (tester) async {
      await scenario(tester, const Size(393, 852), 1, (fixture) async {
        final field = find.byType(TextField);
        await tester.enterText(field, 'Renamed column');
        final input = tester.widget<EditableText>(find.byType(EditableText));
        final selection = input.controller.selection;
        final save = find.widgetWithText(FilledButton, 'Save');
        final cancel = find.widgetWithText(TextButton, 'Cancel');
        final originalSave = tester.getRect(save);
        final originalCancel = tester.getRect(cancel);
        for (final inset in [335.0, 0.0, 335.0, 0.0]) {
          tester.view.viewInsets = FakeViewPadding(bottom: inset);
          await tester.pumpAndSettle();
          expect(tester.getRect(save), originalSave);
          expect(tester.getRect(cancel), originalCancel);
          expect(input.focusNode.hasFocus, isTrue);
          expect(input.controller.text, 'Renamed column');
          expect(input.controller.selection, selection);
          final semantic = _semanticRect(tester.getSemantics(save));
          expect(semantic.center.dx, closeTo(originalSave.center.dx, 1));
          expect(semantic.center.dy, closeTo(originalSave.center.dy, 1));
        }
        await tester.tapAt(_semanticRect(tester.getSemantics(cancel)).center);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
      });
    },
  );

  for (final size in [const Size(393, 852), const Size(852, 393)]) {
    testWidgets('large-text column choices survive keyboard changes in $size', (
      tester,
    ) async {
      await scenario(tester, size, 2, (fixture) async {
        final field = find.byType(TextField);
        await tester.ensureVisible(field);
        await tester.enterText(field, 'Chosen column');
        tester.view.viewInsets = FakeViewPadding(
          bottom: size.width > size.height ? 220 : 335,
        );
        await tester.pumpAndSettle();
        final placement = find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<String>,
        );
        await tester.ensureVisible(placement);
        await tester.pumpAndSettle();
        await tester.tap(placement);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('After a column').last);
        await tester.tap(find.text('After a column').last);
        await settleBoard(tester);
        final anchor = find.byWidgetPredicate(
          (widget) => widget is DropdownButtonFormField<int>,
        );
        await tester.ensureVisible(anchor);
        await tester.pumpAndSettle();
        await tester.tap(anchor);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Column 2').last);
        await tester.tap(find.text('Column 2').last);
        await settleBoard(tester);
        final keyboard = tester.view.viewInsets;
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        tester.view.viewInsets = keyboard;
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(field).controller!.text,
          'Chosen column',
        );
        expect(find.text('After a column'), findsOneWidget);
        expect(find.text('Column 2'), findsOneWidget);
        final save = find.widgetWithText(FilledButton, 'Save');
        final cancel = find.widgetWithText(TextButton, 'Cancel');
        expect(save.hitTestable(), findsOneWidget);
        expect(cancel.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(save).bottom,
          lessThanOrEqualTo(size.height - keyboard.bottom),
        );
        await tester.tapAt(_semanticRect(tester.getSemantics(save)).center);
        await settleBoard(tester);
        expect(find.byType(AlertDialog), findsNothing);
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(writes.map((write) => write.kind), [
          'updateStack',
          'stackReorder',
        ]);
        final update =
            jsonDecode(writes.first.proposal) as Map<String, dynamic>;
        final reorder =
            jsonDecode(writes.last.proposal) as Map<String, dynamic>;
        expect(update['title'], 'Chosen column');
        expect(reorder['anchorStackId'], 11);
        expect(reorder['before'], isFalse);
      });
    });
  }
}
