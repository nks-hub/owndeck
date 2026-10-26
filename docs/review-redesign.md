# OwnDeck: celkový review a redesign

Redesign z 25. 10. 2026 zahrnuje rozbor, review, refaktor a E2E všech funkcí včetně přesouvání. Výchozí zdroj je `1b370a0`; Google Play obsahuje starší `7d13eb6` ve verzi 0.1.0+2.

## Přijímací podmínky

- Každá dostupná akce má popsaný výsledek, stav čekání a opravitelnou chybu. Zápis do místní fronty se neoznačuje jako úspěšné uložení na server.
- Stejná akce používá stejný postup z nástěnky, seznamu, hledání i detailu. Refaktor odstraní duplicity odpovědné za rozdílné chování, zachová data a oprávnění.
- Člověk bez znalosti technických pojmů zvládne přidat, najít, upravit, přiřadit, přesunout a dokončit úkol. Pozice od nuly ani serverová ID nepatří do běžného ovládání.
- Všechny podporované funkce projdou přes skutečné UI a skutečný Nextcloud. Jednotkové testy, přímé API sondy a místní náhrady serveru jsou doplňkový důkaz, nikoli náhrada E2E.
- Každý výsledek nese revizi, hash aplikace, zařízení, verzi serveru a důkaz v UI i následném načtení ze serveru. Předchozí výsledek se nepřenáší na novou revizi bez zdůvodněného vymezení.
- Výchozí cíle: S9, S21 a iOS simulátor na macOS; čeština/angličtina, světlý/tmavý vzhled, malá výška, 200% text, ovládání čtečkou a alternativa ke gestům.

## Dosud doložené nálezy

| Oblast | Současný problém | Požadovaná změna |
|---|---|---|
| Karty na nástěnce | Náhled neukazuje termín, dokončení, štítky ani přiřazené osoby. | Viditelná pracovní metadata s textovým významem a rozumnou hustotou. |
| Přidání úkolu | Akce je až na konci dlouhého sloupce; hlavní navigace nemá rychlé zachycení. | Vždy dostupné přidání s viditelným cílem a zapamatováním posledního platného cíle účtu. |
| Detail | Název je jen v horní liště; sekundární sekce předcházejí popisu. | Úplný název, kontext, metadata a popis před komentáři a přílohami. |
| Přesun | Detail a nástěnka mají různé implementace a číselné pořadí. | Jeden postup s cílovým sloupcem a srozumitelným umístěním; stejné kontroly a zpětná vazba. |
| Odebraná práva | Otevření odkazu při odmítnutí GET nástěnky nevyřadí její starou místní kopii. | Sdílená cesta pro čtení nástěnky; prokazatelné board 403/404 čistí serverová data a zachová vlastní práci. |
| Cizí přesun mezi nástěnkami | Běžné uložení cílového snímku může narazit na stejné ID karty ještě uložené ve zdroji. | Atomické přemístění existující karty a ochrana před starým souběžným snímkem. |
| Přijatá příloha | Po následném odstranění může zůstat trvale v přijatém stavu a blokovat další práci. | Potvrdit známý výsledek a vyřešit nedostupnost bez opakování uploadu. |
| Sloupce | Běžná změna pořadí nepřečísluje ostatní sloupce; server má pro tento účel jinou operaci. | Trvalé OCS řazení s kotvou, bezpečná obnova přijatého výsledku a převod starých operací. |
| Formuláře | Potvrzení leží za dlouhým obsahem, barvy používají hex a umístění nulový index. | Vždy dosažitelné potvrzení, pojmenovaná paleta a lidské volby umístění. |
| Více štítků/lidí | Výběr jedné položky zavře panel; během ukládání se může ztratit zpráva o chybě. | Jeden vícečetný výběr, atomické předání změn frontě a zavření až po výsledku. |
| Hlavní záložky | Opuštění Mých úkolů zahodí místní filtry a text; uložená skrytá záložka naopak nesmí neustále obnovovat síťová data. | Zachovat stav podle účtu a řídit obnovu viditelností. |
| Koncepty a konflikty | Chybí kontext, čas a význam rozhodnutí; běžný textový náhled skrývá rozdíly metadat. | Rozlišit skupiny, ukázat změněná pole i známá oprávnění a popsat důsledky voleb. |
| Velké písmo | Pevná hlavička se může nevejít nad seznam v landscape a vytvořit přetečení. | Posouvatelná hlavička a rozložení podle skutečně dostupného prostoru i měřítka textu. |

