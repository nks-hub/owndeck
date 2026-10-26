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
      'Remove this account from the app? Its saved drafts and unsent changes will be deleted. Your content in Nextcloud will stay.';

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
  String get pendingValueNotSet => 'Not set';

  @override
  String get pendingValueUnavailable => 'Value unavailable';

  @override
  String get moreActions => 'More actions';

  @override
  String get deciding => 'Working';

  @override
  String currentOnServer(String board, String column) {
    return 'Now on server: $board / $column';
  }

  @override
  String get pendingNotCompleted => 'Not completed';

  @override
  String get pendingCompletion => 'Completion';

  @override
  String get confirmRetry =>
      'Retrying may create a duplicate item. Send again?';

  @override
  String get checkServer => 'Check server';

  @override
  String get serverCheckFound =>
      'The server already has this change. Finishing it.';

  @override
  String get serverCheckMissing =>
      'The server does not have this change. You can send it again.';

  @override
  String get confirmResend => 'Send this change again?';

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
  String get drafts => 'Drafts';

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
  String get invalidColor => 'Choose a color.';

  @override
  String get invalidPosition => 'Choose where to place the item.';

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
  String get changeAccepted => 'Accepted';

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
  String get activity => 'Activity';

  @override
  String get noActivity => 'No recorded activity for this card.';

  @override
  String get activityUnavailable =>
      'Activity is read from the server and is not stored on this device. Connect and try again.';

  @override
  String get loadMore => 'Load older';

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

  @override
  String get searchCards => 'Search cards';

  @override
  String get searchCardsHint => 'Title, description or label';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get myTasks => 'My tasks';

  @override
  String get localSearchNotice =>
      'Only data saved on this device is searched. Open a board to load its cards.';

  @override
  String get includeArchived => 'Include archived';

  @override
  String get includeCompleted => 'Include completed';

  @override
  String get anyDueDate => 'Any due date';

  @override
  String get dueToday => 'Today';

  @override
  String get overdueTasks => 'Overdue';

  @override
  String get withoutDueDate => 'No due date';

  @override
  String get noMatchingCards => 'No saved cards match the search and filters.';

  @override
  String get accountSearchUnavailable => 'This account is no longer available.';

  @override
  String get myTasksIdentityRequired =>
      'My tasks will be available after sync verifies your user identity.';

  @override
  String get rateLimited =>
      'The server requested a pause. Sync will retry later.';

  @override
  String get copyCard => 'Copy card';

  @override
  String get copyCardDescription =>
      'The copy includes the title, description, labels and available assignments. Dates, comments and attachments are not copied.';

  @override
  String get copyDestinationBoard => 'Destination board';

  @override
  String get noCopyDestination => 'No writable board is available.';

  @override
  String get linkedCards => 'Linked cards';

  @override
  String get addCardLink => 'Link a card';

  @override
  String get removeCardLink => 'Remove link';

  @override
  String get noLinkedCards => 'This card has no links yet.';

  @override
  String get linkedCardUnavailable =>
      'A linked card is not available in stored data.';

  @override
  String get cardLinksDescription =>
      'Links point to related cards. They do not block completion.';

  @override
  String get cardLinkCachedOnly =>
      'Only cards stored on this device are listed.';

  @override
  String get noLinkCandidates => 'No other stored cards match the search.';

  @override
  String get doneColumn => 'Done column';

  @override
  String get setDoneColumn => 'Set as done column';

  @override
  String get unsetDoneColumn => 'Unset done column';

  @override
  String get setDoneColumnQuestion =>
      'This will be the board’s only done column. Its active cards will be marked complete, and cards moved here will be completed automatically.';

  @override
  String get unsetDoneColumnQuestion =>
      'Unset this done column? Cards already completed will remain completed.';

  @override
  String get deckNotifications => 'Deck notifications';

  @override
  String get notificationsUnavailable =>
      'This server does not support the notification list.';

  @override
  String get noDeckNotifications => 'No Deck notifications.';

  @override
  String get openInNextcloud => 'Open in Nextcloud';

  @override
  String get telemetryTitle => 'Diagnostics and usage';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get crashReporting => 'Error reporting';

  @override
  String get crashReportingDescription =>
      'Send technical errors without card contents, files or credentials.';

  @override
  String get usageAnalytics => 'Usage statistics';

  @override
  String get usageAnalyticsDescription =>
      'Send only predefined screen and action names.';

  @override
  String get telemetryUnavailable =>
      'This option is not available in this version.';

  @override
  String get telemetrySaveFailed => 'The setting could not be saved.';

  @override
  String get openCardLink => 'Open card link';

  @override
  String get cardLinkAddress => 'Nextcloud card link';

  @override
  String get invalidCardLink =>
      'This is not a valid HTTPS Nextcloud card link.';

  @override
  String get cardLinkAccountRequired => 'Add an account for this server';

  @override
  String get chooseCardLinkAccount => 'Choose an account to open the card';

  @override
  String get copyCardLink => 'Copy card link';

  @override
  String get copyComment => 'Copy comment text';

  @override
  String get commentCopied => 'Comment text copied.';

  @override
  String get cardLinkCopied => 'Card link copied.';

  @override
  String get localSearchMode => 'Saved cards';

  @override
  String get serverSearchMode => 'Search on server';

  @override
  String get serverSearchNotice =>
      'Server results do not include changes that have not been sent yet.';

  @override
  String get serverMyTasksNotice =>
      'The server overview includes active, unfinished cards assigned to you.';

  @override
  String get serverSearchLimited =>
      'The server returned the first 200 results. Refine your search.';

  @override
  String get openingCardLink => 'Opening card…';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'Use device setting';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get languageCzech => 'Čeština';

  @override
  String get languageEnglish => 'English';

  @override
  String get appVersion => 'App version';

  @override
  String get versionUnavailable => 'The app version could not be read.';

  @override
  String get preferenceStorageError =>
      'Settings could not be loaded or saved. Changes currently apply only to this app session.';

  @override
  String versionBuild(String version, String build) {
    return '$version ($build)';
  }

  @override
  String get copyBoard => 'Copy board';

  @override
  String get copyBoardDescription =>
      'Copy the current server version, including columns, label definitions and sharing. Deck 1.19 does not copy comments, attachments, start dates or card colors.';

  @override
  String get copyBoardWithCards => 'Include cards';

  @override
  String get copyBoardWithAssignments => 'Keep card assignments';

  @override
  String get copyBoardWithLabels => 'Keep labels on cards';

  @override
  String get copyBoardWithDueDate => 'Keep due dates';

  @override
  String get copyBoardMoveCards => 'Move all cards to the first column';

  @override
  String get copyBoardRestoreArchived => 'Restore archived cards';

  @override
  String get copyBoardInBrowser =>
      'This server provides board copying in the web interface. Open the board in Nextcloud to make a copy.';

  @override
  String get importInNextcloud => 'Import in Nextcloud';

  @override
  String get importInNextcloudHint =>
      'Open Deck in your browser to use the import sources supported by your server, such as Trello.';

  @override
  String get pendingBoardDecision =>
      'Resolve the pending changes on this board first.';

  @override
  String get boardView => 'Board view';

  @override
  String get boardColumns => 'Columns';

  @override
  String get boardList => 'List';

  @override
  String get dropCardHere => 'Drop card here';

  @override
  String boardMovePositionHint(int maximum) {
    return 'Position from 0 to $maximum';
  }

  @override
  String invalidBoardMovePosition(int maximum) {
    return 'Choose a position from 0 to $maximum.';
  }

  @override
  String get filterCards => 'Filter cards';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get allCards => 'All cards';

  @override
  String get openCards => 'Not completed';

  @override
  String get upcomingTasks => 'Upcoming';

  @override
  String get boardNoMatchingCards => 'No cards match these filters.';

  @override
  String get dueSoon => 'Due soon';

  @override
  String get boardOptions => 'Board options';

  @override
  String get applyFilters => 'Apply filters';

  @override
  String get anyMember => 'Anyone';

  @override
  String get anyLabel => 'Any label';

  @override
  String get noAssignee => 'Unassigned';

  @override
  String get destinationBoard => 'Board';

  @override
  String get quickAddHint => 'What needs to be done?';

  @override
  String get quickAddDetails => 'Add details';

  @override
  String get noWritableBoards => 'There is no board you can add cards to.';

  @override
  String get noWritableColumns => 'Create a column on this board first.';

  @override
  String get moveToTop => 'At the beginning';

  @override
  String get moveToBottom => 'At the end';

  @override
  String get moveBefore => 'Before a card';

  @override
  String get moveAfter => 'After a card';

  @override
  String get moveRelativeCard => 'Card';

  @override
  String get invalidDestination =>
      'This destination has changed or is no longer available. Refresh and choose again.';

  @override
  String get quickAddSavedDraft =>
      'Your text is saved in Drafts until you add the card.';

  @override
  String quickAddAccount(String account, String server) {
    return 'Account: $account ($server)';
  }

  @override
  String get chooseShareAccount => 'Choose an account for the new card';

  @override
  String get sharedTextEmpty => 'There was no text to add as a card.';

  @override
  String get sharedTextSavedDraft =>
      'Shared text is saved in Drafts. Sign in to add it as a card.';

  @override
  String get colorDefault => 'No custom color';

  @override
  String get colorCustom => 'Custom color';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorRed => 'Red';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorGray => 'Gray';

  @override
  String get useLocalChanges => 'Use my changes';

  @override
  String get keepServerVersion => 'Keep the server version';

  @override
  String get allChanges => 'All changes';

  @override
  String get needsDecision => 'Needs a decision';

  @override
  String get boardSearchHint => 'Find a board';

  @override
  String get unnamedLabel => 'Unnamed label';

  @override
  String get keepPosition => 'Keep the current position';

  @override
  String get afterColumn => 'After a column';

  @override
  String get pendingWaiting => 'Waiting to sync';

  @override
  String get pendingConflicts => 'Conflicts';

  @override
  String get pendingUncertain => 'Check the result';

  @override
  String get pendingEmptyGroup => 'There are no changes in this group.';

  @override
  String get pendingConflictHelp =>
      'Compare your changes with the server version before choosing what to keep.';

  @override
  String get confirmUseLocalChanges =>
      'Your changes will be sent again after checking the current server version.';

  @override
  String get confirmKeepServerVersion =>
      'Only this local change will be discarded. Nothing will be changed on the server.';

  @override
  String get changedField => 'Different values';

  @override
  String get draftLocationUnavailable =>
      'Original location is no longer available';

  @override
  String get settingsPersonalization => 'Appearance and language';

  @override
  String get settingsData => 'Account and data';

  @override
  String get telemetryChoiceHelp =>
      'You can change these options at any time. They do not affect your boards or tasks.';

  @override
  String get selectionDone => 'Done';

  @override
  String get telemetryEnabledByDefault =>
      'Available options are on by default. You can turn each one off.';

  @override
  String get noMatchingBoards => 'No boards match this filter.';

  @override
  String get permissionAllowed => 'Allowed';

  @override
  String get permissionNotAllowed => 'Not allowed';

  @override
  String get localSaveError =>
      'Changes could not be saved on this device. Try again.';

  @override
  String get writePermissionError =>
      'You do not have permission to save this change.';

  @override
  String get transferCardHint =>
      'The card keeps its comments and attachments. Labels are matched with the destination board.';

  @override
  String get transferAccessHint =>
      'Who can see the card is determined by sharing on the destination board.';

  @override
  String transferLabelLoss(String labels) {
    return 'These labels are not available in the destination board and will be removed: $labels';
  }

  @override
  String get transferToDone => 'This column marks incoming cards complete.';

  @override
  String get transferFromDone =>
      'Moving out of a done column marks the card incomplete.';

  @override
  String get transferPositionPending =>
      'The card has moved. Its position is still being confirmed.';

  @override
  String get confirmTransferRetry =>
      'Check the card on the server before sending the remaining change again.';

  @override
  String get cardArchivedError =>
      'This card is archived. Restore it before editing.';

  @override
  String get commentUnavailable =>
      'This comment is no longer available. Refresh the comments.';

  @override
  String get itemUnavailable =>
      'This item is no longer available. Refresh and check its current state.';

  @override
  String get attachmentMissingError =>
      'This attachment is no longer available. Refresh the attachments.';

  @override
  String get unsupportedOperation => 'This action is not available here.';

  @override
  String get attachmentStorageError =>
      'The attachment could not be read or saved on this device. Try again.';

  @override
  String get noSavedContent => 'No content is saved on this device yet.';

  @override
  String get localReadError =>
      'Saved data could not be read on this device. Try opening this screen again.';

  @override
  String get removeAccountAccessWarning =>
      'The app password used for this account will be revoked. Other apps or devices using the same password will lose access too.';

  @override
  String get selectCard => 'Select card';

  @override
  String get cancelSelection => 'Cancel selection';

  @override
  String selectedCardsCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get moveSelectedCards => 'Move selected cards';

  @override
  String get archiveSelectedCards => 'Archive selected cards';

  @override
  String get unarchiveSelectedCards => 'Restore selected cards from archive';

  @override
  String get selectAllVisibleCards => 'Select all shown cards';

  @override
  String bulkAllQueued(int count) {
    return '$count changes saved on this device. They await server confirmation.';
  }

  @override
  String get bulkResultTitle => 'Result per card';

  @override
  String bulkSummary(int queued, int failed, int blocked) {
    return 'Saved on this device: $queued, failed: $failed, no permission: $blocked.';
  }

  @override
  String get bulkStatusQueued => 'Saved on this device, awaiting server';

  @override
  String bulkStatusFailed(String error) {
    return 'Not saved: $error';
  }

  @override
  String get bulkStatusBlocked => 'No permission, nothing changed';

  @override
  String bulkRetryFailed(int count) {
    return 'Retry failed ($count)';
  }

  @override
  String get bulkSelectionKept => 'Cards that were not saved stay selected.';

  @override
  String get addChecklistItems => 'Add checklist items';

  @override
  String get addChecklistItemsHelp => 'One item per line';

  @override
  String get addItems => 'Add';

  @override
  String get hideCompletedItems => 'Hide completed';

  @override
  String get allItemsCompleted => 'All items are completed';

  @override
  String get syncConflict => 'Conflict';

  @override
  String pendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unsent changes',
      one: '$count unsent change',
    );
    return '$_temp0';
  }

  @override
  String get invalidAttachmentError =>
      'This file cannot be uploaded. Choose it again.';

  @override
  String get identityMismatchError =>
      'The server answered for a different item than this change targets. Discard the change or try again.';

  @override
  String get noArchivedCards => 'There are no archived cards in this column.';

  @override
  String get noServerMatches => 'The server found no cards for this search.';

  @override
  String get noCardsYet => 'There are no cards on your boards yet.';

  @override
  String get myTasksEmpty => 'No open cards are assigned to you.';

  @override
  String get taskListView => 'List';

  @override
  String get taskCalendarView => 'Calendar';

  @override
  String get calendarPreviousMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String calendarIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cards of $count boards are not saved on this device yet, so the calendar may be incomplete. Open the boards to load them.',
      one:
          'Cards of 1 board are not saved on this device yet, so the calendar may be incomplete. Open the board to load them.',
    );
    return '$_temp0';
  }

  @override
  String searchIncomplete(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Cards of $count boards are not saved on this device yet, so this list may be incomplete.',
      one:
          'Cards of 1 board are not saved on this device yet, so this list may be incomplete.',
    );
    return '$_temp0';
  }

  @override
  String get loadCards => 'Load cards';

  @override
  String get calendarNothingOnDay => 'Nothing on this day.';

  @override
  String calendarDayLabel(String date, String summary) {
    return '$date: $summary';
  }

  @override
  String calendarDaySummary(int start, int due, int done) {
    return '$start start, $due due, $done completed';
  }

  @override
  String get calendarDayEmpty => 'no dates';

  @override
  String get colorPickCustom => 'Custom color…';

  @override
  String get colorPickerHint =>
      'Pick a color with the sliders. The text color is chosen automatically.';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorLightness => 'Lightness';

  @override
  String colorIncrease(String name) {
    return 'Increase $name';
  }

  @override
  String colorDecrease(String name) {
    return 'Decrease $name';
  }

  @override
  String get colorHexToggle => 'Enter exact code';

  @override
  String get colorHexLabel => 'Code (6 characters 0-9, A-F)';

  @override
  String get colorHexInvalid => 'Enter exactly 6 characters 0-9 or A-F.';

  @override
  String colorContrast(String ratio) {
    return 'Text contrast $ratio:1';
  }

  @override
  String get colorSample => 'Sample text';

  @override
  String get colorApply => 'Use this color';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';

  @override
  String colorDark(String name) {
    return 'dark $name';
  }

  @override
  String colorLight(String name) {
    return 'light $name';
  }

  @override
  String colorCustomNamed(String description) {
    return 'Custom color: $description';
  }

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String get dueNextWeek => 'Next week';

  @override
  String get dueThisWeek => 'This week';

  @override
  String get dueLater => 'Later';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatList => 'List';

  @override
  String get formatChecklist => 'Checklist';

  @override
  String get formatLink => 'Link';

  @override
  String get loginTagline => 'Tasks and boards from your Nextcloud';

  @override
  String get loginNote =>
      'You sign in on your server in the browser. The app password stays on this device.';

  @override
  String get backgroundSyncTitle => 'Background sync';

  @override
  String get backgroundSyncInterval => 'Interval';

  @override
  String get backgroundSyncOff => 'Off';

  @override
  String get backgroundSync15Minutes => '15 minutes';

  @override
  String get backgroundSync1Hour => '1 hour';

  @override
  String get backgroundSync6Hours => '6 hours';

  @override
  String get backgroundSyncWifiOnly => 'Wi-Fi only';

  @override
  String get backgroundSyncWifiOnlyHint =>
      'Skip runs on mobile data and metered networks.';

  @override
  String get backgroundSyncHelpAndroid =>
      'Sends queued changes and refreshes the local copy while the app is closed. Android chooses the exact time, and battery saver can delay it.';

  @override
  String get backgroundSyncHelpIos =>
      'iOS decides when to run this and may skip runs, especially if you rarely open the app or Low Power Mode is on. The interval is only the earliest start. Open the app to be sure changes are sent.';

  @override
  String get reminderTitle => 'Due date reminders';

  @override
  String get reminderSwitch => 'Remind me of due cards';

  @override
  String get reminderSwitchHint =>
      'For cards assigned to you, from the copy saved on this device.';

  @override
  String get reminderLead => 'When';

  @override
  String get reminderLeadAtDue => 'At the due time';

  @override
  String get reminderLead15Minutes => '15 minutes before';

  @override
  String get reminderLead1Hour => '1 hour before';

  @override
  String get reminderLead1Day => '1 day before';

  @override
  String get reminderDenied =>
      'Notifications are blocked. Allow them for OwnDeck in the system settings.';

  @override
  String get reminderHelpAndroid =>
      'Android may deliver a reminder a few minutes late while the phone is idle. Cards you finish, move to another date or lose access to are removed from the schedule.';

  @override
  String get reminderHelpIos =>
      'iOS keeps at most 64 scheduled notifications, so the 60 nearest are scheduled; later ones are added when the app opens or refreshes in the background. Cards you finish, move to another date or lose access to are removed from the schedule.';

  @override
  String get reminderChannel => 'Card due dates';

  @override
  String reminderBody(String when, String board) {
    return 'Due $when · $board';
  }

  @override
  String get syncTitle => 'Synchronization';

  @override
  String syncLastTime(String time) {
    return 'Last sync: $time';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncRunning => 'Synchronizing...';
}
