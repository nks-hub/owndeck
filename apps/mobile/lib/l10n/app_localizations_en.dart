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
      'Retrying may create a duplicate item. Send again?';

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

  @override
  String get draftSaved =>
      'The draft is saved on this device. Tap Save to send it to the server.';

  @override
  String get savingDraft => 'Saving draft…';

  @override
  String get drafts => 'Card drafts';

  @override
  String get noDrafts => 'You have no card drafts.';

  @override
  String get discardDraft => 'Discard draft';

  @override
  String get discardDraftQuestion =>
      'Permanently remove this draft text from this device?';

  @override
  String get addBoard => 'Add board';

  @override
  String get editBoard => 'Edit board';

  @override
  String get addStack => 'Add column';

  @override
  String get editStack => 'Edit column';

  @override
  String get name => 'Name';

  @override
  String get color => 'Color';

  @override
  String get position => 'Position';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get deleteBoard => 'Delete board';

  @override
  String get deleteStack => 'Delete column';

  @override
  String get deleteStructureQuestion =>
      'Delete the selected item and its contents on the server?';

  @override
  String get activeBoards => 'Active';

  @override
  String get archivedBoards => 'Archived';

  @override
  String get deletedBoards => 'Deleted';

  @override
  String get restoreBoard => 'Restore board';

  @override
  String get invalidName => 'The name must contain 1 to 100 characters.';

  @override
  String get invalidColor =>
      'Enter a six-digit hexadecimal color, for example 008080.';

  @override
  String get invalidPosition => 'Position must be a non-negative integer.';

  @override
  String get boardActions => 'Board actions';

  @override
  String get stackActions => 'Column actions';

  @override
  String get dependencyUnavailable =>
      'The parent board or column was discarded. Your local content has been preserved.';

  @override
  String get awaitingReadback =>
      'The server accepted this change. Waiting to read the result.';

  @override
  String get moveCard => 'Move card';

  @override
  String get destinationColumn => 'Destination column';

  @override
  String get deleteCard => 'Delete card';

  @override
  String get deleteCardQuestion => 'Delete this card from the server?';

  @override
  String get cardUnavailable =>
      'This card is no longer available. Unsent changes remain in Pending changes.';

  @override
  String get labels => 'Labels';

  @override
  String get assignees => 'Assignees';

  @override
  String get noLabels => 'This board has no labels.';

  @override
  String get noUsers => 'No users are available on this board.';

  @override
  String get cardActions => 'Card actions';

  @override
  String get externalImage => 'Tap to open this image in your browser.';

  @override
  String get archivedCards => 'Archived cards';

  @override
  String get activeCards => 'Active cards';

  @override
  String get reorderCard =>
      'Hold and drag the card; Move is also available in the card menu.';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add comment';

  @override
  String get editComment => 'Edit comment';

  @override
  String get deleteComment => 'Delete comment';

  @override
  String get deleteCommentQuestion => 'Delete this comment from the server?';

  @override
  String get reply => 'Reply';

  @override
  String get replyTo => 'Reply to comment';

  @override
  String get noComments => 'No comments yet.';

  @override
  String get commentMessage => 'Comment text';

  @override
  String get invalidComment => 'A comment must contain 1 to 1,000 characters.';

  @override
  String get commentDraft => 'Comment draft';

  @override
  String get localDraftSaved => 'The draft is saved on this device.';

  @override
  String get sendComment => 'Send comment';

  @override
  String get identityUnavailable =>
      'Reconnect first so the app can verify your user ID. Your draft is preserved.';
}