Seznam je pracovní. Zdrojový nález se nepovažuje za potvrzenou příčinu konkrétní hlášené chyby, dokud neodpovídá dané verzi a reprodukci.

Vyvrácený dílčí nález: náhled konceptu komentáře čte `description` správně, protože do tohoto pole ukládá text `saveCommentDraft`. Mění se jeho kontext a čitelnost, nikoli smlouva uložených dat.

## Konkurence převedená do implementace

| Vzor | Použití v OwnDecku | Meze serveru |
|---|---|---|
| Trello: čitelné informace na kartě | Štítky, termín a jeho stav, přiřazení, dokončení a dostupné počty. | Zobrazují se skutečná data Decku; nevymýšlí se nepřítomné počty. |
| Trello: filtr přímo v nástěnce | Hledání, osoba, štítek a termín; jasné aktivní filtry a jejich zrušení. | Filtr nemění serverové pořadí; při skrytých kartách nesmí přesun použít chybný index. |
| Trello/Todoist: rychlé přidání | Krátký tok z hlavních obrazovek i sloupce; delší úpravy jsou druhý krok. | Cíl se ukáže před uložením; automaticky se nezakládá serverový Inbox. |
| Trello: přímé akce a checklist | Jednotné přesuny a dokončení, ovladatelný seznam úkolů v podporovaném Markdownu. | Zachovat ostatní text popisu a limity Decku; nepřidávat smyšlené API pro podúkoly. |
| Todoist: seznam a nástěnka nad stejnými úkoly | Shodné akce a filtry v obou pohledech, uchovaná volba uživatele. | Přepnutí pohledu nesmí změnit data ani sdílené pořadí. |
| Asana: srozumitelná práce bez připojení | Rozlišit místní uložení, čekání, potvrzení, konflikt a odmítnutí; jasná cesta k nápravě. | Žádné sliby okamžité synchronizace při ukončené aplikaci. |

