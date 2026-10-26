import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/card_editor.dart';
import 'package:nextclouddeck/features/comment_editor.dart';
import 'package:nextclouddeck/features/markdown_field.dart';

import 'board_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const connectivity = MethodChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivity, null);
  });

  final controller = TextEditingController();
  Future<void> pump(WidgetTester tester) async {
    controller.clear();
    await tester.pumpWidget(
      boardTestApp(
        Scaffold(
          body: MarkdownField(
            controller: controller,
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Body'),
          ),
        ),
      ),
    );
  }

  // The formatter sees single keystrokes, so Enter arrives as a lone newline.
  Future<void> type(WidgetTester tester, String value) async {
    if (value.endsWith('\n')) {
      await tester.enterText(
        find.byType(TextField),
        value.substring(0, value.length - 1),
      );
    }
    await tester.enterText(find.byType(TextField), value);
  }

  for (final (typed, expected) in [
    ('- one\n', '- one\n- '),
    ('* one\n', '* one\n* '),
    ('1. one\n', '1. one\n2. '),
    ('  9. one\n', '  9. one\n  10. '),
    ('- [ ] one\n', '- [ ] one\n- [ ] '),
    ('- [x] done\n', '- [x] done\n- [ ] '),
    ('plain\n', 'plain\n'),
  ]) {
    testWidgets('Enter on ${typed.trim()} gives ${expected.length} chars', (
      tester,
    ) async {
      await pump(tester);
      await type(tester, typed);
      expect(controller.text, expected);
      expect(controller.selection.baseOffset, expected.length);
    });
  }

  testWidgets('Enter on an empty item ends the list', (tester) async {
    await pump(tester);
    await type(tester, '- [ ] one\n');
    await type(tester, '- [ ] one\n- [ ] \n');
    expect(controller.text, '- [ ] one\n');
    expect(controller.selection.baseOffset, 10);
  });

  testWidgets('toolbar inserts Markdown around the selection', (tester) async {
    await pump(tester);
    await type(tester, 'hello');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.tap(find.byKey(const ValueKey('md-bold')));
    expect(controller.text, '**hello**');

    controller.text = 'a\nb';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);
    await tester.tap(find.byKey(const ValueKey('md-list')));
    expect(controller.text, '- a\n- b');

    controller.text = '';
    await tester.tap(find.byKey(const ValueKey('md-checklist')));
    expect(controller.text, '- [ ] ');

    controller.text = 'site';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.tap(find.byKey(const ValueKey('md-link')));
    expect(controller.text, '[site]()');
    expect(controller.selection.baseOffset, 7);
  });

  for (final comment in [false, true]) {
    testWidgets('${comment ? 'comment' : 'card'} editor has the toolbar', (
      tester,
    ) async {
      final model = (await tester.runAsync(
        () => BoardFixture.create(counts: [1]),
      ))!;
      try {
        await tester.pumpWidget(
          boardTestApp(
            comment
                ? CommentEditor(
                    session: model.session,
                    boardId: 1,
                    stackId: 10,
                    cardId: 100,
                  )
                : CardEditor(session: model.session, boardId: 1, stackId: 10),
          ),
        );
        await settleBoard(tester);
        final field = find.byType(TextField).last;
        await tester.enterText(field, '- a');
        await tester.enterText(field, '- a\n');
        expect(
          tester.widget<TextField>(field).controller!.text,
          '- a\n- ',
        );
        await tester.tap(find.byKey(const ValueKey('md-checklist')));
        expect(
          tester.widget<TextField>(field).controller!.text,
          '- a\n- [ ] - ',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await boardModel(tester, model.close());
      }
    });
  }
}
