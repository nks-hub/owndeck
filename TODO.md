# OwnDeck: úkoly

Tento seznam je průběžný zdroj další práce. Po dokončení celku zapsat výsledek a důkaz; nedokončený bod ponechat otevřený. Nové požadavky doplnit sem před implementací.

- [x] R03 Kompletní review proběhlo ve dvou částech: první našla B46–B58, druhá (přesuny mezi nástěnkami, řazení, přílohy, fronta, sdílení, protokol) B59–B68; řazení sloupců, kopie nástěnky, štítky/ACL, `deck_protocol` a soubory z cloudu bez nálezu. Nálezy vedené jako samostatné body.
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
- [x] U18 Nový vzhled karty: barevné štítky jako pilulky s čitelným textem, barva karty jako horní pruh, kulaté dokončení s přeškrtnutím, náhled popisu bez položek checklistu, metadata v jednom řádku a avatary přiřazených s počtem navíc, tlumená nabídka (`6055cb1`). Ověřeno vykreslením ve světlém/tmavém režimu a při 200% textu, 376 mobilních testů prošlo. Výkon: na S21 v cíli, nový vzhled na S9+ nezhoršil vlákno UI; strop S9+ popisuje P02.
- [x] U19 Předvolby jako mřížka kulatých vzorků s názvem v tooltipu a pro čtečku, trvalý duhový vzorek pro vlastní barvu a dialog s odstínem, sytostí, světlostí, tlačítky +/−, náhledem kontrastu a volitelným kódem (`084db94`, `fd26ffe`). Vybraná vlastní barva zůstává jako samostatný vzorek; 43 testů barev a formulářů prošlo, vzhled ověřen vykreslením ve světlém i tmavém režimu.
- [x] U20 Přepínač Sloupce/Seznam přesunut do horní lišty jako ikona, vyhledávání zhuštěné a řádek s archivem/filtrem jen při aktivním stavu (`158f7be`); 47 testů nástěnky prošlo.
- [x] U21 Přihlašovací obrazovka podle připomínky majitele: místo velkého nadpisu, odstavce a technických odrážek je nahoře ikona, název a jedna věta, hned pod tím adresa serveru, Pokračovat a QR kód a jedna řádka o přihlášení v prohlížeči; barva stejná jako v aplikaci, na mobilu bez rámečku, na desktopu formulář vpravo (`66f91bd`, test `fbdbe31`). Vykresleno na telefonu ve světlém/tmavém režimu, při 200% textu (formulář na první obrazovce) a na desktopu.
- [x] U16 Náhled Markdownu je čitelný a omezený délkou, checkboxy v kódu nezvyšují průběh (`e91c96f`); cílené parser/widget testy prošly.
- [x] U17 Konflikty nástěnek, štítků a sdílení ukazují známá metadata a práva bez JSON/ID/bitů (`8ef69fc`); testy porovnání prošly.
- [x] F01 Checklist mění položku přes stejnou trvalou frontu a zachová ostatní popis (`e485272`, `6465b8e`); devět parser/widget testů a zapnutí/vypnutí ve skutečném UI kandidátu `96b8662` prošly. Finální společná revize v R06.
- [ ] F06 Přesun mezi nástěnkami implementován (`e68650c`, `cdb05f0`); skutečné API 1.18.5 ověřilo identitu, obsah, metadata, komentáře, štítky podle práv a kotvu. API 1.18.5 ověřilo i zachování obsahu přílohy; API 1.19.1 prošlo v CI `40318645367` na `996ef07` pro vlastníka i EDIT bez MANAGE včetně stažení přílohy přes účet přesouvajícího a úplného úklidu; úplné nativní UI ověření zůstává v R06.

## Sdílené přihlášení mezi aplikacemi

Přání majitele: když je v OwnTalku, OwnNotes nebo OwnDecku přihlášený účet, ostatní aplikace ho nabídnou k použití, na desktopu i mobilu.

