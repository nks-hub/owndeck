# OwnDeck: úkoly

Tento seznam je průběžný zdroj další práce. Po dokončení celku zapsat výsledek a důkaz; nedokončený bod ponechat otevřený. Nové požadavky doplnit sem před implementací.

- [x] P01 Soukromý `nks-hub/owndeck` založen a ověřen přes GitHub API; `VERSION` je `0.1.0+1`, pravidla v `docs/versioning.md`.

- [x] P00 Ověřit výchozí stav a vytvořit plán před zahájením vývoje.
- [x] A01 Projit aktuální kód OwnTalk/OwnNotes i MCP Memory; konkrétní soubory a revize v `docs/reuse.md`.
- [x] A02 Porovnáno 7 produktů podle primárních zdrojů; závěry a meze ověření v `docs/competition.md`.
- [x] A03 Zdrojová analýza Deck v1.19.1: 86 verzovaných rout, parametry a 10 nálezů v `docs/nextcloud-api.md` a `docs/api-inventory.md`; runtime důkaz patří do T02.
- [x] A04 Mapa klientských rodin Nextcloud a jejich použití/hranice pro Deck je v `docs/nextcloud-api.md`.
- [x] A05 Zadání obrazovek, chybových stavů, přístupnosti a designu v `docs/product.md`.
- [x] A06 Model dat, trvalá fronta, konflikty a bezpečnost v `docs/architecture.md`; limit serverového If-Match výslovně zaznamenán.
- [x] D01 Založena Flutter aplikace Android/iOS `com.nkshub.nextclouddeck`, SDK 3.44.4, protokol a přihlášení podle OwnNotes; závislosti vyřešeny, runtime ověření zůstává v T01–T03.
- [x] D02 Implementován Login Flow v2, oddělené reference tokenů, databázové účty, opětovné přihlášení, přepnutí a odebrání s odvoláním tokenu; spuštění testů zůstává v T01–T03.
- [ ] D03 Implementovat nástěnky, sloupce, oprávnění, archivaci a sdílení.
- [x] D03a Implementováno vytváření a úpravy nástěnek/sloupců, archivace, mazání a obnova nástěnky, oddělená práva edit/manage a řazení sloupců; sdílení zůstává otevřené, runtime ověření čeká na T01–T03.
- [ ] D04 Implementovat karty, popis, termíny, štítky, přiřazení, dokončení a přesuny.
- [x] D04a Přidán editor názvu, popisu a termínu, volba dokončení u karet s podporovaným polem a lokálně uložené vytvoření/úprava; ověření běhu čeká na T01.
- [ ] D05 Implementovat komentáře, přílohy a návazné soubory.
- [ ] D06 Implementovat místní data, frontu změn, obnovu po restartu a konflikty.
- [x] D06a Přidána databáze a místní kopie nástěnek/sloupců/karet, ETag a ochrana proti pozdním odpovědím odebraného účtu; připraveno 6 databázových scénářů pro T01.
- [x] D06b Implementována trvalá fronta vytvoření/úprav karet, zámek účtu, detekce konfliktu a ruční rozhodnutí, obnova přerušeného zápisu a ochrana před starou odpovědí po potvrzeném zápisu; 6 scénářů připraveno pro T01.
- [ ] D06c Doplnit automatické uložení rozepsaného editoru, závislosti nových entit, ostatní typy zápisů a obnovu při návratu aplikace či sítě.
- [x] D06d Koncept editoru se průběžně ukládá, lze jej obnovit ze seznamu rozepsaných karet a atomicky předat frontě; doplněna obnova při návratu/síti a polling otevřené nástěnky pouze v popředí, 4 scénáře konceptů připraveny pro T01.
- [x] D06e Fronta respektuje závislosti nové nástěnky, sloupce a karty; po potvrzení převádí místní ID, při zrušení rodiče zachová obsah potomků a označí překážku; připraveno 5 dalších scénářů pro T01.
- [ ] D07 Implementovat hledání, přehled vlastních úkolů a odkazy do konkrétních karet.
- [ ] D08 Integrovat volitelné Sentry a Rybbit: konfigurace přes CI v našich buildech, žádné pevné klíče, funkční build i bez služeb, ochrana obsahu a volba uživatele.
- [ ] D09 Dokončit české a anglické texty, přístupnost a chybové stavy.
- [ ] D10 Dokončit kopie, závislosti karet, podporovaný hotový sloupec a přehled oznámení; push posoudit podle skutečných capabilities a infrastruktury.
- [ ] T01 Po vývoji spustit jednotkové, UI a integrační testy a opravit nálezy.
- [ ] T02 Ověřit skutečný Nextcloud server, oba buildy a příjem bezpečných telemetrických událostí.
- [ ] T03 Provést závěrečné fyzické testy S9 a S21 a samostatné ověření iOS; uložit důkazy s revizí.

Aktuální krok: další operace s kartami (D04), sdílení (D03) a přílohy/komentáře (D05). Základní správa nástěnek/sloupců, koncepty a fronta s rodičovskými závislostmi jsou implementované. Závislosti a generování databázových typů proběhly. Testy protokolu a databáze jsou připravené, dosud nespouštěné. Zaškrtnutí D bodů znamená dokončenou implementaci, nikoli úspěch testů; ty mají vlastní T body. Aplikace ani cílová zařízení zatím nebyly testované.
