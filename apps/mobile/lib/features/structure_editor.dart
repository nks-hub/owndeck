import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'sharing.dart';
import 'sync_notice.dart';

part 'board_labels.dart';

class BoardActions extends StatelessWidget {
  const BoardActions({super.key, required this.session, required this.board});
  final DeckSession session;
  final DeckBoard board;

  @override
  Widget build(BuildContext context) {
    if (!board.permissions.manage &&
        (!board.permissions.share || board.deletedAt != 0)) {
      return const SizedBox.shrink();
    }
    final text = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: text.boardActions,
      onSelected: (action) {
        switch (action) {
          case 'sharing':
            unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/board/sharing'),
                  builder: (_) =>
                      SharingScreen(session: session, boardId: board.id),
                ),
              ),
            );
          case 'labels':
            unawaited(
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  settings: const RouteSettings(name: '/board/labels'),
                  builder: (_) =>
                      BoardLabelsScreen(session: session, boardId: board.id),
                ),
              ),
            );
          case 'edit':
            unawaited(editStructure(context, session, board: board));
          case 'archive':
            unawaited(
              changeStructure(
                context,
                session,
                'updateBoard',
                board,
                proposal: {'archived': !board.archived},
              ),
            );
          case 'delete':
            unawaited(changeStructure(context, session, 'deleteBoard', board));
          case 'restore':
            unawaited(changeStructure(context, session, 'restoreBoard', board));
        }
      },
      itemBuilder: (_) => [
        if (board.deletedAt != 0 && board.permissions.manage)
          PopupMenuItem(value: 'restore', child: Text(text.restoreBoard)),
        if (board.deletedAt == 0) ...[
          PopupMenuItem(value: 'sharing', child: Text(text.sharing)),
          if (board.permissions.manage) ...[
            PopupMenuItem(value: 'labels', child: Text(text.manageLabels)),
            PopupMenuItem(value: 'edit', child: Text(text.editBoard)),
            PopupMenuItem(
              value: 'archive',
              child: Text(board.archived ? text.unarchive : text.archive),
            ),
            if (!board.archived)
              PopupMenuItem(value: 'delete', child: Text(text.deleteBoard)),
          ],
        ],
      ],
    );
  }
}

class StackActions extends StatelessWidget {
  const StackActions({
    super.key,
    required this.session,
    required this.board,
    required this.stack,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckStack stack;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.edit_outlined),
          label: Text(text.editStack),
          onPressed: () => editStructure(
            context,
            session,
            board: board,
            stack: stack,
            column: true,
          ),
        ),
        TextButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: Text(text.deleteStack),
          onPressed: () => changeStructure(
            context,
            session,
            'deleteStack',
            board,
            stack: stack,
          ),
        ),
      ],
    );
  }
}

Future<void> editStructure(
  BuildContext context,
  DeckSession session, {
  DeckBoard? board,
  DeckStack? stack,
  bool column = false,
  bool labelItem = false,
  JsonObject? label,
}) async {
  final text = AppLocalizations.of(context)!;
  var initialName = column ? stack?.title ?? '' : board?.title ?? '';
  var initialValue = column
      ? '${stack?.order ?? 999}'
      : board?.color ?? '008080';
  if (labelItem) {
    initialName = label == null ? '' : stringField(label, 'title');
    initialValue = label == null ? '008080' : stringField(label, 'color');
  }
  final name = TextEditingController(text: initialName);
  final value = TextEditingController(text: initialValue);
  var saving = false;
  String? error;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            labelItem
                ? label == null
                      ? text.addLabel
                      : text.editLabel
                : column
                ? stack == null
                      ? text.addStack
                      : text.editStack
                : board == null
                ? text.addBoard
                : text.editBoard,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  enabled: !saving,
                  autofocus: true,
                  decoration: InputDecoration(labelText: text.name),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: value,
                  enabled: !saving,
                  keyboardType: column
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: column ? text.position : text.color,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(error!),
                  ),
                if (saving) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final title = name.text.trim();
                      final rawValue = value.text.trim().replaceFirst('#', '');
                      if (title.isEmpty || title.runes.length > 100) {
                        setState(() => error = text.invalidName);
                        return;
                      }
                      if (column
                          ? int.tryParse(rawValue) == null ||
                                int.parse(rawValue) < 0
                          : !RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(rawValue)) {
                        setState(
                          () => error = column
                              ? text.invalidPosition
                              : text.invalidColor,
                        );
                        return;
                      }
                      setState(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        if (labelItem) {
                          final changes = <String, Object?>{
                            if (label == null || label['title'] != title)
                              'title': title,
                            if (label == null ||
                                label['color'] != rawValue.toLowerCase())
                              'color': rawValue.toLowerCase(),
                          };
                          if (changes.isNotEmpty) {
                            await session.database.queueBoardMetadata(
                              session.account,
                              board!.id,
                              label == null ? 'createLabel' : 'updateLabel',
                              changes,
                              original: label,
                            );
                          }
                        } else {
                          await session.database.queueStructure(
                            session.account,
                            column
                                ? stack == null
                                      ? 'createStack'
                                      : 'updateStack'
                                : board == null
                                ? 'createBoard'
                                : 'updateBoard',
                            {
                              'title': title,
                              if (column)
                                'order': int.parse(rawValue)
                              else
                                'color': rawValue.toLowerCase(),
                            },
                            boardId: board?.id ?? 0,
                            stackId: stack?.id ?? 0,
                            base: column ? stack?.raw : board?.raw,
                          );
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        unawaited(
                          column || labelItem
                              ? session.refreshStacks(board!.id)
                              : session.refreshBoards(),
                        );
                      } catch (failure) {
                        if (dialogContext.mounted) {
                          setState(() {
                            saving = false;
                            error =
                                failure is StateError &&
                                    failure.message == 'pending_decision'
                                ? text.pendingDecision
                                : text.loadError;
                          });
                        }
                      }
                    },
              child: Text(text.save),
            ),
          ],
        ),
      ),
    );
  } finally {
    name.dispose();
    value.dispose();
  }
}

Future<void> changeStructure(
  BuildContext context,
  DeckSession session,
  String kind,
  DeckBoard board, {
  DeckStack? stack,
  JsonObject proposal = const {},
}) async {
  final text = AppLocalizations.of(context)!;
  if (kind.startsWith('delete')) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(stack == null ? text.deleteBoard : text.deleteStack),
        content: Text(text.deleteStructureQuestion),
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
    if (confirmed != true || !context.mounted) return;
  }
  try {
    await session.database.queueStructure(
      session.account,
      kind,
      proposal,
      boardId: board.id,
      stackId: stack?.id ?? 0,
      base: stack?.raw ?? board.raw,
    );
    unawaited(
      stack == null ? session.refreshBoards() : session.refreshStacks(board.id),
    );
  } catch (failure) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failure is StateError && failure.message == 'pending_decision'
                ? text.pendingDecision
                : text.loadError,
          ),
        ),
      );
    }
  }
}
