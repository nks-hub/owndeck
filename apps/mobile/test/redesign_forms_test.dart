import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nextclouddeck/core/app_preferences.dart';
import 'package:nextclouddeck/features/board_view.dart';
import 'package:nextclouddeck/features/card_detail.dart';
import 'package:nextclouddeck/features/card_editor.dart';
import 'package:nextclouddeck/features/structure_editor.dart';

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

  Future<BoardFixture> fixture() async {
    final original = await BoardFixture.create(counts: [3, 0]);
    final board = DeckBoard.fromJson({
      ...original.board.raw,
      'color': '123abc',
      'permissions': {
        'PERMISSION_READ': true,
        'PERMISSION_EDIT': true,
        'PERMISSION_MANAGE': true,
      },
      'labels': [
        {'id': 7, 'title': 'Original label', 'color': 'abcdef'},
      ],
    });
    await original.db.saveBoards(
      original.account.id,
      original.account.generation,
      [board],
      null,
    );
    return BoardFixture(
      original.db,
      original.account,
      original.session,
      board,
      original.stacks,
    );
  }

  Future<DeckCard> currentCard(BoardFixture fixture) async {
    final card = DeckCard.fromJson({
      ...fixture.stacks.first.cards.first.raw,
      'color': '123abc',
      'startdate': '2030-01-14T09:00:00Z',
      'duedate': '2030-01-15T12:00:00Z',
      'done': '2030-01-15T10:00:00Z',
    });
    await fixture.db.saveStacks(
      fixture.account.id,
      fixture.account.generation,
      1,
      [
        DeckStack.fromJson({
          ...fixture.stacks.first.raw,
          'cards': [
            card.raw,
            ...fixture.stacks.first.cards.skip(1).map((card) => card.raw),
          ],
        }),
        fixture.stacks.last,
      ],
      null,
    );
    return card;
  }

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );

  Widget launch(Future<void> Function(BuildContext) open, {double scale = 1}) =>
      boardTestApp(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => open(context),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
        scale: scale,
      );

  void noVisibleHex() {
    final labels = find
        .byType(Text)
        .evaluate()
        .map((element) => (element.widget as Text).data ?? '')
        .join('\n');
    expect(labels.toLowerCase(), isNot(contains('123abc')));
    expect(labels.toLowerCase(), isNot(contains('abcdef')));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Color',
      ),
      findsNothing,
    );
  }

  testWidgets(
    'card rename preserves a custom color and all dates with Save above the keyboard',
    (tester) async {
      final model = (await tester.runAsync(fixture))!;
      try {
        final card = (await tester.runAsync(() => currentCard(model)))!;
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(846, 412);
        tester.view.viewInsets = const FakeViewPadding(bottom: 200);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpWidget(
          launch(
            (context) async =>
                editCard(context, model.session, 1, 10, card: card),
            scale: 2,
          ),
        );
        await tester.tap(find.text('Open form'));
        await settleBoard(tester);
        await tester.enterText(field('Card title'), 'Renamed only');
        await settleBoard(tester);
        noVisibleHex();
        final save = find.text('Save');
        expect(save.hitTestable(), findsOneWidget);
        expect(tester.getBottomLeft(save).dy, lessThan(212));
        await tester.tap(save);
        await settleBoard(tester);
        final write = (await boardModel(
          tester,
          model.db.writesFor(model.account.id),
        )).single;
        expect(jsonDecode(write.proposal), {'title': 'Renamed only'});
        final base = jsonDecode(write.base!);
        for (final key in [
          'description',
          'color',
          'startdate',
          'duedate',
          'done',
        ]) {
          expect(base[key], card.raw[key]);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, model.close());
      }
    },
  );

  testWidgets(
    'card palette changes the selected color without a hexadecimal field',
    (tester) async {
      final model = (await tester.runAsync(fixture))!;
      try {
        final card = (await tester.runAsync(() => currentCard(model)))!;
        await tester.pumpWidget(
          launch(
            (context) async =>
                editCard(context, model.session, 1, 10, card: card),
          ),
        );
        await tester.tap(find.text('Open form'));
        await settleBoard(tester);
        await tester.scrollUntilVisible(
          find.text('Custom color'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        noVisibleHex();
        await tester.ensureVisible(find.text('Blue'));
        await tester.tap(find.text('Blue'));
        await tester.tap(find.text('Save'));
        await settleBoard(tester);
        final write = (await boardModel(
          tester,
          model.db.writesFor(model.account.id),
        )).single;
        expect(jsonDecode(write.proposal), {'color': '2563eb'});
        expect(jsonDecode(write.base!)['description'], card.description);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, model.close());
      }
    },
  );

  for (final label in [false, true]) {
    testWidgets(
      '${label ? 'label' : 'board'} palette preserves custom colors and saves a named choice',
      (tester) async {
        final model = (await tester.runAsync(fixture))!;
        try {
          await tester.pumpWidget(
            launch(
              (context) => editStructure(
                context,
                model.session,
                board: model.board,
                labelItem: label,
                label: label
                    ? {'id': 7, 'title': 'Original label', 'color': 'abcdef'}
                    : null,
              ),
            ),
          );
          await tester.tap(find.text('Open form'));
          await settleBoard(tester);
          expect(find.text('Custom color'), findsOneWidget);
          noVisibleHex();
          await tester.ensureVisible(find.text('Purple'));
          await tester.tap(find.text('Purple'));
          await tester.enterText(field('Name'), 'Renamed');
          await tester.tap(find.text('Save'));
          await settleBoard(tester);
          final write = (await boardModel(
            tester,
            model.db.writesFor(model.account.id),
          )).single;
          expect(write.kind, label ? 'updateLabel' : 'updateBoard');
          final data = jsonDecode(write.proposal);
          expect(data['title'], 'Renamed');
          expect(data['color'], '7c3aed');
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await boardModel(tester, model.close());
        }
      },
    );
  }

  testWidgets(
    'new column is projected after the chosen column rather than a legacy numeric position',
    (tester) async {
      final model = (await tester.runAsync(fixture))!;
      try {
        await tester.pumpWidget(
          launch(
            (context) => editStructure(
              context,
              model.session,
              board: model.board,
              column: true,
            ),
          ),
        );
        await tester.tap(find.text('Open form'));
        await settleBoard(tester);
        await tester.enterText(field('Name'), 'Middle column');
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('After a column').last);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        await tester.tap(find.text('Save'));
        await settleBoard(tester);
        final writes = await boardModel(
          tester,
          model.db.writesFor(model.account.id),
        );
        final creation = writes.singleWhere(
          (write) => write.kind == 'createStack',
        );
        expect(jsonDecode(creation.proposal).containsKey('order'), isFalse);
        expect(
          writes.where((write) => write.kind == 'stackReorder'),
          hasLength(1),
        );
        final stacks = await boardModel(
          tester,
          model.db.stackView(model.account.id, 1),
        );
        expect(stacks.map((stack) => stack.title), [
          'Column 1',
          'Middle column',
          'Column 2',
        ]);
        expect(stacks.first.cards.map((card) => card.id), [100, 101, 102]);
        await boardModel(tester, model.session.refreshStacks(1));
        final server = [
          for (final stack in model.stacks) {...stack.raw},
        ];
        final mutations = <String>[];
        final creations = <Map<String, dynamic>>[];
        final reorders = <Map<String, dynamic>>[];
        http.Response response(Object? body) => http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
        final client = DeckClient(
          base: ServerBase.parse(model.account.server),
          loginName: model.account.loginName,
          appPassword: 'test-password',
          transport: MockClient((request) async {
            final path = request.url.path;
            if (path.endsWith('/boards/1')) return response(model.board.raw);
            if (path.endsWith('/stacks/archived')) return response([]);
            if (path.endsWith('/stacks') && request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              creations.add(body);
              final created = <String, Object?>{
                'id': 42,
                'boardId': 1,
                'cards': [],
                ...body,
              };
              server.add(created);
              mutations.add('create');
              return response(created);
            }
            if (path.endsWith('/stacks')) return response(server);
            if (path.endsWith('/stacks/42/reorder') &&
                request.method == 'PUT') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              reorders.add(body);
              final created = server.singleWhere((stack) => stack['id'] == 42);
              server.remove(created);
              server.insert(body['order'] as int, created);
              for (var i = 0; i < server.length; i++) {
                server[i]['order'] = i;
              }
              mutations.add('reorder');
              return response({
                'ocs': {
                  'meta': {'status': 'ok', 'statuscode': 200},
                  'data': {
                    for (var i = 0; i < server.length; i++) '$i': server[i],
                  },
                },
              });
            }
            fail('Unexpected ${request.method} $path');
          }),
        );
        final sync = DeckSync(model.db, model.account, client);
        try {
          await boardModel(tester, sync.run());
          expect(mutations, ['create', 'reorder']);
          expect(creations.single['order'], 2);
          expect(reorders.single, {'boardId': 1, 'order': 1});
          expect(server.map((stack) => stack['title']), [
            'Column 1',
            'Middle column',
            'Column 2',
          ]);
          expect(server.map((stack) => stack['order']), [0, 1, 2]);
          expect(
            await boardModel(tester, model.db.writesFor(model.account.id)),
            isEmpty,
          );
        } finally {
          sync.close();
          client.transport.close();
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await boardModel(tester, model.close());
      }
    },
  );

  for (final detail in [false, true]) {
    testWidgets(
      '${detail ? 'detail' : 'board menu'} move uses the same full-column anchor order',
      (tester) async {
        final model = (await tester.runAsync(
          () => BoardFixture.create(archivedLeading: true),
        ))!;
        try {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(900, 850);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          final card = model.stacks.first.cards.singleWhere(
            (card) => card.id == 100,
          );
          await tester.pumpWidget(
            boardTestApp(
              detail
                  ? CardScreen(
                      session: model.session,
                      board: model.board,
                      card: card,
                    )
                  : BoardScreen(session: model.session, board: model.board),
              preferences: AppPreferences(store: MemoryBoardPreferences()),
            ),
          );
          await settleBoard(tester);
          if (detail) {
            await tester.tap(find.widgetWithText(OutlinedButton, 'Move card'));
          } else {
            await tester.tap(
              find.descendant(
                of: boardTile(100),
                matching: find.byType(PopupMenuButton<String>),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('Move card'));
          }
          await settleBoard(tester);
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('After a card').last);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Move card'));
          await settleBoard(tester);
          final write = (await boardModel(
            tester,
            model.db.writesFor(model.account.id),
          )).single;
          expect(jsonDecode(write.proposal), {
            'stackId': 10,
            'order': 1,
            'anchorCardId': 101,
            'before': false,
          });
          final stacks = await boardModel(
            tester,
            model.db.stackView(model.account.id, 1),
          );
          expect(
            stacks.first.cards
                .where((card) => !card.archived)
                .map((card) => card.id),
            [101, 100, 102],
          );
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await boardModel(tester, model.close());
        }
      },
    );
  }
}
