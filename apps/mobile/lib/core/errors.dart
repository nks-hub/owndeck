import 'package:deck_protocol/deck_protocol.dart';

import '../l10n/app_localizations.dart';

String errorMessage(Object error, AppLocalizations text) {
  if (error is FormatException) return text.invalidResponse;
  final code = switch (error) {
    DeckException() => error.code,
    LoginException() => error.code,
    StateError() => error.message,
    _ => '',
  };
  return switch (code) {
    'authentication_required' => text.authError,
    'permission_denied' => text.permissionError,
    'pending_decision' => text.pendingDecision,
    'account_unavailable' => text.authError,
    'invalid_title' => text.invalidTitle,
    'invalid_destination' || 'invalid_position' => text.invalidDestination,
    'not_found' || 'card_unavailable' => text.cardUnavailable,
    'concurrent_edit' => text.conflict,
    'deck_unavailable' => text.deckError,
    'tls_failed' => text.certError,
    'rate_limited' => text.rateLimited,
    'timeout' || 'transport_failed' => text.networkError,
    _ => error is LoginException ? text.loginError : text.loadError,
  };
}
