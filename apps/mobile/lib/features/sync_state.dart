import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Short label of a local change state, shared by every screen that shows one.
String syncStateLabel(Object? state, AppLocalizations text) => switch (state) {
  'sending' => text.sending,
  'applied' => text.changeAccepted,
  'conflict' => text.syncConflict,
  'uncertain' => text.pendingUncertain,
  'blocked' => text.needsDecision,
  _ => text.queued,
};

/// Full explanation of a local change state, for details and screen readers.
String syncStateDetail(Object? state, AppLocalizations text) => switch (state) {
  'sending' => text.sending,
  'applied' => text.awaitingReadback,
  'conflict' => text.pendingConflictHelp,
  'uncertain' => text.uncertain,
  'blocked' => text.blocked,
  _ => text.savedLocally,
};

IconData syncStateIcon(Object? state) => switch (state) {
  'sending' || 'applied' => Icons.sync,
  'conflict' => Icons.compare_arrows,
  'uncertain' => Icons.help_outline,
  'blocked' => Icons.error_outline,
  _ => Icons.cloud_upload_outlined,
};
