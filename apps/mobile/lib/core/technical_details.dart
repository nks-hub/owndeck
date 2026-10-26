import 'package:deck_protocol/deck_protocol.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';

enum ErrorCategory {
  maintenance,
  certificate,
  timeout,
  deckMissing,
  network,
  authentication,
  other,
}

ErrorCategory errorCategory(Object error) {
  final code = switch (error) {
    DeckException() => error.code,
    LoginException() => error.code,
    _ => '',
  };
  if (code == 'server_maintenance' ||
      error is DeckException && error.status == 503) {
    return ErrorCategory.maintenance;
  }
  return switch (code) {
    'tls_failed' || 'certificate_rejected' => ErrorCategory.certificate,
    'timeout' => ErrorCategory.timeout,
    'deck_unavailable' => ErrorCategory.deckMissing,
    'transport_failed' => ErrorCategory.network,
    'authentication_required' || 'account_unavailable' =>
      ErrorCategory.authentication,
    _ => ErrorCategory.other,
  };
}

/// What the user can try for [category], or null when there is no specific advice.
String? errorAdvice(ErrorCategory category, AppLocalizations text) =>
    switch (category) {
      ErrorCategory.maintenance => text.adviceMaintenance,
      ErrorCategory.certificate => text.adviceCertificate,
      ErrorCategory.timeout => text.adviceTimeout,
      ErrorCategory.deckMissing => text.adviceDeckMissing,
      _ => null,
    };

/// Versions and the error category for a bug report. It never contains the
/// server address, the account name, tokens or passwords.
Future<String> technicalDetails(
  Object error, {
  String? serverVersion,
  String? deckVersion,
}) async {
  String app;
  try {
    final info = await PackageInfo.fromPlatform();
    app = '${info.version} (${info.buildNumber})';
  } on Object {
    app = 'unknown';
  }
  final code = switch (error) {
    DeckException() => error.code,
    LoginException() => error.code,
    _ => 'unknown',
  };
  final status = error is DeckException ? error.status : null;
  return [
    'OwnDeck: $app',
    'Nextcloud: ${serverVersion ?? 'unknown'}',
    'Deck: ${deckVersion ?? 'unknown'}',
    'Category: ${errorCategory(error).name}',
    'Code: $code',
    'HTTP status: ${status ?? 'none'}',
  ].join('\n');
}
