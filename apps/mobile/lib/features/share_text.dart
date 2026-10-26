import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import 'card_summary.dart';

/// Opens the system share sheet with plain text; replaced in tests.
typedef TextSharer = Future<void> Function(String text, {String? subject});

TextSharer textSharer = (text, {subject}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
};

/// Plain-text summary of a card: title, due date, labels, description, link.
String cardShareText({
  required DeckCard card,
  required Uri link,
  required AppLocalizations text,
  required MaterialLocalizations locale,
}) {
  final due = cardDueDate(card);
  final labels = [
    for (final label in cardObjects(card.raw['labels']))
      if (label['title'] is String && (label['title'] as String).isNotEmpty)
        label['title'] as String,
  ];
  final description = card.description.trim();
  return [
    card.title,
    if (due != null)
      text.shareDue(
        '${locale.formatMediumDate(due)} ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(due))}',
      ),
    if (labels.isNotEmpty) text.shareLabels(labels.join(', ')),
    if (description.isNotEmpty) '\n$description\n',
    link.toString(),
  ].join('\n');
}

/// Web address of a board in the Deck web app.
Uri boardWebUri(ServerBase server, int boardId) =>
    server.endpoint(['index.php', 'apps', 'deck', 'board', '$boardId']);
