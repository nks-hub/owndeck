import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';

import '../data/attachment_files.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'cloud_files.dart';
import 'pending.dart';
import 'sync_notice.dart';

class AttachmentsScreen extends StatefulWidget {
  const AttachmentsScreen({
    super.key,
    required this.session,
    required this.boardId,
    required this.cardId,
  });
  final DeckSession session;
  final int boardId;
  final int cardId;
  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  late final _board = widget.session.database.watchBoard(
    widget.session.account.id,
    widget.boardId,
  );
  late final _card = widget.session.database.watchCard(
    widget.session.account.id,
    widget.boardId,
    widget.cardId,
  );
  @override
  Widget build(BuildContext context) => StreamBuilder<DeckBoard?>(
    stream: _board,
    builder: (context, board) => StreamBuilder<DeckCard?>(
      stream: _card,
      builder: (context, card) {
        final text = AppLocalizations.of(context)!;
        if (board.connectionState == ConnectionState.waiting ||
            card.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(text.attachments)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (board.hasError ||
            card.hasError ||
            board.data == null ||
            card.data == null ||
            !board.data!.permissions.read) {
          return Scaffold(
            appBar: AppBar(title: Text(text.attachments)),
            body: Center(child: Text(text.cardUnavailable)),
          );
        }
        return _AttachmentList(
          key: ValueKey(card.data!.id),
          session: widget.session,
          board: board.data!,
          card: card.data!,
          draftCardId: widget.cardId,
        );
      },
    ),
  );
}

class _AttachmentList extends StatefulWidget {
  const _AttachmentList({
    super.key,
    required this.session,
    required this.board,
    required this.card,
    required this.draftCardId,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckCard card;
  final int draftCardId;
  @override
  State<_AttachmentList> createState() => _AttachmentListState();
}

class _AttachmentListState extends State<_AttachmentList> {
  late final _attachments = widget.session.database.watchAttachments(
    widget.session.account.id,
    widget.card.id,
  );
  late final _writes = widget.session.database.watchWrites(
    widget.session.account.id,
  );
  bool _busy = false;
  bool get _canEdit =>
      widget.board.permissions.edit &&
      !widget.board.archived &&
      widget.board.deletedAt == 0 &&
      !widget.card.archived;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_refresh);
  }

