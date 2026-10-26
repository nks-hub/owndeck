# Co převzít z OwnTalk a OwnNotes

Kontrola zdrojů 24. 10. 2026. Tabulka popisuje vhodné komponenty rodiny Own aplikací. Při převzetí konkrétního souboru zaznamenat jeho původ.

| Potřeba | Existující místo | Rozhodnutí pro OwnDeck |
|---|---|---|
| Přihlášení | OwnNotes `packages/notes_protocol/lib/src/login.dart` | Převzít tok v2, omezení odpovědi 64 KiB, zrušení, timeout, bezpečné chybové kódy a kontrolu stejného serveru. Změnit User-Agent. |
| Adresa serveru | OwnNotes `packages/notes_protocol/lib/src/server_base.dart` | Převzít validaci HTTPS a podadresáře; přidat pouze Deck a potřebné OCS cesty. |
| Účty | OwnNotes `apps/mobile/lib/features/accounts.dart`, `packages/notes_store/lib/src/accounts.dart` | Stejný výběr účtu a oddělení hesla od databáze. Před změnou účtu uložit rozepsanou kartu. |
| Místní data | OwnNotes `packages/notes_store/lib/src/database.dart` | Převzít princip lokálního UUID, odkazu na credential a generace účtu. Vytvořit vlastní tabulky pro Deck. |
| Fronta a obnova | OwnNotes `packages/notes_store/lib/src/sync.dart`, `recovery.dart` | Převzít frontu s trvalým stavem a zámkem účtu. Zápis s nejasným výsledkem po restartu automaticky neopakovat. |
| Telemetrie | OwnTalk `apps/mobile/lib/core/telemetry.dart`, `telemetry_bootstrap.dart` | Převzít konfiguraci sestavení, oddělení SDK, čištění událostí a bezpečné názvy obrazovek. Přidat samostatná uživatelská nastavení a ověřit chování při selhání inicializace. |
| Vzhled | OwnTalk `apps/mobile/lib/core/app_theme.dart` | Využít Material 3, světlé/tmavé plochy a dotykové cíle. Zmenšit dekorativní zaoblení karet pro hustší seznam práce. |
| Automatické testy | OwnNotes `packages/notes_protocol/test/login_test.dart`, mobilní testy účtů a telemetrie | Převzít scénáře a testovací přístupy, upravit očekávání pro Deck. Testy spouštět průběžně na pozadí v odděleném worktree. |
| Buildy | OwnNotes `.flutter-version`, Android/iOS konfigurace | Stejný tvar identifikátoru a verze. Nepřebírat jejich podpisové soubory, Firebase identitu ani store aplikaci. |

Obě aplikace používají monorepo `apps/mobile` a `packages`. OwnDeck zachová tento tvar: `deck_protocol` pro HTTP a modely, `deck_store` pro data a frontu, `apps/mobile` pro UI a systémové integrace. Riverpod odpovídá aktuálnímu OwnNotes. Kopírování celého Talku by přineslo nepotřebné WebRTC, hovory a desktopové části.

## Volba technologie

Flutter doporučuji kvůli již existujícím komponentám, testům a postupům vydání obou aplikací. React Native by umožnil sdílet dva mobilní klienty, ale ne současné Dart komponenty. Samostatný Swift/Kotlin by lépe oddělil systémová UI, za cenu dvou implementací synchronizace a dvou sad oprav. Pro tento projekt jejich přínos nepřevažuje opakovanou práci.

Verze Flutteru se před založením ověří proti skutečnému SDK a připne do `.flutter-version`. Závislosti se převezmou pouze tam, kde je má první implementace používat. Aktualizace knihoven není samostatným cílem.

Pro náhled Markdownu je použit `flutter_markdown_plus`, udržovaný nástupce původního rendereru. Volbu potvrzuje [stránka balíčku](https://pub.dev/packages/flutter_markdown_plus); původní `flutter_markdown` je označený jako ukončený. Externí obrázky se bez klepnutí nestahují.

## Hranice převzetí

Převzít vlastní vhodné komponenty v malém rozsahu a zaznamenat jejich původ. Před převzetím ověřit licenci konkrétního repozitáře. Kód serveru Deck a cizích klientů slouží jako dokumentace chování; nepřebírat AGPL/GPL zdroje do klienta bez rozhodnutí o licenci. Designové vzory lze realizovat samostatně. Názvy produktů a jejich značky nekopírovat.

Rozhodnutí výše vycházejí z přečteného kódu. Starší výsledky testů OwnTalk/OwnNotes nejsou důkazem správnosti OwnDecku.

## Sjednocené přihlášení

Vzhled, texty, ikony, normalizace adresy, QR čtečka a rozhodování o certifikátu vycházejí z OwnTalk revize `029b6d138533d8c0186193561203d3168a0ea0eb`. Liší se název produktu, jeho značka a druh uložených dat. Kontrola dostupnosti Decku zůstává součástí dokončení přihlášení.

Transport certifikátů je převzatý z OwnNotes revize `ec8d00159c39428f8dc0f7753aa89f97ecad2a80`. Připnutý certifikát kontroluje i tehdy, když nový certifikát považuje systém za důvěryhodný. Zrušení přihlášení brání pozdnímu uložení účtu a tajných údajů. Automatické a fyzické ověření se vykazuje pro konkrétní revizi, nikoli podle výsledků sourozeneckých aplikací.
