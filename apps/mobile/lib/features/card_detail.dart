import 'dart:async';

import 'package:flutter/services.dart';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/session.dart';
import '../data/card_edits.dart';
import '../data/card_reads.dart';
import '../l10n/app_localizations.dart';
import 'card_actions.dart';
import 'card_activity.dart';
import 'card_editor.dart';
import 'card_pane.dart';
import 'desktop_shortcuts.dart';
import 'board_moves.dart';
import 'board_presence.dart';
import 'card_description.dart';
import 'card_summary.dart';
import 'card_selection_sheet.dart';
import 'color_choices.dart';
import '../core/errors.dart';
import 'pending.dart';
import 'sync_state.dart';
import 'comments.dart';
import 'attachments.dart';
import 'board_view.dart' show BoardScreen;
import 'card_links.dart';
import 'card_projects.dart';
import 'sharing.dart' show shareParticipantId;
import 'share_text.dart';
import 'state_message.dart';

part 'card_actions_ui.dart';

class CardScreen extends StatelessWidget {
  const CardScreen({
    super.key,
    required this.session,
    required this.board,
    required this.card,
    this.onClose,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckCard card;

  /// Set when the card is shown in a side pane: adds a close button.
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => BoardPresence(
    session: session,
    boardId: board.id,
    child: _CardContent(
      key: ValueKey((session, board.id, card.id)),
      session: session,
      board: board,
      card: card,
      onClose: onClose,
    ),
  );
}

class _CardContent extends StatefulWidget {
  const _CardContent({
    super.key,
    required this.session,
    required this.board,
    required this.card,
    required this.onClose,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckCard card;
  final VoidCallback? onClose;

  @override
  State<_CardContent> createState() => _CardScreenState();
}

class _CardScreenState extends State<_CardContent> {
  bool _copying = false;
  bool _savingDone = false;
  late final _stacks = widget.session.watchStacks(widget.board.id);
  bool _loadingCopyColumns = false;
  void _setCopyState({bool? active, bool? loading}) {
    if (!mounted) return;
    setState(() {
      if (active != null) _copying = active;
      if (loading != null) _loadingCopyColumns = loading;
    });
  }

  late final _card = widget.session.database.watchCard(
    widget.session.account.id,
    widget.board.id,
    widget.card.id,
  );
  late final _writes = widget.session.database.watchWrites(
    widget.session.account.id,
  );
  late final _board = widget.session.database.watchBoard(
    widget.session.account.id,
    widget.board.id,
  );

  Future<void> _action(DeckCard card, String kind, JsonObject values) =>
      runCardAction(
        context,
        widget.session,
        widget.board.id,
        card,
        kind,
        values,
      );

  Future<void> _setDone(DeckCard card, bool value) async {
    if (_savingDone) return;
    setState(() => _savingDone = true);
    try {
      await setCardCompleted(widget.session, widget.board.id, card, value);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localWriteErrorMessage(error, AppLocalizations.of(context)!),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingDone = false);
    }
  }

  Future<void> _link(String? href) async {
    if (href == null) return;
    final parsed = Uri.tryParse(href);
    if (parsed == null) return;
    final uri = widget.session.client.base.uri.resolveUri(parsed);
    if (!{'https', 'http', 'mailto'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty) {
      return;
    }
    final text = AppLocalizations.of(context)!;
    final cardLink = parseDeckCardLink(uri.toString());
    if (cardLink != null &&
        cardLink.server.uri == widget.session.client.base.uri) {
      try {
        final result = await widget.session.openRemoteCard(
          cardLink.boardId,
          cardLink.cardId,
        );
        if (!mounted) return;
        await openCard(context, widget.session, result.board, result.card);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage(error, text))));
        }
      }
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.browserError)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.browserError)));
      }
    }
  }

  List<JsonObject> _items(Object? value) => jsonObjects(value);

  String _uid(Object? value) => value is String
      ? value
      : value is JsonObject
      ? (value['uid'] ?? value['primaryKey'] ?? '').toString()
      : '';

  Widget? _closeButton(AppLocalizations text) => widget.onClose == null
      ? null
      : IconButton(
          tooltip: text.close,
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return DesktopShortcuts(
      onEscape: () => closeCard(context),
      child: StreamBuilder<DeckBoard?>(
        stream: _board,
        initialData: widget.board,
        builder: (context, boardSnapshot) => StreamBuilder<DeckCard?>(
          stream: _card,
          initialData: widget.card,
          builder: (context, cardSnapshot) {
            if (boardSnapshot.hasError || cardSnapshot.hasError) {
              return Scaffold(
                appBar: AppBar(leading: _closeButton(text)),
                body: Center(child: StateMessage(message: text.localReadError)),
              );
            }
            final board = boardSnapshot.data;
            final card = cardSnapshot.data;
            if (board == null || !board.permissions.read || card == null) {
              return Scaffold(
                appBar: AppBar(leading: _closeButton(text)),
                body: Center(
                  child: StateMessage(message: text.cardUnavailable),
                ),
              );
            }
            final canEdit =
                board.permissions.edit &&
                !board.archived &&
                board.deletedAt == 0;
            return Scaffold(
              appBar: AppBar(
                leading: _closeButton(text),
                title: Text(board.title),
                actions: [
                  if (board.permissions.read)
                    PopupMenuButton<String>(
                      enabled: !_copying,
                      tooltip: text.cardActions,
                      onSelected: (action) {
                        switch (action) {
                          case 'copy-link':
                            unawaited(_copyLink(board, card));
                          case 'share':
                            unawaited(_share(board, card));
                          case 'copy':
                            unawaited(_copy(card));
                          case 'move':
                            unawaited(_move(board, card));
                          case 'labels':
                            unawaited(_labels(board, card));
                          case 'users':
                            unawaited(_users(board, card));
                          case 'archive':
                            unawaited(
                              _action(
                                card,
                                card.archived ? 'unarchiveCard' : 'archiveCard',
                                {},
                              ),
                            );
                          case 'delete':
                            unawaited(_delete(card));
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'copy',
                          child: Text(text.copyCard),
                        ),
                        if (board.id > 0 && card.id > 0)
                          PopupMenuItem(
                            value: 'share',
                            child: Text(text.shareCard),
                          ),
                        if (board.id > 0 && card.id > 0)
                          PopupMenuItem(
                            value: 'copy-link',
                            child: Text(text.copyCardLink),
                          ),
                        if (canEdit && !card.archived) ...[
                          PopupMenuItem(
                            value: 'move',
                            child: Text(text.moveCard),
                          ),
                          PopupMenuItem(
                            value: 'labels',
                            child: Text(text.labels),
                          ),
                          PopupMenuItem(
                            value: 'users',
                            child: Text(text.assignees),
                          ),
                        ],
                        if (canEdit)
                          PopupMenuItem(
                            value: 'archive',
                            child: Text(
                              card.archived ? text.unarchive : text.archive,
                            ),
                          ),
                        if (canEdit)
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(text.deleteCard),
                          ),
                      ],
                    ),
                ],
              ),
              bottomNavigationBar: _loadingCopyColumns
                  ? LinearProgressIndicator(semanticsLabel: text.syncing)
                  : null,
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  if (card.raw['syncState'] != null)
                    ListTile(
                      title: Text(syncStateLabel(card.raw['syncState'], text)),
                      subtitle: StreamBuilder<List<PendingWrite>>(
                        stream: _writes,
                        builder: (context, writes) {
                          final count =
                              writes.data
                                  ?.where((write) => write.cardId == card.id)
                                  .length ??
                              0;
                          final detail = syncStateDetail(
                            card.raw['syncState'],
                            text,
                          );
                          return Text(
                            count > 1
                                ? '${text.pendingCount(count)}. $detail'
                                : detail,
                          );
                        },
                      ),
                      leading: Icon(syncStateIcon(card.raw['syncState'])),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(name: '/sync'),
                          builder: (_) =>
                              PendingScreen(session: widget.session),
                        ),
                      ),
                    ),
                  StreamBuilder<List<DeckStack>>(
                    stream: _stacks,
                    builder: (context, snapshot) {
                      final stack = snapshot.data
                          ?.where((s) => s.id == card.stackId)
                          .firstOrNull;
                      return Text(
                        stack == null
                            ? board.title
                            : '${board.title} › ${stack.title}',
                        style: Theme.of(context).textTheme.labelLarge,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    card.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (card.archived) Chip(label: Text(text.archivedCards)),
                  CardLabels(card: card),
                  const SizedBox(height: 8),
                  CardMetadata(
                    card: card,
                    showStartDate: true,
                    showAllAssignees: true,
                  ),
                  if (card.rgbColor != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Chip(
                        avatar: Icon(
                          Icons.circle,
                          size: 18,
                          color: Color(0xff000000 | card.rgbColor!),
                        ),
                        label: Text(colorName(card.raw['color'], text)),
                      ),
                    ),
                  if (canEdit && !card.archived)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copying
                                ? null
                                : () => editCard(
                                    context,
                                    widget.session,
                                    board.id,
                                    card.stackId,
                                    card: card,
                                  ),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(text.editCard),
                          ),
                          OutlinedButton.icon(
                            onPressed: _copying
                                ? null
                                : () => _move(board, card),
                            icon: const Icon(Icons.drive_file_move_outline),
                            label: Text(text.moveCard),
                          ),
                          TextButton.icon(
                            onPressed: () => _labels(board, card),
                            icon: const Icon(Icons.label_outline),
                            label: Text(text.labels),
                          ),
                          TextButton.icon(
                            onPressed: () => _users(board, card),
                            icon: const Icon(Icons.person_add_alt),
                            label: Text(text.assignees),
                          ),
                        ],
                      ),
                    ),
                  if (card.raw.containsKey('done'))
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(text.completed),
                      value: card.raw['done'] != null,
                      onChanged: canEdit && !card.archived && !_savingDone
                          ? (value) => _setDone(card, value)
                          : null,
                    ),
                  const Divider(height: 24),
                  Text(
                    text.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  CardDescription(
                    session: widget.session,
                    boardId: board.id,
                    card: card,
                    canEdit: canEdit && !card.archived,
                    openLink: (href) => unawaited(_link(href)),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    title: Text(text.comments),
                    leading: const Icon(Icons.comment_outlined),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/comments'),
                        builder: (_) => CommentsScreen(
                          session: widget.session,
                          boardId: board.id,
                          stackId: card.stackId,
                          cardId: card.id,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(text.attachments),
                    leading: const Icon(Icons.attach_file),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/attachments'),
                        builder: (_) => AttachmentsScreen(
                          session: widget.session,
                          boardId: board.id,
                          cardId: card.id,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(
                      '${text.linkedCards} (${card.dependentCards.length})',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/card/links'),
                        builder: (_) => CardLinksScreen(
                          session: widget.session,
                          boardId: board.id,
                          cardId: card.id,
                        ),
                      ),
                    ),
                  ),
                  if (widget.session.capabilities != null && card.id > 0)
                    CardProjects(
                      key: ValueKey(card.id),
                      session: widget.session,
                      cardId: card.id,
                      open: (resource) => unawaited(_openProject(resource)),
                    ),
                  if (widget.session.capabilities?.supportsActivity == true &&
                      card.id > 0)
                    CardActivity(session: widget.session, cardId: card.id),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
