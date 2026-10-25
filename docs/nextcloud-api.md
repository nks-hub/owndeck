# Nextcloud a Deck API

## Podklad a hranice ověření

Rozbor ze dne 24. 10. 2026 je připnutý na Deck `v1.19.1`, commit `28efc84c108807cf0821d83e52f45b43cac27412`, vydaný 23. 10. 2026. [Routy](https://github.com/nextcloud/deck/blob/28efc84c108807cf0821d83e52f45b43cac27412/appinfo/routes.php), [API dokumentace](https://github.com/nextcloud/deck/blob/28efc84c108807cf0821d83e52f45b43cac27412/docs/API.md) a příslušné controllery byly načteny přímo ze stejné revize. Živý test uživatelova serveru patří do T02.

Kompletní soupis 86 verzovaných rout a jejich podpisů je v [api-inventory.md](api-inventory.md): 50 REST a 36 OCS. Každá má odkaz na konkrétní controller. Generátor zahrnuje routy s `/api/v{apiVersion}`; interní webové routy mimo toto rozhraní nejsou automaticky považovány za veřejné mobilní API.

Nextcloud je rozšiřitelný systém a nemá jediné konečné API všech aplikací. Níže jsou pokryté jeho klientské rodiny a jejich vztah k Decku. Není tím tvrzeno, že OwnDeck implementuje administraci, Talk, Mail či všechny volitelné aplikace.

## Přenos a autentizace

Výchozí REST cesta je `<base>/index.php/apps/deck/api/v1.1/`. OCS je oddělené `<base>/ocs/v2.php/apps/deck/api/v1.0/`. Verzi REST a OCS neodvozovat mechanicky jednu z druhé. Základní adresa může obsahovat podadresář instalace.

Všechny autentizované požadavky používají Basic Auth s přihlašovacím jménem a samostatným app password z Login Flow v2, `OCS-APIRequest: true` a `Accept: application/json`. JSON zápisy mají `Content-Type: application/json`; binární upload multipart. Přihlašovací POST/poll používá formulářová pole. Neskládat URL s heslem v userinfo.

OCS odpověď má `ocs.meta` a `ocs.data`; kontrolovat nejen HTTP status, ale také úspěch obálky. REST Deck obálku nemá. Nepovažovat HTML přihlašovací stránku s HTTP 200 za úspěch. Timeout, TLS chyba, neplatný JSON a odmítnuté oprávnění jsou rozdílné chyby. Pro logy vracet jen bezpečné kódy, ne body odpovědí.

Login Flow v2: POST `index.php/login/v2`, otevřít dodanou `login` URL systémovým prohlížečem, opakovaně POST `token` na dodaný poll endpoint. Poll 404 znamená čekání; po schválení server vrátí server/loginName/appPassword pouze jednou. Tok lze zrušit. Validovat origin a cestu obou vrácených URL, aby se tajný token neposlal jinému serveru. [Oficiální Login Flow](https://docs.nextcloud.com/server/stable/developer_manual/client_apis/LoginFlow/index.html).

## Modely

| Entita | Pole a význam | Důležité omezení |
|---|---|---|
| Board | ID, title, color, owner, archived, deletedAt, lastModified, labels, acl, permissions, users, settings | Název do 100 znaků; práva jsou samostatná `READ`, `EDIT`, `MANAGE`, `SHARE`. |
| Stack | ID, boardId, title, order, deletedAt, lastModified, cards | Není jen textový status. Pořadí i ID sloupce jsou serverová data. |
| Card | ID, stackId, title, type, owner, description, order, due/start date, done, archived, labels, assignedUsers, counts, deletedAt, ETag | `done` je čas dokončení nebo null, nikoli automaticky bool. Archivace a dokončení jsou jiné stavy. |
| Label | ID, boardId, title, color | Stejný název na různých nástěnkách není stejný štítek. |
| Assignment | ID, cardId, participant, type | Uživatel v přiřazení může být struktura; nepředpokládat vždy prostý text. |
| ACL | participant, type, permissionEdit/Share/Manage | Oprávnění vyhodnocuje server včetně skupin a dalších podporovaných typů. |
| Attachment | ID, type, data/metadata, deletedAt | Typ je součást identity i adresy v API 1.1. |
| Comment | ID, actor, message, creation time, parentId | ID i stránkování převzít z odpovědi, neodvozovat z místního pořadí. |

Neznámá pole tolerovat. Pole, jejichž vynechání změní význam, rozlišit od explicitního null. Vstupní datum odesílat jako ISO 8601 včetně zóny; časy `lastModified`/`deletedAt` jsou jiná kategorie, typicky unixové sekundy. Formát konkrétního pole ověřit fixturem ze serveru. České znaky a emoji testovat na hranici délky názvu; počet UTF-16 jednotek není automaticky počet znaků serveru.

## Funkční skupiny Deck

| Skupina | Operace | Jak ji použít |
|---|---|---|
| Nástěnky REST | seznam/detail, create/update/delete/undo_delete, clone | Seznam podporuje `details` a podmíněné čtení. Detail poskytuje práva a štítky. Kopie má zvláštní přepínače pro karty/přiřazení/termíny. |
| ACL REST/OCS | add/update/delete | Pole práva odesílat explicitně. Vyhledání adresáta zajistí Sharee API; nepoužívat správcovské provisionování uživatelů. |
| Sloupce REST | seznam/detail/archived, create/update/delete | Karty se čtou uvnitř sloupců; nenavrhovat neexistující obecné `GET /cards`. |
| Sloupce OCS | create/delete/reorder, setDoneStack | Doplňková funkce závislá na podporovaném serveru; `boardId` ověřit proti rodiči. |
| Karty REST | detail/create/update/delete, labels/users, reorder, archive/unarchive, dependencies | `update` vyžaduje title/type/owner a výchozí hodnoty mohou vymazat další pole. Použít zachovaný snímek. |
| Karty OCS | create/update, label/user, reorder, dependencies, clone | Alternativní smlouva; nelze jen změnit prefix REST. `update` má odlišné parametry a pracuje i s `deletedAt`. |
| Štítky REST | detail/create/update/delete | Seznam je v nástěnce. Při smazání obnovit vazby karet. |
| Přílohy REST 1.0 | list/display/create/update/delete/restore | Legacy `deck_file`; seznam filtruje novější typy. |
| Přílohy REST 1.1 | stejná rodina s typem v cestě | Preferovat, protože zachová i `file`. Nehádat URL z pouhého attachmentId. |
| Přílohy OCS | list/create/update/delete/restore | Odlišná cesta pro singular `attachment`, mazání používá `type:attachmentId`. |
| Komentáře OCS | GET/POST/PUT/DELETE | GET `limit=20`, `offset=0`; POST message/parentId. Prázdná stránka ukončuje čtení. |
| Config OCS | GET, POST config/key | Povolené klíče vyplývají z controlleru; nepřepisovat globální volby z pohodlnosti klienta. |
| Overview a search OCS | upcoming, search term/limit/cursor | Doplňkový přehled; lokální filtr je použitelný i při nedostupnosti API. |
| Session OCS | create/sync/close s boardId/token | Přítomnost spolupracovníků; token relace není app password. Ukončovat s obrazovkou, neudržovat na pozadí. |
| Import REST | getSystems, config/schema/name, import | Potenciál migrace z Trella; konfigurace je serverově specifická. Zatím zmapované, žádný vlastní odhad struktury importu. |

## Nálezy při porovnání dokumentace a zdrojů

1. Capabilities v této revizi inzerují API `1.0`, `1.1`, nikoli `1.2`. Dokumentace označuje 1.2 jako nevydanou, přesto `done` zpracovává aktuální controller. Verzi funkce nelze odvodit pouze z tohoto nadpisu.
2. Docblock capabilities zmiňuje `supportsDoneColumn`, skutečně vracené pole jej ale neobsahuje. Klient nesmí vyžadovat tento údaj jako jediný důkaz podpory.
3. Dokumentace příloh ukazuje cestu bez typu. Routy 1.1 mají `attachments/{type}/{attachmentId}`. Bez rozlišení typů by se novější přílohy ztratily nebo neotevřely.

Přílohy `file` používají jako ID sdílení, nikoli ID souboru. Nový soubor se nahrává multipart polem `file` s `type=file`. Existující soubor se připojuje přes OCS `apps/files_sharing/api/v1/shares`: cesta souboru, `shareType=12` a `shareWith` jako ID karty. Samotné JSON `data` v create přílohy existující soubor nepřipojí. Smazání `file` odpojí sdílení, zdrojový soubor zachová a nemá obnovu přílohy; `deck_file` má dočasnou obnovu. `extendedData` může být pro čtenáře karty prázdné. Ověřeno ve zdrojích `FilesAppService`, `FileService`, `AttachmentApiController` a `AttachmentList.vue` připnuté verze; funkční ověření serveru zůstává samostatné.
4. Import schématu má v dokumentaci `/config/system/{schema}`, ve vydaných routách `/config/schema/{name}`. Preferovat vydané routy a ověřit živě před zpřístupněním importu.
5. Config dokumentace naznačuje `{id}/{key}`, vydaná routa má pouze `{key}`.
6. `GET /dashboard/due` odkazuje na `CardApiController::findAllWithDue`, která v analyzovaném controlleru není. Pro nový klient nepoužívat jako garantovaný endpoint. Použít OCS overview nebo místní přehled.
7. REST update karty není PATCH. Vynechaný popis má default prázdný, pořadí nula a termín null. Pouhý zápis title by mohl poškodit ostatní data.
8. `done` se v update čte zvlášť pomocí přítomnosti klíče. Vynechání, null a čas nejsou zaměnitelné. Nastavení `done` a webová akce done nemusí mít stejné vedlejší účinky přesunu do hotového sloupce; ověřit v T02.
9. ETag slouží k podmíněnému čtení. V analyzované cestě aktualizace není kontrola `If-Match`; samotné odeslání této hlavičky nezaručí ochranu před přepsáním souběžné změny.
10. Název boardId/stackId v URL není dostačující důkaz oprávnění. Server má vlastní kontroly nad kartou a cílem. Klient musí správně reagovat na odmítnutí i po dříve úspěšné synchronizaci.
11. `CardService::reorder` vrací seznam přerovnaných karet. Cílový `stackId` patří do URL i těla. Obecná mutace nemusí vracet detail karty; například přiřazení může vrátit vazbu. Po přijetí zápisu načíst aktuální kartu a neopakovat mutaci při selhání tohoto následného GET.
12. `CommentService` dovoluje vytvářet komentáře s právem READ, bez EDIT. Změnu a odstranění povoluje pouze autorovi typu `users`; UID je nutné zjistit přes OCS aktuálního uživatele. Stránka má nejvýše 200 komentářů, základní limit zprávy v `IComment` je 1 000 znaků. Načtení částečné stránky není důkaz smazání zbývajících komentářů.
13. Webový Deck hledá příjemce přes OCS `/core/autocomplete/get` s `itemType=deck` a typy 0/1/6/7; tento postup přebírá klient. Přidání a změna ACL vyžadují SHARE, odstranění ACL MANAGE. Správa štítků vyžaduje MANAGE. Server může omezit udělovaná práva podle práv odesílatele, proto klient před zápisem znovu ověřuje možnosti a po potvrzení načítá skutečný výsledek.

Tyto nálezy vycházejí ze zdrojů, nikoli ze spuštění exploitu či měření. Otevřené serverové scénáře jsou přímo v [testing.md](testing.md).

## Ostatní Nextcloud klientská rozhraní

| Rodina | Endpoint / mechanismus | Rozsah OwnDecku |
|---|---|---|
| Status | `/status.php` | Verze a údržba; bez přihlašovacích údajů, ne jako jediný test dostupnosti Decku. |
| Capabilities | `/ocs/v2.php/cloud/capabilities` | Zjistit Deck, verzi a možnosti; bezpečně vypnout nedostupné funkce. |
| Aktuální uživatel | `/ocs/v2.php/cloud/user` | UID a zobrazované jméno pro vlastní přiřazené úkoly. |
| App password | Login Flow v2 a OCS core apppassword | Vlastní token aplikace, jeho odvolání při odebrání účtu. |
| Sharees | `/ocs/v2.php/apps/files_sharing/api/v1/sharees` | Hledání příjemců sdílení, typy filtrovat podle Decku. |
| Autocomplete Deck | `/ocs/v2.php/core/autocomplete/get` | Primární hledání příjemců podle vydaného `src/stores/settings.js`; podporuje uživatele, skupiny, vzdálené uživatele a týmy. |
| Files sharing | `/ocs/v2.php/apps/files_sharing/api/v1/shares` | Pouze když operace přílohy potřebuje vlastní share; práva nástěnky jsou Deck ACL. |
| WebDAV | `/remote.php/dav/files/{user}/...` | PROPFIND, GET a případně PUT pro existující soubory; URL kódovat po segmentech a držet rozsah účtu. |
| Upload v částech | WebDAV uploads | Potřebný pro velké soubory, až po ověření vztahu vytvořeného fileId k Deck attachment. |
| Komentáře DAV | DAV comments | Pro Deck používat jeho OCS comments; neduplikovat dvě různé cesty zápisu. |
| Notifications | `/ocs/v2.php/apps/notifications/api/v2/notifications`, push registrace dle capabilities | Přehled, přečtení/odstranění a bezpečné otevření odkazu; push je samostatná integrace. |
| Activity v2 | `/ocs/v2.php/apps/activity/api/v2/activity/...` | Historie jen podle dostupných filtrů a oprávnění; nenahrazuje synchronizační protokol. |
| Unified search | `/ocs/v2.php/search/providers` a provider search | Volitelné širší hledání; Deck OCS search nebo místní data jsou přímější. |
| CalDAV | `/remote.php/dav/`, discovery principal/calendar-home-set | Zjistit vztah karet k úlohám/kalendáři; nezapisovat stejnou kartu zároveň dvěma protokoly. |
| Remote wipe | OCS core wipe | Zmapovat pro odvolanou aplikaci; při implementaci zneplatnit i frontu a přílohy. |
| Client integration | Capabilities a akce klientů | Volitelné otevření související aplikace; nepředpokládat, že OwnTalk/OwnNotes jsou nainstalované. |
| Preferences, status, recommendations, out-of-office | OCS poskytované serverem | Pro základní klient nejsou potřeba; případná informace má být doplněk, ne podmínka přihlášení. |
| Translation, Assistant, Text/TaskProcessing, FullTextSearch collections | Volitelná OCS rozšíření | Bez požadavku na AI funkce či indexaci se nepoužijí a text karet se jim automaticky neposílá. |
| Provisioning, app management, správcovská API | OCS admin rozhraní | Mimo běžného klienta Deck; aplikace nesmí vyžadovat administrátorský účet. |
| Talk, Notes, Mail, Contacts a další aplikace | Samostatná rozhraní aplikací | Související odkazy, nikoli kopie jejich funkčnosti v OwnDecku. |

Oficiální zdroje: [katalog klientských API](https://docs.nextcloud.com/server/stable/developer_manual/client_apis/index.html), [OCS přehled](https://docs.nextcloud.com/server/stable/developer_manual/client_apis/OCS/ocs-api-overview.html), [WebDAV](https://docs.nextcloud.com/server/stable/developer_manual/client_apis/WebDAV/index.html), [Notifications](https://github.com/nextcloud/notifications/blob/master/docs/ocs-endpoint-v2.md).

## Chyby, limity a kompatibilita

Oprava původní hranice rozšířených polí: `startdate` a `color` přijímají vytvoření i úpravy karet už v [Decku 1.18.0](https://github.com/nextcloud/deck/blob/v1.18.0/lib/Controller/CardApiController.php) a [1.18.5](https://github.com/nextcloud/deck/blob/v1.18.5/lib/Controller/CardApiController.php); [1.17.0](https://github.com/nextcloud/deck/blob/v1.17.0/lib/Controller/CardApiController.php) je ještě nemá. Klient je zpřístupňuje od 1.18. Vytvoření, změna a vymazání obou polí byly ověřené na skutečném Decku 1.18.5; revize a meze jsou v `docs/testing.md`.

400: opravit vstup; 401: obnovit přihlášení; 403: načíst práva a zastavit zápisy; 404: ověřit objekt nebo podporu endpointu; 409/412: zpracovat konflikt pouze pokud jej dané rozhraní skutečně vrací; 413: nabídnout menší přílohu; 423: uzamčený soubor; 429: respektovat Retry-After; 5xx: dočasná chyba bez slepého opakování mutace; 507: kvóta nebo úložiště. HTML proxy odpověď nikdy nezobrazovat jako bezpečný text chyby.

Žádné univerzální stránkování Deck seznamů není v této smlouvě garantované. Stránkovat jen tam, kde jsou parametry skutečně definované, například comments/search. Velké seznamy zpracovat mimo náročné překreslování UI a nezahajovat načítání příloh každé karty. Server s tisíci kartami má vlastní náklady; výkon nelze vyřešit jen mobilní animací.

První implementační cíl: stabilní REST 1.1, OCS comments/config a jednotlivě ověřené doplňkové funkce. Fallback 1.0 musí výslovně omezit typy příloh. Podporované verze Nextcloud/Deck v obchodě uvést až podle skutečně provedené matice T02, nikoli pouze podle úspěchu proti jednomu serveru.

## Kopie, vazby, hotový sloupec a oznámení

Kopie karty používá OCS adresu `apps/deck/api/v1.0/cards/{cardId}/clone` s `targetStackId`, ale vrací přímo JSON karty bez OCS obálky. Zdroj vyžaduje čtení, cílový sloupec úpravy. Kopíruje název, popis, štítky a dostupná přiřazení; termíny, komentáře a přílohy nejsou součástí této operace. Potvrzené ID nové karty se uloží před načtením výsledku, takže výpadek čtení nevyvolá další POST. Zdroj: [připnutý CardApi](https://github.com/nextcloud/deck/blob/28efc84c108807cf0821d83e52f45b43cac27412/src/services/CardApi.js).

Vazby `dependentCards` jsou směrované seznamy ID souvisejících karet. Nezakazují dokončení karty. Změna vyžaduje úpravy zdroje a čtení cíle; fronta řeší i ID dosud nevytvořených rodičů.

Hotový sloupec se nastavuje přes OCS `PUT stacks/{stackId}/done` s `boardId` a booleovským `isDone`. Vyžaduje správu nástěnky. Nastavení zruší předchozí hotový sloupec a dokončí aktivní karty v novém; zrušení nastavení již dokončené karty nevrací. UI vyžaduje přítomnost `isDoneColumn` ve skutečném snímku sloupce a před akcí vysvětlí její účinek. Potvrzení načte aktivní i archivované karty a ověří výsledné příznaky. Zdroj: [připnutý StackService](https://github.com/nextcloud/deck/blob/28efc84c108807cf0821d83e52f45b43cac27412/lib/Service/StackService.php).

Přehled oznámení nejprve ověří capability `notifications.ocs-endpoints` s `list`, čte API v2 a zobrazí pouze položky aplikace `deck`. Odpověď 204 znamená prázdný seznam. Čtení je na vyžádání, bez automatického pollingu a bez nové push registrace. Ověřený odkaz na kartu se načte a otevře nativně se stejným účtem; ostatní povolené odkazy se otevřou v prohlížeči bez přidání autorizačních hlaviček. Zdroj: [Notifications API v2](https://github.com/nextcloud/notifications/blob/master/docs/ocs-endpoint-v2.md).

Kontrola oficiálních zdrojů [Deck v1.18.5](https://github.com/nextcloud/deck/blob/v1.18.5/appinfo/routes.php) potvrzuje stejné tři smlouvy: kopii karty, vazby a hotový sloupec. [CardService](https://github.com/nextcloud/deck/blob/v1.18.5/lib/Service/CardService.php) zachovává kontrolu čtení zdroje a úprav cíle; [StackService](https://github.com/nextcloud/deck/blob/v1.18.5/lib/Service/StackService.php) stejný hromadný účinek nastavení hotového sloupce. Tyto operace tedy nejsou odvozené od podpory novějších polí REST editace karty. Jde o zdrojové ověření, nikoli o důkaz běhu na serveru.