- [ ] SL01 Návrh společného přihlášení OwnTalk/OwnNotes/OwnDeck v `docs/shared-login.md`: co se sdílí (vždy jen identita účtu: server, přihlašovací jméno, UID, zobrazované jméno; tajemství jen se souhlasem), varianta A předvyplněný Login Flow v2 s jedním potvrzením v prohlížeči vs. varianta B sdílený app password (odhlášení v jedné aplikaci ho zruší i ve zbylých, protože Nextcloud z app password nové nevytvoří); rozhodnutí majitele zapsat.
- [ ] SL02 Android: zjistit v Play Console, zda tři aplikace mají stejný podpisový klíč aplikace (Play App Signing dává každé aplikaci vlastní klíč); podle toho provider chráněný oprávněním `signature`, nebo exportovaná aktivita, která po potvrzení ve zdrojové aplikaci vrátí jen identitu účtu; doklad `<queries>` a test na S21 se dvěma aplikacemi.
- [ ] SL03 iOS: sdílená skupina Keychain a App Group pro všechny tři aplikace pod stejným týmem. BLOKOVÁNO: změna identifikátorů a profilů v Apple účtu majitele. Doklad účet z OwnTalku nabídnutý v OwnDecku na simulátoru i podepsaném buildu.
- [ ] SL04 Desktop: společné úložiště účtů pro aktuálního uživatele (Windows Credential Manager se společným prefixem, macOS sdílená skupina Keychain, Linux libsecret se společným schématem); doklad nabídka účtu mezi aplikacemi na Windows a macOS.
- [ ] SL05 Přihlašovací obrazovka nabídne „Pokračovat jako {jméno} na {server} (z OwnTalku)“ i Jiný účet; nikdy automaticky, vždy se souhlasem, a nesmí nabídnout účet, který už v aplikaci je; doklad widget testy a čtečka.
- [ ] SL06 Odhlášení a odvolání: při variantě B počítat, které aplikace token používají, a odvolat ho na serveru až s poslední; varianta A odvolává jen vlastní token; doklad test, že odebrání účtu v OwnDecku neodhlásí OwnTalk.
- [ ] SL07 Implementace v OwnDecku (nabídnutí i převzetí účtu) a E2E na S21, iOS simulátoru a Windows s nainstalovaným OwnTalkem nebo OwnNotes; doklad převzetí účtu bez zadávání adresy a hesla a odhlášení bez vlivu na druhou aplikaci.

## Desktopová verze (Windows, macOS, Linux)

Rozpad z auditu desktopového režimu OwnTalku, souhrn a nálezy v `docs/desktop.md`. Pořadí podle závislostí.

