import 'dart:async';
import 'dart:convert';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'drafts.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key, required this.session});
  final DeckSession session;
  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  late final _writes = widget.session.database.watchWrites(
    widget.session.account.id,
  );

  Future<void> _decide(PendingWrite write, bool discard) async {
    final text = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(discard ? text.discardWrite : text.retryWrite),
        content: Text(
          discard
              ? text.confirmDiscard
              : write.state == 'uncertain'
              ? text.confirmRetry
              : text.conflict,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(text.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(discard ? text.remove : text.retryWrite),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.session.database.decideWrite(
        widget.session.account.id,
        write.id,
        discard: discard,
        acceptRemoteBase: !discard && write.state == 'conflict',
      );
      if (!discard) unawaited(widget.session.refreshStacks(write.boardId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.pendingDecision)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.pendingChanges),
        actions: [
          IconButton(
            tooltip: text.drafts,
            icon: const Icon(Icons.drafts_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/drafts'),
                builder: (_) => DraftsScreen(session: widget.session),
              ),
            ),
          ),

          IconButton(
            tooltip: text.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: widget.session.refreshBoards,
          ),
        ],
      ),
      body: StreamBuilder<List<PendingWrite>>(
        stream: _writes,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(text.storageError));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final writes = snapshot.requireData;
          if (writes.isEmpty) return Center(child: Text(text.noPending));
          return ListView.builder(
            itemCount: writes.length,
            itemBuilder: (context, index) {
              final write = writes[index];
              final changes = object(jsonDecode(write.proposal));
              final base = write.base == null
                  ? <String, Object?>{}
                  : object(jsonDecode(write.base!));
              final remote = write.remote == null
                  ? null
                  : object(jsonDecode(write.remote!));
              final state = switch (write.state) {
                'queued' => text.queued,
                'sending' => text.sending,
                'applied' => text.awaitingReadback,
                'conflict' => text.conflict,
                'uncertain' => text.uncertain,
                _ => text.blocked,
              };
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (changes['title'] ??
                                base['title'] ??
                                (write.kind.endsWith('Comment')
                                    ? text.comments
                                    : text.cardTitle))
                            .toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        write.error == 'dependency_unavailable'
                            ? text.dependencyUnavailable
                            : state,
                      ),
                      const SizedBox(height: 12),
                      Text(text.localVersion),
                      SelectableText(
                        (changes['message'] ??
                                changes['description'] ??
                                base['message'] ??
                                base['description'] ??
                                '')
                            .toString(),
                      ),
                      if (remote != null) ...[
                        const Divider(),
                        Text(text.serverVersion),
                        SelectableText(
                          '${remote['title'] ?? ''}\n${remote['message'] ?? remote['description'] ?? ''}',
                        ),
                      ],
                      if (write.state != 'sending')
                        Wrap(
                          spacing: 8,
                          children: [
                            if (write.state != 'queued' &&
                                write.state != 'applied')
                              TextButton(
                                onPressed: () => _decide(write, false),
                                child: Text(text.retryWrite),
                              ),
                            TextButton(
                              onPressed: () => _decide(write, true),
                              child: Text(text.discardWrite),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
