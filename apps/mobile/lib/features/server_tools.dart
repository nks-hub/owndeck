import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';

Uri deckWebUri(DeckSession session, {DeckBoard? board}) =>
    session.client.base.endpoint([
      'index.php',
      'apps',
      'deck',
      if (board != null) ...['board', '${board.id}'],
    ]);

Future<bool> openDeckWeb(
  DeckSession session, {
  DeckBoard? board,
  Future<bool> Function(Uri)? openBrowser,
}) async {
  session.refreshBoardsOnNextResume();
  final uri = deckWebUri(session, board: board);
  return openBrowser?.call(uri) ??
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<void> showServerImport(BuildContext context, DeckSession session) async {
  final text = AppLocalizations.of(context)!;
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text.importInNextcloud),
      content: SingleChildScrollView(child: Text(text.importInNextcloudHint)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(text.openInNextcloud),
        ),
      ],
    ),
  );
  if (open != true || !context.mounted) return;
  var opened = false;
  try {
    opened = await openDeckWeb(session);
  } catch (_) {
    // Launch errors may contain the user's server URL.
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text.browserError)));
  }
}
