# OwnDeck: úkoly

Tento seznam je průběžný zdroj další práce. Po dokončení celku zapsat výsledek a důkaz; nedokončený bod ponechat otevřený. Nové požadavky doplnit sem před implementací.

- [x] P01 Soukromý `nks-hub/owndeck` založen a ověřen přes GitHub API; `VERSION` je `0.1.0+1`, pravidla v `docs/versioning.md`.

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
- [x] T01 Oddělené paralelní sady prošly; vydávaný `7d13eb6` má úspěšné testy a analyzery všech tří balíků v CI, včetně regresí dialogů a obnovy fronty.
- [ ] T02 Ověřit skutečný Nextcloud server, oba buildy a příjem bezpečných telemetrických událostí.
- [ ] T03 Průběžně provádět fyzické testy S9/S21 na pozadí nad izolovanými kandidáty, nezávisle pro každý telefon, a samostatné ověření iOS; před dokončením doložit finální revizi.

Aktuální krok: Google Play kontroluje první vydání 0.1.0+2 v uzavřeném kanálu alpha. API potvrdilo IN_REVIEW, přesný hash AAB, ikonu, grafiku, dva snímky v cs/en a tři skupiny převzaté z OwnNotes. Všech pět CI úloh `7d13eb6` prošlo; fyzické ověření příloh po odstranění nepotřebných oprávnění běží samostatně. Podrobné revize a meze jsou v `docs/testing.md`.

- [x] N01 Související práce na OwnNotes je dokončená; přesný rozsah a důkazy jsou v jeho vlastním TODO.

- [ ] R01 Při samostatné práci na OwnTalku ověřit také SAN certifikátů a oddělení přístupnosti prvků přihlašovací karty; v Decku a Notes jsou opravené, OwnTalk zde nebyl měněn.
- [ ] R02 Google Play alpha 0.1.0+2 odesláno ke kontrole; API potvrzuje IN_REVIEW a všechny podklady/skupiny, po schválení ještě ověřit dostupnost testerům.
- [ ] P01 Na S9 zlepšit p95 celého snímku při souvislém posunu 1 000 karet: naměřeno 24,388 ms proti cíli 16,7 ms; S21 splnil 10,268 ms, start z cache prošel na obou telefonech.
