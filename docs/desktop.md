# Desktopová verze

OwnDeck a OwnNotes mají běžet i na Windows, macOS a Linuxu. Vzorem je desktopový režim OwnTalku; tento dokument shrnuje jeho audit a co z něj převzít. Pracovní body jsou v `TODO.md` jako DK01–DK29.

## Jak to dělá OwnTalk

| Platforma | Stav | Balíček a aktualizace |
|---|---|---|
| Windows | vydává se | Instalátor Inno Setup pro jednoho uživatele, aktualizace ověřená přes `SHA256SUMS` z GitHub release. Runner hlídá jednu instanci a předává odkazy běžící instanci, registruje vlastní schéma odkazů, ukládá polohu okna a umí autostart. |
| macOS | vydává se | ZIP podepsaný Developer ID, notarizovaný, s aktualizacemi přes Sparkle 2 a appcastem v GitHub release. Sandbox zapnutý, okno má minimální velikost a pamatuje si polohu. |
| Linux | jen sestavení | `tar.gz` z CI; klíčenka přes libsecret, autostart přes XDG. Spuštění ověřené jen ve virtuálním stroji. |

Společné v Dartu: kontrola a instalace aktualizací, přetahování souborů (vlastní fork `desktop_drop`), třípanelové rozložení, zkratky Ctrl/Cmd+F a Esc, Login Flow v2 v systémovém prohlížeči a trezor, který na zamčené klíčence Linuxu nezablokuje start.

## Nálezy v OwnTalku

1. Windows instalátor není podepsaný Authenticode a aktualizace na Windows a Linuxu důvěřují jen `SHA256SUMS` ze stejného release. Kdo ovládne release, spustí kód u všech, kdo aktualizaci potvrdí. macOS má podpis EdDSA.
2. Vydání macOS (notarizace, staple, ZIP pro Sparkle) existuje jen jako popis v dokumentaci, ne jako skript.
3. Sparkle čte appcast z `releases/latest`; tag bez ručně nahraného ZIPu a appcastu potichu zastaví aktualizace na macOS.
4. Linux: chybí jedna instance, soubor `.desktop` se schématem odkazů, oznámení a podpis balíčku. Výměna složky při aktualizaci tiše selže v adresáři bez práva zápisu.
5. Celá aktualizace přímo z aplikace na Windows nebyla nikdy ověřena od začátku do konce.
6. Dokumentace se rozchází s kódem (macOS a Linux „jen odkaz“, limit 64 MiB proti skutečným 128 MiB).
7. Pamatování polohy okna na macOS není ověřené.
8. Větev macOS ve výměně složky je od přechodu na Sparkle mrtvý kód.
9. Kontrolní součet načítá celý instalátor (až 128 MiB) do paměti.
10. Desktopové buildy nenahrávají ladicí symboly do Sentry, nativní pády nebudou čitelné.
11. macOS nemá nativní menu; pravé tlačítko a hover skoro chybí.
12. `local_auth_windows` potřebuje s aktuálním MSVC obchvat `CL=/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`; týká se i OwnNotes.

## Stav OwnDecku

- Platformy jen Android a iOS; CI staví jen APK a iOS.
- Kamera a QR jsou na desktopu skryté. Kanály odkazů, sdílení a souborů mají ošetřenou chybějící implementaci.
- `open_filex` na desktopu vyhazuje `UnsupportedError`, otevření přílohy je potřeba nahradit.
- Trezor nemá nastavení pro macOS a čtení klíčenky při startu hrozí na Linuxu zablokováním jako dříve v OwnTalku.
- Široké rozložení sloupců existuje; chybí boční panel nástěnek, detail jako panel, myš (přetažení bez dlouhého stisku, pravé tlačítko, hover) a klávesové zkratky.
- Systémová oznámení aplikace nemá na žádné platformě, takže je na desktopu není co dorovnávat.

## Co převzít a parametrizovat

Runner pro Windows (jedna instance, předání odkazu, poloha okna, autostart), `MainFlutterWindow.swift` a šablonu entitlements pro macOS, autostart pro Linux, instalátor Inno Setup se smoke testem, skripty podpisu Sparkle a appcastu, služby a testy aktualizací, vzor trezoru a CI joby linux/windows/release. Napevno zadané identifikátory OwnTalku (bundle ID, repozitář, klíče registru, názvy kanálů) je nutné nahradit.

## Externí překážky

Certifikát pro podpis kódu na Windows nemá ani OwnTalk. Podpis a notarizace pro macOS, klíče Sparkle a E2E na Macu s obrazovkou závisí na přístupu vlastníka k Apple účtu a Macu; nativní Linux pro E2E zatím není k dispozici.
