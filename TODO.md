# OwnDeck: úkoly

Tento seznam je průběžný zdroj další práce. Po dokončení celku zapsat výsledek a důkaz; nedokončený bod ponechat otevřený. Nové požadavky doplnit sem před implementací.

- [ ] R03 Kompletní review všech funkcí, datových cest a obrazovek proti zadání; nálezy a přijímací podmínky v `docs/review-redesign.md`.
- [ ] R04 Redesign a refaktor celé aplikace podle review a konkrétních vzorů Trella/Todoistu/Asany; jednotné akce, viditelná metadata, rychlé přidání, filtry a srozumitelné stavy.
- [ ] R05 Opravit všechny doložené funkční chyby z review a E2E; nezúžit práci jen na původně zmíněné přesouvání.
- [ ] R06 Kompletní E2E všech funkcí na finálním kandidátu; skutečný Nextcloud, Android S9/S21 a iOS simulátor, samostatně chyby, offline, restart a oprávnění. Dílčí widget test ani místní náhrada serveru nejsou důkazem této položky.

## Nálezy celkového review a právě prováděný redesign

- [x] B05 Opraven kolizní zápis karty přesunuté jiným klientem mezi nástěnkami i návrat staršího snímku; `f95b78d`, šest reprodukcí před opravou selhalo, po opravě 129 store testů prošlo. E2E patří do R06.
- [x] B06 Čtení nástěnky z odkazů sjednoceno v `fa63597`; board 403/404/noREAD vyřadí cache, card 403 ostatní nástěnku nemaže. Pět protokolových a 29 mobilních testů prošlo; skutečný E2E zůstává v R06.
- [x] B07 Přijaté přílohy při následném odstranění nebo přesunu nezablokují frontu a neodesílají další POST; převzato z `cb8b786`, 137 store a 29 mobilních testů prošlo. E2E zůstává v R06.
- [x] B08 Nakonfigurované telemetrie jsou na čisté instalaci zapnuté a lze je samostatně vypnout. Nastavení jej vysvětlí, E17 ověří výchozí stav i vypnutí.
- [x] B09 Zastaralá fixture testu obnovy fronty doplněna o skutečný tvar readbacku karty/sloupce v `2251930`; cílený test a analyzer prošly, nejde o opravu produkce.
- [x] B10 Řazení sloupců používá trvalé OCS reorder a převod starých operací (`b54d406`); pořadí pokrývají store testy. Skutečné UI a server zůstávají v R06.
- [x] B11 Rychlé přidání při zániku výslovného cíle nevymění sloupec; reprodukce před opravou selhala, po opravě prošla v sedmi scénářích rychlého přidání (`1a58735`).
- [x] B12 Nový sloupec ukládá název a samostatné umístění bez starého order=999 (`ba77d62`); widget/SQLite scénář ověřil vytvoření za zvoleným sloupcem.
- [x] B13 Akce Přidat kartu při malé výšce patří do horního pruhu (`3110575`); původní překrytí nabídky reprodukováno a cílený widget test i analyzer prošly. Opravené APK ještě ověřit na S9.
- [x] B14 Evidence zaniklé polohy a opakování odmítnutého čtení chrání přesun při závodu prázdný zdroj → cíl → starý zdroj (`0b11e38`); regresní store scénáře prošly.
- [x] B15 Převod staré pozice zachovává původní pořadí záměrů před novějšími přesuny (`bd5fcd5`); regresní store scénáře prošly.
- [x] B16 Již přiřazené osoby a štítky mimo nabídku cílové nástěnky lze zachovat nebo odebrat (`7611139`); testy ověřily i rozlišení typu účastníka.
- [x] B17 Editory rozlišují ztrátu oprávnění, přihlášení, čekající rozhodnutí a chybu místního uložení (`36352f9`); osm widget/SQLite scénářů prošlo.
- [x] B18 Metadata přijímají pouze textové názvy a zobrazují známé typy přiřazení bez raw JSON (`ea667cd`); regresní testy prošly.
- [x] B19 Filtr Nepřiřazeno respektuje i skupiny a další existující typy přiřazení (`ea667cd`); regresní scénář prošel.
- [x] B20 Běžné editace používají OCS aktualizaci s povinným ID a zachováním archivace/smazání (`6831b8c`, `b6f0a83`); tři skutečné API scénáře na Decku 1.18.5 prošly včetně souběžného smazání a archivace. Nativní UI patří do R06.
- [x] B21 Viditelný detail i přehled obnovují data po návratu a změně sítě bez nového čtení zakrytých tras (`1d058b4`, `ed41e58`); 25 testů prošlo, analyzer čistý.
- [x] B22 Správa sloupce je v nabídce bez přetečení (`e7d07c2`); reprodukce selhala před opravou, po opravě osm testů prošlo včetně správce a 200% textu. Opravené APK ještě ověřit na S21.
- [x] B23 Rychlé přidání respektuje spodní systémový okraj i klávesnici (`b5ba90b`); reprodukce selhala před opravou, po opravě osm testů prošlo. Opravený dotykový cíl ještě ověřit na S21.
- [x] B24 Přesuny uchovávají začátek/konec/kotvu a vyhodnocují je proti čerstvému sloupci (`e68650c`, `cdb05f0`); zaniklá kotva blokuje zápis, starší číselná fronta zůstává čitelná. Devět position-intent testů prošlo; `9fce5e8` navíc předá záměr serveru i při shodné místní pozici, reprodukce a 32 navazujících UI testů prošly.
- [x] B25 Vnořená navigace nyní předává systémové Zpět aktivnímu účtu (`e9f06ac`) a respektuje ochranu konceptů; tři reprodukce před opravou selhaly, po opravě deset testů prošlo. Nové APK ověřit na S9/S21 v R06.
- [x] B26 Čekající přesun zachová názvy cíle po potvrzení místních ID; zahození obnoví zdroj i cíl bez mutací, opakování pozice odešle právě jedno řazení. Tři reprodukce před opravou selhaly, poté prošlo 17 cílených a 34 regresních testů, analyzer čistý.
- [x] B27 Sdílení ukazuje pouze dostupné textové jméno příjemce; chybný typ nezobrazí jako JSON a chybějící jméno nenahradí interním ID. Widget reprodukce před opravou selhala, po opravě prošla, analyzer čistý.
- [x] T05 Sedm zastaralých očekávání CI `40295912768` sladěno s obnovováním viditelného detailu, plným seznamem přiřazených a kotvou přesunu; nulové mutace při zrušení zůstávají ověřené. Všech 21 souvisejících testů a analyzer prošly; společné CI zopakovat v T01.
- [x] B28 Fronta zobrazuje známý důvod odmítnutí (cíl, archivace, soubor, odpověď) bez syrových chyb; význam nejistého a přijatého zápisu zůstává zachován. Čtyři původní reprodukce a dvě navazující kontroly významu přílohy/nejistého zápisu před opravou selhaly; po opravě všech 14 testů prošlo, analyzer čistý.
- [x] B29 Přehled i nástěnka rozlišují načítání, chybu bez uložených dat, filtrovaný výsledek a potvrzeně prázdný obsah; existující data zachována. Pět reprodukcí před opravou selhalo; po opravě 16 UI/SQLite testů prošlo, analyzer čistý.
- [ ] B30 iOS kandidát po schválení v Safari při rozděleném testovacím průchodu vrátil chybu spojení místo přihlášení; aplikace se nerestartovala. Ověřit souvislý tok a příčinu případného timeoutu před změnou přihlašovací logiky.
- [x] T04 E2E používá oddělené testovací identity a evidenci vlastních záznamů; úklid odstraňuje pouze testem vytvořená data a přístupy, ověřuje jejich stav a zachovává ostatní účty.
- [x] U01 Společný souhrn karty zobrazuje štítky, termíny, dokončení, známé počty a přiřazení (`5514cc7`, `3b82d66`, `ea667cd`); widget testy metadat prošly. E2E všech cest zůstává v R06.
- [x] U02 Rychlé přidání z přehledu a sloupce uchová cíl podle účtu i koncept (`1a58735`, `b5ba90b`); osm cílených testů prošlo. Opravený bezpečný okraj ověřit v R06.
- [x] U03 Hlavní hlavičky ukazují účet a pracovní akce, správa je v nabídce (`ba77d62`, `e7d07c2`, `3110575`); testy malé výšky a plných práv prošly.
- [x] U04 Přesun používá společný dialog nástěnky/sloupce a volby začátek/konec/před/za (`cdb05f0`); backend zachovává kotvu do čerstvého čtení (`e68650c`). 26 navazujících UI/SQLite testů prošlo; skutečný server v R06.
- [x] U05 Detail ukazuje úplný název, metadata, všechny štítky/lidi, začátek a popis před vedlejšími sekcemi (`ba77d62`, `ce0b476`); cílené testy prošly.
- [x] U06 Moje úkoly mají rychlé termínové volby a panel podrobných filtrů, nástěnky kombinované filtry se zrušením (`5514cc7`); widget scénáře prošly.
- [ ] U07 Sjednotit význam a zobrazení místního uložení, odesílání, potvrzení a problému; počet čekajících změn a srozumitelné konkrétní chyby místo obecné hlášky.
- [x] U08 Uložit/Odeslat je v horním pruhu, autosave a chybové kategorie zachované (`ba77d62`, `36352f9`); scénáře dlouhého textu, klávesnice a chyb místního uložení prošly.
- [ ] U09 Barvy vybírat vizuálně podle názvu; nikde v běžném UI nevypisovat hex, serverová ID, nulové indexy ani syrové chyby. Platí pro karty, nástěnky, štítky i konflikty; stávající vlastní barvu zachovat.
- [x] U10 Vícečetný výběr drží panel až do Hotovo a předá změny atomicky; při ukládání nejde zahodit tažením (`ba77d62`, `43a16e2`); šest widget/SQLite scénářů prošlo.
- [x] U11 Hlavní záložky uchovají stav podle účtu, skryté neobnovují data (`ba77d62`, `ed41e58`); testy navigace a viditelnosti prošly.
- [x] U12 Čekající změny rozlišují čekání, konflikt, nejistý výsledek a koncepty (`3c56742`); přijatý přenos ukáže zbývající umístění bez opakování celé operace (`d9d7644`), šest nových regresí prošlo.
- [x] U13 Koncepty mají typ, kontext a čas (`3c56742`); zaniklý přístup odstraní kontext. Náhled komentáře ponechán správně v description, testy prošly.
- [ ] U14 Prázdné/chybové stavy rozlišují prázdný obsah, filtr, neúplnou cache a chybějící oprávnění; nabídnout jednu odpovídající následující akci.
- [ ] U15 Sjednotit vzhled a význam komponent napříč všemi obrazovkami při zachování rodiny OwnTalk/Notes; ověřit světlý/tmavý režim, 200% text, klávesnici a čtečku.
- [x] U16 Náhled Markdownu je čitelný a omezený délkou, checkboxy v kódu nezvyšují průběh (`e91c96f`); cílené parser/widget testy prošly.
- [x] U17 Konflikty nástěnek, štítků a sdílení ukazují známá metadata a práva bez JSON/ID/bitů (`8ef69fc`); testy porovnání prošly.
- [x] F01 Checklist mění položku přes stejnou trvalou frontu a zachová ostatní popis (`e485272`, `6465b8e`); devět parser/widget testů a zapnutí/vypnutí ve skutečném UI kandidátu `96b8662` prošly. Finální společná revize v R06.
- [ ] F06 Přesun mezi nástěnkami implementován (`e68650c`, `cdb05f0`); skutečné API 1.18.5 ověřilo identitu, obsah, metadata, komentáře, štítky podle práv a kotvu. API 1.18.5 ověřilo i zachování obsahu přílohy; API 1.19.1 a nativní UI obou systémů zůstávají v R06.

