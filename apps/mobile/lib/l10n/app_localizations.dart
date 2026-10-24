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
  /// **'Connect'**
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
  /// **'Enter a valid Nextcloud HTTPS address.'**
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
  /// **'Clear due date'**
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
  /// **'Card drafts'**
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
  /// **'Enter a six-digit hexadecimal color, for example 008080.'**
  String get invalidColor;

  /// No description provided for @invalidPosition.
  ///
  /// In en, this message translates to:
  /// **'Position must be a non-negative integer.'**
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
