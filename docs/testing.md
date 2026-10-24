# Testovací plán

Podle upřesnění zadání se automatické testy smějí spouštět během vývoje pouze neblokujícím způsobem na pozadí. Nezávislé sady běží souběžně v izolovaném pracovním stromu s přesnou revizí. Hlavní pracovní strom se během testů může měnit. Každý proces má uložené ID, log a konečný návratový kód; samotné spuštění není výsledek.

Podle dalšího upřesnění zadání jsou také fyzické S9/S21 součástí průběžných testů na pozadí, nikoli až krokem po vývoji. Každý telefon má vlastní proces a kandidáta z odděleného pracovního stromu. Stejné zařízení nesmějí řídit dva procesy současně. Během implementace probíhá statická kontrola typů a stylu; ta neprokazuje funkčnost na serveru ani zařízení.

## Automatické ověření po vývoji

První průběžný běh na izolované revizi `95b19ed4f1a500ff512d4c57fe77b42769ccdfa6` dne 24. 10. 2026: protokol 13/13, databáze a fronta 38/38, bez přeskočení. Obě sady běžely na pozadí souběžně a skončily kódem 0. Tento výsledek nepokrývá UI, skutečný server, telemetrii ani telefony. Další změny vyžadují ověření nové revize.

- Přihlášení: podadresář, zrušený tok, poll 404/200, timeout, neplatný certifikát, cizí poll/login URL, HTML odpověď a jednorázové předání hesla.
- Protokol: REST/OCS obálky, 304, null versus chybějící pole, `done` jako datum, přílohy 1.0/1.1, zachování popisu/termínu/pořadí při přejmenování, bezpečné chyby.
- Účty: stejná serverová ID na dvou účtech, přepnutí při požadavku, odebrání účtu za běhu, nedostupné bezpečné úložiště.
- Databáze: transakční zápis konceptu a fronty, migrace, plný disk, restart během `sending`, mapování lokálního ID na remote ID.
- Synchronizace: offline editace, souběžná změna stejného pole, nezávislá pole, vymazaná karta/sloupec, odebrané právo, změna účtu, nejistý POST a žádné automatické vytvoření duplikátu.
- UI: prázdný a načtený stav, chyba s obnovou, velké písmo, čtečka, seznam/nástěnka, přesun bez tažení, přidání komentáře a přílohy, odebrání účtu s neodeslanou prací.
- Telemetrie: bez konfigurace nulový síťový provoz SDK, konfigurace každé služby zvlášť, nesouhlas, odvolání souhlasu, vyprázdnění fronty, výpadek endpointu a redakce citlivých polí.
- Build: kontrola applicationId/bundle ID/verze, debug bez podpisových tajemství, oficiální konfigurace přes CI a absence admin tokenů v balíčku.

## Integrace s reálným Nextcloudem

Použít ověřený testovací účet a vlastní dočasnou nástěnku. Osobní ani pracovní nástěnky neměnit. Založit dvě testovací identity pro ověření čtenáře/editora a konfliktu s webem. Zaznamenat přesnou verzi serveru, Decku a capabilities bez tokenů.

| Scénář | Očekávaný výsledek |
|---|---|
| Vytvořit nástěnku/sloupce/kartu, upravit title | Popis, termín, štítky a pořadí zůstávají správné i na webu. |
| Nastavit a zrušit `done` | Správná hodnota/null a ověřené chování hotového sloupce. |
| Archivovat a obnovit | Archivace není zaměněna se smazáním ani dokončením. |
| Přesun a pořadí | Web i druhý klient zobrazí stejné umístění. |
| Přidat/odebrat štítek a přiřazení | Server i klient mají stejné vazby. |
| Komentář a stránkování | Bez duplicit, úprava a mazání respektují práva. |
| Oba typy příloh a existující soubor | Správný obsah, MIME, typ v URL a oprávnění; zrušení uploadu nehlásí úspěch. |
| Sdílení čtenáři, editorovi, odebrání přístupu | Čtenář nezapisuje; stará fronta po ztrátě práva neodešle změny. |
| Síť přerušena po přijetí POST | Klient přizná nejistý výsledek a automaticky nezaloží další kartu. |
| Dva souběžné editory | Uchování konceptu, detekce předem známého konfliktu, pravdivé omezení atomické kontroly. |
| Search/overview/config/clone/dependencies | Skutečně podporované funkce odpovídají zjištěným routám; nepodporované jsou skryté nebo vysvětlené. |
| Odhlášení/odvolání app password | Fronta se zastaví, tajemství zmizí z telefonu, stav serverového odvolání je známý. |
| Sentry a Rybbit | Bezpečná testovací událost dorazí do vlastního projektu se správnou revizí/verzí; vypnutý režim nic neodešle. |

Testované kombinace verzí se doplní podle dostupného prostředí. Jedna zelená kombinace není důkaz podpory všech verzí. Nepoužívat tvrzení „kompletní API ověřeno“ na základě několika GET požadavků.

## Průběžné testy na cílových zařízeních

| Zařízení | Stav | Povinné scénáře |
|---|---|---|
| Samsung Galaxy S9+ | Android 10: kandidát `9134c05`, start a HTTPS validace prošly | Instalace, přihlášení, čtení, všechny hlavní zápisy, offline/restart, velká nástěnka, klávesnice, TalkBack, telemetrie. |
| Samsung Galaxy S21 | Android 15: kandidát `79c1be8`, nové přihlášení a HTTPS validace prošly | Totéž, přepnutí sítě, návrat z prohlížeče, systémové Zpět, soubory a oprávnění aktuálního OS. |
| iPhone | Konkrétní dostupný model zjistit před T03 | Systémový prohlížeč, Keychain, návrat gestem, výběr přílohy, VoiceOver, životní cyklus a telemetrie. |