## Navazující funkce z konkurenční analýzy

- [ ] F02 Návrh z Trella: hromadný výběr karet a přesun/archivace; před realizací vyřešit částečný úspěch, oprávnění každé karty a srozumitelné obnovení.
- [ ] F03 Návrh z Trella/Vikunji: kalendářní přehled existujících termínů bez kopírování dat; rozlišit začátek, termín a dokončení, přiznat neúplná místní data.
- [ ] F04 Návrh z rychlého zachycení Trella: příjem textu/odkazu ze systémového sdílení do nového úkolu; vždy potvrdit účet a cíl, zachovat koncept při zrušení přihlášení.
- [ ] F05 Návrh z Trello checklistů: vložení více položek najednou a skrytí hotových; nejprve zachovat bezeztrátový převod do podporovaného Markdownu Decku.
- [ ] F07 Návrh z API auditu: nabídnout nové přiřazení skupiny/týmu na kartu podle skutečně podporovaného typu; stávající přiřazení nyní zachovat a umožnit odebrat bez záměny za stejně pojmenovaného uživatele.

## Původní plán a průběžné důkazy

- [x] P03 Repozitář `nks-hub/owndeck` je veřejný; anonymní přístup ověřen, README, licence a štítky zkontrolované, aplikace doplněna do profilu organizace.

