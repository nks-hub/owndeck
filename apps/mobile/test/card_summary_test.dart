import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/features/board_filters.dart';
import 'package:nextclouddeck/features/card_summary.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DeckCard task({Object? due, Object? done, List<Object?>? assigned}) =>
      DeckCard.fromJson({
        'id': 1,
        'stackId': 10,
        'order': 0,
        'title': 'Prepare release',
        'description': 'Check the mobile package',
        'duedate': due,
        'done': done,
        'labels': [
          {'id': 7, 'title': 'Review', 'color': '008080'},
        ],
        'assignedUsers':
            assigned ??
            [
              {
                'type': 0,
                'participant': {'uid': 'editor', 'displayname': 'Editor'},
              },
            ],
      });

  test('board filters intersect query, member, label and calendar date', () {
    final now = DateTime(2030, 1, 15, 12);
    final card = task(due: DateTime(2030, 1, 15, 14).toIso8601String());
    const selected = BoardCardFilter(
      query: 'release mobile',
      memberId: 'editor',
      labelId: 7,
      due: BoardDueFilter.today,
      completion: BoardCompletionFilter.open,
    );
    expect(selected.matches(card, now: now), isTrue);
    expect(selected.withQuery('different').matches(card, now: now), isFalse);
    expect(const BoardCardFilter(memberId: '').matches(card), isFalse);
    expect(
      const BoardCardFilter(memberId: '').matches(task(assigned: [])),
      isTrue,
    );
    expect(
      const BoardCardFilter(due: BoardDueFilter.overdue).matches(
        task(
          due: DateTime(2030, 1, 14).toIso8601String(),
          done: '2030-01-14T12:00:00Z',
        ),
        now: now,
      ),
      isFalse,
    );
    expect(
      const BoardCardFilter(
        due: BoardDueFilter.upcoming,
      ).matches(task(due: DateTime(2030, 1, 16).toIso8601String()), now: now),
      isTrue,
    );
    expect(
      const BoardCardFilter(due: BoardDueFilter.noDate).matches(task()),
      isTrue,
    );
  });

  testWidgets(
    'card summary exposes working metadata without inventing counts',
    (tester) async {
      final card = DeckCard.fromJson({
        ...task(due: '2030-01-15T12:00:00Z', done: '2030-01-15T11:00:00Z').raw,
        'commentsCount': 3,
        'attachmentCount': 2,
        'syncState': 'queued',
      });
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(
              body: Card(child: CardSummary(card: card)),
            ),
          ),
        );
        expect(find.text('Review'), findsOneWidget);
        expect(find.text('Prepare release'), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp('Assignees: Editor')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(RegExp('Comments: 3')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Attachments: 2')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Completed:')), findsOneWidget);
        expect(find.text('Queued'), findsOneWidget);
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(
              body: Card(child: CardSummary(card: task())),
            ),
          ),
        );
        expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
        expect(find.byIcon(Icons.attach_file), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'checklist summary ignores fenced examples and follows edited text',
    (tester) async {
      DeckCard withDescription(String description) => DeckCard.fromJson({
        ...task().raw,
        'description': description,
        'labels': [
          {'id': 8, 'title': '', 'color': '008080'},
        ],
      });
      final initial = withDescription(
        '- [x] Ready\n- [ ] Pending\n```\n- [x] Example\n```',
      );
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(body: CardSummary(card: initial)),
        ),
      );
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('Unnamed label'), findsOneWidget);
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: CardSummary(
              card: withDescription('- [x] Ready\n- [x] Pending'),
            ),
          ),
        ),
      );
      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('1/2'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('detail metadata keeps every label and the start date', (
    tester,
  ) async {
    final card = DeckCard.fromJson({
      ...task().raw,
      'startdate': '2030-01-14T09:00:00Z',
      'labels': [
        for (var i = 1; i <= 5; i++)
          {'id': i, 'title': 'Label $i', 'color': '008080'},
      ],
    });
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: Column(
              children: [
                CardLabels(card: card),
                CardMetadata(card: card, showStartDate: true),
              ],
            ),
          ),
        ),
      );
      for (var i = 1; i <= 5; i++) {
        expect(find.text('Label $i'), findsOneWidget);
      }
      expect(find.bySemanticsLabel(RegExp('Start date:')), findsOneWidget);
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(body: CardMetadata(card: card)),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Start date:')), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
