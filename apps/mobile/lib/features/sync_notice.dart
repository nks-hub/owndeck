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
    if (error != null) {
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 12, right: 12),
                child: Icon(Icons.cloud_off_outlined),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(errorMessage(error, text)),
                      if (hasData)
                        Text(
                          text.cachedData,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: retry,
                tooltip: text.retry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      );
    }
    if (session.loading(scope)) {
      return LinearProgressIndicator(semanticsLabel: text.syncing);
    }
    return const SizedBox.shrink();
  }
}
