import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/card_editor.dart';
import 'package:nextclouddeck/features/comment_editor.dart';
import 'package:nextclouddeck/features/structure_editor.dart';

import 'board_test_support.dart';

const _permission = 'You do not have permission to save this change.';
const _storage = 'Changes could not be saved on this device. Try again.';

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

  Future<void> finish(WidgetTester tester, BoardFixture model) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await boardModel(tester, model.close());
  }

  for (final scenario in ['permission', 'account', 'storage', 'pending']) {
    testWidgets('card save reports $scenario and keeps the edited draft', (
      tester,
    ) async {
      final model = (await tester.runAsync(
        () => BoardFixture.create(counts: [1]),
      ))!;
      final card = model.stacks.first.cards.first;
      try {
        await tester.pumpWidget(
          boardTestApp(
            CardEditor(
              session: model.session,
              boardId: 1,
              stackId: card.stackId,
              card: card,
              draftKey: 'card-error-draft',
            ),
          ),
        );
        await settleBoard(tester);
        await tester.enterText(
          find.byType(TextField).first,
          'Keep this local title',
        );
        await settleBoard(tester);
        switch (scenario) {
          case 'permission':
            await boardModel(
              tester,
              model.db.saveBoards(model.account.id, model.account.generation, [
                DeckBoard.fromJson({
                  ...model.board.raw,
                  'permissions': {
                    'PERMISSION_READ': true,
                    'PERMISSION_EDIT': false,
                  },
                }),
              ], null),
            );
          case 'account':
            await boardModel(
              tester,
              model.db.customStatement(
                'UPDATE stored_accounts SET generation = generation + 1 WHERE id = ?',
                [model.account.id],
              ),
            );
          case 'storage':
            await boardModel(
              tester,
              model.db.customStatement(
                "CREATE TRIGGER fail_write BEFORE INSERT ON pending_writes BEGIN SELECT RAISE(ABORT, 'private storage detail'); END",
              ),
            );
          case 'pending':
            await boardModel(
              tester,
              model.db.queueCardAction(
                model.account,
                1,
                card,
                'archiveCard',
                {},
              ),
            );
        }
        await tester.tap(find.text('Save').hitTestable());
        await settleBoard(tester);
        final expected = switch (scenario) {
          'permission' => _permission,
          'account' => 'Your session expired. Add the same account again.',
          'storage' => _storage,
          _ =>
            'This card has a sending or unresolved change. Open Pending changes first.',
        };
        expect(find.text(expected), findsOneWidget);
        expect(find.textContaining('Secure storage'), findsNothing);
        expect(find.textContaining('private storage detail'), findsNothing);
        final draft = await boardModel(
          tester,
          model.db.editorDraft(model.account.id, 'card-error-draft'),
        );
        expect(jsonDecode(draft!.payload)['title'], 'Keep this local title');
        final writes = await boardModel(
          tester,
          model.db.writesFor(model.account.id),
        );
        expect(writes.length, scenario == 'pending' ? 1 : 0);
        expect(tester.takeException(), isNull);
      } finally {
        await finish(tester, model);
      }
    });
  }

  for (final missingIdentity in [false, true]) {
    testWidgets(
      'comment save preserves text after ${missingIdentity ? 'missing identity' : 'read revocation'}',
      (tester) async {
        final model = (await tester.runAsync(
          () => BoardFixture.create(counts: [1]),
        ))!;
        try {
          if (!missingIdentity) {
            await boardModel(
              tester,
              model.db.saveUserIdentity(model.account, 'user'),
            );
          }
          await tester.pumpWidget(
            boardTestApp(
              CommentEditor(
                session: model.session,
                boardId: 1,
                stackId: 10,
                cardId: 100,
                draftKey: 'comment-error-draft',
              ),
            ),
          );
          await settleBoard(tester);
          await tester.enterText(find.byType(TextField), 'Keep this comment');
          await settleBoard(tester);
          if (!missingIdentity) {
            await boardModel(
              tester,
              model.db.revokeBoardAccess(model.account, 1),
            );
          }
          await tester.tap(find.byTooltip('Send comment'));
          await settleBoard(tester);
          expect(
            find.text(
              missingIdentity
                  ? 'Reconnect first so the app can verify your user ID. Your draft is preserved.'
                  : _permission,
            ),
            findsOneWidget,
          );
          expect(find.textContaining('Secure storage'), findsNothing);
          final draft = await boardModel(
            tester,
            model.db.editorDraft(model.account.id, 'comment-error-draft'),
          );
          expect(
            jsonDecode(draft!.payload)['description'],
            'Keep this comment',
          );
          expect(
            await boardModel(tester, model.db.writesFor(model.account.id)),
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        } finally {
          await finish(tester, model);
        }
      },
    );
  }

  testWidgets(
    'board edit reports lost manage permission and keeps the entered title',
    (tester) async {
      final model = (await tester.runAsync(
        () => BoardFixture.create(counts: [1]),
      ))!;
      final managerBoard = DeckBoard.fromJson({
        ...model.board.raw,
        'permissions': {
          'PERMISSION_READ': true,
          'PERMISSION_EDIT': true,
          'PERMISSION_MANAGE': true,
        },
      });
      try {
        await boardModel(
          tester,
          model.db.saveBoards(model.account.id, model.account.generation, [
            managerBoard,
          ], null),
        );
        await tester.pumpWidget(
          boardTestApp(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => editStructure(
                    context,
                    model.session,
                    board: managerBoard,
                  ),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open editor'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Unsent board title');
        await boardModel(
          tester,
          model.db.saveBoards(model.account.id, model.account.generation, [
            model.board,
          ], null),
        );
        await tester.tap(find.text('Save'));
        await settleBoard(tester);
        expect(find.text(_permission), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'Unsent board title',
        );
        expect(
          await boardModel(tester, model.db.writesFor(model.account.id)),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await finish(tester, model);
      }
    },
  );

  testWidgets(
    'failed autosave warns before leaving and keeps the text on cancel',
    (tester) async {
      final model = (await tester.runAsync(
        () => BoardFixture.create(counts: [1]),
      ))!;
      try {
        await tester.pumpWidget(
          boardTestApp(
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => editCard(
                    context,
                    model.session,
                    1,
                    10,
                    card: model.stacks.first.cards.first,
                  ),
                  child: const Text('Open editor'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open editor'));
        await settleBoard(tester);
        await boardModel(
          tester,
          model.db.customStatement(
            "CREATE TRIGGER fail_draft BEFORE INSERT ON editor_drafts BEGIN SELECT RAISE(ABORT, 'private storage detail'); END",
          ),
        );
        await tester.enterText(
          find.byType(TextField).first,
          'Keep unsaved text',
        );
        await settleBoard(tester);
        expect(find.text(_storage), findsOneWidget);
        expect(find.textContaining('Secure storage'), findsNothing);
        await tester.pageBack();
        await settleBoard(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(_storage),
          ),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          'Keep unsaved text',
        );
        expect(
          await boardModel(tester, model.db.writesFor(model.account.id)),
          isEmpty,
        );
        expect(tester.takeException(), isNull);
      } finally {
        await finish(tester, model);
      }
    },
  );
}
