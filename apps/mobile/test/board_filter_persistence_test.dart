import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_filters.dart';
import 'package:nextclouddeck/features/board_view.dart';
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

  test('filter JSON round trips and damaged input gives the empty filter', () {
    const filter = BoardCardFilter(
      query: 'abc',
      memberId: 'u',
      labelId: 3,
      due: BoardDueFilter.overdue,
      completion: BoardCompletionFilter.open,
    );
    final restored = BoardCardFilter.decode(filter.encode());
    expect(restored.query, 'abc');
    expect(restored.memberId, 'u');
    expect(restored.labelId, 3);
    expect(restored.due, BoardDueFilter.overdue);
    expect(restored.completion, BoardCompletionFilter.open);
    expect(const BoardCardFilter().encode(), isNull);
    expect(BoardCardFilter.decode('{broken').active, isFalse);
  });

  testWidgets('board filter survives restart and clearing removes it', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    final store = MemoryBoardPreferences();
    Widget app(AppPreferences preferences) => boardTestApp(
      BoardScreen(session: fixture.session, board: fixture.board),
      preferences: preferences,
    );
    Finder card(String title) =>
        find.byWidgetPredicate((w) => w is Text && w.data == title);
    try {
      await tester.pumpWidget(app(AppPreferences(store: store)));
      await settleBoard(tester);
      await tester.enterText(
        find.byKey(const ValueKey('board-card-search')),
        'Card 100',
      );
      await settleBoard(tester);
      expect(card('Card 101'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(AppPreferences(store: store)));
      await settleBoard(tester);
      expect(card('Card 100'), findsOneWidget);
      expect(card('Card 101'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('board-card-search')))
            .controller!
            .text,
        'Card 100',
      );

      await tester.tap(find.text('Clear filters'));
      await settleBoard(tester);
      expect(card('Card 101'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(AppPreferences(store: store)));
      await settleBoard(tester);
      expect(card('Card 101'), findsOneWidget);
      expect(store.values.values.where((v) => v.contains('Card')), isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
