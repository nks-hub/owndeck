import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/attachments.dart';
import 'package:nextclouddeck/features/sharing.dart';

import 'board_test_support.dart';

DeckAttachment _file(int id, String name) => DeckAttachment.fromJson({
  'id': id,
  'cardId': 100,
  'type': 'file',
  'data': name,
  'lastModified': 1,
  'deletedAt': 0,
});

Set<String?> _tooltips(WidgetTester tester) => tester
    .widgetList<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
    .map((button) => button.tooltip)
    .toSet();

Future<void> _guidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
  });

  testWidgets('attachment menus name their file and meet guidelines', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    try {
      await boardModel(
        tester,
        fixture.db.saveAttachments(fixture.account, 1, 100, [
          _file(7, 'report.txt'),
          _file(8, 'photo.png'),
        ], 0),
      );
      await tester.pumpWidget(
        boardTestApp(
          AttachmentsScreen(session: fixture.session, boardId: 1, cardId: 100),
        ),
      );
      await settleBoard(tester);
      expect(_tooltips(tester), {
        'More actions: report.txt',
        'More actions: photo.png',
      });
      await _guidelines(tester);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });

  testWidgets('share menus name the person, pending decision is explained', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() => BoardFixture.create()))!;
    try {
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
                'PERMISSION_EDIT': true,
                'PERMISSION_SHARE': true,
                'PERMISSION_MANAGE': true,
              },
              'acl': [
                for (final (id, name) in [(2, 'Alice'), (3, 'Bob')])
                  {
                    'id': id,
                    'type': 0,
                    'participant': {'uid': 'u$id', 'displayname': name},
                  },
              ],
            }),
          ],
          null,
        ),
      );
      await tester.pumpWidget(
        boardTestApp(SharingScreen(session: fixture.session, boardId: 1)),
      );
      await settleBoard(tester);
      expect(_tooltips(tester), {'More actions: Alice', 'More actions: Bob'});
      await _guidelines(tester);

      Future<void> editAliceAndSave() async {
        await tester.tap(find.byTooltip('More actions: Alice'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit permissions'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Edit'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        await settleBoard(tester);
      }

      await editAliceAndSave();
      expect(find.byType(AlertDialog), findsNothing);
      await editAliceAndSave();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text(
          'This card has a sending or unresolved change. Open Pending changes first.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('You no longer have access to this content.'),
        findsNothing,
      );
      final live = find.ancestor(
        of: find.textContaining('Open Pending changes'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await boardModel(tester, fixture.close());
    }
  });
}
