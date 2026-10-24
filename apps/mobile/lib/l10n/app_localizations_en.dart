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
  String get connect => 'Continue';

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
  String get invalidServer => 'Enter a valid HTTPS Nextcloud address.';

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
  String get clearDate => 'Clear date';

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

  @override
  String get sharing => 'Board sharing';

  @override
  String get findRecipient => 'Find a user, group, or team';

  @override
  String get noRecipients => 'No matching recipients.';

  @override
  String get addShare => 'Add share';

  @override
  String get editShare => 'Edit permissions';

  @override
  String get removeShare => 'Remove share';

  @override
  String get removeShareQuestion =>
      'Remove this recipient’s access to the board?';

  @override
  String get permissionRead => 'Read';

  @override
  String get permissionEdit => 'Edit';

  @override
  String get permissionShare => 'Share';

  @override
  String get permissionManage => 'Manage';

  @override
  String get user => 'User';

  @override
  String get group => 'Group';

  @override
  String get team => 'Team';

  @override
  String get externalRecipient => 'External recipient';

  @override
  String get noShares => 'This board is not shared yet.';

  @override
  String get manageLabels => 'Manage labels';

  @override
  String get addLabel => 'Add label';

  @override
  String get editLabel => 'Edit label';

  @override
  String get deleteLabel => 'Delete label';

  @override
  String get deleteLabelQuestion =>
      'Remove this label from the board and all its cards?';

  @override
  String get alreadyShared =>
      'This recipient already has access. Refresh the board and edit the existing share.';

  @override
  String get startDate => 'Start date';

  @override
  String get cardColor => 'Card color';

  @override
  String get optionalColor => 'Leave empty for no custom color.';

  @override
  String get invalidDateRange =>
      'The start date must not be after the due date.';

  @override
  String get certificateFingerprintLabel => 'SHA-256 fingerprint';

  @override
  String get scanLoginCodeCameraUnavailable =>
      'This device has no camera that can read a login code.';

  @override
  String get secureTitle => 'Credentials stay on this device';

  @override
  String get serverAddressHint => 'cloud.example.com';

  @override
  String get reauthenticateAccountMismatch =>
      'Sign in with the same account. The stored account was not changed.';

  @override
  String get scanLoginCodeCameraDenied =>
      'Camera access is turned off. Allow it in system settings to scan a login code.';

  @override
  String get waitingForLogin => 'Finish signing in in your browser';

  @override
  String get close => 'Close';

  @override
  String get certificateChangedTitle => 'Server certificate changed';

  @override
  String get unexpectedError =>
      'Something went wrong. No account data was changed.';

  @override
  String get openingLogin => 'Opening secure sign-in…';

  @override
  String get serverMaintenance =>
      'This server is currently in maintenance mode.';

  @override
  String get reauthenticateAccountTitle => 'Sign in to this account again';

  @override
  String get certificateTrustAction => 'Trust and continue';

  @override
  String get scannedLoginRejected =>
      'The scanned login code could not be used. Create a new one on the server.';

  @override
  String get browserUnavailable => 'The sign-in page could not be opened.';

  @override
  String get multiServerBody =>
      'Add personal and work accounts without rebuilding the app or sharing their data.';

  @override
  String get serverNotInstalled =>
      'Nextcloud is not installed on this server yet.';

  @override
  String get checkingServer => 'Checking the server…';

  @override
  String get waitingForLoginBody =>
      'This screen will continue automatically after Nextcloud approves the app.';

  @override
  String get serverUnavailable =>
      'The server could not be reached. Check the address and your connection.';

  @override
  String get secureBody =>
      'App passwords are stored in the system Keychain or Keystore, never in the card database.';

  @override
  String get onboardingTitle => 'Your boards, one app';

  @override
  String certificateChangedBody(String host) {
    return '$host now presents a different certificate than the one this account trusts. If you replaced the certificate yourself, remove the account and add it again.';
  }

  @override
  String get scanLoginCode => 'Scan a login code';

  @override
  String get loginTimedOut => 'The sign-in request expired. Start it again.';

  @override
  String get scanLoginCodeUnreadable => 'This is not a Nextcloud login code.';

  @override
  String get reauthenticateAccountAction => 'Sign in again';

  @override
  String get multiServerTitle => 'Built for multiple servers';

  @override
  String get scanLoginCodeHint =>
      'Point the camera at the QR code your server shows under Settings, Security, Create new app password.';

  @override
  String get invalidResponse =>
      'The server returned a response this app cannot safely use.';

  @override
  String get certificateUnverifiedTitle => 'Unverified server certificate';

  @override
  String certificateUnverifiedBody(String host) {
    return '$host presented a certificate this device cannot verify. Continue only if the fingerprint below is the one your server shows.';
  }

  @override
  String get localPersistenceFailed =>
      'The account could not be stored securely on this device.';

  @override
  String get serverUpgrade =>
      'The server must finish its database upgrade first.';

  @override
  String get addServerTitle => 'Add a Nextcloud server';

  @override
  String get openAppSettings => 'Open settings';

  @override
  String get onboardingBody =>
      'Connect any supported Nextcloud server. Accounts, their stored data and background work stay strictly separated.';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String get attachments => 'Attachments';

  @override
  String get uploadFile => 'Upload file';

  @override
  String get linkCloudFile => 'Attach from Nextcloud';

  @override
  String get noAttachments => 'No attachments yet.';

  @override
  String get openFile => 'Open file';

  @override
  String get saveFile => 'Save file';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get restoreAttachment => 'Restore attachment';

  @override
  String get removeLinkedFileQuestion =>
      'The file will be detached from this card. It will remain in Nextcloud.';

  @override
  String get removeLegacyFileQuestion =>
      'Remove this attachment? It can be restored for a limited time before the server permanently deletes it.';

  @override
  String get attachmentTooLarge =>
      'The file exceeds 64 MiB. Choose a smaller file.';

  @override
  String get attachmentFailed => 'The file could not be processed. Try again.';

  @override
  String get unsupportedAttachment =>
      'This attachment type cannot be opened yet.';

  @override
  String get offlineAttachment =>
      'Using a previously downloaded copy of the file.';

  @override
  String get chooseCloudFile => 'Choose a Nextcloud file';

  @override
  String get fileNotShareable => 'You cannot share this file.';

  @override
  String get noCloudFiles => 'This folder is empty.';

  @override
  String get parentFolder => 'Parent folder';

  @override
  String get fileSaved => 'File saved.';

  @override
  String get fileOpenFailed =>
      'The file could not be opened. You can save it and open it in another app.';

  @override
  String get deletedAttachment => 'Removed attachment';

  @override
  String get fileAttachment => 'File';
}
