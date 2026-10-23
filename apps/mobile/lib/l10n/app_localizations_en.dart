// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OwnDeck';

  @override
  String get connectTitle => 'Connect Nextcloud';

  @override
  String get connectDescription =>
      'Sign in through your server in the browser. Your account password stays on the server.';

  @override
  String get serverLabel => 'Server address';

  @override
  String get connect => 'Connect';

  @override
  String get waiting => 'Finish signing in through your browser.';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get boards => 'Boards';

  @override
  String get accounts => 'Accounts';

  @override
  String get addAccount => 'Add account';

  @override
  String get noBoards => 'No boards yet';

  @override
  String get noBoardsHint => 'This account has no active boards available.';

  @override
  String get emptyStack => 'There are no cards in this column.';

  @override
  String get noStacks => 'This board has no columns.';

  @override
  String get refresh => 'Refresh';

  @override
  String get readOnly => 'Read only';

  @override
  String get noDescription => 'No description';

  @override
  String get storageError =>
      'Secure storage is unavailable. Unlock the device and try again.';

  @override
  String get invalidServer => 'Enter a valid Nextcloud HTTPS address.';

  @override
  String get loginError =>
      'Sign-in could not be completed. Start a new attempt.';

  @override
  String get networkError =>
      'The server is unavailable. Check your connection and try again.';

  @override
  String get authError => 'Your session expired. Add the same account again.';

  @override
  String get permissionError => 'You no longer have access to this content.';

  @override
  String get deckError => 'Deck with API 1.1 is not available on this server.';

  @override
  String get certError =>
      'The server certificate is not trusted. Check the address and server configuration.';

  @override
  String get browserError => 'The browser could not be opened.';

  @override
  String get loadError => 'The content could not be loaded.';

  @override
  String get removeAccount => 'Remove account';

  @override
  String get removeAccountQuestion =>
      'Remove this account and all its local data from this device? Server data will be preserved.';

  @override
  String get remove => 'Remove';

  @override
  String get revocationFailed =>
      'The account was removed from this device. Server-side revocation could not be confirmed; check connected apps in Nextcloud settings.';

  @override
  String get cachedData => 'Showing the saved copy.';

  @override
  String get syncing => 'Refreshing…';

  @override
  String get addCard => 'Add card';

  @override
  String get editCard => 'Edit card';

  @override
  String get cardTitle => 'Card title';

  @override
  String get description => 'Description';

  @override
  String get save => 'Save';

  @override
  String get savedLocally =>
      'Saved on this device. The change is awaiting server confirmation.';

  @override
  String get invalidTitle => 'The title must contain 1 to 255 characters.';

  @override
  String get dueDate => 'Due date';

  @override
  String get clearDate => 'Clear due date';

  @override
  String get completed => 'Completed';

  @override
  String get pendingChanges => 'Pending changes';

  @override
  String get noPending => 'All changes have been confirmed.';

  @override
  String get queued => 'Queued';

  @override
  String get sending => 'Sending';

  @override
  String get conflict => 'The same field changed on the server.';

  @override
  String get uncertain =>
      'The server may have accepted this change. Check the server before retrying.';

  @override
  String get blocked => 'This change cannot be sent. Check access and content.';

  @override
  String get retryWrite => 'Send again';

  @override
  String get discardWrite => 'Discard local change';

  @override
  String get localVersion => 'Local version';

  @override
  String get serverVersion => 'Server version';

  @override
  String get confirmRetry =>
      'Retrying may create a duplicate card. Send again?';

  @override
  String get confirmDiscard =>
      'Discard this local change? This will not undo any write already applied on the server.';

  @override
  String get pendingDecision =>
      'This card has a sending or unresolved change. Open Pending changes first.';

  @override
  String get unsavedChanges => 'Leave unsaved changes?';

  @override
  String get leave => 'Leave';
}
