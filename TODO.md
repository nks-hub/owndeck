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
- [x] B30 Příčina: čekací cyklus přihlášení ukončil celý tok po jediném ztraceném dotazu na mrtvém socketu po návratu ze Safari; souvislý XCUITest na `535d167` prošel za 42 s, rozdělený 613s běh selhal. Oprava `3a28e8d` opakuje `transport_failed`/`timeout` nejvýše pětkrát po sobě; reprodukce selhala před opravou, celá mobilní sada prošla. Nativní ověření opraveného buildu patří do R06.
- [x] B31 Čtení místní databáze a uložení konceptu mají vlastní hlášky; výzva k odemknutí zůstává u úložiště přihlašovacích údajů. Dvě reprodukce před opravou selhaly; 18 navazujících testů včetně zachování textu po chybě prošlo, analyzer čistý.
- [x] B32 Potvrzení odebrání účtu uvádí smazání neodeslané práce i odvolání hesla sdíleného s dalšími klienty; dialog se posouvá i při 200% textu na šířku. Reprodukce před opravou selhala, čtyři testy včetně zachování konceptu po Zrušit a analyzer prošly; chování revokace se nemění.
- [x] B33 Dialog přesunu má stabilní výšku a posuvný obsah (`9b55562`); deset testů prošlo včetně 200% textu a orientace na šířku. Nativní iOS na `bd3b039` potvrdil stejné přístupnostní souřadnice i skutečný přesun před zvolenou kartu; server potvrdil obsah, metadata, komentář, přílohu a štítky.
- [x] B34 Profil S9 ukázal zbytečné výjimky při čtení chybějícího termínu a rozbor prostých vět jako Markdown; obě práce odstraněny bez změny náhledu. Osmnáct testů včetně prázdných číslovaných seznamů prošlo, analyzer čistý; přínos na telefonu a cílové časy zůstávají v P02.
- [x] B35 Komentáře a přílohy rozlišují načítání, chybu bez místních dat a potvrzeně prázdný seznam. Dvě reprodukce před opravou selhaly; devět testů včetně opakovaného načtení prošlo, analyzer a nezávislé review bez nálezu. Nativní ověření zůstává v R06.
- [x] B36 Komentáře a přílohy rozlišují chybu místního čtení od ztráty přístupu a nedostupné karty; dvě reprodukce nad selhávajícím SQLite čtením před opravou selhaly. Po opravě všech jedenáct souvisejících testů prošlo, analyzer a nezávislé review bez nálezu.
- [x] B37 Přijatá změna má na kartě štítek Přijato a ikonu synchronizace; podrobné vysvětlení zůstává pro čtečku i tooltip. Původní reprodukce selhala, oprava a 35 souvisejících testů karet/fronty/konfliktů prošly, analyzer i nezávislé review bez nálezu.
- [x] B38 Nové karty určují konec z čerstvého sloupce a stejně se promítají místně; stará fronta s 999 zůstává čitelná. Před zápisem se atomicky ověří platný vlastní zámek a stav operace. Čtyři reprodukce selhaly před opravou; 200 store a 274 mobilních testů prošlo, analyzer/review čisté. Nativní iOS `21ca536` a server potvrdily dvě nové karty za původními, správné pořadí po potvrzení i restartu a zachování ostatních dat.
- [x] B39 Formulář je ukotvený nahoře a změnu klávesnice zpracuje bez posunu celého dialogu (`cc0af45`); pět testů prošlo včetně focusu, textu, uložení a 200% landscape. Nativní iOS `21ca536` potvrdil shodu obrazu a přístupnostních souřadnic Uložit, skutečné přerovnání sloupce i zachování pořadí po restartu; server ověřil ostatní data beze změny.
- [x] B40 Vypnutí Rybbit odstraní offline frontu po ukončení SDK; přerušený úklid se dokončí před dalším zapnutím a starší zapnutí nepřepíše novější vypnutí. Reprodukce se skutečným SDK/Hive a dvě závodní situace selhaly před opravou; všech 32 telemetrických testů prošlo, analyzer/review čisté. Běžný shutdown frontu zachová, nezávislé přepínače i automatické zapnutí nakonfigurovaných buildů zůstávají.
- [x] B41 Tlačítko neodeslaných změn má srozumitelný přístupnostní název i lokalizovaný počet. Původní reprodukce ukázala pouze „1“; po opravě 15 testů prošlo včetně skutečné aktivace přes SemanticsAction.tap do fronty, analyzer a nezávislé review bez nálezu. Nové APK ještě ověřit v R06.
- [x] T04 E2E používá oddělené testovací identity a evidenci vlastních záznamů; úklid odstraňuje pouze testem vytvořená data a přístupy, ověřuje jejich stav a zachovává ostatní účty.
- [x] U01 Společný souhrn karty zobrazuje štítky, termíny, dokončení, známé počty a přiřazení (`5514cc7`, `3b82d66`, `ea667cd`); widget testy metadat prošly. E2E všech cest zůstává v R06.
- [x] U02 Rychlé přidání z přehledu a sloupce uchová cíl podle účtu i koncept (`1a58735`, `b5ba90b`); osm cílených testů prošlo. Opravený bezpečný okraj ověřit v R06.
- [x] U03 Hlavní hlavičky ukazují účet a pracovní akce, správa je v nabídce (`ba77d62`, `e7d07c2`, `3110575`); testy malé výšky a plných práv prošly.
- [x] U04 Přesun používá společný dialog nástěnky/sloupce a volby začátek/konec/před/za (`cdb05f0`); backend zachovává kotvu do čerstvého čtení (`e68650c`). 26 navazujících UI/SQLite testů prošlo; skutečný server v R06.
- [x] U05 Detail ukazuje úplný název, metadata, všechny štítky/lidi, začátek a popis před vedlejšími sekcemi (`ba77d62`, `ce0b476`); cílené testy prošly.
- [x] U06 Moje úkoly mají rychlé termínové volby a panel podrobných filtrů, nástěnky kombinované filtry se zrušením (`5514cc7`); widget scénáře prošly.
- [x] U07 Společný `sync_state.dart` dává jeden název, vysvětlení a ikonu stavu změny na kartě, v detailu, přílohách, komentářích, nástěnkách, sloupcích, štítcích, sdílení, vazbách i ve frontě; fronta a detail ukazují počet změn, `invalid_attachment` a `identity_mismatch` mají vlastní hlášku (`6276c24`). Dvanáct reprodukcí U07/U14 selhalo před opravou, 312 mobilních testů a analyzer prošly.
- [x] U08 Uložit/Odeslat je v horním pruhu, autosave a chybové kategorie zachované (`ba77d62`, `36352f9`); scénáře dlouhého textu, klávesnice a chyb místního uložení prošly.
- [x] U09 Karty, nástěnky, štítky i konflikty používají pojmenované barvy a zachovávají vlastní odstín; metadata a umístění mají textové názvy místo ID, nulových indexů či JSON. Formulářové a stavové testy v CI `943a7b9` prošly včetně nezobrazení hexu a zachování vlastní barvy; úplné nativní ověření zůstává v R06.
- [x] U10 Vícečetný výběr drží panel až do Hotovo a předá změny atomicky; při ukládání nejde zahodit tažením (`ba77d62`, `43a16e2`); šest widget/SQLite scénářů prošlo.
- [x] U11 Hlavní záložky uchovají stav podle účtu, skryté neobnovují data (`ba77d62`, `ed41e58`); testy navigace a viditelnosti prošly.
- [x] U12 Čekající změny rozlišují čekání, konflikt, nejistý výsledek a koncepty (`3c56742`); přijatý přenos ukáže zbývající umístění bez opakování celé operace (`d9d7644`), šest nových regresí prošlo.
- [x] U13 Koncepty mají typ, kontext a čas (`3c56742`); zaniklý přístup odstraní kontext. Náhled komentáře ponechán správně v description, testy prošly.
- [x] U14 Společný `StateMessage` s nejvýše jednou akcí: hledání a Moje úkoly rozlišují filtr, neúplnou cache, potvrzeně prázdný obsah a neověřenou identitu; štítky, sdílení a vazby po chybě čtení netvrdí prázdný seznam a po ztrátě přístupu nabídnou zavření; archiv má vlastní text (`6276c24`).
- [x] U15 Devět obrazovek, editory, koncepty, kalendář, nástěnka, oznámení i hledání používají společný `StateMessage`, `IncompleteDataNotice` a `CompletionBox`; ikony stejného významu sjednocené (`f7d959a`). Sdílené prvky ověřené ve světlém/tmavém režimu a při 200% textu; plné nativní ověření v R06.
- [ ] U18 Redesign vzhledu karty na nástěnce, v seznamu, hledání i kalendáři: majitel hodnotí současný vzhled karet jako nevyhovující. Nový návrh se světlým/tmavým režimem, 200% textem a čtečkou, v rozpočtu P02 (p95 ≤ 16,7 ms na S9); ověřit snímky před/po.
- [x] U19 Předvolby jako mřížka kulatých vzorků s názvem v tooltipu a pro čtečku, trvalý duhový vzorek pro vlastní barvu a dialog s odstínem, sytostí, světlostí, tlačítky +/−, náhledem kontrastu a volitelným kódem (`084db94`, `fd26ffe`). Vybraná vlastní barva zůstává jako samostatný vzorek; 43 testů barev a formulářů prošlo, vzhled ověřen vykreslením ve světlém i tmavém režimu.
- [x] U20 Přepínač Sloupce/Seznam přesunut do horní lišty jako ikona, vyhledávání zhuštěné a řádek s archivem/filtrem jen při aktivním stavu (`158f7be`); 47 testů nástěnky prošlo.
- [x] U16 Náhled Markdownu je čitelný a omezený délkou, checkboxy v kódu nezvyšují průběh (`e91c96f`); cílené parser/widget testy prošly.
- [x] U17 Konflikty nástěnek, štítků a sdílení ukazují známá metadata a práva bez JSON/ID/bitů (`8ef69fc`); testy porovnání prošly.
- [x] F01 Checklist mění položku přes stejnou trvalou frontu a zachová ostatní popis (`e485272`, `6465b8e`); devět parser/widget testů a zapnutí/vypnutí ve skutečném UI kandidátu `96b8662` prošly. Finální společná revize v R06.
- [ ] F06 Přesun mezi nástěnkami implementován (`e68650c`, `cdb05f0`); skutečné API 1.18.5 ověřilo identitu, obsah, metadata, komentáře, štítky podle práv a kotvu. API 1.18.5 ověřilo i zachování obsahu přílohy; API 1.19.1 prošlo v CI `40318645367` na `996ef07` pro vlastníka i EDIT bez MANAGE včetně stažení přílohy přes účet přesouvajícího a úplného úklidu; úplné nativní UI ověření zůstává v R06.