- [x] DK01 `docs/reuse.md` a popis v pubspec uvádějí Android, iOS i desktop.
- [ ] DK02 Platformy Windows, macOS a Linux s ID `com.nkshub.nextclouddeck` a názvem OwnDeck, ikony generuje `tool/icon_assets.py`. Release build na Windows otevře okno OwnDeck za 1,1 s, release build na macOS se spustí s jedním oknem. Zbývá Linux build v CI (DK03).
- [ ] DK03 CI matice sestavení rozšířená o Linux (libgtk-3-dev, libsecret-1-dev, libcurl4-openssl-dev), Windows a macOS; zbývá první zelený běh.
- [x] DK04 QR skener se na Windows, macOS ani Linuxu nenabízí (`test/desktop_platform_test.dart`).
- [x] DK05 Start na desktopu přežije chybějící kanály odkazů a sdílení (test) a log ladicího běhu na Windows je bez MissingPluginException.
- [ ] DK06 Entitlements pro macOS (sandbox, síť, soubory vybrané uživatelem) a `MacOsOptions(usesDataProtectionKeychain: false, synchronizable: false)`; zbývá ověřit přihlášení po restartu na macOS.
- [ ] DK07 Na Linuxu se celý trezor čte jen se značkovým souborem, takže zamčená klíčenka bez účtů start nezablokuje; testy s úložištěm, které visí nebo vyhazuje chybu. Zbývá běh na skutečném Linuxu.
- [ ] DK08 Opravená chyba: přihlášení na desktopu čekalo až 5 minut na návrat do aplikace, nyní dotazuje hned po otevření prohlížeče; ověřeno proti testovacímu serveru Login Flow v2 (dotaz každé 2 s). Zbývá přihlášení proti skutečnému Nextcloudu na každém OS.
- [ ] DK09 Okno na Windows drží minimum 600×400 a pamatuje si polohu a velikost (321,123, 900×640 po restartu); macOS má minimum a autosave rámce, Linux minimum. Zbývá ověřit macOS a Linux.
- [x] DK10 Na desktopu je v celém motivu kompaktní hustota prvků; widget test výšek.
- [ ] DK11 Od 1024 px na desktopu je vlevo seznam nástěnek, uprostřed nástěnka a karta jako pravý panel se zavřením; odkazy, hledání, kalendář i deep linky otevírají do panelu, mobil beze změny (`04cff3d`). Testy 720/1024/1440/1920 px na Windows/macOS/Linuxu včetně Zpět a Esc. Zbývá: při zmenšení pod 1024 px panel zmizí místo přechodu na stránku; ověření na skutečném desktopu.
- [x] DK12 Na desktopu myš táhne kartu hned, dotyk dál dlouhým stiskem; automatický posun a logika upuštění beze změny (`04cff3d`), widget testy.
- [x] DK13 Ctrl/Cmd+N rychlé přidání, Ctrl/Cmd+F hledání, Esc zruší výběr nebo zavře detail, Enter otevře kartu, šipky přesouvají fokus (`04cff3d`); testy pro Windows i macOS.
- [x] DK14 Pravé tlačítko na kartě (přesun, štítky, archivace, smazání, výběr, čekající změny) a na záhlaví sloupce (hotový sloupec, úprava, smazání podle práv) ze sdíleného `card_actions.dart`, kurzor ruky na kartě; lehké `CardMenuButton` zachované (`04cff3d`).
- [ ] DK15 Na desktopu se příloha otevře přes `launchUrl(Uri.file(path))` s hláškou při selhání, mobil dál `OpenFilex` (`04cff3d`); test s falešným spouštěčem. Skutečné otevření v systému ověří desktopové E2E.
- [ ] DK16 Zdroje `file_picker` pro Windows, Linux i macOS zapisují bajty v `saveFile` samy; test ověřuje shodné SHA-256 (`04cff3d`). Skutečný dialog ověří desktopové E2E.
- [ ] DK17 Přetažení souboru ze správce souborů do detailu karty jako příloha (fork `desktop_drop` z OwnTalku); doklad reálné přetažení na Windows a macOS a příloha na serveru.
- [ ] DK18 Jedna instance a odkazy `ncdeck:` na desktopu (HKCU, CFBundleURLTypes, `.desktop` s x-scheme-handler, předání běžící instanci podle OwnTalku); doklad odkaz otevře kartu v běžícím okně.
- [ ] DK19 Telemetrie na desktopu: Sentry a Rybbit hlásí platformu, ladicí symboly se nahrávají (`--split-debug-info`, sentry-cli); doklad čitelný testovací pád z Windows buildu.
- [ ] DK20 Kontrola a instalace aktualizací převzaté z OwnTalku s repem nks-hub/owndeck, ve výchozím stavu vypnuté; doklad převzaté testy a dotaz na skutečný release.
- [ ] DK21 Windows instalátor Inno Setup pro jednoho uživatele s novým AppId; doklad smoke test instalace, upgradu za běhu, zamítnutí downgradu a odinstalace se zachováním dat.
- [ ] DK22 Podpis instalátoru Authenticode a signtool v CI. BLOKOVÁNO: chybí certifikát pro podpis kódu na Windows. Doklad `Get-AuthenticodeSignature` = Valid.
- [ ] DK23 Skript vydání macOS v `tool/` (build, podpis Sparkle, podpis zevnitř ven, notarytool, stapler, ZIP `owndeck-macos-<verze>-<build>.zip`). Podepisovací identita Developer ID existuje, přístup k notarizaci je potřeba nastavit a ověřit. Doklad spctl „Notarized Developer ID“ a stapler validate.
- [ ] DK24 Sparkle pro OwnDeck: vlastní pár klíčů EdDSA, SUFeedURL na nks-hub/owndeck, appcast u každého tagu. Pro OwnDeck vygenerovat vlastní klíče. Doklad aktualizace N na N+1 se sandboxem.
- [ ] DK25 Linux balíček (tarball s bundlem, `.desktop` a ikonou) a výměna složky z OwnTalku; doklad aktualizace na reálném Linuxu a návrat při selhání.
- [ ] DK26 CI joby linux, windows (testy a instalátor) a release se SHA256SUMS podle OwnTalku; doklad zelený workflow_dispatch se všemi artefakty.
- [ ] DK27 Desktopové testy (layout, zkratky, myš, přetažení, aktualizace) a integrační test na Windows; doklad `flutter test` a `flutter test integration_test -d windows`.
- [ ] DK28 E2E na reálných strojích Windows 10/11, macOS s obrazovkou a nativním Linuxu: přihlášení, nástěnky, přesun myší, přílohy, odkaz, aktualizace, restart. BLOKOVÁNO: Mac s obrazovkou a oprávněním Accessibility a nativní Linux. Doklad zápis v `docs/testing.md`.
- [ ] DK29 První desktopové vydání: tag, GitHub release se všemi artefakty a SHA256SUMS, macOS ZIP s appcastem; doklad stažení, instalace a spuštění na každém OS.

## Navazující funkce z konkurenční analýzy

