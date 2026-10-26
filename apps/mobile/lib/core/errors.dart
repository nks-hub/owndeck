import 'package:deck_protocol/deck_protocol.dart';

import '../l10n/app_localizations.dart';

String _errorCode(Object error) => switch (error) {
  DeckException() => error.code,
  LoginException() => error.code,
  StateError() => error.message,
  _ => '',
};

String errorMessage(Object error, AppLocalizations text, {String? fallback}) {
  if (error is FormatException) return fallback ?? text.invalidResponse;
  return switch (_errorCode(error)) {
    'authentication_required' => text.authError,
    'permission_denied' => text.permissionError,
    'pending_decision' => text.pendingDecision,
    'account_unavailable' => text.authError,
    'identity_unavailable' => text.identityUnavailable,
    'invalid_title' => text.invalidTitle,
    'invalid_destination' || 'invalid_position' => text.invalidDestination,
    'not_found' || 'card_unavailable' => text.cardUnavailable,
    'card_archived' => text.cardArchivedError,
    'comment_missing' => text.commentUnavailable,
    'item_missing' => text.itemUnavailable,
    'attachment_missing' => text.attachmentMissingError,
    'attachment_storage_unavailable' => text.localSaveError,
    'invalid_response' => text.invalidResponse,
    'unsupported_operation' => text.unsupportedOperation,
    'concurrent_edit' => text.conflict,
    'deck_unavailable' => text.deckError,
    'tls_failed' => text.certError,
    'rate_limited' => text.rateLimited,
    'timeout' || 'transport_failed' => text.networkError,
    _ => error is LoginException ? text.loginError : fallback ?? text.loadError,
  };
}

String localWriteErrorMessage(
  Object error,
  AppLocalizations text, {
  String? pendingMessage,
}) => switch (_errorCode(error)) {
  'permission_denied' => text.writePermissionError,
  'pending_decision' => pendingMessage ?? text.pendingDecision,
  _ => errorMessage(error, text, fallback: text.localSaveError),
};
