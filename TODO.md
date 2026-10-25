# OwnDeck: úkoly

Tento seznam je průběžný zdroj další práce. Po dokončení celku zapsat výsledek a důkaz; nedokončený bod ponechat otevřený. Nové požadavky doplnit sem před implementací.

- [x] P01 Soukromý `nks-hub/owndeck` založen a ověřen přes GitHub API; vydávaná verze je `0.1.0+2`, tag `v0.1.0+2`, pravidla v `docs/versioning.md`.

- [x] P00 Ověřit výchozí stav a vytvořit plán před zahájením vývoje.
- [x] A01 Projit aktuální kód OwnTalk/OwnNotes i MCP Memory; konkrétní soubory a revize v `docs/reuse.md`.
- [x] A02 Porovnáno 7 produktů podle primárních zdrojů; závěry a meze ověření v `docs/competition.md`.
- [x] A03 Zdrojová analýza Deck v1.19.1: 86 verzovaných rout, parametry a průběžně doplňované nálezy v `docs/nextcloud-api.md` a `docs/api-inventory.md`; runtime důkaz patří do T02.
- [x] A04 Mapa klientských rodin Nextcloud a jejich použití/hranice pro Deck je v `docs/nextcloud-api.md`.
- [x] A05 Zadání obrazovek, chybových stavů, přístupnosti a designu v `docs/product.md`.
- [x] A06 Model dat, trvalá fronta, konflikty a bezpečnost v `docs/architecture.md`; limit serverového If-Match výslovně zaznamenán.
- [x] D01 Založena Flutter aplikace Android/iOS `com.nkshub.nextclouddeck`, SDK 3.44.4, protokol a přihlášení podle OwnNotes; závislosti vyřešeny, runtime ověření zůstává v T01–T03.
- [x] D02 Implementován Login Flow v2, oddělené reference tokenů, databázové účty, opětovné přihlášení, přepnutí a odebrání s odvoláním tokenu; spuštění testů zůstává v T01–T03.
- [x] D02b Přihlášení sjednoceno podle OwnTalku v Decku i Notes: texty, ovládací ikony, vzhled, QR, průběh a certifikáty; Deck ověřen automaticky a na S21, cílené testy Notes prošly, jeho fyzické ověření zatím není dokončené.
- [x] D02c HTTP 401 otevírá obnovu přihlášení bez ztráty konceptů; stará generace nesmí odhlásit nový účet, nový login přežije chybu starého účtu a dialog drží správnou adresu při přepnutí. Testy i odebrání testovacích účtů na skutečném serveru prošly.
- [x] D03 Implementovány nástěnky, sloupce, oprávnění, archivace a sdílení; runtime důkazy zůstávají v T01–T03.
- [x] D03a Implementováno vytváření a úpravy nástěnek/sloupců, archivace, mazání a obnova nástěnky, oddělená práva edit/manage a řazení sloupců; runtime ověření čeká na T01–T03.
- [x] D03b Doplněno hledání uživatelů/skupin/týmů a externích příjemců, vytvoření/změna/odebrání ACL, omezení udělovaných práv a vyřazení cache po ztrátě přístupu; 6 metadata scénářů a 1 hledací scénář připraveny pro T01.
- [x] D04 Implementovány karty, popis, termíny, štítky, přiřazení, dokončení a přesuny; ověření běhu zůstává v T01–T03.
- [x] D04a Přidán editor názvu, popisu a termínu, volba dokončení u karet s podporovaným polem a lokálně uložené vytvoření/úprava; ověření běhu čeká na T01.
- [x] D04b Implementován přesun přes nabídku a řazení tažením uvnitř sloupce, archiv/obnova/smazání karty, přiřazení existujících štítků a uživatelů, živý detail a Markdown bez automatického stahování externích obrázků; 5 scénářů akcí připraveno pro T01.
- [x] D04c Doplněn začátek, volitelná barva, zachování hodnot v konceptu a skrytí nepodporovaných polí; 2 protokolové scénáře připraveny, ověření operací zůstává v T01/T02.
- [x] D04d Implementováno vytváření, přejmenování, změna barvy a mazání štítků včetně návazné fronty přiřazení a odstranění smazaného štítku z místní kopie karet.
- [x] D05 Komentáře, přílohy a návazné soubory implementované; skutečný Deck ověřil běžné i legacy přílohy.
- [x] D05a Implementováno stránkované čtení komentářů, odpovědi, úprava/smazání autorem, serverové UID a průběžně uložené koncepty; 4 protokolové a 6 databázových scénářů připraveno pro T01.
- [x] D05b REST 1.1 přílohy, multipart, stažení, obnova legacy souboru, share type 12, WebDAV, trvalý staging a UI hotové; skutečný server prošel na `8b0780b`, S21 ověřil picker, offline frontu, restart, SHA a export na `1dbada7`.
- [x] D06 Místní data, trvalá fronta, obnova, závislosti a konflikty implementované; nejistý POST se automaticky neopakuje.
- [x] D06a Přidána databáze a místní kopie nástěnek/sloupců/karet, ETag a ochrana proti pozdním odpovědím odebraného účtu; připraveno 6 databázových scénářů pro T01.
- [x] D06b Implementována trvalá fronta vytvoření/úprav karet, zámek účtu, detekce konfliktu a ruční rozhodnutí, obnova přerušeného zápisu a ochrana před starou odpovědí po potvrzeném zápisu; 6 scénářů připraveno pro T01.
- [x] D06c Autosave konceptů, závislosti nových entit, komentáře/přílohy/metadata a obnova po návratu aplikace či sítě jsou zapojené.
- [x] D06d Koncept editoru se průběžně ukládá, lze jej obnovit ze seznamu rozepsaných karet a atomicky předat frontě; doplněna obnova při návratu/síti a polling otevřené nástěnky pouze v popředí, 4 scénáře konceptů připraveny pro T01.
- [x] D06e Fronta respektuje závislosti nové nástěnky, sloupce a karty; po potvrzení převádí místní ID, při zrušení rodiče zachová obsah potomků a označí překážku; připraveno 5 dalších scénářů pro T01.
- [x] D06f Potvrzené akce karet mají samostatný stav čekání na načtení výsledku; opakuje se pouze GET a další změny stejné karty čekají na vyřešení předchozího zápisu.
- [x] D06g Retry-After se ukládá pro účet, přežije restart a platí i pro přímé čtení souborů; čekající fronta se obnovuje v popředí také z přehledu nástěnek. Testy aktuálního sloučeného stromu běží v T01.
- [x] D07 Místní i serverové hledání, Moje úkoly, online přehled a webové/ncdeck odkazy hotové; D07 API + web ověřené na `14318f5`, cold/warm a oddělení účtů fyzicky na S21. Serverové hledání poctivě omezeno na 200 výsledků.
- [x] D08 Volitelné Sentry/Rybbit, konfigurace přes CI, obě služby v našich buildech a oddělené přepínače hotové; doručení ze S9 ověřené, nastavení přežije restart na S9/S21. Sentry zachytává Dart/Flutter chyby, nativní crash/hang sběr není zapnutý.
- [x] D09 České/anglické texty, srozumitelné chyby, společné přihlášení, vlastní launcher ikony a hlavní přístupnost zapojené; 200% text a malá výška ověřené testy, landscape editor i Cancel fyzicky na S9 v `ba364e0`. Formální TalkBack/VoiceOver audit se netvrdí.
- [x] D10 Kopie karet, směrované vazby, hotový sloupec a přehled oznámení hotové a ověřené i na Decku 1.18.5. Vazby neblokují dokončení karty. OS push není zapnutý; chybí ověřený mobilní push kanál pro Deck.
- [x] D11 Nastavení vzhledu, jazyka, verze a účtů doplněno v `781dbb0`, třetí navigační cíl v `6c3eeb3`; test ověřil zachování navigace, rozepsaného textu a filtru při změně jazyka/tématu.
- [ ] D12 Doplnit seznam/sloupce, uchování pohledu pro nástěnku, široké rozložení a tažení karty mezi sloupci.
- [x] D13 Kopie nástěnky přes trvalou frontu a serverový import jsou zapojené v `4fc690b`, `708defd`, `2cbef2a`; 122 databázových a 9 cílených UI scénářů prošlo, skutečný Deck 1.19.1 ověřil šest voleb API. Průběžný test zařízení patří do T03.
- [ ] D15 V řešení konfliktu zobrazit vedle textu také místní a serverový termín, začátek, barvu a dokončení; nynější přehled tato upravitelná pole neukazuje.
- [x] D14 Oznámení otevírají ověřené karty nativně se stejným účtem; ostatní odkazy zůstávají v prohlížeči. Šest widget testů a analyzer prošly včetně skutečného načtení karty a nulového volání externího prohlížeče.
- [x] B01 Migrace z verzí 1–3 opravena v `a329d28`; před opravou tři selhání na duplicitním sloupci, po opravě všech osm migrací 1–8 zachovalo účty, koncepty i čekající zápisy.
- [x] B02 Přijaté zápisy se už neopakují ani nezaseknou po cizím přesunu; aktuální sloupec/nástěnka se ověřují, 403/404 nevracejí cache. `77cea35` + `ca8c723` + `41b25b3`, 107 databázových testů a analyzer prošly.
- [x] B03 Známá ztráta přístupu čistí serverovou cache i stažené soubory, blokuje zápisy a zachovává vlastní koncepty/staging. Ověřeno 28 mobilními testy, databázovou sadou a skutečným odebráním sdílení na jednom serveru.
- [x] B04 Hranice startdate/color opravena na Deck 1.18 v `b9c6903`; 108 protokolových testů prošlo a skutečný Deck 1.18.5 potvrdil vytvoření, změnu i vymazání obou polí se zachováním ostatních hodnot.
- [ ] T01 Vydaný `7d13eb6` má úspěšné celé CI; nové opravy a nastavení prošly samostatnými sadami, po doplnění zbývajících funkcí ověřit společnou finální revizi.
- [ ] T02 Ověřit skutečný Nextcloud server, oba buildy a příjem bezpečných telemetrických událostí.
- [x] T02b Dva vlastní izolované účty na stejném serveru: READ a EDIT omezení i odebrání sdílení ověřené; skutečný DeckSync vyřadil cache bez mutace a zachoval čekající texty. Celkem 12 scénářů včetně rozšířených polí a úklidu API.
- [ ] T03 Průběžně provádět fyzické testy S9/S21 a podle upřesnění uživatele iOS simulátor na macOS, vše na pozadí nad izolovanými kandidáty; před dokončením doložit finální revizi.

