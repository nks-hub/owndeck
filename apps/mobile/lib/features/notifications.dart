import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.session, this.openLink});
  final DeckSession session;
  final Future<bool> Function(Uri)? openLink;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<DeckNotifications> _result = _load();
  Future<DeckNotifications> _load() =>
      widget.session.readServer((client) => client.notifications());
  void _refresh() => setState(() => _result = _load());

  Future<void> _open(DeckNotification notification) async {
    final uri = notification.deckLink(widget.session.client.base);
    if (uri == null) return;
    final text = AppLocalizations.of(context)!;
    try {
      final opened =
          await (widget.openLink?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened && mounted) {
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMessage(snapshot.error!, text)),
                    TextButton(onPressed: _refresh, child: Text(text.retry)),
                  ],
                ),
              ),
            );
          }
          final result = snapshot.requireData;
          if (!result.supported) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(text.notificationsUnavailable),
              ),
            );
          }
          if (result.items.isEmpty) {
            return Center(child: Text(text.noDeckNotifications));
          }
          return ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final item = result.items[index];
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
                      if (item.deckLink(widget.session.client.base) != null)
                        TextButton.icon(
                          onPressed: () => _open(item),
                          icon: const Icon(Icons.open_in_browser),
                          label: Text(text.openInNextcloud),
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
