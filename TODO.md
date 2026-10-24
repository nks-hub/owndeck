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
- [x] D03 Implementovány nástěnky, sloupce, oprávnění, archivace a sdílení; runtime důkazy zůstávají v T01–T03.
- [x] D03a Implementováno vytváření a úpravy nástěnek/sloupců, archivace, mazání a obnova nástěnky, oddělená práva edit/manage a řazení sloupců; runtime ověření čeká na T01–T03.
- [x] D03b Doplněno hledání uživatelů/skupin/týmů a externích příjemců, vytvoření/změna/odebrání ACL, omezení udělovaných práv a vyřazení cache po ztrátě přístupu; 6 metadata scénářů a 1 hledací scénář připraveny pro T01.
- [x] D04 Implementovány karty, popis, termíny, štítky, přiřazení, dokončení a přesuny; ověření běhu zůstává v T01–T03.
- [x] D04a Přidán editor názvu, popisu a termínu, volba dokončení u karet s podporovaným polem a lokálně uložené vytvoření/úprava; ověření běhu čeká na T01.
- [x] D04b Implementován přesun přes nabídku a řazení tažením uvnitř sloupce, archiv/obnova/smazání karty, přiřazení existujících štítků a uživatelů, živý detail a Markdown bez automatického stahování externích obrázků; 5 scénářů akcí připraveno pro T01.
- [x] D04c Doplněn začátek, volitelná barva, zachování hodnot v konceptu a skrytí nepodporovaných polí; 2 protokolové scénáře připraveny, ověření operací zůstává v T01/T02.
- [x] D04d Implementováno vytváření, přejmenování, změna barvy a mazání štítků včetně návazné fronty přiřazení a odstranění smazaného štítku z místní kopie karet.
- [ ] D05 Implementovat komentáře, přílohy a návazné soubory.
- [x] D05a Implementováno stránkované čtení komentářů, odpovědi, úprava/smazání autorem, serverové UID a průběžně uložené koncepty; 4 protokolové a 6 databázových scénářů připraveno pro T01.
- [ ] D06 Implementovat místní data, frontu změn, obnovu po restartu a konflikty.
- [x] D06a Přidána databáze a místní kopie nástěnek/sloupců/karet, ETag a ochrana proti pozdním odpovědím odebraného účtu; připraveno 6 databázových scénářů pro T01.
- [x] D06b Implementována trvalá fronta vytvoření/úprav karet, zámek účtu, detekce konfliktu a ruční rozhodnutí, obnova přerušeného zápisu a ochrana před starou odpovědí po potvrzeném zápisu; 6 scénářů připraveno pro T01.
- [ ] D06c Doplnit automatické uložení rozepsaného editoru, závislosti nových entit, ostatní typy zápisů a obnovu při návratu aplikace či sítě.
- [x] D06d Koncept editoru se průběžně ukládá, lze jej obnovit ze seznamu rozepsaných karet a atomicky předat frontě; doplněna obnova při návratu/síti a polling otevřené nástěnky pouze v popředí, 4 scénáře konceptů připraveny pro T01.
- [x] D06e Fronta respektuje závislosti nové nástěnky, sloupce a karty; po potvrzení převádí místní ID, při zrušení rodiče zachová obsah potomků a označí překážku; připraveno 5 dalších scénářů pro T01.
- [x] D06f Potvrzené akce karet mají samostatný stav čekání na načtení výsledku; opakuje se pouze GET a další změny stejné karty čekají na vyřešení předchozího zápisu.
- [ ] D06g Dokončit odložené opakování podle Retry-After a uchování fronty pro komentáře, přílohy a další operace.
- [ ] D07 Implementovat hledání, přehled vlastních úkolů a odkazy do konkrétních karet.
- [ ] D08 Integrovat volitelné Sentry a Rybbit: konfigurace přes CI v našich buildech, žádné pevné klíče, funkční build i bez služeb, ochrana obsahu a volba uživatele.
- [ ] D09 Dokončit české a anglické texty, přístupnost a chybové stavy.
- [ ] D10 Dokončit kopie, závislosti karet, podporovaný hotový sloupec a přehled oznámení; push posoudit podle skutečných capabilities a infrastruktury.
- [ ] T01 Spouštět jednotkové a UI sady neblokujícím způsobem na pozadí, nezávislé sady paralelně; po vývoji dokončit integrační ověření a opravit nálezy.
- [ ] T02 Ověřit skutečný Nextcloud server, oba buildy a příjem bezpečných telemetrických událostí.
- [ ] T03 Průběžně provádět fyzické testy S9/S21 na pozadí nad izolovanými kandidáty, nezávisle pro každý telefon, a samostatné ověření iOS; před dokončením doložit finální revizi.

Aktuální krok: přílohy (D05) a další otevřené D body. Průběžné paralelní testy na pozadí nad izolovanou revizí `95b19ed` prošly: protokol 13/13, databáze a fronta 38/38, bez přeskočení. Nepokrývají UI ani skutečný server a zařízení. Nástěnky/sloupce, sdílení, štítky, akce karet, komentáře a koncepty jsou implementované. Statické kontroly jsou bez nálezů. Fyzické testy zatím neproběhly.
