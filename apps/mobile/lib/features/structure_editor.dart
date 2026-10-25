import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../core/errors.dart';
import '../l10n/app_localizations.dart';
import 'sharing.dart';
import 'sync_notice.dart';
import 'board_clone_dialog.dart';
import 'color_choices.dart';

part 'board_labels.dart';
part 'structure_form.dart';

class BoardActions extends StatelessWidget {
  const BoardActions({
    super.key,
    required this.session,
    required this.board,
    this.extraItems = const [],
    this.onExtraAction,
  });
  final DeckSession session;
  final DeckBoard board;
  final List<PopupMenuEntry<String>> extraItems;
  final ValueChanged<String>? onExtraAction;

  @override
  Widget build(BuildContext context) {
    final canCopy =
        board.id > 0 &&
        board.permissions.read &&
        board.deletedAt == 0 &&
        session.capabilities?.canCreateBoards == true;
    if (!board.permissions.manage &&
        (!board.permissions.share || board.deletedAt != 0) &&
        !canCopy &&
        extraItems.isEmpty) {
      return const SizedBox.shrink();
    }
    final text = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      tooltip: text.boardActions,
      onSelected: (action) {
        switch (action) {
          case 'copy':
            unawaited(showBoardClone(context, session, board));
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
          default:
            onExtraAction?.call(action);
        }
      },
      itemBuilder: (_) => [
        ...extraItems,
        if (board.deletedAt != 0 && board.permissions.manage)
          PopupMenuItem(value: 'restore', child: Text(text.restoreBoard)),
        if (board.deletedAt == 0) ...[
          if (canCopy)
            PopupMenuItem(value: 'copy', child: Text(text.copyBoard)),
          if (board.permissions.share || board.permissions.manage)
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
    if (!board.permissions.manage || board.archived || board.deletedAt != 0) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      tooltip: text.stackActions,
      onSelected: (action) {
        switch (action) {
          case 'done':
            unawaited(_changeDoneStack(context, session, board, stack));
          case 'edit':
            unawaited(
              editStructure(
                context,
                session,
                board: board,
                stack: stack,
                column: true,
              ),
            );
          case 'delete':
            unawaited(
              changeStructure(
                context,
                session,
                'deleteStack',
                board,
                stack: stack,
              ),
            );
        }
      },
      itemBuilder: (_) => [
        if (stack.supportsDoneColumn)
          PopupMenuItem(
            value: 'done',
            child: Text(
              stack.isDoneColumn ? text.unsetDoneColumn : text.setDoneColumn,
            ),
          ),
        PopupMenuItem(value: 'edit', child: Text(text.editStack)),
        PopupMenuItem(value: 'delete', child: Text(text.deleteStack)),
      ],
    );
  }
}

Future<void> _changeDoneStack(
  BuildContext context,
  DeckSession session,
  DeckBoard board,
  DeckStack stack,
) async {
  final text = AppLocalizations.of(context)!;
  final isDone = !stack.isDoneColumn;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isDone ? text.setDoneColumn : text.unsetDoneColumn),
      content: SingleChildScrollView(
        child: Text(
          isDone ? text.setDoneColumnQuestion : text.unsetDoneColumnQuestion,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(text.save),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await changeStructure(
    context,
    session,
    'setDoneStack',
    board,
    stack: stack,
    proposal: {'title': stack.title, 'isDone': isDone},
  );
}

Future<void> editStructure(
  BuildContext context,
  DeckSession session, {
  DeckBoard? board,
  DeckStack? stack,
  bool column = false,
  bool labelItem = false,
  JsonObject? label,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _StructureForm(
    session: session,
    board: board,
    stack: stack,
    column: column,
    labelItem: labelItem,
    label: label,
  ),
);

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
