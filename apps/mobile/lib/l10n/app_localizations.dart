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
