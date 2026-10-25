import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nextclouddeck/core/markdown_preview.dart';
import 'package:nextclouddeck/features/card_summary.dart';

import 'test_support.dart';

void main() {
  test(
    'preview removes formatting and separates headings, paragraphs and list items',
    () {
      const source =
          '# Plan\n\nRead **bold** and _italic_ [notes](https://example.com).\n\n- [ ] First item\n- [x] Second item\n\n> Final paragraph';
      expect(
        markdownPreview(source),
        'Plan Read bold and italic notes. First item Second item Final paragraph',
      );
      expect(markdownPreview('left**middle**right'), 'leftmiddleright');
    },
  );

  test('preview keeps code content without treating it as checklist state', () {
    const source =
        '```text\n- [ ] code example\n**literal**\n```\n\n- [x] Real task\n\nUse `a < b`.';
    expect(
      markdownPreview(source),
      '- [ ] code example **literal** Real task Use a < b.',
    );
  });

  test('preview keeps table cells, image descriptions and decoded entities', () {
    const source =
        '| Name | Status |\n| --- | --- |\n| Alice | Ready |\n\n![Useful diagram](https://example.com/image.png) ![](https://example.com/empty.png)\n\nTea &amp; coffee';
    expect(
      markdownPreview(source),
      'Name Status Alice Ready Useful diagram Tea & coffee',
    );
    expect(markdownPreview('   \n\n'), isEmpty);
    expect(markdownPreview('![](https://example.com/image.png)'), isEmpty);
  });

  test(
    'preview bounds input and output without splitting Unicode clusters',
    () {
      const family = '👩‍👩‍👧‍👦';
      final source = List.filled(200, family).join();
      expect(
        markdownPreviewInput(source).runes.length,
        markdownPreviewSourceLimit + 1,
      );
      final preview = markdownPreview(source);
      expect(preview.characters.length, markdownPreviewLength);
      expect(
        preview,
        '${List.filled(markdownPreviewLength - 1, family).join()}…',
      );
      expect(
        markdownPreview('Žluťoučký **🧑🏽‍💻** kůň'),
        'Žluťoučký 🧑🏽‍💻 kůň',
      );
      expect(source.characters.length, 200);
    },
  );

  testWidgets(
    'card preview shows plain text and image alt without loading remote resources',
    (tester) async {
      var connections = 0;
      const source =
          '- [ ] **Readable task**\n\n![Diagram](https://example.com/secret-image.png)';
      final card = DeckCard.fromJson({
        'id': 1,
        'stackId': 2,
        'order': 0,
        'title': 'A card',
        'description': source,
      });
      await HttpOverrides.runZoned(
        () async {
          await tester.pumpWidget(
            localizedTestApp(
              home: Scaffold(body: CardSummary(card: card)),
            ),
          );
          expect(find.text('Readable task Diagram'), findsOneWidget);
          expect(find.text(source), findsNothing);
          expect(find.byType(Image), findsNothing);
          expect(tester.takeException(), isNull);
        },
        createHttpClient: (_) {
          connections++;
          throw StateError('preview_must_not_request_network');
        },
      );
      expect(connections, 0);
      expect(card.description, source);
    },
  );

  testWidgets(
    'preview parsing is cached across theme changes and unseen tail updates',
    (tester) async {
      var parses = 0;
      final lengths = <int>[];
      String buildPreview(String source) {
        parses++;
        lengths.add(source.runes.length);
        return markdownPreview(source);
      }

      final prefix =
          '**Visible** ${List.filled(markdownPreviewSourceLimit, 'word ').join()}';
      final original = '$prefix${List.filled(1024 * 1024, 'a').join()}';
      Widget app(String source, Brightness brightness) => MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: CardDescriptionPreview(
            description: source,
            buildPreview: buildPreview,
          ),
        ),
      );
      await tester.pumpWidget(app(original, Brightness.light));
      expect(parses, 1);
      expect(lengths.single, markdownPreviewSourceLimit + 1);
      final state = tester.state(find.byType(CardDescriptionPreview));
      await tester.pumpWidget(app(original, Brightness.dark));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(CardDescriptionPreview)), same(state));
      expect(parses, 1);
      await tester.pumpWidget(
        app('$prefix${List.filled(1024 * 1024, 'b').join()}', Brightness.dark),
      );
      expect(parses, 1);
      await tester.pumpWidget(
        app('**Changed**\n\n- [ ] Next', Brightness.dark),
      );
      expect(parses, 2);
      expect(find.text('Changed Next'), findsOneWidget);
      expect(
        lengths.every((length) => length <= markdownPreviewSourceLimit + 1),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
