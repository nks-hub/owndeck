import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/errors.dart';
import '../core/technical_details.dart';
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

  Future<void> _copyDetails(BuildContext context, Object error) async {
    final text = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final details = await technicalDetails(
      error,
      serverVersion: session.capabilities?.serverVersion,
      deckVersion: session.capabilities?.version,
    );
    await Clipboard.setData(ClipboardData(text: details));
    messenger.showSnackBar(SnackBar(content: Text(text.technicalDetailsCopied)));
  }

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
                      if (errorAdvice(errorCategory(error), text)
                          case final advice?)
                        Text(
                          advice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (hasData)
                        Text(
                          text.cachedData,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      TextButton.icon(
                        onPressed: () => unawaited(_copyDetails(context, error)),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: Text(text.copyTechnicalDetails),
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