Aktuální krok: uzavřený test 0.1.0+2 je publikovaný, API to potvrdilo 25. 10. 2026. Probíhá dokončení D12 a průběžné ověřování kandidáta `2cbef2a` v oddělených worktree. Testy, analyzery, sestavení i testy zařízení běží pouze na pozadí; hlavní vlákno pokračuje v implementaci. Podrobné revize a meze jsou v `docs/testing.md`.

- [x] N01 Související práce na OwnNotes je dokončená; přesný rozsah a důkazy jsou v jeho vlastním TODO.

- [ ] R01 Při samostatné práci na OwnTalku ověřit také SAN certifikátů a oddělení přístupnosti prvků přihlašovací karty; v Decku a Notes jsou opravené, OwnTalk zde nebyl měněn.
- [x] R02 Google Play alpha 0.1.0+2 schváleno a publikováno; API potvrzuje PUBLISHED, ověřené podklady a tři skupiny jako OwnNotes; testovací odkaz: https://play.google.com/apps/testing/com.nkshub.nextclouddeck.
- [ ] P02 Na S9 zlepšit p95 latence celého snímku při souvislém posunu 1 000 karet: naměřeno 24,388 ms proti cíli 16,7 ms; S21 splnil 10,268 ms, start z cache prošel na obou telefonech.
