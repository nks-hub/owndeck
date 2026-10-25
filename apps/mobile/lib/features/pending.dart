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
  String _cardSummary(JsonObject value, Set<String> fields) {
    final text = AppLocalizations.of(context)!;
    String textField(String key) => switch (value[key]) {
      String value => value,
      null => '',
      _ => text.pendingValueUnavailable,
    };
    String dateValue(Object? value) {
      if (value == null || value == '') return text.pendingValueNotSet;
      final date = switch (value) {
        String value => DateTime.tryParse(value),
        int value when value >= 0 && value <= 253402300799 =>
          DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true),
        _ => null,
      };
      if (date == null || date.year < 1 || date.year > 9999) {
        return text.pendingValueUnavailable;
      }
      final localDate = date.toLocal();
      final local = MaterialLocalizations.of(context);
      final time = local.formatTimeOfDay(
        TimeOfDay.fromDateTime(localDate),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      return '${local.formatMediumDate(localDate)} $time';
    }

    String dateField(String key) => value.containsKey(key)
        ? dateValue(value[key])
        : text.pendingValueUnavailable;
    final color = value['color'];
    final colorValue = !value.containsKey('color')
        ? text.pendingValueUnavailable
        : color == null || color == ''
        ? text.pendingValueNotSet
        : color is String && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(color)
        ? '#${color.toUpperCase()}'
        : text.pendingValueUnavailable;
    final done = value['done'];
    final completion = !value.containsKey('done')
        ? text.pendingValueUnavailable
        : done == null
        ? text.pendingNotCompleted
        : dateValue(done);
    return [
      '${text.cardTitle}: ${textField('title')}',
      '${text.description}: ${textField('description')}',
      '${text.dueDate}: ${dateField('duedate')}',
      if (fields.contains('startdate'))
        '${text.startDate}: ${dateField('startdate')}',
      if (fields.contains('color')) '${text.cardColor}: $colorValue',
      if (fields.contains('done')) '${text.pendingCompletion}: $completion',
    ].join('\n');
  }

  String _attachmentSummary(JsonObject value) {
    final name = (value['name'] ?? value['data'] ?? '').toString();
    final modified = value['lastModified'];
    if (modified is! int || modified <= 0 || modified > 253402300799) {
      return name;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(modified * 1000).toLocal();
    final local = MaterialLocalizations.of(context);
    return '$name\n${local.formatMediumDate(date)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

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
              final attachment = attachmentKinds.contains(write.kind);
              final card =
                  write.kind == 'createCard' || write.kind == 'updateCard';
              final base = write.base == null
                  ? <String, Object?>{}
                  : object(jsonDecode(write.base!));
              final remote = write.remote == null
                  ? null
                  : object(jsonDecode(write.remote!));
              final localCard = {...base, ...changes};
              final remoteCard = card && remote?['acceptedCard'] is Map
                  ? object(remote!['acceptedCard'])
                  : remote;
              final cardFields = {
                ...localCard.keys,
                if (remoteCard != null) ...remoteCard.keys,
              };
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
                        (changes['displayName'] ??
                                changes['name'] ??
                                changes['title'] ??
                                base['title'] ??
                                (write.kind.endsWith('Comment')
                                    ? text.comments
                                    : text.cardTitle))
                            .toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        write.error == 'already_shared'
                            ? text.alreadyShared
                            : write.error == 'dependency_unavailable'
                            ? text.dependencyUnavailable
                            : state,
                      ),
                      const SizedBox(height: 12),
                      Text(text.localVersion),
                      SelectableText(
                        attachment
                            ? _attachmentSummary({...base, ...changes})
                            : card
                            ? _cardSummary(localCard, cardFields)
                            : (changes['message'] ??
                                      changes['description'] ??
                                      base['message'] ??
                                      base['description'] ??
                                      '')
                                  .toString(),
                      ),
                      if (remote != null &&
                          (!attachment ||
                              remote['data'] is String ||
                              remote['name'] is String)) ...[
                        const Divider(),
                        Text(text.serverVersion),
                        SelectableText(
                          attachment
                              ? _attachmentSummary(remote)
                              : card
                              ? _cardSummary(remoteCard!, cardFields)
                              : '${remote['title'] ?? ''}\n${remote['message'] ?? remote['description'] ?? ''}',
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