Podklady: [Trello filtry](https://support.atlassian.com/trello/docs/filtering-for-cards-on-a-board/), [Trello termíny](https://support.atlassian.com/trello/docs/adding-dates-to-cards/), [Trello štítky](https://support.atlassian.com/trello/docs/adding-labels-to-cards/), [Trello checklist](https://support.atlassian.com/trello/docs/adding-checklists-to-cards/), [Trello rychlé zachycení](https://support.atlassian.com/trello/docs/trello-inbox/), [Todoist nástěnky](https://www.todoist.com/help/articles/board-layout-in-todoist-nutzen-AiAVsyEI). Další podklady a rozdíly jsou v `competition.md`.

## Matice E2E

Každá rodina se rozpadne na jednotlivé scénáře v běhovém manifestu. Prázdný, přeskočený nebo pouze připravený scénář není splněný. Není-li funkce na daném serveru dostupná, ověří se správné omezení UI a její podporovaná varianta na odpovídající verzi serveru.

| ID | Rodina | Povinné postupy a důkazy |
|---|---|---|
| E01 | Přihlášení | Adresa, podadresář, systémový prohlížeč, schválení, návrat, zrušení, timeout, chybná adresa, certifikát, QR, skutečné bezpečné úložiště a restart. |
| E02 | Účty | Přidání, přepnutí při otevřené kartě/požadavku, stejné serverové ID, obnovení po 401, odebrání s rozepsanou prací a odvolání tokenu. |
| E03 | Nástěnky | Vytvoření, název/barva, vlastní/sdílené, archiv/obnova, smazání/obnova, kopie se všemi volbami, zakázané vytváření. |
| E04 | Sloupce | Vytvoření, přejmenování, pořadí, smazání, nastavení/zrušení hotového sloupce, zachování karet a oprávnění. |
| E05 | Pohledy a filtry | Seznam/sloupce, uložení volby, telefon/tablet, hledání, osoba, štítek, termín, aktivní filtry, zrušení a prázdný výsledek. |
| E06 | Vytvoření a editace | Rychlé přidání, cílový sloupec, název, popis, začátek/termín/barva/dokončení, zrušení, obnovení konceptu a zachování nepozměněných polí. |
| E07 | Přesuny a pořadí | Menu i tažení, stejný/jiný sloupec i nástěnka, začátek/konec/kotva podle čerstvých dat, prázdný cíl, automatický posun, změna filtru, cizí změna, odmítnutí a restart. Mezi nástěnkami zachovat identitu, komentáře a přílohy; ověřit štítky, hotový sloupec a obnovu mezi přenosem a řazením. |
| E08 | Akce karty | Kopie, odkaz, archiv/obnova, smazání, štítky, přiřazení, vazby a přechod na související kartu. |
| E09 | Checklist a Markdown | Čtení, změna položky, uchování ostatního textu, odkazy, externí obrázky jen po akci uživatele, souběžná změna. |
| E10 | Komentáře | Stránkování, vytvoření/odpověď, vlastní úprava/smazání, cizí komentář, koncept a nejasně přijatý POST bez duplikace. |
| E11 | Přílohy | Systémový picker, upload, existující soubor, oba serverové typy, stažení/cache, otevření/export, odpojení, legacy obnova, odmítnutí/kvóta a shoda obsahu. |
| E12 | Sdílení | Uživatel/skupina/tým dle serveru, změna ACL, čtenář/editor/správce, odebrání během čtení/zápisu, vyřazení cache a uchování vlastní práce. |
| E13 | Moje úkoly a hledání | Vlastní karty, dnes/po termínu/bez termínu, archiv/hotové, místní/online výsledky, neúplná cache, limit výsledků a otevření správného účtu. |
| E14 | Oznámení a odkazy | Nativní karta, ostatní bezpečný odkaz, cold/warm start, podadresář, cizí URL, chybějící karta a odvolané oprávnění. |
| E15 | Fronta a konflikty | Offline vytvoření/úprava/pořadí, restart, závislosti, serverový konflikt, lokální/serverové hodnoty, zahození/opakování, nejistý POST, 429 a obnova přihlášení. |
| E16 | Nastavení | Jazyk/vzhled/verze, zachování rozpracované navigace, přepínače obou telemetrií, návrat z importu a persistence po restartu. |
| E17 | Telemetrie | Bez konfigurace nulový provoz, automatické zapnutí dostupných služeb na čisté instalaci, každá zvlášť vypnutelná, persistence a zastavení odesílání, bezpečná skutečně doručená událost a žádný přenos obsahu nebo tajemství. |
| E18 | Přístupnost a výkon | 200% text, landscape, klávesnice, čtečka a focus, 48bodové cíle, alternativy gest; profile start/scroll 1 000 karet na S9/S21. |

## Pořadí práce

1. Zjistit skutečné nedostatky celého produktu a sestavit úplný seznam scénářů.
2. Současně opravit datové příčiny, sjednotit akce a zavést jednotnou mobilní hierarchii obrazovek.
3. Průběžně ověřovat oddělené kandidáty na pozadí; nové chyby vracet do implementace.
4. Závěrečné E2E musí pokrýt společnou revizi. Až potom lze tvrdit, že je redesign funkční a připravený k vydání.
