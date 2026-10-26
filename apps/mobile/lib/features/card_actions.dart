import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_selection_sheet.dart';

/// Objects of a raw API collection that is either a list or an id-keyed map.
List<JsonObject> jsonObjects(Object? value) => switch (value) {
  List list => list.whereType<JsonObject>().toList(),
  JsonObject map => map.values.whereType<JsonObject>().toList(),
  _ => const [],
};

/// Queues one card action and refreshes the board; failures go to a snack bar.
Future<void> runCardAction(
  BuildContext context,
  DeckSession session,
  int boardId,
  DeckCard card,
  String kind,
  JsonObject values,
) async {
  final text = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await session.database.queueCardAction(
      session.account,
      boardId,
      card,
      kind,
      values,
    );
    unawaited(session.refreshStacks(boardId));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(errorMessage(error, text))));
  }
}

Future<void> deleteCardWithConfirmation(
  BuildContext context,
  DeckSession session,
  int boardId,
  DeckCard card,
) async {
  final text = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text.deleteCard),
      content: Text(text.deleteCardQuestion),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(text.remove),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await runCardAction(context, session, boardId, card, 'deleteCard', {});
  }
}

Future<void> chooseCardLabels(
  BuildContext context,
  DeckSession session,
  DeckBoard board,
  DeckCard card,
) async {
  final text = AppLocalizations.of(context)!;
  final boardLabels = jsonObjects(
    board.raw['labels'],
  ).where((label) => label['id'] is int).toList();
  final cardLabels = jsonObjects(
    card.raw['labels'],
  ).where((label) => label['id'] is int).toList();
  final byId = {for (final label in boardLabels) label['id']: label};
  for (final label in cardLabels) {
    byId.putIfAbsent(label['id'], () => label);
  }
  final labels = byId.values.toList();
  final assigned = cardLabels.map((label) => '${label['id']}').toSet();
  await showCardSelection(
    context,
    title: text.labels,
    emptyMessage: text.noLabels,
    options: {
      for (final label in labels)
        '${label['id']}': switch (label['title']) {
          String title when title.trim().isNotEmpty => title,
          _ => text.unnamedLabel,
        },
    },
    selected: assigned,
    onSave: (selected) async {
      await session.database.transaction(() async {
        for (final label in labels) {
          final id = '${label['id']}';
          if (assigned.contains(id) == selected.contains(id)) continue;
          await session.database.queueCardAction(
            session.account,
            board.id,
            card,
            selected.contains(id) ? 'assignLabel' : 'removeLabel',
            {'labelId': label['id'], 'label': label},
          );
        }
      });
      unawaited(session.refreshStacks(board.id));
    },
  );
}