- [x] F02 Hromadný výběr z nabídky karty v obou pohledech, přesun společným dialogem se zachováním pořadí a archivace; každá karta jde samostatně trvalou frontou, výsledek po kartách (uloženo/selhalo/bez oprávnění), opakování jen selhaných se zachováním výběru (`00af4e9`). Sedm cílených testů včetně 200% textu prošlo; nativní ověření v R06.
- [x] F03 Moje úkoly mají přepínač Seznam/Kalendář: měsíční mřížka a agenda dne z místní cache bez kopírování, rozlišení začátku, termínu a dokončení ikonou i textem, upozornění na nástěnky bez uložených karet a otevření karty ve správném účtu (`b57bdc4`). Pět testů kalendáře a test zachování volby přes přepínání záložek prošly; karty bez termínu se nezobrazují.
- [x] F04 Příjem textu/odkazu ze systémového sdílení do nové karty s potvrzením účtu a cíle a konceptem při zrušení přihlášení. Android `ACTION_SEND` bez nových oprávnění (`2236d7b`), Dart tok (`dd9bdba`) a iOS Share Extension přes App Group `group.com.nkshub.nextclouddeck` (`e3a629c`). Simulátorový build `ba9c7b9` obsahuje `ShareExtension.appex`, 6 XCTestů a 331 mobilních testů prošlo; skutečný share sheet ověří R06.
- [x] B42 Sdílený text bez účtu se ukládá do `share.pending`, přežije restart a nabídne se po přihlášení; poškozená hodnota start neblokuje (`dfc5ed2`), pět testů úložiště a tři testy toku prošly.
- [x] B43 Odkaz na kartu a sdílený text se zachovají oba, nejdřív se otevře karta a pak nabídne text (`dfc5ed2`); reprodukce ztráty textu selhala před opravou.
- [x] B45 Sdílení je FIFO fronta v Dartu (zpětně čte starou hodnotu), na iOS (soubor na sdílení) i Androidu; další sdílení se nabídne po zavření předchozího (`1c2a798`, `b21d5fb`, `bd6a310`).
- [x] B46 P1 R03: odesílač zabral řádek jen podle stavu a poslal starý snímek návrhu; `startWrite` nově ověří shodu návrhu, nástěnky, sloupce, karty i základu a při změně zápis znovu načte. Platí pro karty, komentáře, akce, přílohy, strukturu, řazení sloupců, metadata i kopii nástěnky (`4f6ac01`); reprodukce odeslala A místo B, po opravě B.
- [x] B47 P2 R03: `SceneDelegate` posílá URL nejdřív do sdílení, `CardLinkDelivery` přijímá jen host `open` (`bd6a310`). XCUITest na simulátoru iOS 26.2 otevřel studeně i teple list Přidat kartu se sdíleným textem; Runner `030a0335…`, 7 XCTestů prošlo.
- [x] B48 P2 R03: Moje úkoly ukazují upozornění na neuložené nástěnky s akcí Načíst karty a netvrdí prázdný seznam (`3c2b3ca`).
- [x] B49 P2 R03: přerušený komentář se při zavření synchronizace nebo ztrátě zámku vrátí do fronty místo stavu `sending` (`df07496`); reprodukce selhala před opravou.
- [x] B50 P2 R03: Keychain používá `first_unlock_this_device` a jednorázová migrace přepíše existující položky, při selhání zápisu vrátí původní hodnotu (`ea2d550`); čtyři testy migrace s falešným úložištěm, skutečná obnova ze zálohy neověřena.
- [x] B51 P2 R03: tělo migrace běží v transakci; selhání vrátí změny a po odstranění kolize se databáze otevře ve verzi 9 (`5701467`). Osm migračních testů B01 dál prochází.
- [x] B52 P2 R03: 404 bez JSON (proxy, vypnutý Deck) vrací `deck_unavailable`, zápis zůstává ve frontě a cache se nemění; JSON 404 dál odvolá přístup (`7493201`). Chování Nextcloudu pro vypnutou aplikaci ve zdroji nedohledáno, použito konzervativní pravidlo. Store 207, protokol 125 a mobil 339 testů prošlo.
- [x] B53 P3 R03: kalendář řadí hotovou kartu ke dni a času dokončení, i bez termínu (`3c2b3ca`).
- [x] B54 P3 R03: dokončení jde z Mých úkolů, hledání i agendy kalendáře se stejnou kontrolou práv; odkaz na kartu Decku v popisu se otevře nativně (`3c2b3ca`).
- [x] B55 P3 R03: hromadné akce mají průběh, vypnutá tlačítka a ochranu proti druhému spuštění; souhrn říká Uloženo v telefonu (`37cb274`).
- [x] B56 P3 R03: koncept `share:` se uloží před otevřením rychlého přidání, takže přežije i bez zapisovatelného cíle (`1c2a798`).
- [ ] B57 P3 R03: Android ignoruje intenty s `FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY` pro sdílení i odkazy (`b21d5fb`); zatím jen kompilace, ověření návratu z Nedávných na S9/S21 zbývá.
- [x] B58 P3 R03 (U15): chybové stavy se společnou obnovou, chyby místního zápisu hlášené jako zápis, chyba checklistu jako místní, buňka kalendáře 49 dp (`37cb274`). Dvanáct nových testů B48–B58 selhalo na starém kódu, 350 mobilních testů prošlo na `f7d959a`.
- [x] B59 P2 R03b: `decideWrite` u přijaté změny vyhazuje `already_applied` a UI Zahodit nenabízí (výjimka: přijatý přesun mezi nástěnkami s volbou verze serveru), závislé komentáře zůstávají ve frontě (`fdbab6d`).
- [x] B60 P2 R03b: akce Zkontrolovat server hledá jedinou shodu vzniklou po odeslání (karta, komentář, nahrání a sdílení přílohy) a při shodě pokračuje načtením výsledku; varování před duplicitou jen u POST. Čas odeslání ve sloupci `sent_at`, schéma 10 s migrací (`fdbab6d`). Ověřeno proti mock transportu, živý server v R06.
- [x] B61 P2 R03b: přílohy používají aktuální kontext karty a posílají do aktuálního sloupce; blokuje jen archivace nebo změna nástěnky (`5a8902f`).
- [x] B62 P3 R03b: opakovaný přesun, který server už provedl, zapíše výsledek přenosu a pošle jen řazení (`fc0bff1`).
- [x] B63 P3 R03b: cizí přesun karty přepíše u komentářů, příloh a úprav ve stejné nástěnce jen umístění; konflikt zůstává pro přesuny a změnu nástěnky (`5a8902f`).
- [x] B64 P3 R03b: otevření databáze uvolní zámky `sync_leases`, fronta se po zabití aplikace odešle hned (`fdbab6d`).
- [x] B65 P3 R03b: neodeslané změny se přes `requeueUnsent` vrací do fronty se `stale_response` (`5a8902f`). Osm nových testů B59–B65 před opravou padalo; store 225, protokol 125 a mobil 376 testů prošlo.
- [x] B66 P3 R03b: konflikt přesunu mezi nástěnkami ukazuje řádek Teď na serveru s nástěnkou a sloupcem (`a6ce685`).
- [x] B67 P3 R03b: sdílení mapuje chyby společným `errorMessage`, čekající rozhodnutí a nedostupný účet mají vlastní text (`a6ce685`).
- [x] B68 P3 R03b: chyba ve sdílení je live region, nabídky příloh a sdílení mají tooltip s názvem položky, rozhodování ukazuje indikátor s popiskem (`a6ce685`); guidelines tap target a kontrastu na přílohách, sdílení a čekajících změnách prošly, celá sada 376 testů.
- [x] B69 P1 Nález z testu F11 v simulátoru iOS: aplikace padala při každém startu, protože Dart odeslal úlohu `BGTaskScheduler` dřív, než byl při spuštění zaregistrovaný její handler (`workmanager_apple` registruje jen dříve uložené úlohy); synchronizace na pozadí je ve výchozím stavu zapnutá. Oprava `3d34e5c` registruje identifikátor v `didFinishLaunching` ; v simulátoru iPhone 16 / iOS 26.2 pád před opravou (záznam `BGTaskScheduler _handleSubmissionWithoutRegistration`), po opravě aplikace běží a načte nástěnky bez nového záznamu o pádu. Vydání pro Android se netýká.
- [x] B70 P2 Nález z testu F13 na S21: přepočet připomínek po jejich čase, ale před doručením nepřesného alarmu (start aplikace nebo běh na pozadí), připomínku zrušil a nepřišla. Oprava `a3c35c8` nechá čekající připomínku, dokud karta platí beze změny; regresní test selhal před opravou, 22 testů připomínek prošlo.
- [ ] R09 Před vydáním iOS zaregistrovat App Group `group.com.nkshub.nextclouddeck` a identifikátor `com.nkshub.nextclouddeck.ShareExtension` v Apple účtu a ověřit podepsaný build; nález z implementace F04.
- [x] F08 Archivované karty lze vybrat a hromadně obnovit (bez přesunu), výběr všech zobrazených karet respektuje filtr (`d42f12b`); dva nové widget testy prošly.
- [x] B44 Skrytý seznam Mých úkolů při přepnutí na kalendář znovu spouštěl stejný dotaz a do jeho dokončení animoval indikátor; StreamBuilder je nově klíčovaný dotazem (`50cd2fa`). Nález z testu F03, reprodukce selhala před opravou a 22 navazujících testů prošlo.
- [x] F05 Vícerádkové přidání položek `- [ ] ` na konec popisu stejnou trvalou frontou jako F01 a přepínač Skrýt hotové jen v pohledu; ostatní text zůstává bajtově shodný včetně CRLF (`2a2c49c`). Parserové a widget testy prošly.
- [x] F07 Přiřazení sdílené skupiny (typ 1, Deck 1.10+) a týmu (typ 7, 1.18+) podle verze serveru; bez známých capabilities se nenabízí. Skupiny a týmy mají v názvu typ, existující přiřazení lze odebrat bez záměny (`99b3acb`). Protokolové, store a widget testy prošly; živý server v R06.

