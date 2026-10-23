import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_editor.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  late final _drafts = widget.session.database.watchEditorDrafts(
    widget.session.account.id,
  );

  Future<void> _discard(EditorDraft draft) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.discardDraft),
        content: Text(text.discardDraftQuestion),
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
    if (confirmed != true || !mounted) return;
    try {
      await widget.session.database.deleteEditorDraft(
        draft.accountId,
        draft.draftKey,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.storageError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(text.drafts)),
      body: StreamBuilder<List<EditorDraft>>(
        stream: _drafts,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(text.storageError));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final drafts = snapshot.requireData;
          if (drafts.isEmpty) return Center(child: Text(text.noDrafts));
          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final fields = object(jsonDecode(draft.payload));
              return ListTile(
                title: Text(
                  stringField(fields, 'title').isEmpty
                      ? text.addCard
                      : stringField(fields, 'title'),
                ),
                subtitle: Text(
                  stringField(fields, 'description'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => editCard(
                  context,
                  widget.session,
                  draft.boardId,
                  draft.stackId,
                  draftKey: draft.draftKey,
                ),
                trailing: IconButton(
                  tooltip: text.discardDraft,
                  onPressed: () => _discard(draft),
                  icon: const Icon(Icons.delete_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
