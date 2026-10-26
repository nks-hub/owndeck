import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('cs'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OwnDeck'**
  String get appTitle;

  /// No description provided for @connectTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Nextcloud'**
  String get connectTitle;

  /// No description provided for @connectDescription.
  ///
  /// In en, this message translates to:
  /// **'Sign in through your server in the browser. Your account password stays on the server.'**
  String get connectDescription;

  /// No description provided for @serverLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverLabel;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get connect;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in through your browser.'**
  String get waiting;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @boards.
  ///
  /// In en, this message translates to:
  /// **'Boards'**
  String get boards;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @noBoards.
  ///
  /// In en, this message translates to:
  /// **'No boards yet'**
  String get noBoards;

  /// No description provided for @noBoardsHint.
  ///
  /// In en, this message translates to:
  /// **'This account has no active boards available.'**
  String get noBoardsHint;

  /// No description provided for @emptyStack.
  ///
  /// In en, this message translates to:
  /// **'There are no cards in this column.'**
  String get emptyStack;

  /// No description provided for @noStacks.
  ///
  /// In en, this message translates to:
  /// **'This board has no columns.'**
  String get noStacks;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get readOnly;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @storageError.
  ///
  /// In en, this message translates to:
  /// **'Secure storage is unavailable. Unlock the device and try again.'**
  String get storageError;

  /// No description provided for @invalidServer.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid HTTPS Nextcloud address.'**
  String get invalidServer;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in could not be completed. Start a new attempt.'**
  String get loginError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'The server is unavailable. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Add the same account again.'**
  String get authError;

  /// No description provided for @permissionError.
  ///
  /// In en, this message translates to:
  /// **'You no longer have access to this content.'**
  String get permissionError;

  /// No description provided for @deckError.
  ///
  /// In en, this message translates to:
  /// **'Deck with API 1.1 is not available on this server.'**
  String get deckError;

  /// No description provided for @certError.
  ///
  /// In en, this message translates to:
  /// **'The server certificate is not trusted. Check the address and server configuration.'**
  String get certError;

  /// No description provided for @browserError.
  ///
  /// In en, this message translates to:
  /// **'The browser could not be opened.'**
  String get browserError;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'The content could not be loaded.'**
  String get loadError;

  /// No description provided for @removeAccount.
  ///
  /// In en, this message translates to:
  /// **'Remove account'**
  String get removeAccount;

  /// No description provided for @removeAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this account and all its local data from this device? Server data will be preserved.'**
  String get removeAccountQuestion;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @revocationFailed.
  ///
  /// In en, this message translates to:
  /// **'The account was removed from this device. Server-side revocation could not be confirmed; check connected apps in Nextcloud settings.'**
  String get revocationFailed;

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'Showing the saved copy.'**
  String get cachedData;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get syncing;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @editCard.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get editCard;

  /// No description provided for @cardTitle.
  ///
  /// In en, this message translates to:
  /// **'Card title'**
  String get cardTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savedLocally.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. The change is awaiting server confirmation.'**
  String get savedLocally;

  /// No description provided for @invalidTitle.
  ///
  /// In en, this message translates to:
  /// **'The title must contain 1 to 255 characters.'**
  String get invalidTitle;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get pendingChanges;

  /// No description provided for @noPending.
  ///
  /// In en, this message translates to:
  /// **'All changes have been confirmed.'**
  String get noPending;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get sending;

  /// No description provided for @conflict.
  ///
  /// In en, this message translates to:
  /// **'The same field changed on the server.'**
  String get conflict;

  /// No description provided for @uncertain.
  ///
  /// In en, this message translates to:
  /// **'The server may have accepted this change. Check the server before retrying.'**
  String get uncertain;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'This change cannot be sent. Check access and content.'**
  String get blocked;

  /// No description provided for @retryWrite.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get retryWrite;

  /// No description provided for @discardWrite.
  ///
  /// In en, this message translates to:
  /// **'Discard local change'**
  String get discardWrite;

  /// No description provided for @localVersion.
  ///
  /// In en, this message translates to:
  /// **'Local version'**
  String get localVersion;

  /// No description provided for @serverVersion.
  ///
  /// In en, this message translates to:
  /// **'Server version'**
  String get serverVersion;

  /// No description provided for @pendingValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get pendingValueNotSet;

  /// No description provided for @pendingValueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Value unavailable'**
  String get pendingValueUnavailable;

  /// No description provided for @pendingNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get pendingNotCompleted;

  /// No description provided for @pendingCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get pendingCompletion;

  /// No description provided for @confirmRetry.
  ///
  /// In en, this message translates to:
  /// **'Retrying may create a duplicate item. Send again?'**
  String get confirmRetry;

  /// No description provided for @confirmDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard this local change? This will not undo any write already applied on the server.'**
  String get confirmDiscard;

  /// No description provided for @pendingDecision.
  ///
  /// In en, this message translates to:
  /// **'This card has a sending or unresolved change. Open Pending changes first.'**
  String get pendingDecision;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Leave unsaved changes?'**
  String get unsavedChanges;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'The draft is saved on this device. Tap Save to send it to the server.'**
  String get draftSaved;

  /// No description provided for @savingDraft.
  ///
  /// In en, this message translates to:
  /// **'Saving draft…'**
  String get savingDraft;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @noDrafts.
  ///
  /// In en, this message translates to:
  /// **'You have no card drafts.'**
  String get noDrafts;

  /// No description provided for @discardDraft.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get discardDraft;

  /// No description provided for @discardDraftQuestion.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this draft text from this device?'**
  String get discardDraftQuestion;

  /// No description provided for @addBoard.
  ///
  /// In en, this message translates to:
  /// **'Add board'**
  String get addBoard;

  /// No description provided for @editBoard.
  ///
  /// In en, this message translates to:
  /// **'Edit board'**
  String get editBoard;

  /// No description provided for @addStack.
  ///
  /// In en, this message translates to:
  /// **'Add column'**
  String get addStack;

  /// No description provided for @editStack.
  ///
  /// In en, this message translates to:
  /// **'Edit column'**
  String get editStack;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @deleteBoard.
  ///
  /// In en, this message translates to:
  /// **'Delete board'**
  String get deleteBoard;

  /// No description provided for @deleteStack.
  ///
  /// In en, this message translates to:
  /// **'Delete column'**
  String get deleteStack;

  /// No description provided for @deleteStructureQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete the selected item and its contents on the server?'**
  String get deleteStructureQuestion;

  /// No description provided for @activeBoards.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBoards;

  /// No description provided for @archivedBoards.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archivedBoards;

  /// No description provided for @deletedBoards.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedBoards;

  /// No description provided for @restoreBoard.
  ///
  /// In en, this message translates to:
  /// **'Restore board'**
  String get restoreBoard;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'The name must contain 1 to 100 characters.'**
  String get invalidName;

  /// No description provided for @invalidColor.
  ///
  /// In en, this message translates to:
  /// **'Choose a color.'**
  String get invalidColor;

  /// No description provided for @invalidPosition.
  ///
  /// In en, this message translates to:
  /// **'Choose where to place the item.'**
  String get invalidPosition;

  /// No description provided for @boardActions.
  ///
  /// In en, this message translates to:
  /// **'Board actions'**
  String get boardActions;

  /// No description provided for @stackActions.
  ///
  /// In en, this message translates to:
  /// **'Column actions'**
  String get stackActions;

  /// No description provided for @dependencyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The parent board or column was discarded. Your local content has been preserved.'**
  String get dependencyUnavailable;

  /// No description provided for @awaitingReadback.
  ///
  /// In en, this message translates to:
  /// **'The server accepted this change. Waiting to read the result.'**
  String get awaitingReadback;

  /// No description provided for @moveCard.
  ///
  /// In en, this message translates to:
  /// **'Move card'**
  String get moveCard;

  /// No description provided for @destinationColumn.
  ///
  /// In en, this message translates to:
  /// **'Destination column'**
  String get destinationColumn;

  /// No description provided for @deleteCard.
  ///
  /// In en, this message translates to:
  /// **'Delete card'**
  String get deleteCard;

  /// No description provided for @deleteCardQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this card from the server?'**
  String get deleteCardQuestion;

  /// No description provided for @cardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This card is no longer available. Unsent changes remain in Pending changes.'**
  String get cardUnavailable;

  /// No description provided for @labels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labels;

  /// No description provided for @assignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees'**
  String get assignees;

  /// No description provided for @noLabels.
  ///
  /// In en, this message translates to:
  /// **'This board has no labels.'**
  String get noLabels;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users are available on this board.'**
  String get noUsers;

  /// No description provided for @cardActions.
  ///
  /// In en, this message translates to:
  /// **'Card actions'**
  String get cardActions;

  /// No description provided for @externalImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to open this image in your browser.'**
  String get externalImage;

  /// No description provided for @archivedCards.
  ///
  /// In en, this message translates to:
  /// **'Archived cards'**
  String get archivedCards;

  /// No description provided for @activeCards.
  ///
  /// In en, this message translates to:
  /// **'Active cards'**
  String get activeCards;

  /// No description provided for @reorderCard.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag the card; Move is also available in the card menu.'**
  String get reorderCard;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get addComment;

  /// No description provided for @editComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get editComment;

  /// No description provided for @deleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteComment;

  /// No description provided for @deleteCommentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment from the server?'**
  String get deleteCommentQuestion;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to comment'**
  String get replyTo;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noComments;

  /// No description provided for @commentMessage.
  ///
  /// In en, this message translates to:
  /// **'Comment text'**
  String get commentMessage;

  /// No description provided for @invalidComment.
  ///
  /// In en, this message translates to:
  /// **'A comment must contain 1 to 1,000 characters.'**
  String get invalidComment;

  /// No description provided for @commentDraft.
  ///
  /// In en, this message translates to:
  /// **'Comment draft'**
  String get commentDraft;

  /// No description provided for @localDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'The draft is saved on this device.'**
  String get localDraftSaved;

  /// No description provided for @sendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get sendComment;

  /// No description provided for @identityUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reconnect first so the app can verify your user ID. Your draft is preserved.'**
  String get identityUnavailable;

  /// No description provided for @sharing.
  ///
  /// In en, this message translates to:
  /// **'Board sharing'**
  String get sharing;

  /// No description provided for @findRecipient.
  ///
  /// In en, this message translates to:
  /// **'Find a user, group, or team'**
  String get findRecipient;

  /// No description provided for @noRecipients.
  ///
  /// In en, this message translates to:
  /// **'No matching recipients.'**
  String get noRecipients;

  /// No description provided for @addShare.
  ///
  /// In en, this message translates to:
  /// **'Add share'**
  String get addShare;

  /// No description provided for @editShare.
  ///
  /// In en, this message translates to:
  /// **'Edit permissions'**
  String get editShare;

  /// No description provided for @removeShare.
  ///
  /// In en, this message translates to:
  /// **'Remove share'**
  String get removeShare;

  /// No description provided for @removeShareQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this recipient’s access to the board?'**
  String get removeShareQuestion;

  /// No description provided for @permissionRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get permissionRead;

  /// No description provided for @permissionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get permissionEdit;

  /// No description provided for @permissionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get permissionShare;

  /// No description provided for @permissionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get permissionManage;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @externalRecipient.
  ///
  /// In en, this message translates to:
  /// **'External recipient'**
  String get externalRecipient;

  /// No description provided for @noShares.
  ///
  /// In en, this message translates to:
  /// **'This board is not shared yet.'**
  String get noShares;

  /// No description provided for @manageLabels.
  ///
  /// In en, this message translates to:
  /// **'Manage labels'**
  String get manageLabels;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add label'**
  String get addLabel;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete label'**
  String get deleteLabel;

  /// No description provided for @deleteLabelQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this label from the board and all its cards?'**
  String get deleteLabelQuestion;

  /// No description provided for @alreadyShared.
  ///
  /// In en, this message translates to:
  /// **'This recipient already has access. Refresh the board and edit the existing share.'**
  String get alreadyShared;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @cardColor.
  ///
  /// In en, this message translates to:
  /// **'Card color'**
  String get cardColor;

  /// No description provided for @optionalColor.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no custom color.'**
  String get optionalColor;

  /// No description provided for @invalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'The start date must not be after the due date.'**
  String get invalidDateRange;

  /// No description provided for @certificateFingerprintLabel.
  ///
  /// In en, this message translates to:
  /// **'SHA-256 fingerprint'**
  String get certificateFingerprintLabel;

  /// No description provided for @scanLoginCodeCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device has no camera that can read a login code.'**
  String get scanLoginCodeCameraUnavailable;

  /// No description provided for @secureTitle.
  ///
  /// In en, this message translates to:
  /// **'Credentials stay on this device'**
  String get secureTitle;

  /// No description provided for @serverAddressHint.
  ///
  /// In en, this message translates to:
  /// **'cloud.example.com'**
  String get serverAddressHint;

  /// No description provided for @reauthenticateAccountMismatch.
  ///
  /// In en, this message translates to:
  /// **'Sign in with the same account. The stored account was not changed.'**
  String get reauthenticateAccountMismatch;

  /// No description provided for @scanLoginCodeCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access is turned off. Allow it in system settings to scan a login code.'**
  String get scanLoginCodeCameraDenied;

  /// No description provided for @waitingForLogin.
  ///
  /// In en, this message translates to:
  /// **'Finish signing in in your browser'**
  String get waitingForLogin;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @certificateChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Server certificate changed'**
  String get certificateChangedTitle;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. No account data was changed.'**
  String get unexpectedError;

  /// No description provided for @openingLogin.
  ///
  /// In en, this message translates to:
  /// **'Opening secure sign-in…'**
  String get openingLogin;

  /// No description provided for @serverMaintenance.
  ///
  /// In en, this message translates to:
  /// **'This server is currently in maintenance mode.'**
  String get serverMaintenance;

  /// No description provided for @reauthenticateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to this account again'**
  String get reauthenticateAccountTitle;

  /// No description provided for @certificateTrustAction.
  ///
  /// In en, this message translates to:
  /// **'Trust and continue'**
  String get certificateTrustAction;

  /// No description provided for @scannedLoginRejected.
  ///
  /// In en, this message translates to:
  /// **'The scanned login code could not be used. Create a new one on the server.'**
  String get scannedLoginRejected;

  /// No description provided for @browserUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The sign-in page could not be opened.'**
  String get browserUnavailable;

  /// No description provided for @multiServerBody.
  ///
  /// In en, this message translates to:
  /// **'Add personal and work accounts without rebuilding the app or sharing their data.'**
  String get multiServerBody;

  /// No description provided for @serverNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Nextcloud is not installed on this server yet.'**
  String get serverNotInstalled;

  /// No description provided for @checkingServer.
  ///
  /// In en, this message translates to:
  /// **'Checking the server…'**
  String get checkingServer;

  /// No description provided for @waitingForLoginBody.
  ///
  /// In en, this message translates to:
  /// **'This screen will continue automatically after Nextcloud approves the app.'**
  String get waitingForLoginBody;

  /// No description provided for @serverUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The server could not be reached. Check the address and your connection.'**
  String get serverUnavailable;

  /// No description provided for @secureBody.
  ///
  /// In en, this message translates to:
  /// **'App passwords are stored in the system Keychain or Keystore, never in the card database.'**
  String get secureBody;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your boards, one app'**
  String get onboardingTitle;

  /// No description provided for @certificateChangedBody.
  ///
  /// In en, this message translates to:
  /// **'{host} now presents a different certificate than the one this account trusts. If you replaced the certificate yourself, remove the account and add it again.'**
  String certificateChangedBody(String host);

  /// Button that opens the camera to scan a Nextcloud login QR code
  ///
  /// In en, this message translates to:
  /// **'Scan a login code'**
  String get scanLoginCode;

  /// No description provided for @loginTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The sign-in request expired. Start it again.'**
  String get loginTimedOut;

  /// No description provided for @scanLoginCodeUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This is not a Nextcloud login code.'**
  String get scanLoginCodeUnreadable;

  /// No description provided for @reauthenticateAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get reauthenticateAccountAction;

  /// No description provided for @multiServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Built for multiple servers'**
  String get multiServerTitle;

  /// No description provided for @scanLoginCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code your server shows under Settings, Security, Create new app password.'**
  String get scanLoginCodeHint;

  /// No description provided for @invalidResponse.
  ///
  /// In en, this message translates to:
  /// **'The server returned a response this app cannot safely use.'**
  String get invalidResponse;

  /// No description provided for @certificateUnverifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unverified server certificate'**
  String get certificateUnverifiedTitle;

  /// No description provided for @certificateUnverifiedBody.
  ///
  /// In en, this message translates to:
  /// **'{host} presented a certificate this device cannot verify. Continue only if the fingerprint below is the one your server shows.'**
  String certificateUnverifiedBody(String host);

  /// No description provided for @localPersistenceFailed.
  ///
  /// In en, this message translates to:
  /// **'The account could not be stored securely on this device.'**
  String get localPersistenceFailed;

  /// No description provided for @serverUpgrade.
  ///
  /// In en, this message translates to:
  /// **'The server must finish its database upgrade first.'**
  String get serverUpgrade;

  /// No description provided for @addServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Nextcloud server'**
  String get addServerTitle;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openAppSettings;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'Connect any supported Nextcloud server. Accounts, their stored data and background work stay strictly separated.'**
  String get onboardingBody;

  /// No description provided for @serverAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddressLabel;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFile;

  /// No description provided for @linkCloudFile.
  ///
  /// In en, this message translates to:
  /// **'Attach from Nextcloud'**
  String get linkCloudFile;

  /// No description provided for @noAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments yet.'**
  String get noAttachments;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @saveFile.
  ///
  /// In en, this message translates to:
  /// **'Save file'**
  String get saveFile;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @restoreAttachment.
  ///
  /// In en, this message translates to:
  /// **'Restore attachment'**
  String get restoreAttachment;

  /// No description provided for @removeLinkedFileQuestion.
  ///
  /// In en, this message translates to:
  /// **'The file will be detached from this card. It will remain in Nextcloud.'**
  String get removeLinkedFileQuestion;

  /// No description provided for @removeLegacyFileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove this attachment? It can be restored for a limited time before the server permanently deletes it.'**
  String get removeLegacyFileQuestion;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file exceeds 64 MiB. Choose a smaller file.'**
  String get attachmentTooLarge;

  /// No description provided for @attachmentFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be processed. Try again.'**
  String get attachmentFailed;

  /// No description provided for @unsupportedAttachment.
  ///
  /// In en, this message translates to:
  /// **'This attachment type cannot be opened yet.'**
  String get unsupportedAttachment;

  /// No description provided for @offlineAttachment.
  ///
  /// In en, this message translates to:
  /// **'Using a previously downloaded copy of the file.'**
  String get offlineAttachment;

  /// No description provided for @chooseCloudFile.
  ///
  /// In en, this message translates to:
  /// **'Choose a Nextcloud file'**
  String get chooseCloudFile;

  /// No description provided for @fileNotShareable.
  ///
  /// In en, this message translates to:
  /// **'You cannot share this file.'**
  String get fileNotShareable;

  /// No description provided for @noCloudFiles.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty.'**
  String get noCloudFiles;

  /// No description provided for @parentFolder.
  ///
  /// In en, this message translates to:
  /// **'Parent folder'**
  String get parentFolder;

  /// No description provided for @fileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved.'**
  String get fileSaved;

  /// No description provided for @fileOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be opened. You can save it and open it in another app.'**
  String get fileOpenFailed;

  /// No description provided for @deletedAttachment.
  ///
  /// In en, this message translates to:
  /// **'Removed attachment'**
  String get deletedAttachment;

  /// No description provided for @fileAttachment.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileAttachment;

  /// No description provided for @searchCards.
  ///
  /// In en, this message translates to:
  /// **'Search cards'**
  String get searchCards;

  /// No description provided for @searchCardsHint.
  ///
  /// In en, this message translates to:
  /// **'Title, description or label'**
  String get searchCardsHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get myTasks;

  /// No description provided for @localSearchNotice.
  ///
  /// In en, this message translates to:
  /// **'Only data saved on this device is searched. Open a board to load its cards.'**
  String get localSearchNotice;

  /// No description provided for @includeArchived.
  ///
  /// In en, this message translates to:
  /// **'Include archived'**
  String get includeArchived;

  /// No description provided for @includeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Include completed'**
  String get includeCompleted;

  /// No description provided for @anyDueDate.
  ///
  /// In en, this message translates to:
  /// **'Any due date'**
  String get anyDueDate;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// No description provided for @overdueTasks.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueTasks;

  /// No description provided for @withoutDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get withoutDueDate;

  /// No description provided for @noMatchingCards.
  ///
  /// In en, this message translates to:
  /// **'No saved cards match the search and filters.'**
  String get noMatchingCards;

  /// No description provided for @accountSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This account is no longer available.'**
  String get accountSearchUnavailable;

  /// No description provided for @myTasksIdentityRequired.
  ///
  /// In en, this message translates to:
  /// **'My tasks will be available after sync verifies your user identity.'**
  String get myTasksIdentityRequired;

  /// No description provided for @rateLimited.
  ///
  /// In en, this message translates to:
  /// **'The server requested a pause. Sync will retry later.'**
  String get rateLimited;

  /// No description provided for @copyCard.
  ///
  /// In en, this message translates to:
  /// **'Copy card'**
  String get copyCard;

  /// No description provided for @copyCardDescription.
  ///
  /// In en, this message translates to:
  /// **'The copy includes the title, description, labels and available assignments. Dates, comments and attachments are not copied.'**
  String get copyCardDescription;

  /// No description provided for @copyDestinationBoard.
  ///
  /// In en, this message translates to:
  /// **'Destination board'**
  String get copyDestinationBoard;

  /// No description provided for @noCopyDestination.
  ///
  /// In en, this message translates to:
  /// **'No writable board is available.'**
  String get noCopyDestination;

  /// No description provided for @linkedCards.
  ///
  /// In en, this message translates to:
  /// **'Linked cards'**
  String get linkedCards;

  /// No description provided for @addCardLink.
  ///
  /// In en, this message translates to:
  /// **'Link a card'**
  String get addCardLink;

  /// No description provided for @removeCardLink.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get removeCardLink;

  /// No description provided for @noLinkedCards.
  ///
  /// In en, this message translates to:
  /// **'This card has no links yet.'**
  String get noLinkedCards;

  /// No description provided for @linkedCardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A linked card is not available in stored data.'**
  String get linkedCardUnavailable;

  /// No description provided for @cardLinksDescription.
  ///
  /// In en, this message translates to:
  /// **'Links point to related cards. They do not block completion.'**
  String get cardLinksDescription;

  /// No description provided for @cardLinkCachedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only cards stored on this device are listed.'**
  String get cardLinkCachedOnly;

  /// No description provided for @noLinkCandidates.
  ///
  /// In en, this message translates to:
  /// **'No other stored cards match the search.'**
  String get noLinkCandidates;

  /// No description provided for @doneColumn.
  ///
  /// In en, this message translates to:
  /// **'Done column'**
  String get doneColumn;

  /// No description provided for @setDoneColumn.
  ///
  /// In en, this message translates to:
  /// **'Set as done column'**
  String get setDoneColumn;

  /// No description provided for @unsetDoneColumn.
  ///
  /// In en, this message translates to:
  /// **'Unset done column'**
  String get unsetDoneColumn;

  /// No description provided for @setDoneColumnQuestion.
  ///
  /// In en, this message translates to:
  /// **'This will be the board’s only done column. Its active cards will be marked complete, and cards moved here will be completed automatically.'**
  String get setDoneColumnQuestion;

  /// No description provided for @unsetDoneColumnQuestion.
  ///
  /// In en, this message translates to:
  /// **'Unset this done column? Cards already completed will remain completed.'**
  String get unsetDoneColumnQuestion;

  /// No description provided for @deckNotifications.
  ///
  /// In en, this message translates to:
  /// **'Deck notifications'**
  String get deckNotifications;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This server does not support the notification list.'**
  String get notificationsUnavailable;

  /// No description provided for @noDeckNotifications.
  ///
  /// In en, this message translates to:
  /// **'No Deck notifications.'**
  String get noDeckNotifications;

  /// No description provided for @openInNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Open in Nextcloud'**
  String get openInNextcloud;

  /// No description provided for @telemetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics and usage'**
  String get telemetryTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @crashReporting.
  ///
  /// In en, this message translates to:
  /// **'Error reporting'**
  String get crashReporting;

  /// No description provided for @crashReportingDescription.
  ///
  /// In en, this message translates to:
  /// **'Send technical errors without card contents, files or credentials.'**
  String get crashReportingDescription;

  /// No description provided for @usageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics'**
  String get usageAnalytics;

  /// No description provided for @usageAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Send only predefined screen and action names.'**
  String get usageAnalyticsDescription;

  /// No description provided for @telemetryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This option is not available in this version.'**
  String get telemetryUnavailable;

  /// No description provided for @telemetrySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The setting could not be saved.'**
  String get telemetrySaveFailed;

  /// No description provided for @openCardLink.
  ///
  /// In en, this message translates to:
  /// **'Open card link'**
  String get openCardLink;

  /// No description provided for @cardLinkAddress.
  ///
  /// In en, this message translates to:
  /// **'Nextcloud card link'**
  String get cardLinkAddress;

  /// No description provided for @invalidCardLink.
  ///
  /// In en, this message translates to:
  /// **'This is not a valid HTTPS Nextcloud card link.'**
  String get invalidCardLink;

  /// No description provided for @cardLinkAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Add an account for this server'**
  String get cardLinkAccountRequired;

  /// No description provided for @chooseCardLinkAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose an account to open the card'**
  String get chooseCardLinkAccount;

  /// No description provided for @copyCardLink.
  ///
  /// In en, this message translates to:
  /// **'Copy card link'**
  String get copyCardLink;

  /// No description provided for @cardLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Card link copied.'**
  String get cardLinkCopied;

  /// No description provided for @localSearchMode.
  ///
  /// In en, this message translates to:
  /// **'Saved cards'**
  String get localSearchMode;

  /// No description provided for @serverSearchMode.
  ///
  /// In en, this message translates to:
  /// **'Search on server'**
  String get serverSearchMode;

  /// No description provided for @serverSearchNotice.
  ///
  /// In en, this message translates to:
  /// **'Server results do not include changes that have not been sent yet.'**
  String get serverSearchNotice;

  /// No description provided for @serverMyTasksNotice.
  ///
  /// In en, this message translates to:
  /// **'The server overview includes active, unfinished cards assigned to you.'**
  String get serverMyTasksNotice;

  /// No description provided for @serverSearchLimited.
  ///
  /// In en, this message translates to:
  /// **'The server returned the first 200 results. Refine your search.'**
  String get serverSearchLimited;

  /// No description provided for @openingCardLink.
  ///
  /// In en, this message translates to:
  /// **'Opening card…'**
  String get openingCardLink;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'Use device setting'**
  String get systemDefault;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @languageCzech.
  ///
  /// In en, this message translates to:
  /// **'Čeština'**
  String get languageCzech;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @versionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The app version could not be read.'**
  String get versionUnavailable;

  /// No description provided for @preferenceStorageError.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded or saved. Changes currently apply only to this app session.'**
  String get preferenceStorageError;

  /// No description provided for @versionBuild.
  ///
  /// In en, this message translates to:
  /// **'{version} ({build})'**
  String versionBuild(String version, String build);

  /// No description provided for @copyBoard.
  ///
  /// In en, this message translates to:
  /// **'Copy board'**
  String get copyBoard;

  /// No description provided for @copyBoardDescription.
  ///
  /// In en, this message translates to:
  /// **'Copy the current server version, including columns, label definitions and sharing. Deck 1.19 does not copy comments, attachments, start dates or card colors.'**
  String get copyBoardDescription;

  /// No description provided for @copyBoardWithCards.
  ///
  /// In en, this message translates to:
  /// **'Include cards'**
  String get copyBoardWithCards;

  /// No description provided for @copyBoardWithAssignments.
  ///
  /// In en, this message translates to:
  /// **'Keep card assignments'**
  String get copyBoardWithAssignments;

  /// No description provided for @copyBoardWithLabels.
  ///
  /// In en, this message translates to:
  /// **'Keep labels on cards'**
  String get copyBoardWithLabels;

  /// No description provided for @copyBoardWithDueDate.
  ///
  /// In en, this message translates to:
  /// **'Keep due dates'**
  String get copyBoardWithDueDate;

  /// No description provided for @copyBoardMoveCards.
  ///
  /// In en, this message translates to:
  /// **'Move all cards to the first column'**
  String get copyBoardMoveCards;

  /// No description provided for @copyBoardRestoreArchived.
  ///
  /// In en, this message translates to:
  /// **'Restore archived cards'**
  String get copyBoardRestoreArchived;

  /// No description provided for @copyBoardInBrowser.
  ///
  /// In en, this message translates to:
  /// **'This server provides board copying in the web interface. Open the board in Nextcloud to make a copy.'**
  String get copyBoardInBrowser;

  /// No description provided for @importInNextcloud.
  ///
  /// In en, this message translates to:
  /// **'Import in Nextcloud'**
  String get importInNextcloud;

  /// No description provided for @importInNextcloudHint.
  ///
  /// In en, this message translates to:
  /// **'Open Deck in your browser to use the import sources supported by your server, such as Trello.'**
  String get importInNextcloudHint;

  /// No description provided for @pendingBoardDecision.
  ///
  /// In en, this message translates to:
  /// **'Resolve the pending changes on this board first.'**
  String get pendingBoardDecision;

  /// No description provided for @boardView.
  ///
  /// In en, this message translates to:
  /// **'Board view'**
  String get boardView;

  /// No description provided for @boardColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get boardColumns;

  /// No description provided for @boardList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get boardList;

  /// No description provided for @dropCardHere.
  ///
  /// In en, this message translates to:
  /// **'Drop card here'**
  String get dropCardHere;

  /// No description provided for @boardMovePositionHint.
  ///
  /// In en, this message translates to:
  /// **'Position from 0 to {maximum}'**
  String boardMovePositionHint(int maximum);

  /// No description provided for @invalidBoardMovePosition.
  ///
  /// In en, this message translates to:
  /// **'Choose a position from 0 to {maximum}.'**
  String invalidBoardMovePosition(int maximum);

  /// No description provided for @filterCards.
  ///
  /// In en, this message translates to:
  /// **'Filter cards'**
  String get filterCards;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @allCards.
  ///
  /// In en, this message translates to:
  /// **'All cards'**
  String get allCards;

  /// No description provided for @openCards.
  ///
  /// In en, this message translates to:
  /// **'Not completed'**
  String get openCards;

  /// No description provided for @upcomingTasks.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTasks;

  /// No description provided for @boardNoMatchingCards.
  ///
  /// In en, this message translates to:
  /// **'No cards match these filters.'**
  String get boardNoMatchingCards;

  /// No description provided for @dueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dueSoon;

  /// No description provided for @boardOptions.
  ///
  /// In en, this message translates to:
  /// **'Board options'**
  String get boardOptions;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @anyMember.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get anyMember;

  /// No description provided for @anyLabel.
  ///
  /// In en, this message translates to:
  /// **'Any label'**
  String get anyLabel;

  /// No description provided for @noAssignee.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get noAssignee;

  /// No description provided for @destinationBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get destinationBoard;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get quickAddHint;

  /// No description provided for @quickAddDetails.
  ///
  /// In en, this message translates to:
  /// **'Add details'**
  String get quickAddDetails;

  /// No description provided for @noWritableBoards.
  ///
  /// In en, this message translates to:
  /// **'There is no board you can add cards to.'**
  String get noWritableBoards;

  /// No description provided for @noWritableColumns.
  ///
  /// In en, this message translates to:
  /// **'Create a column on this board first.'**
  String get noWritableColumns;

  /// No description provided for @moveToTop.
  ///
  /// In en, this message translates to:
  /// **'At the beginning'**
  String get moveToTop;

  /// No description provided for @moveToBottom.
  ///
  /// In en, this message translates to:
  /// **'At the end'**
  String get moveToBottom;

  /// No description provided for @moveBefore.
  ///
  /// In en, this message translates to:
  /// **'Before a card'**
  String get moveBefore;

  /// No description provided for @moveAfter.
  ///
  /// In en, this message translates to:
  /// **'After a card'**
  String get moveAfter;

  /// No description provided for @moveRelativeCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get moveRelativeCard;

  /// No description provided for @invalidDestination.
  ///
  /// In en, this message translates to:
  /// **'This destination has changed or is no longer available. Refresh and choose again.'**
  String get invalidDestination;

  /// No description provided for @quickAddSavedDraft.
  ///
  /// In en, this message translates to:
  /// **'Your text is saved in Drafts until you add the card.'**
  String get quickAddSavedDraft;

  /// No description provided for @colorDefault.
  ///
  /// In en, this message translates to:
  /// **'No custom color'**
  String get colorDefault;

  /// No description provided for @colorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get colorCustom;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @useLocalChanges.
  ///
  /// In en, this message translates to:
  /// **'Use my changes'**
  String get useLocalChanges;

  /// No description provided for @keepServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Keep the server version'**
  String get keepServerVersion;

  /// No description provided for @allChanges.
  ///
  /// In en, this message translates to:
  /// **'All changes'**
  String get allChanges;

  /// No description provided for @needsDecision.
  ///
  /// In en, this message translates to:
  /// **'Needs a decision'**
  String get needsDecision;

  /// No description provided for @boardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find a board'**
  String get boardSearchHint;

  /// No description provided for @unnamedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unnamed label'**
  String get unnamedLabel;

  /// No description provided for @keepPosition.
  ///
  /// In en, this message translates to:
  /// **'Keep the current position'**
  String get keepPosition;

  /// No description provided for @afterColumn.
  ///
  /// In en, this message translates to:
  /// **'After a column'**
  String get afterColumn;

  /// No description provided for @pendingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to sync'**
  String get pendingWaiting;

  /// No description provided for @pendingConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get pendingConflicts;

  /// No description provided for @pendingUncertain.
  ///
  /// In en, this message translates to:
  /// **'Check the result'**
  String get pendingUncertain;

  /// No description provided for @pendingEmptyGroup.
  ///
  /// In en, this message translates to:
  /// **'There are no changes in this group.'**
  String get pendingEmptyGroup;

  /// No description provided for @pendingConflictHelp.
  ///
  /// In en, this message translates to:
  /// **'Compare your changes with the server version before choosing what to keep.'**
  String get pendingConflictHelp;

  /// No description provided for @confirmUseLocalChanges.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be sent again after checking the current server version.'**
  String get confirmUseLocalChanges;

  /// No description provided for @confirmKeepServerVersion.
  ///
  /// In en, this message translates to:
  /// **'Only this local change will be discarded. Nothing will be changed on the server.'**
  String get confirmKeepServerVersion;

  /// No description provided for @changedField.
  ///
  /// In en, this message translates to:
  /// **'Different values'**
  String get changedField;

  /// No description provided for @draftLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original location is no longer available'**
  String get draftLocationUnavailable;

  /// No description provided for @settingsPersonalization.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language'**
  String get settingsPersonalization;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Account and data'**
  String get settingsData;

  /// No description provided for @telemetryChoiceHelp.
  ///
  /// In en, this message translates to:
  /// **'You can change these options at any time. They do not affect your boards or tasks.'**
  String get telemetryChoiceHelp;

  /// No description provided for @selectionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get selectionDone;

  /// No description provided for @telemetryEnabledByDefault.
  ///
  /// In en, this message translates to:
  /// **'Available options are on by default. You can turn each one off.'**
  String get telemetryEnabledByDefault;

  /// No description provided for @noMatchingBoards.
  ///
  /// In en, this message translates to:
  /// **'No boards match this filter.'**
  String get noMatchingBoards;

  /// No description provided for @permissionAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get permissionAllowed;

  /// No description provided for @permissionNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get permissionNotAllowed;

  /// No description provided for @localSaveError.
  ///
  /// In en, this message translates to:
  /// **'Changes could not be saved on this device. Try again.'**
  String get localSaveError;

  /// No description provided for @writePermissionError.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to save this change.'**
  String get writePermissionError;

  /// No description provided for @transferCardHint.
  ///
  /// In en, this message translates to:
  /// **'The card keeps its comments and attachments. Labels are matched with the destination board.'**
  String get transferCardHint;

  /// No description provided for @transferAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Who can see the card is determined by sharing on the destination board.'**
  String get transferAccessHint;

  /// No description provided for @transferLabelLoss.
  ///
  /// In en, this message translates to:
  /// **'These labels are not available in the destination board and will be removed: {labels}'**
  String transferLabelLoss(String labels);

  /// No description provided for @transferToDone.
  ///
  /// In en, this message translates to:
  /// **'This column marks incoming cards complete.'**
  String get transferToDone;

  /// No description provided for @transferFromDone.
  ///
  /// In en, this message translates to:
  /// **'Moving out of a done column marks the card incomplete.'**
  String get transferFromDone;

  /// No description provided for @transferPositionPending.
  ///
  /// In en, this message translates to:
  /// **'The card has moved. Its position is still being confirmed.'**
  String get transferPositionPending;

  /// No description provided for @confirmTransferRetry.
  ///
  /// In en, this message translates to:
  /// **'Check the card on the server before sending the remaining change again.'**
  String get confirmTransferRetry;

  /// No description provided for @cardArchivedError.
  ///
  /// In en, this message translates to:
  /// **'This card is archived. Restore it before editing.'**
  String get cardArchivedError;

  /// No description provided for @commentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This comment is no longer available. Refresh the comments.'**
  String get commentUnavailable;

  /// No description provided for @itemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available. Refresh and check its current state.'**
  String get itemUnavailable;

  /// No description provided for @attachmentMissingError.
  ///
  /// In en, this message translates to:
  /// **'The file to upload is no longer on this device. Attach it again.'**
  String get attachmentMissingError;

  /// No description provided for @unsupportedOperation.
  ///
  /// In en, this message translates to:
  /// **'This action is not available here.'**
  String get unsupportedOperation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
