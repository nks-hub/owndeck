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

  testWidgets(
    'detail metadata shows every existing assignee without expanding person filters',
    (tester) async {
      final card = task(
        assigned: [
          {
            'type': 0,
            'participant': {'uid': 'alice', 'displayname': 'Alice'},
          },
          {
            'type': 0,
            'participant': {'uid': 'bob', 'displayname': 'Bob'},
          },
          {
            'type': 1,
            'participant': {'uid': 'group-id', 'displayname': 'Engineering'},
          },
          {
            'type': 7,
            'participant': {
              'uid': 'opaque-team',
              'displayname': {'invalid': 'payload'},
            },
          },
        ],
      );
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: CardMetadata(card: card, showAllAssignees: true),
          ),
        ),
      );
      for (final name in ['Alice', 'Bob', 'Engineering', 'Team']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.textContaining('opaque-team'), findsNothing);
      expect(find.textContaining('invalid'), findsNothing);
      expect(find.text('Alice +3'), findsNothing);
      expect(cardPeople(card).map((person) => person.id), ['alice', 'bob']);
    },
  );

  test(
    'typed person identity keeps filtering IDs separate from display names',
    () {
      expect(cardPerson({'uid': 'alice', 'displayname': ' Alice '}), (
        id: 'alice',
        name: 'Alice',
      ));
      expect(
        cardPerson({'primaryKey': 'other', 'displayName': 'Other person'}),
        (id: 'other', name: 'Other person'),
      );
      expect(cardPerson('opaque-user'), (id: 'opaque-user', name: ''));
      expect(
        cardPerson({
          'uid': 'opaque-user',
          'displayname': {'internal': 'private-name'},
        }),
        (id: 'opaque-user', name: ''),
      );
      expect(
        cardPerson({
          'uid': {'id': 'not-an-id'},
          'displayname': 'Invalid',
        }),
        isNull,
      );
      expect(cardPerson({'uid': 42, 'displayname': 'Invalid'}), isNull);
      expect(cardPerson({'uid': '   ', 'displayname': 'Invalid'}), isNull);
      final mixed = task(
        assigned: [
          {'type': 0, 'participant': 'opaque-user'},
          {
            'type': 1,
            'participant': {'uid': 'group-id', 'displayname': 'A group'},
          },
        ],
      );
      expect(cardPeople(mixed), [(id: 'opaque-user', name: '')]);
      expect(
        const BoardCardFilter(memberId: 'opaque-user').matches(mixed),
        isTrue,
      );
      expect(
        const BoardCardFilter(memberId: 'group-id').matches(mixed),
        isFalse,
      );
    },
  );

  testWidgets('typed label captions never render an object as text', (
    tester,
  ) async {
    final card = DeckCard.fromJson({
      ...task().raw,
      'labels': [
        {
          'id': 1,
          'title': {'internal': 'opaque-label'},
          'color': '008080',
        },
        {'id': 2, 'title': 17, 'color': '008080'},
        {'id': 3, 'title': '  Valid label  ', 'color': '008080'},
      ],
    });
    await tester.pumpWidget(
      localizedTestApp(
        home: Scaffold(body: CardLabels(card: card)),
      ),
    );
    expect(find.text('Unnamed label'), findsNWidgets(2));
    expect(find.text('Valid label'), findsOneWidget);
    expect(find.textContaining('opaque-label'), findsNothing);
    expect(find.text('17'), findsNothing);
  });

  testWidgets(
    'typed metadata includes existing groups teams and external assignees',
    (tester) async {
      final card = task(
        assigned: [
          {
            'type': 1,
            'participant': {
              'primaryKey': 'group-id',
              'displayname': 'Engineering',
            },
          },
          {
            'type': 7,
            'participant': {'uid': 'team-id', 'displayName': 'Operations'},
          },
          {
            'type': 6,
            'participant': {'uid': 'external-id', 'name': 'Partner'},
          },
        ],
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(body: CardMetadata(card: card)),
          ),
        );
        expect(
          find.bySemanticsLabel(
            RegExp('Assignees: Engineering, Operations, Partner'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('group-id'), findsNothing);
        expect(find.textContaining('team-id'), findsNothing);
        expect(find.textContaining('external-id'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'typed metadata uses localized names when only opaque or malformed values exist',
    (tester) async {
      final card = task(
        assigned: [
          {
            'type': 0,
            'participant': {
              'uid': 'opaque-user',
              'displayname': {'private': 'name'},
            },
          },
          {
            'type': 1,
            'participant': {
              'uid': 'opaque-group',
              'displayName': ['private-group'],
            },
          },
          {'type': 6, 'participant': 'opaque-remote'},
          {
            'type': 7,
            'participant': {'uid': 'opaque-team', 'name': 'Team name'},
          },
        ],
      );
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(body: CardMetadata(card: card)),
          ),
        );
        expect(find.text('+1'), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp('Assignees: User, Group, External recipient, Team name'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('opaque-'), findsNothing);
        expect(find.textContaining('private'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'typed member filter uses human fallback without adding group filters',
    (tester) async {
      final board = DeckBoard.fromJson({
        'id': 1,
        'title': 'Board',
        'color': '008080',
        'archived': false,
        'deletedAt': 0,
        'permissions': {'PERMISSION_READ': true},
        'users': [
          {
            'uid': 'opaque-user',
            'displayname': {'private': 'value'},
          },
          {'uid': 'alice', 'displayname': 'Alice'},
          {
            'uid': {'bad': 'identity'},
            'displayname': 'Invalid identity',
          },
        ],
      });
      final stack = DeckStack.fromJson({
        'id': 10,
        'boardId': 1,
        'title': 'Column',
        'order': 0,
        'cards': [
          task(
            assigned: [
              {'type': 0, 'participant': 'alice'},
              {
                'type': 1,
                'participant': {'uid': 'group-id', 'displayname': 'A group'},
              },
            ],
          ).raw,
        ],
      });
      BoardCardFilter? chosen;
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  chosen = await showBoardFilters(
                    context,
                    filter: const BoardCardFilter(),
                    board: board,
                    stacks: [stack],
                  );
                },
                child: const Text('Open filter'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('board-filter-member')));
      await tester.pumpAndSettle();
      expect(find.text('User').hitTestable(), findsOneWidget);
      expect(find.text('Alice').hitTestable(), findsOneWidget);
      expect(find.text('A group'), findsNothing);
      expect(find.textContaining('opaque-user'), findsNothing);
      expect(find.textContaining('private'), findsNothing);
      expect(find.text('Invalid identity'), findsNothing);
      await tester.tap(find.text('User').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply filters'));
      await tester.pumpAndSettle();
      expect(chosen?.memberId, 'opaque-user');
    },
  );

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

  test(
    'unassigned filter excludes existing group assignments without enabling group member filters',
    () {
      final groupOnly = task(
        assigned: [
          {
            'type': 1,
            'participant': {
              'primaryKey': 'engineering',
              'displayname': 'Engineering',
            },
          },
        ],
      );
      expect(const BoardCardFilter(memberId: '').matches(groupOnly), isFalse);
      expect(
        const BoardCardFilter(memberId: '').matches(task(assigned: [])),
        isTrue,
      );
      expect(
        const BoardCardFilter(memberId: '').matches(
          task(
            assigned: [
              {
                'type': 1,
                'participant': {
                  'uid': {'invalid': 'identity'},
                },
              },
            ],
          ),
        ),
        isTrue,
      );
      expect(
        const BoardCardFilter(memberId: 'engineering').matches(groupOnly),
        isFalse,
      );
    },
  );

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
    'problem card changes name their state instead of a generic label',
    (tester) async {
      for (final entry in {
        'conflict': 'Conflict',
        'uncertain': 'Check the result',
        'blocked': 'Needs a decision',
        'sending': 'Sending',
        'queued': 'Queued',
      }.entries) {
        final card = DeckCard.fromJson({...task().raw, 'syncState': entry.key});
        await tester.pumpWidget(
          localizedTestApp(
            home: Scaffold(
              body: Card(child: CardSummary(card: card)),
            ),
          ),
        );
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
        expect(find.text('Pending changes'), findsNothing, reason: entry.key);
      }
    },
  );

  testWidgets('accepted card changes are not labelled as queued', (
    tester,
  ) async {
    final card = DeckCard.fromJson({...task().raw, 'syncState': 'applied'});
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        localizedTestApp(
          home: Scaffold(
            body: Card(child: CardSummary(card: card)),
          ),
        ),
      );
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Queued'), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(
            RegExp.escape(
              'The server accepted this change. Waiting to read the result.',
            ),
          ),
        ),
        findsOneWidget,
      );
    } finally {
      semantics.dispose();
    }
  });

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