  void _refresh() => unawaited(
    widget.session.refreshAttachments(
      widget.board.id,
      widget.card.stackId,
      widget.card.id,
    ),
  );
  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } catch (error) {
      if (mounted) {
        final text = AppLocalizations.of(context)!;
        _message(
          error is AttachmentTooLarge
              ? text.attachmentTooLarge
              : text.attachmentFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() => _run(() async {
    final picked = await FilePicker.pickFile();
    if (picked == null || !mounted) return;
    final size = await picked.length();
    if (size != null && size > attachmentMaxBytes) {
      throw const AttachmentTooLarge();
    }
    await widget.session.uploadAttachment(
      widget.board.id,
      widget.card.stackId,
      widget.card.id,
      name: picked.name,
      mime: lookupMimeType(picked.name) ?? 'application/octet-stream',
      bytes: picked.readAsByteStream(),
    );
  });

  Future<void> _link() => _run(() async {
    final file = await Navigator.of(context).push<CloudFile>(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/files'),
        builder: (_) => CloudFilesScreen(session: widget.session),
      ),
    );
    if (file == null || !mounted) return;
    await widget.session.linkAttachment(
      widget.board.id,
      widget.card.stackId,
      widget.card.id,
      file,
    );
  });

  Future<void> _download(DeckAttachment attachment, {required bool save}) =>
      _run(() async {
        final downloaded = await widget.session.downloadAttachment(
          widget.board.id,
          widget.card.stackId,
          attachment,
        );
        final bytes = save ? await downloaded.file.readAsBytes() : null;
        if (!mounted) return;
        await widget.session.ensureAttachmentAccess(
          widget.board.id,
          attachment.cardId,
        );
        if (!mounted) return;
        final text = AppLocalizations.of(context)!;
        if (downloaded.offline) _message(text.offlineAttachment);
        final mime =
            lookupMimeType(attachment.name) ?? 'application/octet-stream';
        if (save) {
          final result = await FilePicker.saveFile(
            fileName: safeAttachmentName(attachment.name),
            bytes: bytes!,
            mimeType: mime,
          );
          if (result != null) _message(text.fileSaved);
        } else {
          if (!Platform.isAndroid && !Platform.isIOS) {
            throw UnsupportedError('mobile_file_viewer_required');
          }
          final result = await OpenFilex.open(downloaded.file.path, type: mime);
          if (result.type != ResultType.done) _message(text.fileOpenFailed);
        }
      });

  Future<void> _change(DeckAttachment attachment, {required bool restore}) =>
      _run(() async {
        final text = AppLocalizations.of(context)!;
        if (!restore) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(text.removeAttachment),
              content: Text(
                attachment.type == 'file'
                    ? text.removeLinkedFileQuestion
                    : text.removeLegacyFileQuestion,
              ),
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
        }
        await widget.session.changeAttachment(
          widget.board.id,
          widget.card.stackId,
          attachment,
          restore: restore,
        );
      });

  void _pending() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/sync'),
      builder: (_) => PendingScreen(session: widget.session),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.attachments),
        actions: [
          IconButton(
            tooltip: text.pendingChanges,
            onPressed: _pending,
            icon: const Icon(Icons.sync_problem_outlined),
          ),
          IconButton(
            tooltip: text.refresh,
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => StreamBuilder<List<DeckAttachment>>(
          stream: _attachments,
          builder: (context, snapshot) => StreamBuilder<List<PendingWrite>>(
            stream: _writes,
            builder: (context, writes) {
              if (snapshot.hasError || writes.hasError) {
                return Center(child: Text(text.loadError));
              }
              if ((snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) ||
                  (writes.connectionState == ConnectionState.waiting &&
                      !writes.hasData)) {
                return const Center(child: CircularProgressIndicator());
              }
              final scope = 'attachments:${widget.card.id}';
              final items = snapshot.data ?? [];
              final pending = (writes.data ?? []).where(
                (write) =>
                    attachmentKinds.contains(write.kind) &&
                    (write.cardId == widget.card.id ||
                        write.cardId == widget.draftCardId),
              );
              return ListView(
                children: [
                  SyncNotice(
                    session: widget.session,
                    scope: scope,
                    retry: _refresh,
                    hasData: items.isNotEmpty,
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (_canEdit)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy ? null : _upload,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(text.uploadFile),
                          ),
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _link,
                            icon: const Icon(Icons.add_link),
                            label: Text(text.linkCloudFile),
                          ),
                        ],
                      ),
                    ),
                  for (final write in pending)
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text(
                        object(
                              jsonDecode(write.proposal),
                            )['name']?.toString() ??
                            text.attachments,
                      ),
                      subtitle: Text(switch (write.state) {
                        'queued' => text.queued,
                        'sending' => text.sending,
                        'applied' => text.awaitingReadback,
                        'uncertain' => text.uncertain,
                        'conflict' => text.conflict,
                        _ => text.blocked,
                      }),
                      onTap: _pending,
                    ),
                  if (items.isEmpty &&
                      pending.isEmpty &&
                      !widget.session.loading(scope))
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.session.error(scope) == null
                            ? text.noAttachments
                            : text.noSavedContent,
                      ),
                    ),
                  for (final attachment in items)
                    ListTile(
                      leading: Icon(
                        attachment.deletedAt == 0
                            ? Icons.attach_file
                            : Icons.delete_outline,
                      ),
                      title: Text(attachment.name),
                      subtitle: Text(
                        !attachment.supported
                            ? text.unsupportedAttachment
                            : attachment.deletedAt != 0
                            ? text.deletedAttachment
                            : attachment.size == null
                            ? text.fileAttachment
                            : '${(attachment.size! / 1024).ceil()} KiB',
                      ),
                      onTap:
                          _busy ||
                              !attachment.supported ||
                              attachment.deletedAt != 0
                          ? null
                          : () => _download(attachment, save: false),
                      trailing:
                          !attachment.supported ||
                              attachment.deletedAt != 0 &&
                                  (!_canEdit || !attachment.canRestore)
                          ? null
                          : PopupMenuButton<String>(
                              enabled: !_busy,
                              onSelected: (action) => switch (action) {
                                'save' => _download(attachment, save: true),
                                'remove' => _change(attachment, restore: false),
                                'restore' => _change(attachment, restore: true),
                                _ => _download(attachment, save: false),
                              },
                              itemBuilder: (_) => [
                                if (attachment.deletedAt == 0) ...[
                                  PopupMenuItem(
                                    value: 'open',
                                    child: Text(text.openFile),
                                  ),
                                  PopupMenuItem(
                                    value: 'save',
                                    child: Text(text.saveFile),
                                  ),
                                  if (_canEdit)
                                    PopupMenuItem(
                                      value: 'remove',
                                      child: Text(text.removeAttachment),
                                    ),
                                ],
                                if (_canEdit && attachment.canRestore)
                                  PopupMenuItem(
                                    value: 'restore',
                                    child: Text(text.restoreAttachment),
                                  ),
                              ],
                            ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
