import 'package:deck_protocol/deck_protocol.dart';
import 'package:flutter/material.dart';

import '../data/session.dart';
import '../l10n/app_localizations.dart';
import '../core/errors.dart';

/// Card history from the server Activity app. It is read live and never cached,
/// so offline the section says so instead of showing stale or invented entries.
class CardActivity extends StatefulWidget {
  const CardActivity({super.key, required this.session, required this.cardId});
  final DeckSession session;
  final int cardId;

  @override
  State<CardActivity> createState() => _CardActivityState();
}

class _CardActivityState extends State<CardActivity> {
  final _items = <DeckActivity>[];
  int? _next;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.session.client.cardActivity(
        widget.cardId,
        since: more ? _next : null,
      );
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll(page.items);
        _next = page.next;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final locale = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(text.activity, style: Theme.of(context).textTheme.titleMedium),
        for (final item in _items)
          ListTile(
            key: ValueKey(item.id),
            contentPadding: EdgeInsets.zero,
            title: Text(item.subject),
            subtitle: Text(
              '${locale.formatMediumDate(item.created.toLocal())} '
              '${locale.formatTimeOfDay(TimeOfDay.fromDateTime(item.created.toLocal()))}',
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null) ...[
          Text(
            _items.isEmpty
                ? text.activityUnavailable
                : errorMessage(_error!, text),
          ),
          TextButton(
            onPressed: () => _load(more: _items.isNotEmpty),
            child: Text(text.retry),
          ),
        ] else if (_items.isEmpty)
          Text(text.noActivity)
        else if (_next != null)
          TextButton(
            onPressed: () => _load(more: true),
            child: Text(text.loadMore),
          ),
      ],
    );
  }
}
