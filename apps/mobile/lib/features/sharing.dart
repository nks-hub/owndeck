import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'share_permissions.dart';
import 'sync_notice.dart';
import 'state_message.dart';
import 'sync_state.dart';

String shareParticipantId(Object? participant) => participant is JsonObject
    ? (participant['uid'] ??
              participant['id'] ??
              participant['primaryKey'] ??
              '')
          .toString()
    : participant?.toString() ?? '';
String shareParticipantName(Object? participant, String unavailable) {
  if (participant is JsonObject) {
    for (final key in ['displayname', 'displayName', 'name']) {
      final value = participant[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
  }
  return unavailable;
}

class SharingScreen extends StatefulWidget {
  const SharingScreen({
    super.key,
    required this.session,
    required this.boardId,
  });
  final DeckSession session;
  final int boardId;
  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  late final _board = widget.session.database.watchBoard(
    widget.session.account.id,
    widget.boardId,
  );
  final _search = TextEditingController();
  Timer? _debounce;
  int _generation = 0;
  bool _searching = false;
  Object? _error;
  List<DeckShareTarget> _targets = [];

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() => widget.session.refreshStacks(widget.boardId));
  }

  void _changed(String term) {
    _debounce?.cancel();
    final generation = ++_generation;
    setState(() {
      _searching = term.trim().isNotEmpty;
      _targets = [];
      _error = null;
    });
    if (term.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final targets = await widget.session.client.searchDeckRecipients(
          term.trim(),
        );
        if (mounted && generation == _generation) {
          setState(() => _targets = targets);
        }
      } catch (error) {
        if (mounted && generation == _generation) {
          setState(() => _error = error);
        }
      } finally {
        if (mounted && generation == _generation) {
          setState(() => _searching = false);
        }
      }
    });
  }

  Future<void> _remove(DeckBoard board, JsonObject acl) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text.removeShare),
        content: Text(text.removeShareQuestion),
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
      await widget.session.database.queueBoardMetadata(
        widget.session.account,
        board.id,
        'deleteAcl',
        {},
        original: acl,
      );
      unawaited(widget.session.refreshStacks(board.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.permissionError)));
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.sharing),
        actions: [
          IconButton(
            tooltip: text.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.session.refreshStacks(widget.boardId),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => StreamBuilder<DeckBoard?>(
          stream: _board,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: StateMessage(message: text.localReadError));
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.deletedAt != 0) {
              return Center(
                child: StateMessage(
                  message: text.permissionError,
                  actionLabel: text.close,
                  onAction: () => Navigator.maybePop(context),
                ),
              );
            }
            final board = snapshot.requireData!;
            final acl = objects(board.raw['acl'] ?? <Object?>[]);
            final targets = _targets
                .where(
                  (target) =>
                      !(target.type == 0 &&
                          target.id == widget.session.userId) &&
                      !acl.any(
                        (entry) =>
                            entry['type'] == target.type &&
                            shareParticipantId(entry['participant']) ==
                                target.id,
                      ),
                )
                .toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SyncNotice(
                  session: widget.session,
                  scope: 'board:${widget.boardId}',
                  retry: () => widget.session.refreshStacks(widget.boardId),
                  hasData: acl.isNotEmpty,
                ),
                if (board.permissions.share) ...[
                  TextField(
                    controller: _search,
                    onChanged: _changed,
                    decoration: InputDecoration(
                      labelText: text.findRecipient,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  if (_searching) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(errorMessage(_error!, text)),
                    ),
                  for (final target in targets)
                    ListTile(
                      title: Text(target.label),
                      subtitle: Text(switch (target.type) {
                        1 => text.group,
                        6 => text.externalRecipient,
                        7 => text.team,
                        _ => text.user,
                      }),
                      leading: const Icon(Icons.person_add_alt),
                      onTap: () => editSharePermissions(
                        context,
                        widget.session,
                        board,
                        target: target,
                      ),
                    ),
                  if (_search.text.isNotEmpty &&
                      !_searching &&
                      _error == null &&
                      targets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(text.noRecipients),
                    ),
                  const Divider(),
                ],
                if (acl.isEmpty)
                  StateMessage(
                    message:
                        widget.session.error('board:${widget.boardId}') == null
                        ? text.noShares
                        : text.noSavedContent,
                  ),
                for (final entry in acl)
                  ListTile(
                    title: Text(
                      shareParticipantName(
                        entry['participant'],
                        text.pendingValueUnavailable,
                      ),
                    ),
                    subtitle: Text(
                      [
                        text.permissionRead,
                        if (entry['permissionEdit'] == true)
                          text.permissionEdit,
                        if (entry['permissionShare'] == true)
                          text.permissionShare,
                        if (entry['permissionManage'] == true)
                          text.permissionManage,
                        if (entry['syncState'] != null)
                          syncStateLabel(entry['syncState'], text),
                      ].join(' · '),
                    ),
                    trailing:
                        entry['owner'] == true ||
                            !(board.permissions.share ||
                                board.permissions.manage &&
                                    intField(entry, 'id') > 0)
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                unawaited(
                                  editSharePermissions(
                                    context,
                                    widget.session,
                                    board,
                                    original: entry,
                                  ),
                                );
                              }
                              if (action == 'delete') {
                                unawaited(_remove(board, entry));
                              }
                            },
                            itemBuilder: (_) => [
                              if (board.permissions.share)
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(text.editShare),
                                ),
                              if (board.permissions.manage &&
                                  intField(entry, 'id') > 0)
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(text.removeShare),
                                ),
                            ],
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