Před testem zapsat skutečný model, verzi OS, revizi, verzi balíčku a SHA-256 artefaktu. Pro každou hlavní akci ověřit výsledek v aplikaci i na serveru. U výkonu zaznamenat nejméně 5 studených startů a 30 s scrollování po zahřátí; měřit v profile/release režimu, ne debug.

Oprava po fyzickém testu vytváří nového kandidáta. Znovu ověřit opravený scénář a související regresi na dotčených zařízeních; staré výsledky nepřenášet automaticky. Nedostupný iPhone nezmění fyzický Android test na ověření iOS.

## Záznam důkazu

Výsledek má tvar: datum, commit, zařízení/runtime, OS, build/hash, scénář, očekávání, skutečnost, odkaz na redigovaný záznam. Screenshot neobsahuje osobní data. Do Gitu patří stručné výsledky; velké logy do ignorované `.artifacts/`. Tokeny nepatří ani do těchto logů.

## Ověření společného přihlášení

Protokol `4f6dbc8`: 56 testů prošlo, včetně šesti skutečných lokálních TLS scénářů. Databáze `c5866ce`: 40 testů prošlo. Mobilní UI `1af10e2`: 24 testů prošlo, včetně QR, zrušení, cizí identity při opětovném přihlášení a čitelnosti chyby pro asistivní nástroje. Mezi těmito uvedenými přihlašovacími revizemi se měnily jen testy a přístupnost formuláře; toto historické ověření nepokrývá pozdější funkce.

Android kandidát `79c1be8` na S21 prošel instalací, startem, přesným zadáním HTTP adresy, odmítnutím této adresy a kontrolou runtime chyb. SHA-256 APK: `0ae818387e14b2c589dc4fb13e4a73bfffa2345682fa5bdd65b0b39dee3ae393`. Přihlášení se serverem a iOS nejsou tímto základním scénářem ověřené.

Na stejném kandidátu S21 následně prošel celý tok s odděleným lokálním HTTPS testovacím serverem: potvrzení certifikátu, otevření a návrat z prohlížeče, zrušení před schválením bez vytvoření účtu, dokončení a autentizované čtení, zachování účtu a pinu po restartu. Při výměně certifikátu server nedostal žádný HTTP požadavek. Odmítnutí kamery zobrazilo vysvětlení a nastavení. Testovací účet byl odebrán a požadavek na odvolání tokenu dorazil. Schválení prováděl testovací server; nejde o důkaz kompatibility se skutečným Nextcloudem ani ověření jeho odvolání tokenů.

## Funkční milníky 24.–25. 10. 2026

| Revize | Ověření | Meze |
|---|---|---|
| `8b0780b` | Skutečný Nextcloud 34.0.4 / Deck 1.18.5 / API 1.1: 16 kontrol CRUD, komentářů, štítků, přiřazení, příloh, kopií, vazeb, hotového sloupce a oznámení; dalších 5 kontrol legacy příloh včetně obnovy. | CLI používá skutečný produkční protokol. Druhý schválený účet patřil jinému serveru, proto nebylo provedeno živé ověření ACL mezi účty. Start/barva jsou na 1.18 skryté. |
| `14318f5` | Skutečný server: 8 kontrol hledání, upcoming, kontextu karty, tvaru odpovědí a úklidu; izolovaný prohlížeč otevřel správnou kartu přes vytvořený webový odkaz. | Serverový search má limit 200; timestamp cursor nezaručuje úplnost u shodných časů. Přehled se řídí serverovým výběrem aktivních nedokončených karet. |
| `927304b` | S9+ / Android 10 a S21 / Android 15: přihlášení, nástěnka/sloupec/karta, úpravy, komentář, hledání, Moje úkoly, samostatné přepínače telemetrie a restart; změny potvrzené API readbackem. | Stejný přihlašovací tok telefonu schválil izolovaný prohlížeč na hostu. Nejde o důkaz zadávání hesla do prohlížeče telefonu. |
| `ba364e0` | S9+: opravený editor na šířku, obě pole s otevřenou IME, zrušení a návrat bez restartu; bez framework/runtime chyb. | Cílený retest opravuje chybu nalezenou v předchozí revizi, není novým úplným průchodem všech funkcí. |
| `14318f5` | S21: cold/warm `ncdeck` odkazy, neplatné a cizí adresy bez přeposlání přístupu, skutečné kopírování/vložení, zachování dialogu a přepnutí účtů bez staré route. | Dva místní HTTPS testovací servery s různými přístupy a shodnými ID karet; kompatibilitu skutečného serveru dokládá předchozí řádek. |
| `add58f3` | Skutečný SDK startup na S9 a doručení bezpečných událostí do obou služeb. Následný běžný kandidát měl probe vypnutý. | Sentry testuje Dart/Flutter pipeline, nikoli nativní crash/hang záznam. |
| `fe8d724` | Oficiální Android release a iOS release bez podpisu s oběma CI konfiguracemi prošly; jednotkové sady a analyzer také. | Není to store distribuce ani fyzický iOS test. Běžný Android debug CI vyčerpal disk runneru; cílená oprava je v `1a4f576`. |

Vlastní testovací účty v telefonech, přístupové soubory, lokální servery a ADB mapování byly uklizeny. Serverové testovací nástěnky a legacy přílohy jsou odstraněné podle serverového soft-delete; vlastní nahrané běžné soubory byly smazané přes WebDAV a jejich nepřítomnost ověřena. Žádná existující uživatelská data se neměnila. Podrobné záznamy zůstávají mimo Git.
