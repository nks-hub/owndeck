import 'package:deck_protocol/deck_protocol.dart';

import '../l10n/app_localizations.dart';

String errorMessage(Object error, AppLocalizations text) {
  if (error is FormatException) return text.invalidServer;
  final code = switch (error) {
    DeckException() => error.code,
    LoginException() => error.code,
    _ => '',
  };
  return switch (code) {
    'authentication_required' => text.authError,
    'permission_denied' => text.permissionError,
    'deck_unavailable' => text.deckError,
    'tls_failed' => text.certError,
    'timeout' || 'transport_failed' => text.networkError,
    _ => error is LoginException ? text.loginError : text.loadError,
  };
}
