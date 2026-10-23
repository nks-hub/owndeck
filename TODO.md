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
- [ ] D01 Založit Flutter aplikaci Android/iOS jako `com.nkshub.nextclouddeck` podle OwnTalk/OwnNotes a převzít vhodné společné komponenty.
- [ ] D02 Implementovat přihlášení Nextcloud Login Flow v2, bezpečné ukládání a více účtů.
- [ ] D03 Implementovat nástěnky, sloupce, oprávnění, archivaci a sdílení.
- [ ] D04 Implementovat karty, popis, termíny, štítky, přiřazení, dokončení a přesuny.
- [ ] D05 Implementovat komentáře, přílohy a návazné soubory.
- [ ] D06 Implementovat místní data, frontu změn, obnovu po restartu a konflikty.
- [ ] D07 Implementovat hledání, přehled vlastních úkolů a odkazy do konkrétních karet.
- [ ] D08 Integrovat volitelné Sentry a Rybbit: konfigurace přes CI v našich buildech, žádné pevné klíče, funkční build i bez služeb, ochrana obsahu a volba uživatele.
- [ ] D09 Dokončit české a anglické texty, přístupnost a chybové stavy.
- [ ] D10 Dokončit kopie, závislosti karet, podporovaný hotový sloupec a přehled oznámení; push posoudit podle skutečných capabilities a infrastruktury.
- [ ] T01 Po vývoji spustit jednotkové, UI a integrační testy a opravit nálezy.
- [ ] T02 Ověřit skutečný Nextcloud server, oba buildy a příjem bezpečných telemetrických událostí.
- [ ] T03 Provést závěrečné fyzické testy S9 a S21 a samostatné ověření iOS; uložit důkazy s revizí.
- [ ] N01 Převzít výsledek paralelní integrace OwnNotes a stav vydání v obou obchodech.

Aktuální krok: D01, založení aplikace po uzavření zdrojové analýzy. Testovací scénáře jsou připravené v `docs/testing.md`; aplikace ani cílová zařízení zatím nebyly testované.