- [x] P01 Repozitář `nks-hub/owndeck` založen a ověřen přes GitHub API; vydávaná verze je `0.1.0+2`, tag `v0.1.0+2`, pravidla v `docs/versioning.md`.

- [x] P00 Ověřit výchozí stav a vytvořit plán před zahájením vývoje.
- [x] A01 Projít aktuální kód OwnTalk/OwnNotes; konkrétní soubory a revize v `docs/reuse.md`.
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
- [x] D06g Retry-After se ukládá pro účet, přežije restart a platí i pro přímé čtení souborů; čekající fronta se obnovuje v popředí také z přehledu nástěnek. Ověření aktuálního sloučeného stromu čeká na T01.
- [x] D07 Místní i serverové hledání, Moje úkoly, online přehled a webové/ncdeck odkazy hotové; D07 API + web ověřené na `14318f5`, cold/warm a oddělení účtů fyzicky na S21. Serverové hledání poctivě omezeno na 200 výsledků.
- [x] D08 Volitelné Sentry/Rybbit, konfigurace přes CI, obě služby v našich buildech a oddělené přepínače hotové; doručení ze S9 ověřené, nastavení přežije restart na S9/S21. Sentry zachytává Dart/Flutter chyby, nativní crash/hang sběr není zapnutý.
- [x] D09 České/anglické texty, srozumitelné chyby, společné přihlášení, vlastní launcher ikony a hlavní přístupnost zapojené; 200% text a malá výška ověřené testy, landscape editor i Cancel fyzicky na S9 v `ba364e0`. Formální TalkBack/VoiceOver audit se netvrdí.
- [x] D10 Kopie karet, směrované vazby, hotový sloupec a přehled oznámení hotové a ověřené i na Decku 1.18.5. Vazby neblokují dokončení karty. OS push není zapnutý; chybí ověřený mobilní push kanál pro Deck.
- [x] D11 Nastavení vzhledu, jazyka, verze a účtů doplněno v `781dbb0`, třetí navigační cíl v `6c3eeb3`; test ověřil zachování navigace, rozepsaného textu a filtru při změně jazyka/tématu.
- [x] D12 Seznam/sloupce, uchování pohledu, široké rozložení a tažení mezi sloupci sloučené v `93ab150`; 12 cílených a 22 navazujících scénářů prošlo pro samostatnou revizi změny.
- [x] D13 Kopie nástěnky přes trvalou frontu a serverový import jsou zapojené v `4fc690b`, `708defd`, `2cbef2a`; 122 databázových a 9 cílených UI scénářů prošlo, skutečný Deck 1.19.1 ověřil šest voleb API. Průběžný test zařízení patří do T03.
- [x] D15 Přehled konfliktů v `c5ac925` zobrazuje místní a serverový termín, začátek, barvu a dokončení; rozlišuje vymazanou a chybějící hodnotu. Kód posouzen čtením; nové testy jsou odložené v T01.
- [x] D14 Oznámení otevírají ověřené karty nativně se stejným účtem; ostatní odkazy zůstávají v prohlížeči. Šest widget testů a analyzer prošly včetně skutečného načtení karty a nulového volání externího prohlížeče.
- [x] B01 Migrace z verzí 1–3 opravena v `a329d28`; před opravou tři selhání na duplicitním sloupci, po opravě všech osm migrací 1–8 zachovalo účty, koncepty i čekající zápisy.
- [x] B02 Přijaté zápisy se už neopakují ani nezaseknou po cizím přesunu; aktuální sloupec/nástěnka se ověřují, 403/404 nevracejí cache. `77cea35` + `ca8c723` + `41b25b3`, 107 databázových testů a analyzer prošly.
- [x] B03 Známá ztráta přístupu čistí serverovou cache i stažené soubory, blokuje zápisy a zachovává vlastní koncepty/staging. Ověřeno 28 mobilními testy, databázovou sadou a skutečným odebráním sdílení na jednom serveru.
- [x] B04 Hranice startdate/color opravena na Deck 1.18 v `b9c6903`; 108 protokolových testů prošlo a skutečný Deck 1.18.5 potvrdil vytvoření, změnu i vymazání obou polí se zachováním ostatních hodnot.
- [ ] T01 Ověřit společnou finální revizi; dílčí historické výsledky nepokrývají celý nový strom.
- [ ] T02 Ověřit finální revizi proti skutečnému Nextcloudu, oba buildy a doručení telemetrie.
- [x] T02b Dva vlastní izolované účty na stejném serveru: READ a EDIT omezení i odebrání sdílení ověřené; skutečný DeckSync vyřadil cache bez mutace a zachoval čekající texty. Celkem 12 scénářů včetně rozšířených polí a úklidu API.
- [ ] T03 Kompletní E2E na S9/S21 a iOS simulátoru obnovené; kandidát `2cbef2a` má jen dílčí historické ověření proti místnímu testovacímu serveru. Finální redesign tím není ověřený.

