import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/errors.dart';
import '../data/card_reads.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';
import 'card_detail.dart';
import 'state_message.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.session, this.openLink});
  final DeckSession session;
  final Future<bool> Function(Uri)? openLink;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int? _opening;
  late Future<DeckNotifications> _result = _load();
  Future<DeckNotifications> _load() =>
      widget.session.readServer((client) => client.notifications());
  void _refresh() => setState(() => _result = _load());

  DeckCardLink? _nativeLink(Uri uri) {
    final link = parseDeckCardLink(uri.toString());
    return link?.server.uri == widget.session.client.base.uri ? link : null;
  }

  Future<void> _open(DeckNotification notification) async {
    final uri = notification.deckLink(widget.session.client.base);
    if (uri == null || _opening != null) return;
    final text = AppLocalizations.of(context)!;
    final cardLink = _nativeLink(uri);
    setState(() => _opening = notification.id);
    try {
      if (cardLink != null && widget.openLink == null) {
        final result = await widget.session.openRemoteCard(
          cardLink.boardId,
          cardLink.cardId,
        );
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/card'),
            builder: (_) => CardScreen(
              session: widget.session,
              board: result.board,
              card: result.card,
            ),
          ),
        );
        return;
      }
      final opened =
          await (widget.openLink?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.browserError)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cardLink == null ? text.browserError : errorMessage(error, text),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(text.deckNotifications),
        actions: [
          IconButton(
            tooltip: text.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<DeckNotifications>(
        future: _result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: StateMessage(
                message: errorMessage(snapshot.error!, text),
                actionLabel: text.retry,
                onAction: _refresh,
              ),
            );
          }
          final result = snapshot.requireData;
          if (!result.supported) {
            return Center(
              child: StateMessage(message: text.notificationsUnavailable),
            );
          }
          if (result.items.isEmpty) {
            return Center(
              child: StateMessage(message: text.noDeckNotifications),
            );
          }
          return ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final item = result.items[index];
              final uri = item.deckLink(widget.session.client.base);
              final cardLink = uri == null ? null : _nativeLink(uri);
              final local = MaterialLocalizations.of(context);
              final created = item.created.toLocal();
              return Card(
                margin: const EdgeInsets.all(12),
                semanticContainer: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (item.message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(item.message),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${local.formatMediumDate(created)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(created))}',
                      ),
                      if (uri != null)
                        TextButton.icon(
                          onPressed: _opening == null
                              ? () => _open(item)
                              : null,
                          icon: Icon(
                            cardLink == null
                                ? Icons.open_in_browser
                                : Icons.open_in_new,
                          ),
                          label: Text(
                            _opening == item.id
                                ? text.openingCardLink
                                : cardLink == null
                                ? text.openInNextcloud
                                : text.openCardLink,
                          ),
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
