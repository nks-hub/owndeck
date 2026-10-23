import 'package:flutter/material.dart';

import '../core/errors.dart';
import '../data/session.dart';
import '../l10n/app_localizations.dart';

class SyncNotice extends StatelessWidget {
  const SyncNotice({
    super.key,
    required this.session,
    required this.scope,
    required this.retry,
    required this.hasData,
  });
  final DeckSession session;
  final String scope;
  final VoidCallback retry;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final error = session.error(scope);
    if (error != null)
      return Material(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(errorMessage(error, text)),
              if (hasData) Text(text.cachedData),
              TextButton(onPressed: retry, child: Text(text.retry)),
            ],
          ),
        ),
      );
    if (session.loading(scope))
      return LinearProgressIndicator(semanticsLabel: text.syncing);
    return const SizedBox.shrink();
  }
}
