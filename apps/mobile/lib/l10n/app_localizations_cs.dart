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
  String get connect => 'Připojit';

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
  String get invalidServer => 'Zadejte platnou HTTPS adresu Nextcloudu.';

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
      'Odstranit účet a všechna jeho místní data z tohoto zařízení? Data na serveru zůstanou zachovaná.';

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
  String get clearDate => 'Zrušit termín';

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
  String get drafts => 'Rozepsané karty';

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
  String get invalidColor =>
      'Barvu zadejte šesti hexadecimálními znaky, například 008080.';

  @override
  String get invalidPosition => 'Pořadí musí být celé nezáporné číslo.';

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
}
