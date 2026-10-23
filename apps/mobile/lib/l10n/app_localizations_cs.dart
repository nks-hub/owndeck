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
}