## Inspirace oficiální aplikací Deck pro Android

Z rozboru zdrojů a issues oficiální aplikace (GPL-3.0, jen nápady bez převzatého kódu), souhrn v `docs/competition.md`.

- [ ] F09 P1 Sdílení souborů z jiné aplikace (obrázky, PDF, víc najednou) jako přílohy nové nebo existující karty: Android SEND/SEND_MULTIPLE pro všechny typy, iOS Share Extension s obrázky a soubory, nahrání přes trvalou frontu; doklad tři fotky z Galerie na S21 a iOS simulátoru se shodnou SHA-256 na serveru a offline odeslání po obnovení sítě.
- [ ] F10 P1 Sdílený text jde připojit k existující kartě (konec popisu, položka checklistu nebo komentář); doklad widget test výběru karty a server s bajtově shodným zbytkem popisu.
- [ ] F11 P1 Odeslání fronty a obnova cache na pozadí: Android WorkManager (výchozí 15 min, jen se sítí, vypínatelné), iOS BGAppRefreshTask v mezích systému; doklad offline změna na S21 s ukončenou aplikací je po zapnutí sítě na serveru do 20 min. Volba intervalu Vypnuto/15 min/1 h/6 h a přepínač Jen přes Wi-Fi (UNMETERED) se správnou výchozí hodnotou; v oficiální aplikaci výchozí hodnoty neodpovídají volbám. Implementováno (`2d9b7a1`): Android WorkManager s volbou Vypnuto/15 min/1 h/6 h a Jen přes Wi-Fi, iOS BGAppRefreshTask s poctivým textem o omezení systému, vlastní zámek `background:` bez souběhu s popředím, nejisté zápisy se neopakují; testy prošly na win11lite2. Zbývá sestavení APK a iOS a E2E na zařízeních. S21 (Android 15, APK `4631ffd`): úloha WorkManager se zaregistruje po přihlášení, Jen přes Wi-Fi vyžaduje NOT_METERED, Vypnuto úlohu zruší a změna z fronty se po vynuceném běhu úlohy dostala na server bez otevření aplikace (readback Deck API). Přirozené spuštění po 15 min zachyceno jen jednou; iOS build a start ověřeny v simulátoru po opravě B69.
- [ ] F12 P2 Vyfotit přílohu přímo z detailu karty s vlastní hláškou při zamítnutém oprávnění; doklad S21 a iOS: fotka na serveru a po restartu se otevře.
- [x] F13 P2 Místní připomínka termínu z cache s volitelným předstihem, otevře kartu ve správném účtu a zruší se po dokončení či změně termínu; doklad oznámení při zavřené aplikaci na S21 i iOS a žádné po dokončení. Implementováno (`f34f309`): jen otevřené přiřazené karty s termínem, ve výchozím stavu vypnuto, oprávnění k oznámením, předstih 0/15 min/1 h/1 den, nepřesné alarmy bez oprávnění k přesným, iOS nejbližších 60 připomínek; testy prošly. Zbývá doručení při zavřené aplikaci a po restartu na S21 a iOS. S21: oprávnění, doručení při zavřené a zamčené aplikaci (zpoždění ~4,5 min kvůli nepřesným alarmům), otevření správné karty klepnutím a zrušení po dokončení karty prošly; nalezená chyba B70 opravena. iOS (simulátor v CI, Xcode 26.3, sonda nad skutečným `ReminderService`): naplánování, zavření aplikace a restart zařízení před termínem, doručení, přepočet doručenou připomínku nezruší, dokončená karta připomínku zruší a nepřijde; prošlo. Klepnutí na banner připomínky doručené po restartu simulátoru spustí aplikaci se správným účtem a kartou; prošlo. Android S9+ stejnou sondou: doručení po restartu telefonu bez otevření aplikace (do 75 s po termínu kvůli nepřesnému alarmu), přepočet doručenou nezruší, dokončená karta připomínku zruší a žádný alarm nezbude; prošlo. Klepnutí na připomínku doručenou po restartu S9+ spustí aplikaci se správným účtem a kartou; prošlo.
- [ ] F14 P2 Widget Moje úkoly na ploše (Android AppWidget, iOS WidgetKit) z místní cache, klepnutí otevře kartu; doklad stejné karty jako záložka a změna po dokončení. Doplnit i widget jednoho sloupce (konfigurace účet, nástěnka, sloupec) a widget jedné vybrané karty; klepnutí otevře kartu ve správném účtu.
- [ ] F15 P2 Zkratky ikony Přidat kartu a Moje úkoly (Android i iOS) a dlaždice Přidat kartu v rychlém nastavení Androidu; doklad studené i teplé spuštění otevře rychlé přidání s posledním cílem účtu.
- [x] F16 P2 Historie aktivity karty z Activity API v2 (`filter?object_type=deck_card`, stránkování přes `since`) v detailu, jen s capabilities `filters-api`; bez sítě poctivá hláška a Zkusit znovu, nic se neukládá. Protokolové a widget testy prošly; živý server v R06.
- [x] F17 P2 Zmínky v komentářích ve formátu serveru `@uid` / `@"uid"` (ne zobrazované jméno, podle `Comment::getMentions`), našeptávač z účastníků nástěnky a zvýraznění podle `mentionDisplayName`. Testy prošly; oznámení druhému účtu ověří R06, skupiny a týmy se nenabízejí.
- [x] F18 P2 Rychlé volby Dnes, Zítra, Příští týden a Bez termínu v editoru karty; dny se přičítají kalendářně, takže změna letního času datum neposune (`399bdd7`).
- [ ] F19 P2 Nabídka karty na nástěnce a v seznamu doplněná o Přiřadit mně, Archivovat, Kopírovat odkaz a Smazat se stejnou kontrolou práv jako detail; doklad widget testy pro READ a EDIT a zápis přes frontu.
- [x] F20 P3 Moje úkoly seskupené pod záhlavími Po termínu, Dnes, Zítra, Tento týden (po–ne), Později a Bez termínu; upozornění na neúplná data a kalendář zachované (`0bd71d5`).
- [x] F21 P3 Filtr nástěnky včetně hledaného textu se ukládá pro účet a nástěnku, obnoví se po restartu i přepnutí a Zrušit filtry ho smaže (`1e63625`).
- [ ] F22 P3 Volitelný kompaktní vzhled karty (název, štítky, termín) v Nastavení; doklad test výšky při 100 a 200 % textu a měření P02 bez zhoršení.
- [ ] F23 P3 Volitelná obálka karty z obrázkové přílohy přes serverový náhled, výchozí vypnutá; doklad žádný požadavek na náhled při vypnuté volbě a měření P02 bez zhoršení.
- [x] F24 P3 Společné pole Markdownu pro popis i komentář: Enter pokračuje v odrážce, číslovaném seznamu i checklistu, na prázdné položce seznam ukončí, lišta tučné/seznam/checklist/odkaz (`35330f6`). Spojeno se zmínkami F17 v editoru komentářů.
- [ ] F25 P3 Volitelná komprese fotek před nahráním se zachováním orientace; doklad 12MP fotka pod 2 MB se správnou orientací na serveru.
- [ ] F26 P2 Miniatury obrázkových příloh přes serverový náhled `core/preview?fileId=` a celoobrazovkový prohlížeč s přiblížením a listováním; doklad widget test gest a na S21 miniatura bez stažení celého souboru.
- [ ] F27 P2 Akce sloupce Archivovat všechny karty s potvrzením počtu, při aktivním filtru jen filtrované, každá karta přes trvalou frontu; doklad widget test s filtrem a server archivuje jen vybrané karty.
- [x] F28 P2 Sdílet kartu (název, termín, štítky, popis, odkaz) systémovým dialogem z detailu i nabídky karty a odkaz na nástěnku z nabídky nástěnky přes `share_plus` bez nových oprávnění (`7adf1b6`); tři testy s falešným voláním platformy.
- [x] F29 P3 Sekce Projekty v detailu karty z `ocs/v2.php/collaboration/resources/deck-card/{id}` (ověřeno ve zdrojích Nextcloudu a Decku), soubory, místnosti Talku, karty a nástěnky, skrytá při prázdném výsledku, 404 nebo offline (`486bf15`); protokolové a widget testy.
- [ ] F30 P3 Akce přílohy Vložit odkaz do popisu (Markdown odkaz nebo obrázek na konec popisu přes frontu jako F01); doklad server s bajtově shodným zbytkem popisu.
- [x] F31 P3 Každý účet si pamatuje poslední nástěnku a sloupec a po restartu nebo přepnutí účtu je otevře, jen když stále existuje a je čitelná (`2b183aa`); testy restartu a přepnutí.
- [x] F32 P3 Nastavení ukáže čas poslední úspěšné synchronizace účtu a tlačítko Synchronizovat teď; doklad widget test po úspěšném čtení a po chybě sítě. Hotovo (`c9d9717`): čas poslední úspěšné synchronizace pro každý účet a Synchronizovat teď pro aktuální účet, po chybě sítě zůstane starý čas s hláškou; widget testy prošly.
- [x] F33 P3 Kopírovat text komentáře z jeho nabídky u každého komentáře, zmínky jako jména (`809566f`); widget test schránky.
- [x] F34 P3 Pruh chyby synchronizace má radu podle druhu (údržba, certifikát, timeout, chybějící Deck) a Zkopírovat technické údaje (verze aplikace, Nextcloudu a Decku, druh, kód, HTTP stav) bez adres, jmen a hesel (`42a3ed9`); testy každého druhu a nepřítomnosti tajných údajů. Přihlašovací a ostatní chybové dialogy tlačítko zatím nemají.
- [ ] F35 P3 Přiložit kontakt jako vCard přes systémový výběr kontaktu bez trvalého oprávnění READ_CONTACTS; doklad .vcf na serveru se shodnou SHA-256 na S21.