Aktuální rozsah zahrnuje analýzu, review, redesign, refaktor a E2E všech funkcí včetně praktického zapracování konkurenční analýzy. Probíhá paralelní review datové vrstvy, UI a příprava E2E; staré dokončené implementační body nejsou důkazem přijatelnosti finálního produktu. Google Play zatím obsahuje 0.1.0+2.

- [x] N01 Související práce na OwnNotes je dokončená; přesný rozsah a důkazy jsou v jeho vlastním TODO.

- [x] R01 OwnTalk `c994a07b`: kontrola názvu serveru čte SAN certifikátu místo CN a přihlašovací karta neslučuje ovládací prvky pro čtečku. Převzato stejné řešení jako v Decku; nové testy a vydání OwnTalku se neprováděly.
- [x] R02 Google Play alpha 0.1.0+2 schváleno a publikováno; API potvrzuje PUBLISHED, ověřené podklady a tři skupiny jako OwnNotes; testovací odkaz: https://play.google.com/apps/testing/com.nkshub.nextclouddeck.
- [ ] P02 Na finální revizi ověřit p95 celého snímku do 16,7 ms a podle měření odstranit příčinu zpomalení; staré měření S9 bylo 24,388 ms, S21 10,268 ms. Úspory D12 samy splnění cíle nedokládají.
