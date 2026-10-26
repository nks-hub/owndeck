// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'OwnDeck';

  @override
  String get connectTitle => 'Připojit Nextcloud';

  @override
  String get connectDescription =>
      'Přihlášení proběhne v prohlížeči vašeho serveru. Heslo k účtu zůstává na serveru.';

  @override
  String get serverLabel => 'Adresa serveru';

  @override
  String get connect => 'Pokračovat';

  @override
  String get waiting => 'Dokončete přihlášení v prohlížeči.';

  @override
  String get cancel => 'Zrušit';

  @override
  String get retry => 'Zkusit znovu';

  @override
  String get boards => 'Nástěnky';

  @override
  String get accounts => 'Účty';

  @override
  String get addAccount => 'Přidat účet';

  @override
  String get noBoards => 'Zatím žádné nástěnky';

  @override
  String get noBoardsHint =>
      'Na tomto účtu nejsou dostupné žádné aktivní nástěnky.';

  @override
  String get emptyStack => 'V tomto sloupci nejsou karty.';

  @override
  String get noStacks => 'Nástěnka nemá žádné sloupce.';

  @override
  String get refresh => 'Obnovit';

  @override
  String get readOnly => 'Pouze čtení';

  @override
  String get noDescription => 'Bez popisu';

  @override
  String get storageError =>
      'Bezpečné úložiště není dostupné. Odemkněte zařízení a zkuste to znovu.';

  @override
  String get invalidServer => 'Zadejte platnou HTTPS adresu Nextcloud serveru.';

  @override
  String get loginError =>
      'Přihlášení se nepodařilo dokončit. Zkuste nový pokus.';

  @override
  String get networkError =>
      'Server není dostupný. Zkontrolujte připojení a zkuste to znovu.';

  @override
  String get authError => 'Přihlášení vypršelo. Přidejte znovu stejný účet.';

  @override
  String get permissionError => 'K tomuto obsahu již nemáte přístup.';

  @override
  String get deckError => 'Na serveru není dostupný Deck s API 1.1.';

  @override
  String get certError =>
      'Certifikátu serveru nelze důvěřovat. Zkontrolujte adresu a nastavení serveru.';

  @override
  String get browserError => 'Prohlížeč se nepodařilo otevřít.';

  @override
  String get loadError => 'Obsah se nepodařilo načíst.';

  @override
  String get removeAccount => 'Odebrat účet';

  @override
  String get removeAccountQuestion =>
      'Odebrat účet z této aplikace? Jeho uložené koncepty a neodeslané změny se smažou. Obsah v Nextcloudu zůstane zachovaný.';

  @override
  String get remove => 'Odebrat';

  @override
  String get revocationFailed =>
      'Účet byl odebrán z telefonu. Odvolání přístupu na serveru se nepodařilo potvrdit; zkontrolujte aplikace v nastavení Nextcloudu.';

  @override
  String get cachedData => 'Zobrazuji uloženou kopii.';

  @override
  String get syncing => 'Aktualizuji…';

  @override
  String get addCard => 'Přidat kartu';

  @override
  String get editCard => 'Upravit kartu';

  @override
  String get cardTitle => 'Název karty';

  @override
  String get description => 'Popis';

  @override
  String get save => 'Uložit';

  @override
  String get savedLocally =>
      'Uloženo v telefonu. Změna čeká na potvrzení serverem.';

  @override
  String get invalidTitle => 'Název musí mít 1 až 255 znaků.';

  @override
  String get dueDate => 'Termín';

  @override
  String get clearDate => 'Zrušit datum';

  @override
  String get completed => 'Dokončeno';

  @override
  String get pendingChanges => 'Neodeslané změny';

  @override
  String get noPending => 'Všechny změny jsou potvrzené.';

  @override
  String get queued => 'Čeká na odeslání';

  @override
  String get sending => 'Odesílá se';

  @override
  String get conflict => 'Na serveru se změnilo stejné pole.';

  @override
  String get uncertain =>
      'Server mohl změnu přijmout. Před opakováním zkontrolujte obsah na serveru.';

  @override
  String get blocked => 'Změnu nelze odeslat. Zkontrolujte přístup a obsah.';

  @override
  String get retryWrite => 'Znovu odeslat';

  @override
  String get discardWrite => 'Zahodit místní změnu';

  @override
  String get localVersion => 'Místní verze';

  @override
  String get serverVersion => 'Verze na serveru';

  @override
  String get pendingValueNotSet => 'Nenastaveno';

  @override
  String get pendingValueUnavailable => 'Hodnota není dostupná';

  @override
  String get pendingNotCompleted => 'Nedokončeno';

  @override
  String get pendingCompletion => 'Dokončení';

  @override
  String get confirmRetry =>
      'Opakování může vytvořit duplicitní položku. Opravdu odeslat znovu?';

  @override
  String get confirmDiscard =>
      'Zahodit tuto místní změnu? Případný již provedený zápis na serveru to nevrátí.';

  @override
  String get pendingDecision =>
      'Tato karta má právě odesílanou nebo nevyřešenou změnu. Nejdřív otevřete Neodeslané změny.';

  @override
  String get unsavedChanges => 'Opustit neuložené úpravy?';

  @override
  String get leave => 'Opustit';

  @override
  String get draftSaved =>
      'Koncept je uložený v telefonu. Na server se odešle až po stisku Uložit.';

  @override
  String get savingDraft => 'Ukládám koncept…';

  @override
  String get drafts => 'Koncepty';

  @override
  String get noDrafts => 'Nemáte žádné rozepsané karty.';

  @override
  String get discardDraft => 'Zahodit koncept';

  @override
  String get discardDraftQuestion =>
      'Trvale odstranit tento rozepsaný text z telefonu?';

  @override
  String get addBoard => 'Přidat nástěnku';

  @override
  String get editBoard => 'Upravit nástěnku';

  @override
  String get addStack => 'Přidat sloupec';

  @override
  String get editStack => 'Upravit sloupec';

  @override
  String get name => 'Název';

  @override
  String get color => 'Barva';

  @override
  String get position => 'Pořadí';

  @override
  String get archive => 'Archivovat';

  @override
  String get unarchive => 'Vrátit z archivu';

  @override
  String get deleteBoard => 'Smazat nástěnku';

  @override
  String get deleteStack => 'Smazat sloupec';

  @override
  String get deleteStructureQuestion =>
      'Opravdu smazat vybranou položku včetně jejího obsahu na serveru?';

  @override
  String get activeBoards => 'Aktivní';

  @override
  String get archivedBoards => 'Archivované';

  @override
  String get deletedBoards => 'Smazané';

  @override
  String get restoreBoard => 'Obnovit nástěnku';

  @override
  String get invalidName => 'Název musí mít 1 až 100 znaků.';

  @override
  String get invalidColor => 'Vyberte barvu.';

  @override
  String get invalidPosition => 'Vyberte umístění položky.';

  @override
  String get boardActions => 'Akce nástěnky';

  @override
  String get stackActions => 'Akce sloupce';

  @override
  String get dependencyUnavailable =>
      'Nadřazená nástěnka nebo sloupec byly zrušeny. Místní obsah zůstal zachovaný.';

  @override
  String get awaitingReadback =>
      'Server změnu přijal. Čeká se na načtení výsledku.';

  @override
  String get changeAccepted => 'Přijato';

  @override
  String get moveCard => 'Přesunout kartu';

  @override
  String get destinationColumn => 'Cílový sloupec';

  @override
  String get deleteCard => 'Smazat kartu';

  @override
  String get deleteCardQuestion => 'Opravdu smazat tuto kartu ze serveru?';

  @override
  String get cardUnavailable =>
      'Karta už není dostupná. Neodeslané změny najdete v jejich přehledu.';

  @override
  String get labels => 'Štítky';

  @override
  String get assignees => 'Přiřazení';

  @override
  String get noLabels => 'Nástěnka nemá žádné štítky.';

  @override
  String get noUsers => 'Na nástěnce nejsou dostupní uživatelé.';

  @override
  String get cardActions => 'Akce karty';

  @override
  String get externalImage => 'Obrázek otevřete klepnutím v prohlížeči.';

  @override
  String get archivedCards => 'Archivované karty';

  @override
  String get activeCards => 'Aktivní karty';

  @override
  String get reorderCard =>
      'Podržte a přetáhněte kartu; přesun je také v nabídce karty.';

  @override
  String get comments => 'Komentáře';

  @override
  String get addComment => 'Přidat komentář';

  @override
  String get editComment => 'Upravit komentář';

  @override
  String get deleteComment => 'Smazat komentář';

  @override
  String get deleteCommentQuestion =>
      'Opravdu smazat tento komentář ze serveru?';

  @override
  String get reply => 'Odpovědět';

  @override
  String get replyTo => 'Odpověď na komentář';

  @override
  String get noComments => 'Zatím žádné komentáře.';

  @override
  String get commentMessage => 'Text komentáře';

  @override
  String get invalidComment => 'Komentář musí mít 1 až 1 000 znaků.';

  @override
  String get commentDraft => 'Rozepsaný komentář';

  @override
  String get localDraftSaved => 'Koncept je uložený v telefonu.';

  @override
  String get sendComment => 'Odeslat komentář';

  @override
  String get identityUnavailable =>
      'Nejdřív obnovte připojení, aby aplikace ověřila vaše uživatelské ID. Koncept zůstává uložený.';

  @override
  String get sharing => 'Sdílení nástěnky';

  @override
  String get findRecipient => 'Najít uživatele, skupinu nebo tým';

  @override
  String get noRecipients => 'Žádní odpovídající příjemci.';

  @override
  String get addShare => 'Přidat sdílení';

  @override
  String get editShare => 'Upravit oprávnění';

  @override
  String get removeShare => 'Odebrat sdílení';

  @override
  String get removeShareQuestion =>
      'Odebrat tomuto příjemci přístup k nástěnce?';

  @override
  String get permissionRead => 'Čtení';

  @override
  String get permissionEdit => 'Úpravy';

  @override
  String get permissionShare => 'Sdílení';

  @override
  String get permissionManage => 'Správa';

  @override
  String get user => 'Uživatel';

  @override
  String get group => 'Skupina';

  @override
  String get team => 'Tým';

  @override
  String get externalRecipient => 'Externí příjemce';

  @override
  String get noShares => 'Nástěnka zatím není sdílená.';

  @override
  String get manageLabels => 'Spravovat štítky';

  @override
  String get addLabel => 'Přidat štítek';

  @override
  String get editLabel => 'Upravit štítek';

  @override
  String get deleteLabel => 'Smazat štítek';

  @override
  String get deleteLabelQuestion =>
      'Smazat štítek z nástěnky i ze všech jejích karet?';

  @override
  String get alreadyShared =>
      'Příjemce už má přístup. Obnovte nástěnku a upravte existující sdílení.';

  @override
  String get startDate => 'Začátek';

  @override
  String get cardColor => 'Barva karty';

  @override
  String get optionalColor => 'Prázdné pole znamená bez vlastní barvy.';

  @override
  String get invalidDateRange =>
      'Začátek musí být nejpozději v termínu dokončení.';

  @override
  String get certificateFingerprintLabel => 'Otisk SHA-256';

  @override
  String get scanLoginCodeCameraUnavailable =>
      'Toto zařízení nemá fotoaparát, kterým by šlo kód načíst.';

  @override
  String get secureTitle => 'Přihlašovací údaje zůstávají v zařízení';

  @override
  String get serverAddressHint => 'cloud.example.com';

  @override
  String get reauthenticateAccountMismatch =>
      'Přihlaste se ke stejnému účtu. Uložený účet nebyl změněn.';

  @override
  String get scanLoginCodeCameraDenied =>
      'Přístup k fotoaparátu je vypnutý. Povolte jej v nastavení systému, aby šlo kód načíst.';

  @override
  String get waitingForLogin => 'Dokončete přihlášení v prohlížeči';

  @override
  String get close => 'Zavřít';

  @override
  String get certificateChangedTitle => 'Certifikát serveru se změnil';

  @override
  String get unexpectedError => 'Něco se nepodařilo. Data účtu nebyla změněna.';

  @override
  String get openingLogin => 'Otevírá se bezpečné přihlášení…';

  @override
  String get serverMaintenance => 'Server je právě v režimu údržby.';

  @override
  String get reauthenticateAccountTitle => 'Znovu se přihlásit k tomuto účtu';

  @override
  String get certificateTrustAction => 'Důvěřovat a pokračovat';

  @override
  String get scannedLoginRejected =>
      'Načtený přihlašovací kód se nepodařilo použít. Vytvořte na serveru nový.';

  @override
  String get browserUnavailable =>
      'Přihlašovací stránku se nepodařilo otevřít.';

  @override
  String get multiServerBody =>
      'Přidejte osobní i pracovní účty bez nového sestavení aplikace a bez sdílení jejich dat.';

  @override
  String get serverNotInstalled =>
      'Nextcloud na tomto serveru zatím není nainstalovaný.';

  @override
  String get checkingServer => 'Kontrola serveru…';

  @override
  String get waitingForLoginBody =>
      'Po schválení aplikace v Nextcloudu bude tato obrazovka automaticky pokračovat.';

  @override
  String get serverUnavailable =>
      'Server se nepodařilo kontaktovat. Zkontrolujte adresu a připojení.';

  @override
  String get secureBody =>
      'Hesla aplikace se ukládají do systémového Keychainu nebo Keystoru, nikdy do databáze karet.';

  @override
  String get onboardingTitle => 'Všechny nástěnky v jedné aplikaci';

  @override
  String certificateChangedBody(String host) {
    return 'Server $host nyní předkládá jiný certifikát, než kterému tento účet důvěřuje. Pokud jste certifikát vyměnili vy, účet odeberte a přidejte znovu.';
  }

  @override
  String get scanLoginCode => 'Načíst přihlašovací kód';

  @override
  String get loginTimedOut =>
      'Požadavek na přihlášení vypršel. Spusťte jej znovu.';

  @override
  String get scanLoginCodeUnreadable =>
      'Tohle není přihlašovací kód Nextcloudu.';

  @override
  String get reauthenticateAccountAction => 'Přihlásit se znovu';

  @override
  String get multiServerTitle => 'Připraveno pro více serverů';

  @override
  String get scanLoginCodeHint =>
      'Namiřte fotoaparát na QR kód, který server ukáže v Nastavení, Zabezpečení, Vytvořit nové heslo aplikace.';

  @override
  String get invalidResponse =>
      'Server vrátil odpověď, kterou aplikace nemůže bezpečně použít.';

  @override
  String get certificateUnverifiedTitle => 'Neověřený certifikát serveru';

  @override
  String certificateUnverifiedBody(String host) {
    return 'Server $host předložil certifikát, který zařízení neumí ověřit. Pokračujte jen tehdy, když otisk níže odpovídá tomu, co ukazuje váš server.';
  }

  @override
  String get localPersistenceFailed =>
      'Účet se nepodařilo bezpečně uložit do tohoto zařízení.';

  @override
  String get serverUpgrade =>
      'Server musí nejdřív dokončit aktualizaci databáze.';

  @override
  String get addServerTitle => 'Přidat Nextcloud server';

  @override
  String get openAppSettings => 'Otevřít nastavení';

  @override
  String get onboardingBody =>
      'Připojte libovolný podporovaný Nextcloud server. Účty, jejich uložená data i práce na pozadí zůstávají přísně oddělené.';

  @override
  String get serverAddressLabel => 'Adresa serveru';

  @override
  String get attachments => 'Přílohy';

  @override
  String get uploadFile => 'Nahrát soubor';

  @override
  String get linkCloudFile => 'Připojit z Nextcloudu';

  @override
  String get noAttachments => 'Zatím žádné přílohy.';

  @override
  String get openFile => 'Otevřít soubor';

  @override
  String get saveFile => 'Uložit soubor';

  @override
  String get removeAttachment => 'Odebrat přílohu';

  @override
  String get restoreAttachment => 'Obnovit přílohu';

  @override
  String get removeLinkedFileQuestion =>
      'Soubor se odpojí od karty. V Nextcloudu zůstane zachovaný.';

  @override
  String get removeLegacyFileQuestion =>
      'Odebrat tuto přílohu? Po omezenou dobu ji lze obnovit, než ji server trvale odstraní.';

  @override
  String get attachmentTooLarge =>
      'Soubor je větší než 64 MiB. Vyberte menší soubor.';

  @override
  String get attachmentFailed =>
      'Soubor se nepodařilo zpracovat. Zkuste to znovu.';

  @override
  String get unsupportedAttachment => 'Tento typ přílohy zatím nelze otevřít.';

  @override
  String get offlineAttachment => 'Používá se dříve stažená kopie souboru.';

  @override
  String get chooseCloudFile => 'Vybrat soubor v Nextcloudu';

  @override
  String get fileNotShareable => 'Tento soubor nemůžete dále sdílet.';

  @override
  String get noCloudFiles => 'Tato složka je prázdná.';

  @override
  String get parentFolder => 'Nadřazená složka';

  @override
  String get fileSaved => 'Soubor byl uložen.';

  @override
  String get fileOpenFailed =>
      'Soubor nelze otevřít. Můžete jej uložit a otevřít v jiné aplikaci.';

  @override
  String get deletedAttachment => 'Odebraná příloha';

  @override
  String get fileAttachment => 'Soubor';

  @override
  String get searchCards => 'Hledat karty';

  @override
  String get searchCardsHint => 'Název, popis nebo štítek';

  @override
  String get clearSearch => 'Vymazat hledání';

  @override
  String get myTasks => 'Moje úkoly';

  @override
  String get localSearchNotice =>
      'Hledá se pouze v datech uložených v zařízení. Otevřete nástěnku, aby se načetly její karty.';

  @override
  String get includeArchived => 'Zahrnout archivované';

  @override
  String get includeCompleted => 'Zahrnout dokončené';

  @override
  String get anyDueDate => 'Libovolný termín';

  @override
  String get dueToday => 'Dnes';

  @override
  String get overdueTasks => 'Po termínu';

  @override
  String get withoutDueDate => 'Bez termínu';

  @override
  String get noMatchingCards =>
      'Žádné uložené karty neodpovídají hledání a filtrům.';

  @override
  String get accountSearchUnavailable => 'Tento účet už není dostupný.';

  @override
  String get myTasksIdentityRequired =>
      'Moje úkoly lze zobrazit až po ověření uživatele při synchronizaci.';

  @override
  String get rateLimited =>
      'Server požádal o přestávku. Synchronizace se později zopakuje.';

  @override
  String get copyCard => 'Vytvořit kopii karty';

  @override
  String get copyCardDescription =>
      'Kopie převezme název, popis, štítky a dostupná přiřazení. Termíny, komentáře a přílohy se nekopírují.';

  @override
  String get copyDestinationBoard => 'Cílová nástěnka';

  @override
  String get noCopyDestination =>
      'Není dostupná žádná nástěnka, do které můžete zapisovat.';

  @override
  String get linkedCards => 'Propojené karty';

  @override
  String get addCardLink => 'Propojit kartu';

  @override
  String get removeCardLink => 'Odebrat vazbu';

  @override
  String get noLinkedCards => 'Tato karta zatím nemá žádné vazby.';

  @override
  String get linkedCardUnavailable =>
      'Propojená karta není dostupná v místních datech.';

  @override
  String get cardLinksDescription =>
      'Vazby odkazují na související karty. Neblokují jejich dokončení.';

  @override
  String get cardLinkCachedOnly =>
      'Nabídka obsahuje pouze karty uložené v tomto zařízení.';

  @override
  String get noLinkCandidates =>
      'Žádné další uložené karty neodpovídají hledání.';

  @override
  String get doneColumn => 'Hotový sloupec';

  @override
  String get setDoneColumn => 'Nastavit jako hotový sloupec';

  @override
  String get unsetDoneColumn => 'Zrušit hotový sloupec';

  @override
  String get setDoneColumnQuestion =>
      'Tento sloupec bude jediným hotovým sloupcem nástěnky. Jeho aktivní karty se označí jako dokončené a nově přesunuté karty se budou dokončovat automaticky.';

  @override
  String get unsetDoneColumnQuestion =>
      'Zrušit nastavení hotového sloupce? Již dokončené karty zůstanou dokončené.';

  @override
  String get deckNotifications => 'Oznámení Decku';

  @override
  String get notificationsUnavailable => 'Server nepodporuje přehled oznámení.';

  @override
  String get noDeckNotifications => 'Žádná oznámení Decku.';

  @override
  String get openInNextcloud => 'Otevřít v Nextcloudu';

  @override
  String get telemetryTitle => 'Diagnostika a používání';

  @override
  String get privacyPolicy => 'Zásady ochrany soukromí';

  @override
  String get crashReporting => 'Hlášení chyb';

  @override
  String get crashReportingDescription =>
      'Odesílat technické chyby bez obsahu karet, souborů a přihlašovacích údajů.';

  @override
  String get usageAnalytics => 'Statistiky používání';

  @override
  String get usageAnalyticsDescription =>
      'Odesílat pouze předem určené názvy obrazovek a akcí.';

  @override
  String get telemetryUnavailable => 'Tato volba není v této verzi dostupná.';

  @override
  String get telemetrySaveFailed => 'Nastavení se nepodařilo uložit.';

  @override
  String get openCardLink => 'Otevřít odkaz na kartu';

  @override
  String get cardLinkAddress => 'Odkaz na kartu v Nextcloudu';

  @override
  String get invalidCardLink =>
      'Toto není platný HTTPS odkaz na kartu v Nextcloudu.';

  @override
  String get cardLinkAccountRequired => 'Přidejte účet pro tento server';

  @override
  String get chooseCardLinkAccount => 'Vyberte účet pro otevření karty';

  @override
  String get copyCardLink => 'Kopírovat odkaz na kartu';

  @override
  String get cardLinkCopied => 'Odkaz na kartu byl zkopírován.';

  @override
  String get localSearchMode => 'Uložené karty';

  @override
  String get serverSearchMode => 'Hledat na serveru';

  @override
  String get serverSearchNotice =>
      'Výsledky ze serveru neobsahují dosud neodeslané změny.';

  @override
  String get serverMyTasksNotice =>
      'Serverový přehled obsahuje aktivní nedokončené karty přiřazené vám.';

  @override
  String get serverSearchLimited =>
      'Server vrátil prvních 200 výsledků. Upřesněte hledání.';

  @override
  String get openingCardLink => 'Otevírá se karta…';

  @override
  String get settings => 'Nastavení';

  @override
  String get appearance => 'Vzhled';

  @override
  String get language => 'Jazyk';

  @override
  String get systemDefault => 'Podle zařízení';

  @override
  String get lightTheme => 'Světlý';

  @override
  String get darkTheme => 'Tmavý';

  @override
  String get languageCzech => 'Čeština';

  @override
  String get languageEnglish => 'English';

  @override
  String get appVersion => 'Verze aplikace';

  @override
  String get versionUnavailable => 'Verzi aplikace se nepodařilo načíst.';

  @override
  String get preferenceStorageError =>
      'Nastavení se nepodařilo načíst nebo uložit. Změny zatím platí jen pro toto spuštění aplikace.';

  @override
  String versionBuild(String version, String build) {
    return '$version ($build)';
  }

  @override
  String get copyBoard => 'Kopírovat nástěnku';

  @override
  String get copyBoardDescription =>
      'Zkopíruje se aktuální stav na serveru včetně sloupců, štítků a sdílení. Deck 1.19 nekopíruje komentáře, přílohy, začátky ani barvy karet.';

  @override
  String get copyBoardWithCards => 'Včetně karet';

  @override
  String get copyBoardWithAssignments => 'Zachovat přiřazení lidí';

  @override
  String get copyBoardWithLabels => 'Zachovat štítky na kartách';

  @override
  String get copyBoardWithDueDate => 'Zachovat termíny';

  @override
  String get copyBoardMoveCards => 'Přesunout karty do prvního sloupce';

  @override
  String get copyBoardRestoreArchived => 'Obnovit archivované karty';

  @override
  String get copyBoardInBrowser =>
      'Tento server umožňuje kopírování nástěnek ve webovém rozhraní. Otevřete nástěnku v Nextcloudu a vytvořte kopii tam.';

  @override
  String get importInNextcloud => 'Importovat v Nextcloudu';

  @override
  String get importInNextcloudHint =>
      'Otevřete Deck v prohlížeči a použijte zdroje importu podporované vaším serverem, například Trello.';

  @override
  String get pendingBoardDecision =>
      'Nejprve vyřešte neodeslané změny této nástěnky.';

  @override
  String get boardView => 'Zobrazení nástěnky';

  @override
  String get boardColumns => 'Sloupce';

  @override
  String get boardList => 'Seznam';

  @override
  String get dropCardHere => 'Sem přetáhněte kartu';

  @override
  String boardMovePositionHint(int maximum) {
    return 'Pozice od 0 do $maximum';
  }

  @override
  String invalidBoardMovePosition(int maximum) {
    return 'Zadejte pozici od 0 do $maximum.';
  }

  @override
  String get filterCards => 'Filtrovat karty';

  @override
  String get clearFilters => 'Zrušit filtry';

  @override
  String get allCards => 'Všechny karty';

  @override
  String get openCards => 'Nedokončené';

  @override
  String get upcomingTasks => 'Nadcházející';

  @override
  String get boardNoMatchingCards => 'Žádná karta neodpovídá těmto filtrům.';

  @override
  String get dueSoon => 'Blíží se termín';

  @override
  String get boardOptions => 'Možnosti nástěnky';

  @override
  String get applyFilters => 'Použít filtry';

  @override
  String get anyMember => 'Kdokoliv';

  @override
  String get anyLabel => 'Libovolný štítek';

  @override
  String get noAssignee => 'Nepřiřazeno';

  @override
  String get destinationBoard => 'Nástěnka';

  @override
  String get quickAddHint => 'Co je potřeba udělat?';

  @override
  String get quickAddDetails => 'Doplnit podrobnosti';

  @override
  String get noWritableBoards =>
      'Nemáte nástěnku, do které můžete přidávat karty.';

  @override
  String get noWritableColumns => 'Nejprve v této nástěnce vytvořte sloupec.';

  @override
  String get moveToTop => 'Na začátek';

  @override
  String get moveToBottom => 'Na konec';

  @override
  String get moveBefore => 'Před kartu';

  @override
  String get moveAfter => 'Za kartu';

  @override
  String get moveRelativeCard => 'Karta';

  @override
  String get invalidDestination =>
      'Cílové místo se změnilo nebo už není dostupné. Obnovte obsah a vyberte jej znovu.';

  @override
  String get quickAddSavedDraft =>
      'Text zůstává v Konceptech, dokud kartu nepřidáte.';

  @override
  String get colorDefault => 'Bez vlastní barvy';

  @override
  String get colorCustom => 'Vlastní barva';

  @override
  String get colorBlue => 'Modrá';

  @override
  String get colorTeal => 'Petrolejová';

  @override
  String get colorGreen => 'Zelená';

  @override
  String get colorPurple => 'Fialová';

  @override
  String get colorOrange => 'Oranžová';

  @override
  String get colorRed => 'Červená';

  @override
  String get colorPink => 'Růžová';

  @override
  String get colorGray => 'Šedá';

  @override
  String get useLocalChanges => 'Použít moje změny';

  @override
  String get keepServerVersion => 'Ponechat verzi serveru';

  @override
  String get allChanges => 'Všechny změny';

  @override
  String get needsDecision => 'Vyžaduje rozhodnutí';

  @override
  String get boardSearchHint => 'Najít nástěnku';

  @override
  String get unnamedLabel => 'Štítek bez názvu';

  @override
  String get keepPosition => 'Ponechat na současném místě';

  @override
  String get afterColumn => 'Za sloupec';

  @override
  String get pendingWaiting => 'Čeká na odeslání';

  @override
  String get pendingConflicts => 'Konflikty';

  @override
  String get pendingUncertain => 'Zkontrolovat výsledek';

  @override
  String get pendingEmptyGroup => 'V této skupině nejsou žádné změny.';

  @override
  String get pendingConflictHelp =>
      'Porovnejte svoje změny s verzí na serveru a zvolte, co ponechat.';

  @override
  String get confirmUseLocalChanges =>
      'Vaše změny se znovu odešlou po kontrole aktuální verze na serveru.';

  @override
  String get confirmKeepServerVersion =>
      'Zahodí se pouze tato místní změna. Na serveru se nic nezmění.';

  @override
  String get changedField => 'Rozdílné hodnoty';

  @override
  String get draftLocationUnavailable => 'Původní umístění už není dostupné';

  @override
  String get settingsPersonalization => 'Vzhled a jazyk';

  @override
  String get settingsData => 'Účet a data';

  @override
  String get telemetryChoiceHelp =>
      'Tyto volby můžete kdykoli změnit. Nemají vliv na vaše nástěnky ani úkoly.';

  @override
  String get selectionDone => 'Hotovo';

  @override
  String get telemetryEnabledByDefault =>
      'Dostupné volby jsou ve výchozím stavu zapnuté. Každou můžete vypnout.';

  @override
  String get noMatchingBoards => 'Tomuto filtru neodpovídá žádná nástěnka.';

  @override
  String get permissionAllowed => 'Povoleno';

  @override
  String get permissionNotAllowed => 'Nepovoleno';

  @override
  String get localSaveError =>
      'Změny se nepodařilo uložit v zařízení. Zkuste to znovu.';

  @override
  String get writePermissionError => 'Nemáte oprávnění tuto změnu uložit.';

  @override
  String get transferCardHint =>
      'Komentáře a přílohy zůstanou u karty. Štítky se přiřadí podle cílové nástěnky.';

  @override
  String get transferAccessHint =>
      'Kdo kartu uvidí, bude záviset na sdílení cílové nástěnky.';

  @override
  String transferLabelLoss(String labels) {
    return 'Tyto štítky nejsou v cílové nástěnce dostupné a při přesunu se odeberou: $labels';
  }

  @override
  String get transferToDone =>
      'Tento sloupec označuje přesunuté karty jako dokončené.';

  @override
  String get transferFromDone =>
      'Přesun z hotového sloupce vrátí kartu mezi nedokončené.';

  @override
  String get transferPositionPending =>
      'Karta už byla přesunuta. Ještě se potvrzuje její umístění.';

  @override
  String get confirmTransferRetry =>
      'Před opakováním zbývající změny ověřte aktuální stav karty na serveru.';

  @override
  String get cardArchivedError =>
      'Karta je archivovaná. Před další úpravou ji obnovte.';

  @override
  String get commentUnavailable =>
      'Komentář už není dostupný. Obnovte seznam komentářů.';

  @override
  String get itemUnavailable =>
      'Položka už není dostupná. Obnovte data a ověřte její aktuální stav.';

  @override
  String get attachmentMissingError =>
      'Příloha už není dostupná. Obnovte seznam příloh.';

  @override
  String get unsupportedOperation => 'Tuto akci zde nelze provést.';

  @override
  String get attachmentStorageError =>
      'Přílohu nelze v tomto zařízení přečíst nebo uložit. Zkuste akci znovu.';

  @override
  String get noSavedContent => 'Na tomto zařízení zatím nejsou uložená data.';

  @override
  String get localReadError =>
      'Uložená data nelze v tomto zařízení načíst. Zkuste obrazovku otevřít znovu.';

  @override
  String get removeAccountAccessWarning =>
      'Použité heslo pro aplikaci se zneplatní. Pokud stejné heslo používáte v dalších aplikacích či zařízeních, ztratí přístup také.';

  @override
  String get selectCard => 'Vybrat kartu';

  @override
  String get cancelSelection => 'Zrušit výběr';

  @override
  String selectedCardsCount(int count) {
    return 'Vybráno: $count';
  }

  @override
  String get moveSelectedCards => 'Přesunout vybrané karty';

  @override
  String get archiveSelectedCards => 'Archivovat vybrané karty';

  @override
  String bulkAllQueued(int count) {
    return 'Změny uložené v telefonu: $count. Čekají na potvrzení serverem.';
  }

  @override
  String get bulkResultTitle => 'Výsledek u každé karty';

  @override
  String bulkSummary(int queued, int failed, int blocked) {
    return 'Uloženo: $queued, selhalo: $failed, bez oprávnění: $blocked.';
  }

  @override
  String get bulkStatusQueued => 'Uloženo v telefonu, čeká na server';

  @override
  String bulkStatusFailed(String error) {
    return 'Neuloženo: $error';
  }

  @override
  String get bulkStatusBlocked => 'Chybí oprávnění, nic se nezměnilo';

  @override
  String bulkRetryFailed(int count) {
    return 'Zkusit znovu neúspěšné ($count)';
  }

  @override
  String get bulkSelectionKept =>
      'Karty, které se neuložily, zůstávají vybrané.';

  @override
  String get addChecklistItems => 'Přidat položky seznamu';

  @override
  String get addChecklistItemsHelp => 'Jedna položka na řádek';

  @override
  String get addItems => 'Přidat';

  @override
  String get hideCompletedItems => 'Skrýt hotové';

  @override
  String get allItemsCompleted => 'Všechny položky jsou hotové';
}
