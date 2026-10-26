import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_editor.dart';
import 'comment_editor.dart';

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
  late final _boards = widget.session.watchBoards();
  final _locations =
      <Object, Future<({int boardId, String? stack, String? card})>>{};
  final _stacks = <Object, Future<List<DeckStack>>>{};

  Future<({int boardId, String? stack, String? card})> _location(
    EditorDraft draft,
    List<DeckBoard> boards,
  ) {
    final stamp = [
      for (final board in boards) '${board.id}:${board.raw['lastModified']}',
    ].join(',');
    return _locations.putIfAbsent(
      (draft.boardId, draft.stackId, draft.cardId, stamp),
      () async {
        final database = widget.session.database;
        final boardId =
            await database.resolveId(
              draft.accountId,
              draft.boardId,
              'createBoard',
            ) ??
            draft.boardId;
        if (!boards.any(
          (board) => board.id == boardId && board.permissions.read,
        )) {
          return (boardId: boardId, stack: null, card: null);
        }
        final columns = await _stacks.putIfAbsent((
          boardId,
          stamp,
        ), () => database.stackView(draft.accountId, boardId));
        final stackId =
            await database.resolveId(
              draft.accountId,
              draft.stackId,
              'createStack',
            ) ??
            draft.stackId;
        final stack = columns
            .where((column) => column.id == stackId)
            .firstOrNull;
        final cardId = draft.cardId == null
            ? null
            : await database.resolveId(
                    draft.accountId,
                    draft.cardId!,
                    'createCard',
                  ) ??
                  draft.cardId;
        final card = stack?.cards
            .where((card) => card.id == cardId)
            .firstOrNull;
        return (boardId: boardId, stack: stack?.title, card: card?.title);
      },
    );
  }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.localSaveError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(text.drafts)),
      body: StreamBuilder<List<DeckBoard>>(
        stream: _boards,
        builder: (context, boardSnapshot) => StreamBuilder<List<EditorDraft>>(
          stream: _drafts,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(text.localReadError));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final drafts = snapshot.requireData;
            if (drafts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drafts_outlined, size: 40),
                      const SizedBox(height: 12),
                      Text(text.noDrafts),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        child: Text(text.close),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: drafts.length,
              itemBuilder: (context, index) {
                final draft = drafts[index];
                final fields = object(jsonDecode(draft.payload));
                final date = draft.updatedAt.toLocal();
                final locale = MaterialLocalizations.of(context);
                final modified =
                    '${locale.formatMediumDate(date)} ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
                final kind = draft.kind == 'comment'
                    ? text.commentDraft
                    : draft.cardId == null
                    ? text.addCard
                    : text.editCard;
                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ListTile(
                    isThreeLine: true,
                    leading: Icon(
                      draft.kind == 'comment'
                          ? Icons.comment_outlined
                          : Icons.edit_note,
                    ),
                    title: Text(
                      draft.kind == 'comment'
                          ? text.commentDraft
                          : stringField(fields, 'title').isEmpty
                          ? text.addCard
                          : stringField(fields, 'title'),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$kind · $modified',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (boardSnapshot.hasError)
                          Text(text.localReadError)
                        else if (boardSnapshot.hasData)
                          FutureBuilder<
                            ({int boardId, String? stack, String? card})
                          >(
                            future: _location(draft, boardSnapshot.requireData),
                            builder: (context, location) {
                              final value = location.data;
                              final board = boardSnapshot.data
                                  ?.where(
                                    (board) =>
                                        board.id == value?.boardId &&
                                        board.permissions.read,
                                  )
                                  .firstOrNull;
                              final parts = <String>[
                                if (board != null) board.title,
                                if (board != null && value?.stack != null)
                                  value!.stack!,
                                if (board != null &&
                                    draft.kind == 'comment' &&
                                    value?.card != null)
                                  value!.card!,
                              ];
                              return Text(
                                location.connectionState != ConnectionState.done
                                    ? text.syncing
                                    : location.hasError
                                    ? text.localReadError
                                    : parts.isEmpty
                                    ? text.draftLocationUnavailable
                                    : parts.join(' › '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        const SizedBox(height: 4),
                        Text(
                          stringField(fields, 'description'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    onTap: draft.kind == 'comment'
                        ? () => openCommentEditor(
                            context,
                            widget.session,
                            draft.boardId,
                            draft.stackId,
                            draft.cardId!,
                            draftKey: draft.draftKey,
                          )
                        : () => editCard(
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