## Původní plán a průběžné důkazy

- [x] R07 `0.1.1+4` nahráno přes API do Google Play alpha ze zdroje `e6b54b8`; celé CI `40387820624` prošlo. API ověřilo shodu podepsaného AAB, zachování tří skupin testerů a grafiky. Stav je IN_REVIEW, nikoli publikováno; úplné E2E a výkon S9 zůstávají otevřené.
- [x] R08 `0.1.1+4` schváleno: Publishing API 26. 10. 2026 vrací pro alpha `0.1.1 (4)` ve stavu RELEASE_LIFECYCLE_STATE_PUBLISHED.
- [x] R10 `0.1.2+5` nahráno přes API do Google Play alpha ze zdroje `bf54047`: podepsaný AAB ověřený bundletoolem bez širokých oprávnění k médiím (nově oznámení, start po restartu a WorkManager), tři skupiny testerů zachované. CI: testy, Android, iOS, Linux a Windows prošly; sestavení pro macOS selhalo na starém Xcode a je opravené v `85dc725`. Stav IN_REVIEW, předchozí `0.1.1+4` PUBLISHED.
- [x] R11 Verzi `0.1.2+5` nahradila `0.1.3+6` (R12) dřív, než ji Google schválil.
- [x] R12 `0.1.3+6` s opravami B69 a B70 nahráno přes API do alpha ze zdroje `c1361dd`: podepsaný AAB ověřený, CI ve všech osmi úlohách včetně macOS prošlo, brány na `83214c0` prošly (mobil 514 testů). Google schválil, API 27. 10. 2026 vrací pro alpha `0.1.3 (6)` RELEASE_LIFECYCLE_STATE_PUBLISHED.
- [x] R13 `0.1.4+7` (Sentry s čitelným textem chyby) ze zdroje `aa6a716`: Google Play alpha přijala build 7 ke kontrole (IN_REVIEW), TestFlight build 7 je VALID, interní testování běží, externí čeká na beta review. Rozšíření pro sdílení vyžaduje iOS 15, protože App Store odmítl přibalenou knihovnu Swift Concurrency.
- [ ] R14 `0.1.4 (7)` odeslána ke kontrole do App Store (stav WAITING_FOR_REVIEW); Google Play produkce čeká na podmínku 12 testerů po 14 dní v uzavřeném testu.

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
- [ ] P02 Cíl p95 celého snímku do 16,7 ms. S21 splněno: po odlehčení nabídky a ořezu karty (`d7e7ef8`) 9,73/10,11 ms. S9+ nesplněno: 28,66/30,73 ms (před 25,93/27,32), zlepšilo se jen vlákno UI o ~2,4 ms. Strop zařízení: holá Flutter aplikace se seznamem karet má na S9+ p95 ~14,3–15 ms a rasterizace kolísá 12–18 ms i u prázdného seznamu, v režimu Optimalizováno stejně. Měřeno 2× před/po, 5 studených startů a 36 s posunu, místní data 1000/10. Rozhodnout, zda cíl pro S9+ upravit.
