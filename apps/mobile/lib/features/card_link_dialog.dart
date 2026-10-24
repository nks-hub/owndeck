import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/card_link_inbox.dart';
import '../l10n/app_localizations.dart';

Future<void> enterCardLink(BuildContext context) async {
  final link = await showDialog<DeckCardLink>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const CardLinkDialog(),
  );
  if (link != null && context.mounted) {
    incomingCardLinks.offer(link.webUri.toString());
  }
}

class CardLinkDialog extends StatefulWidget {
  const CardLinkDialog({super.key});
  @override
  State<CardLinkDialog> createState() => _CardLinkDialogState();
}

class _CardLinkDialogState extends State<CardLinkDialog> {
  final _text = TextEditingController();
  bool _invalid = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _open() {
    final link = parseDeckCardLink(_text.text);
    if (link == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, link);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(text.openCardLink),
      content: TextField(
        key: const Key('card-link-input'),
        controller: _text,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => _open(),
        autocorrect: false,
        decoration: InputDecoration(
          labelText: text.cardLinkAddress,
          errorText: _invalid ? text.invalidCardLink : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.cancel),
        ),
        FilledButton(onPressed: _open, child: Text(text.openCardLink)),
      ],
    );
  }
}
