import 'dart:convert';

import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/card_editor.dart';

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

  // 2026-03-28 is the evening before the EU spring DST change.
  final eve = DateTime(2026, 3, 28, 23, 30);

  test('days are added on the calendar so a DST change keeps the time', () {
    final tomorrow = quickDueDate(QuickDue.tomorrow, eve, current: eve)!;
    expect(tomorrow, DateTime(2026, 3, 29, 23, 30));
    final week = quickDueDate(QuickDue.nextWeek, eve, current: eve)!;
    expect((week.year, week.month, week.day), (2026, 4, 4));
    expect((week.hour, week.minute), (23, 30));
    final today = quickDueDate(QuickDue.today, eve)!;
    expect(today, DateTime(2026, 3, 28, 12));
    expect(quickDueDate(QuickDue.none, eve, current: eve), isNull);
  });

  testWidgets('quick choices set and clear the due date of a new card', (
    tester,
  ) async {
    final model = (await tester.runAsync(
      () => BoardFixture.create(counts: [1]),
    ))!;
    Future<DateTime?> savedDue() async {
      await settleBoard(tester);
      final draft = await boardModel(
        tester,
        model.db.editorDraft(model.account.id, 'quick-due'),
      );
      final value = jsonDecode(draft!.payload)['duedate'] as String?;
      return value == null ? null : DateTime.parse(value).toLocal();
    }

    Future<void> choose(QuickDue choice) async {
      final chip = find.byKey(ValueKey(('quick-due', choice)));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
    }

    try {
      await tester.pumpWidget(
        boardTestApp(
          CardEditor(
            session: model.session,
            boardId: 1,
            stackId: 10,
            draftKey: 'quick-due',
            clock: () => eve,
          ),
        ),
      );
      await settleBoard(tester);
      await choose(QuickDue.tomorrow);
      expect(await savedDue(), DateTime(2026, 3, 29, 12));
      await choose(QuickDue.nextWeek);
      expect(await savedDue(), DateTime(2026, 4, 4, 12));
      await choose(QuickDue.today);
      expect(await savedDue(), DateTime(2026, 3, 28, 12));
      await choose(QuickDue.none);
      expect(await savedDue(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await boardModel(tester, model.close());
    }
  });
}
