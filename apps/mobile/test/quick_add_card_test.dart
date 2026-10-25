import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/card_editor.dart';
import 'package:nextclouddeck/features/drafts.dart';
import 'package:nextclouddeck/features/quick_add_card.dart';

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

  Future<DeckBoard> addDestination(BoardFixture fixture) async {
    final board = DeckBoard.fromJson({
      ...fixture.board.raw,
      'id': 2,
      'title': 'Second board',
    });
    await fixture.db.saveBoards(
      fixture.account.id,
      fixture.account.generation,
      [fixture.board, board],
      null,
    );
    await fixture.db.saveStacks(
      fixture.account.id,
      fixture.account.generation,
      2,
      [
        DeckStack.fromJson({
          'id': 20,
          'boardId': 2,
          'title': 'Second column',
          'order': 0,
          'cards': [],
        }),
      ],
      null,
    );
    return board;
  }

  Widget composer(
    BoardFixture fixture,
    AppPreferences preferences, {
    DeckBoard? board,
    int? stackId,
  }) => boardTestApp(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => showQuickAddCard(
                  context,
                  fixture.session,
                  board: board,
                  stackId: stackId,
                ),
                child: const Text('Open composer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DraftsScreen(session: fixture.session),
                  ),
                ),
                child: const Text('Open drafts'),
              ),
            ],
          ),
        ),
      ),
    ),
    preferences: preferences,
  );

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );

  Finder dropdown(String label) => find.ancestor(
    of: find.byWidgetPredicate(
      (widget) =>
          widget is InputDecorator && widget.decoration.labelText == label,
    ),
    matching: find.byType(DropdownButtonFormField<int>),
  );
  Finder boardField() => dropdown('Board');
  Finder columnField() => dropdown('Destination column');

  Future<void> openComposer(WidgetTester tester) async {
    await tester.tap(find.text('Open composer'));
    await settleBoard(tester);
    await tester.pumpAndSettle();
  }

  Future<List<EditorDraft>> drafts(WidgetTester tester, BoardFixture fixture) =>
      boardModel(tester, (fixture.db.select(fixture.db.editorDrafts)).get());

  testWidgets('quick add restores a destination separately for each account', (
    tester,
  ) async {
    final first = (await tester.runAsync(() => BoardFixture.create()))!;
    final second = (await tester.runAsync(() => BoardFixture.create()))!;
    final store = MemoryBoardPreferences();
    final seed = AppPreferences(store: store);
    try {
      await tester.runAsync(() async {
        await addDestination(first);
        await addDestination(second);
      });
      await boardModel(
        tester,
        seed.rememberCardDestination(first.account.id, 2, 20),
      );
      await boardModel(
        tester,
        seed.rememberCardDestination(second.account.id, 1, 11),
      );
      await tester.pumpWidget(composer(first, AppPreferences(store: store)));
      await openComposer(tester);
      expect(tester.state<FormFieldState<int>>(boardField()).value, 2);
      expect(tester.state<FormFieldState<int>>(columnField()).value, 20);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(composer(second, AppPreferences(store: store)));
      await openComposer(tester);
      expect(tester.state<FormFieldState<int>>(boardField()).value, 1);
      expect(tester.state<FormFieldState<int>>(columnField()).value, 11);
      expect(
        await boardModel(tester, first.db.writesFor(first.account.id)),
        isEmpty,
      );
      expect(
        await boardModel(tester, second.db.writesFor(second.account.id)),
        isEmpty,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      seed.dispose();
      await boardModel(tester, first.close());
      await boardModel(tester, second.close());
    }
  });

  testWidgets(
    'an unavailable explicitly requested board never silently changes destination',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      final preferences = AppPreferences(store: MemoryBoardPreferences());
      try {
        await tester.runAsync(() => addDestination(fixture));
        final requested = DeckBoard.fromJson({
          ...fixture.board.raw,
          'id': 99,
          'title': 'Unavailable board',
        });
        await tester.pumpWidget(
          composer(fixture, preferences, board: requested),
        );
        await openComposer(tester);
        expect(tester.state<FormFieldState<int>>(boardField()).value, isNull);
        expect(tester.widget<TextField>(field('Card title')).enabled, isFalse);
        expect(
          find.text('You no longer have access to this content.'),
          findsOneWidget,
        );
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'an unavailable explicitly requested column never selects the first column',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await tester.pumpWidget(
          composer(
            fixture,
            AppPreferences(store: MemoryBoardPreferences()),
            board: fixture.board,
            stackId: 999,
          ),
        );
        await openComposer(tester);
        expect(
          tester.widget<TextField>(field('Card title')).enabled,
          isFalse,
          reason:
              'An action from a removed column must not target another column.',
        );
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'quick add queues one card, removes its draft and remembers the selected target',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      final preferences = AppPreferences(store: MemoryBoardPreferences());
      try {
        final board = (await tester.runAsync(() => addDestination(fixture)))!;
        await tester.pumpWidget(
          composer(fixture, preferences, board: board, stackId: 20),
        );
        await openComposer(tester);
        await tester.enterText(field('Card title'), 'New follow-up');
        await tester.tap(find.text('Add details'));
        await tester.pumpAndSettle();
        await tester.enterText(
          field('Description'),
          'Details stay with this card',
        );
        await settleBoard(tester);
        expect(
          jsonDecode(
            (await drafts(tester, fixture)).single.payload,
          )['description'],
          'Details stay with this card',
        );
        final save = find.widgetWithText(FilledButton, 'Add card');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await settleBoard(tester);
        await tester.pumpAndSettle();
        final writes = await boardModel(
          tester,
          fixture.db.writesFor(fixture.account.id),
        );
        expect(writes.length, 1);
        expect(writes.single.kind, 'createCard');
        expect(writes.single.boardId, 2);
        expect(writes.single.stackId, 20);
        expect(jsonDecode(writes.single.proposal)['title'], 'New follow-up');
        expect(
          jsonDecode(writes.single.proposal)['description'],
          'Details stay with this card',
        );
        expect(await drafts(tester, fixture), isEmpty);
        expect(await preferences.lastCardDestination(fixture.account.id), (
          boardId: 2,
          stackId: 20,
        ));
        expect(find.byType(TextField), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'cancelled quick add can be reopened from drafts with its original text',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await tester.pumpWidget(
          composer(fixture, AppPreferences(store: MemoryBoardPreferences())),
        );
        await openComposer(tester);
        await tester.enterText(field('Card title'), 'Continue later');
        await settleBoard(tester);
        await tester.tap(find.byTooltip('Close'));
        await settleBoard(tester);
        await tester.pumpAndSettle();
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
        final saved = (await drafts(tester, fixture)).single;
        expect(jsonDecode(saved.payload)['title'], 'Continue later');
        await tester.tap(find.text('Open drafts'));
        await settleBoard(tester);
        await tester.tap(find.text('Continue later'));
        await settleBoard(tester);
        expect(find.byType(CardEditor), findsOneWidget);
        expect(
          tester.widget<TextField>(field('Card title')).controller!.text,
          'Continue later',
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'clearing all quick add text removes the previous autosaved draft',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await tester.pumpWidget(
          composer(fixture, AppPreferences(store: MemoryBoardPreferences())),
        );
        await openComposer(tester);
        await tester.enterText(field('Card title'), 'Do not restore this');
        await settleBoard(tester);
        expect(await drafts(tester, fixture), hasLength(1));
        await tester.enterText(field('Card title'), '');
        await settleBoard(tester);
        await tester.tap(find.byTooltip('Close'));
        await settleBoard(tester);
        expect(await drafts(tester, fixture), isEmpty);
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets(
    'permission loss during quick add preserves the draft and reports refusal',
    (tester) async {
      final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
      try {
        await tester.pumpWidget(
          composer(fixture, AppPreferences(store: MemoryBoardPreferences())),
        );
        await openComposer(tester);
        await tester.enterText(field('Card title'), 'Keep my work');
        await settleBoard(tester);
        await boardModel(
          tester,
          fixture.db.saveBoards(
            fixture.account.id,
            fixture.account.generation,
            [
              DeckBoard.fromJson({
                ...fixture.board.raw,
                'permissions': {
                  'PERMISSION_READ': true,
                  'PERMISSION_EDIT': false,
                },
              }),
            ],
            null,
          ),
        );
        final save = find.widgetWithText(FilledButton, 'Add card');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await settleBoard(tester);
        expect(
          find.text('You no longer have access to this content.'),
          findsOneWidget,
        );
        expect(
          tester.widget<TextField>(field('Card title')).controller!.text,
          'Keep my work',
        );
        expect(
          jsonDecode((await drafts(tester, fixture)).single.payload)['title'],
          'Keep my work',
        );
        expect(
          await boardModel(tester, fixture.db.writesFor(fixture.account.id)),
          isEmpty,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, fixture.close());
      }
    },
  );

  testWidgets('quick add submit stays above navigation and keyboard insets', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    try {
      await tester.pumpWidget(
        composer(fixture, AppPreferences(store: MemoryBoardPreferences())),
      );
      await openComposer(tester);
      await tester.enterText(field('Card title'), 'Reachable submit');
      await settleBoard(tester);
      final submit = find.widgetWithText(FilledButton, 'Add card');
      for (final keyboard in [0.0, 300.0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        tester.view.padding = FakeViewPadding(bottom: keyboard == 0 ? 48 : 0);
        await tester.pumpAndSettle();
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        expect(
          tester.getBottomRight(submit).dy,
          lessThanOrEqualTo(800 - (keyboard == 0 ? 48 : keyboard)),
        );
        expect(submit.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(submit);
      await settleBoard(tester);
      final writes = await boardModel(
        tester,
        fixture.db.select(fixture.db.pendingWrites).get(),
      );
      expect(writes.where((write) => write.kind == 'createCard'), hasLength(1));
      expect(jsonDecode(writes.single.proposal)['title'], 'Reachable submit');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await boardModel(tester, fixture.close());
    }
  });
}
