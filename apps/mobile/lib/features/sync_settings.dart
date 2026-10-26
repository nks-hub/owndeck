import 'dart:async';

import 'package:deck_store/deck_store.dart';
import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';

/// Last successful sync of every account and a button that syncs the
/// account in use. Other accounts are refreshed when they are selected or by
/// the background run.
class SyncSettingsTile extends StatefulWidget {
  const SyncSettingsTile({super.key, required this.session});
  final DeckSession session;

  @override
  State<SyncSettingsTile> createState() => _SyncSettingsTileState();
}

class _SyncSettingsTileState extends State<SyncSettingsTile> {
  bool _running = false;
  Object? _error;

  Future<void> _sync() async {
    final session = widget.session;
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final ok = await session.syncNow();
      if (!ok) {
        _error =
            session.error('boards') ??
            session.error('board') ??
            StateError('sync_failed');
      }
    } on Object catch (error) {
      _error = error;
    }
    if (mounted) setState(() => _running = false);
  }

  String _time(BuildContext context, DateTime at) {
    final local = at.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}';
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final session = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            text.syncTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        StreamBuilder<List<AccountSyncStatus>>(
          stream: session.database.watchSyncStatus(),
          builder: (context, snapshot) => Column(
            children: [
              for (final status in snapshot.data ?? const <AccountSyncStatus>[])
                ListTile(
                  key: ValueKey(('sync-status', status.account.id)),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${status.account.loginName} (${status.account.server})',
                  ),
                  subtitle: Text(
                    status.lastSyncedAt == null
                        ? text.syncNever
                        : text.syncLastTime(
                            _time(context, status.lastSyncedAt!),
                          ),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                errorMessage(_error!, text),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            key: const Key('sync-now'),
            onPressed: _running ? null : () => unawaited(_sync()),
            icon: _running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_running ? text.syncRunning : text.syncNow),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
