import 'dart:async';

import 'package:deck_protocol/deck_protocol.dart';
import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_editor.dart';
import 'pending.dart';

part 'card_actions_ui.dart';

class CardScreen extends StatefulWidget {
  const CardScreen({
    super.key,
    required this.session,
    required this.board,
    required this.card,
  });
  final DeckSession session;
  final DeckBoard board;
  final DeckCard card;
  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  late final _card = widget.session.database.watchCard(
    widget.session.account.id,
    widget.board.id,
    widget.card.id,
  );
  late final _board = widget.session.database.watchBoard(
    widget.session.account.id,
    widget.board.id,
  );

  Future<void> _action(DeckCard card, String kind, JsonObject values) async {
    final text = AppLocalizations.of(context)!;
    try {
      await widget.session.database.queueCardAction(
        widget.session.account,
        widget.board.id,
        card,
        kind,
        values,
      );
      unawaited(widget.session.refreshStacks(widget.board.id));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.pendingDecision)));
    }
  }

  Future<void> _link(String? href) async {
    if (href == null) return;
    final parsed = Uri.tryParse(href);
    if (parsed == null) return;
    final uri = widget.session.client.base.uri.resolveUri(parsed);
    if (!{'https', 'http', 'mailto'}.contains(uri.scheme) ||
        uri.userInfo.isNotEmpty)
      return;
    final text = AppLocalizations.of(context)!;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.browserError)));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.browserError)));
    }
  }

  List<JsonObject> _items(Object? value) => switch (value) {
    List list => list.whereType<JsonObject>().toList(),
    JsonObject map => map.values.whereType<JsonObject>().toList(),
    _ => const [],
  };

  String _uid(Object? value) => value is String
      ? value
      : value is JsonObject
      ? (value['uid'] ?? value['primaryKey'] ?? '').toString()
      : '';
  String _name(Object? value) => value is JsonObject
      ? (value['displayname'] ?? value['displayName'] ?? _uid(value)).toString()
      : _uid(value);

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return StreamBuilder<DeckBoard?>(
      stream: _board,
      initialData: widget.board,
      builder: (context, boardSnapshot) => StreamBuilder<DeckCard?>(
        stream: _card,
        initialData: widget.card,
        builder: (context, cardSnapshot) {
          if (boardSnapshot.hasError || cardSnapshot.hasError)
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(text.storageError)),
            );
          final board = boardSnapshot.data;
          final card = cardSnapshot.data;
          if (board == null || !board.permissions.read || card == null)
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(text.cardUnavailable)),
            );
          final canEdit =
              board.permissions.edit && !board.archived && board.deletedAt == 0;
          final labels = _items(card.raw['labels']);
          final assigned = _items(card.raw['assignedUsers']);
          final due = DateTime.tryParse(
            card.raw['duedate']?.toString() ?? '',
          )?.toLocal();
          return Scaffold(
            appBar: AppBar(
              title: Text(card.title),
              actions: [
                if (canEdit)
                  PopupMenuButton<String>(
                    tooltip: text.cardActions,
                    onSelected: (action) {
                      switch (action) {
                        case 'move':
                          unawaited(_move(card));
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
                      if (!card.archived) ...[
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
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(
                          card.archived ? text.unarchive : text.archive,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(text.deleteCard),
                      ),
                    ],
                  ),
              ],
            ),
            floatingActionButton: canEdit && !card.archived
                ? FloatingActionButton.extended(
                    onPressed: () => editCard(
                      context,
                      widget.session,
                      board.id,
                      card.stackId,
                      card: card,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(text.editCard),
                  )
                : null,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              children: [
                if (card.raw['syncState'] != null)
                  ListTile(
                    title: Text(text.pendingChanges),
                    leading: const Icon(Icons.cloud_upload_outlined),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/sync'),
                        builder: (_) => PendingScreen(session: widget.session),
                      ),
                    ),
                  ),
                if (card.archived) Chip(label: Text(text.archivedCards)),
                if (card.raw['done'] != null)
                  Chip(
                    label: Text(text.completed),
                    avatar: const Icon(Icons.check, size: 18),
                  ),
                if (due != null)
                  ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(text.dueDate),
                    subtitle: Text(
                      '${MaterialLocalizations.of(context).formatMediumDate(due)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(due))}',
                    ),
                  ),
                if (labels.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final label in labels)
                        InputChip(
                          label: Text(label['title']?.toString() ?? ''),
                          onDeleted: canEdit && !card.archived
                              ? () => _action(card, 'removeLabel', {
                                  'labelId': label['id'],
                                })
                              : null,
                        ),
                    ],
                  ),
                if (assigned.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final assignment in assigned)
                        InputChip(
                          label: Text(_name(assignment['participant'])),
                          avatar: const Icon(Icons.person_outline, size: 18),
                          onDeleted: canEdit && !card.archived
                              ? () => _action(card, 'unassignUser', {
                                  'userId': _uid(assignment['participant']),
                                  'type': assignment['type'] ?? 0,
                                })
                              : null,
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                MarkdownBody(
                  data: card.description.isEmpty
                      ? text.noDescription
                      : card.description,
                  selectable: true,
                  onTapLink: (_, href, _) => _link(href),
                  imageBuilder: (uri, title, alt) => TextButton.icon(
                    onPressed: () => _link(uri.toString()),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      alt?.isNotEmpty == true ? alt! : text.externalImage,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
