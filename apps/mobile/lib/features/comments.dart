import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'comment_editor.dart';
import 'pending.dart';
import 'sync_notice.dart';

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({
    super.key,
    required this.session,
    required this.boardId,
    required this.stackId,
    required this.cardId,
  });
  final DeckSession session;
  final int boardId;
  final int stackId;
  final int cardId;
  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  StreamSubscription<DeckBoard?>? _boardChanges;
  bool _canRead = true;
  bool _boardReadFailed = false;
  late final _comments = widget.session.database.watchComments(
    widget.session.account.id,
    widget.cardId,
  );
  Future<void> _refresh() => widget.session.refreshComments(widget.cardId);

  @override
  void initState() {
    super.initState();
    _boardChanges = widget.session.database
        .watchBoard(widget.session.account.id, widget.boardId)
        .listen(
          (board) {
            if (mounted) {
              setState(() {
                _boardReadFailed = false;
                _canRead =
                    board?.permissions.read == true && board?.deletedAt == 0;
              });
            }
          },
          onError: (Object _) {
            if (mounted) setState(() => _boardReadFailed = true);
          },
        );
    scheduleMicrotask(_refresh);
  }

  @override
  void dispose() {
    unawaited(_boardChanges?.cancel());
    super.dispose();
  }

  Future<void> _compose({DeckComment? original, DeckComment? replyTo}) =>
      openCommentEditor(
        context,
        widget.session,
        widget.boardId,
        widget.stackId,
        widget.cardId,
        original: original,
        replyTo: replyTo,
      );

  Future<void> _delete(DeckComment comment) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.deleteComment),
        content: Text(text.deleteCommentQuestion),
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
    if (!mounted || confirmed != true) return;
    try {
      await widget.session.database.queueComment(
        widget.session.account,
        widget.boardId,
        widget.stackId,
        widget.cardId,
        'deleteComment',
        {},
        original: comment,
      );
      unawaited(_refresh());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.permissionError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    if (_boardReadFailed || !_canRead) {
      return Scaffold(
        appBar: AppBar(title: Text(text.comments)),
        body: Center(
          child: Text(
            _boardReadFailed ? text.localReadError : text.permissionError,
          ),
        ),
      );
    }
    final locale = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(text.comments),
        actions: [
          IconButton(
            tooltip: text.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        label: Text(text.addComment),
        icon: const Icon(Icons.add_comment_outlined),
      ),
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => StreamBuilder<List<DeckComment>>(
          stream: _comments,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(text.localReadError));
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final scope = 'comments:${widget.cardId}';
            final comments = snapshot.data ?? [];
            return Column(
              children: [
                SyncNotice(
                  session: widget.session,
                  scope: scope,
                  retry: _refresh,
                  hasData: comments.isNotEmpty,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: comments.isEmpty ? 1 : comments.length,
                      itemBuilder: (context, index) {
                        if (comments.isEmpty) {
                          if (widget.session.loading(scope)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              widget.session.error(scope) == null
                                  ? text.noComments
                                  : text.noSavedContent,
                            ),
                          );
                        }
                        final comment = comments[index];
                        final own =
                            comment.actorType == 'users' &&
                            comment.actorId == widget.session.userId;
                        final date = comment.created.toLocal();
                        final reply = comment.raw['replyTo'];
                        return Card(
                          key: ValueKey(comment.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.actorName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ),
                                    if (own)
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            unawaited(
                                              _compose(original: comment),
                                            );
                                          }
                                          if (action == 'delete') {
                                            unawaited(_delete(comment));
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text(text.editComment),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text(text.deleteComment),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                Text(
                                  '${locale.formatMediumDate(date)} ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (reply is JsonObject)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      '${text.replyTo}: ${reply['message'] ?? ''}',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                SelectableText(comment.message),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _compose(replyTo: comment),
                                      child: Text(text.reply),
                                    ),
                                    if (comment.raw['syncState'] != null)
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.cloud_upload_outlined,
                                        ),
                                        label: Text(text.pendingChanges),
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                settings: const RouteSettings(
                                                  name: '/sync',
                                                ),
                                                builder: (_) => PendingScreen(
                                                  session: widget.session,
                                                ),
                                              ),
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
