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
}