## Navazující funkce z konkurenční analýzy

- [x] F02 Hromadný výběr z nabídky karty v obou pohledech, přesun společným dialogem se zachováním pořadí a archivace; každá karta jde samostatně trvalou frontou, výsledek po kartách (uloženo/selhalo/bez oprávnění), opakování jen selhaných se zachováním výběru (`00af4e9`). Sedm cílených testů včetně 200% textu prošlo; nativní ověření v R06.
- [x] F03 Moje úkoly mají přepínač Seznam/Kalendář: měsíční mřížka a agenda dne z místní cache bez kopírování, rozlišení začátku, termínu a dokončení ikonou i textem, upozornění na nástěnky bez uložených karet a otevření karty ve správném účtu (`b57bdc4`). Pět testů kalendáře a test zachování volby přes přepínání záložek prošly; karty bez termínu se nezobrazují.
- [x] F04 Příjem textu/odkazu ze systémového sdílení do nové karty s potvrzením účtu a cíle a konceptem při zrušení přihlášení. Android `ACTION_SEND` bez nových oprávnění (`2236d7b`), Dart tok (`dd9bdba`) a iOS Share Extension přes App Group `group.com.nkshub.nextclouddeck` (`e3a629c`). Simulátorový build `ba9c7b9` obsahuje `ShareExtension.appex`, 6 XCTestů a 331 mobilních testů prošlo; skutečný share sheet ověří R06.
- [x] B42 Sdílený text bez účtu se ukládá do `share.pending`, přežije restart a nabídne se po přihlášení; poškozená hodnota start neblokuje (`dfc5ed2`), pět testů úložiště a tři testy toku prošly.
- [x] B43 Odkaz na kartu a sdílený text se zachovají oba, nejdřív se otevře karta a pak nabídne text (`dfc5ed2`); reprodukce ztráty textu selhala před opravou.
- [ ] B45 Dvě sdílení těsně po sobě se přepíšou na Androidu i iOS, zachová se jen poslední; nález z implementace F04.
- [x] B46 P1 R03: odesílač zabral řádek jen podle stavu a poslal starý snímek návrhu; `startWrite` nově ověří shodu návrhu, nástěnky, sloupce, karty i základu a při změně zápis znovu načte. Platí pro karty, komentáře, akce, přílohy, strukturu, řazení sloupců, metadata i kopii nástěnky (`4f6ac01`); reprodukce odeslala A místo B, po opravě B.
- [ ] B47 P2 R03: iOS `ncdeck://share` přes UIScene nikdy nedojde do sdílení (`SceneDelegate` posílá URL jen do odkazů karet) a `CardLinkDelivery` přijímá libovolný host `ncdeck`.
- [x] B48 P2 R03: Moje úkoly ukazují upozornění na neuložené nástěnky s akcí Načíst karty a netvrdí prázdný seznam (`3c2b3ca`).
- [x] B49 P2 R03: přerušený komentář se při zavření synchronizace nebo ztrátě zámku vrátí do fronty místo stavu `sending` (`df07496`); reprodukce selhala před opravou.
- [ ] B50 P2 R03: iOS Keychain používá výchozí `unlocked` místo `*_this_device`, app password tak může přejít zálohou na jiné zařízení; přepsat i existující položky.
- [x] B51 P2 R03: tělo migrace běží v transakci; selhání vrátí změny a po odstranění kolize se databáze otevře ve verzi 9 (`5701467`). Osm migračních testů B01 dál prochází.
- [x] B52 P2 R03: 404 bez JSON (proxy, vypnutý Deck) vrací `deck_unavailable`, zápis zůstává ve frontě a cache se nemění; JSON 404 dál odvolá přístup (`7493201`). Chování Nextcloudu pro vypnutou aplikaci ve zdroji nedohledáno, použito konzervativní pravidlo. Store 207, protokol 125 a mobil 339 testů prošlo.
- [x] B53 P3 R03: kalendář řadí hotovou kartu ke dni a času dokončení, i bez termínu (`3c2b3ca`).
- [x] B54 P3 R03: dokončení jde z Mých úkolů, hledání i agendy kalendáře se stejnou kontrolou práv; odkaz na kartu Decku v popisu se otevře nativně (`3c2b3ca`).
- [x] B55 P3 R03: hromadné akce mají průběh, vypnutá tlačítka a ochranu proti druhému spuštění; souhrn říká Uloženo v telefonu (`37cb274`).
- [ ] B56 P3 R03: sdílený text se ztratí, když rychlé přidání nemá zapisovatelný cíl nebo selže čtení sloupců; koncept uložit hned.
- [ ] B57 P3 R03 (ověřit na zařízení): Android po návratu z Nedávných znovu doručí původní SEND/VIEW intent (`FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY`).
- [x] B58 P3 R03 (U15): chybové stavy se společnou obnovou, chyby místního zápisu hlášené jako zápis, chyba checklistu jako místní, buňka kalendáře 49 dp (`37cb274`). Dvanáct nových testů B48–B58 selhalo na starém kódu, 350 mobilních testů prošlo na `f7d959a`.
- [ ] R09 Před vydáním iOS zaregistrovat App Group `group.com.nkshub.nextclouddeck` a identifikátor `com.nkshub.nextclouddeck.ShareExtension` v Apple účtu a ověřit podepsaný build; nález z implementace F04.
- [x] F08 Archivované karty lze vybrat a hromadně obnovit (bez přesunu), výběr všech zobrazených karet respektuje filtr (`d42f12b`); dva nové widget testy prošly.
- [x] B44 Skrytý seznam Mých úkolů při přepnutí na kalendář znovu spouštěl stejný dotaz a do jeho dokončení animoval indikátor; StreamBuilder je nově klíčovaný dotazem (`50cd2fa`). Nález z testu F03, reprodukce selhala před opravou a 22 navazujících testů prošlo.
- [x] F05 Vícerádkové přidání položek `- [ ] ` na konec popisu stejnou trvalou frontou jako F01 a přepínač Skrýt hotové jen v pohledu; ostatní text zůstává bajtově shodný včetně CRLF (`2a2c49c`). Parserové a widget testy prošly.
- [x] F07 Přiřazení sdílené skupiny (typ 1, Deck 1.10+) a týmu (typ 7, 1.18+) podle verze serveru; bez známých capabilities se nenabízí. Skupiny a týmy mají v názvu typ, existující přiřazení lze odebrat bez záměny (`99b3acb`). Protokolové, store a widget testy prošly; živý server v R06.

## Původní plán a průběžné důkazy

- [x] R07 `0.1.1+4` nahráno přes API do Google Play alpha ze zdroje `e6b54b8`; celé CI `40387820624` prošlo. API ověřilo shodu podepsaného AAB, zachování tří skupin testerů a grafiky. Stav je IN_REVIEW, nikoli publikováno; úplné E2E a výkon S9 zůstávají otevřené.
- [x] R08 `0.1.1+4` schváleno: Publishing API 26. 10. 2026 vrací pro alpha `0.1.1 (4)` ve stavu RELEASE_LIFECYCLE_STATE_PUBLISHED.

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
- [ ] P02 Finální revize musí mít p95 celého snímku do 16,7 ms. S21 `69d3a0c` při 60 Hz prošel s 11,087 ms a startem 0,771–0,889 s. S9 `8b9cfde` v ověřeném režimu Optimalizováno měl 29,176 ms; oddělený experiment ořezávání karet `a1b5242` 18,308 ms, stále nad cílem a dosud nesloučený. Všechny běhy používají místní 1000/10 fixture, zachycují podmínky a mají ověřenou obnovu nastavení; nejsou důkazem skutečného serveru ani aktuální finální revize.
