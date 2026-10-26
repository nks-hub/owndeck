# Zadání mobilní aplikace OwnDeck

## Uživatel a výsledek

OwnDeck umožní spravovat vlastní i sdílené Nextcloud nástěnky na Androidu a iOS. Uživatel přidá úkol, upraví jej, přiřadí člověka, nastaví termín, přesune kartu a doplní komentář nebo přílohu. Rozpracovaná práce přežije ztrátu připojení i restart aplikace.

Výchozí jazyk je jazyk zařízení, podporované texty budou česky a anglicky. Změna jazyka ani účtu nesmí zahodit koncept. Přesná identita je v [pravidlech verzování](versioning.md).

## Obrazovky a přijímací podmínky

| Obrazovka | Hlavní chování | Podmínka dokončení |
|---|---|---|
| Připojit server | HTTPS adresa, systémový prohlížeč, návrat do aplikace, čekání/zrušení | SSO/2FA zůstává na serveru; ukládá se jen app password. Podadresář funguje. Neznámý certifikát má srozumitelnou chybu. |
| Účty | Více serverů a uživatelů, přepnutí, odebrání | Shodné ID karty na dvou účtech nikdy nezamění obsah ani oprávnění. Odebrání zruší úlohy, odstraní data a pokusí se odvolat token. |
| Nástěnky | Vlastní, sdílené, archiv, barva, přidání, úprava, kopie a smazání | Respektuje `canCreateBoards` i oprávnění konkrétní nástěnky. Archiv je oddělený, smazání potvrzené. |
| Nástěnka | Sloupce a seznam, filtr, řazení, nový sloupec/karta | Ovládání funguje jednou rukou a s velkým písmem. Řazení odpovídá serveru po obnovení. |
| Detail karty | Název, Markdown, checklist v Markdownu, štítky, přiřazení, začátek/termín, dokončení, archiv | Chybějící schopnost serveru není nahrazena falešným úspěchem. Každá editace zachová ostatní pole. |
| Přesun | Výběr sloupce a pozice; přesun přes menu i tažením | Po chybě se neztratí původní karta. Pro jinou nástěnku se nejprve ověří serverová podpora a oprávnění. |
| Komentáře | Stránkování, přidání, úprava a odstranění vlastního komentáře | Nejasně potvrzený POST se neopakuje a nevytvoří duplicitu. Text je dostupný do vyřešení. |
| Přílohy | Výběr souboru, upload, připojení existujícího souboru, stažení, otevření, odebrání | Rozlišuje `file` a `deck_file`; odmítnutí oprávnění nebo kvóty nic nemaže. Soubor se neposílá do telemetrie. |
| Sdílení | Uživatelé/skupiny podle serveru, čtení/editace/správa/sdílení | UI neodvozuje práva z názvu role. Po odebrání práva zastaví čekající zápisy. |
| Moje úkoly | Přiřazené, dnes, po termínu, bez termínu; odkazy na kartu | Bere v úvahu časovou zónu, dokončení i archiv. Lokální neúplné výsledky jsou označené. |
| Hledání | V místních datech a online podle dostupného API | Filtry a výsledek patří ke konkrétnímu účtu. Zrušený požadavek nepřepíše novější hledání. |
| Synchronizace | Čekající změny, problém s přihlášením, konflikt, nejasný výsledek | Uživatel vidí vlastní koncept i serverovou verzi a může rozhodnout bez ztráty textu. |
| Nastavení | Vzhled, jazyk, účty, dvě samostatné volby telemetrie, verze | Bez konfigurace Sentry/Rybbit aplikace funguje a nic neposílá; naše buildy dostanou konfiguraci z CI. |

## Rozsah navazujících funkcí

Závislosti karet a sloupec dokončených úkolů jsou součástí analýzy a budou zpřístupněny na podporovaném serveru. Kopie karty a nástěnky používá serverovou funkci. Import z Trella a jeho konfigurace jsou zmapované; do prvního klienta patří odkaz na serverové možnosti, nikoli nový nekompatibilní importér. Univerzální automatizace, placené plány, Gantt a nový backend nejsou požadavkem tohoto zadání.

Oznámení: přehled oznámení a otevření karty přes ověřený odkaz. Push vyžaduje samostatné ověření podpory Nextcloud Notifications pro identitu OwnDeck. Nepřebírat tokeny/Firebase konfiguraci jiné aplikace. Dokud není push ověřený, neslibovat okamžité upozornění při ukončené aplikaci.

## Design

Použít rodinné rysy OwnTalk/OwnNotes: jednoduchý horní pruh, jasný přepínač účtu, světlý/tmavý režim, čitelná typografie. Hlavní navigace má tři cíle: Nástěnky, Moje úkoly, Nastavení. Hledání je akce dostupná v nástěnkách i vlastních úkolech. Detail karty je samostatná obrazovka, aby klávesnice ponechala místo pro delší popis.

Přihlašovací obrazovka má odpovídat aktuálnímu OwnTalku texty, ikonami, rozložením i chováním. Stejný vzor platí pro OwnNotes. Shodu ověřit také pro čekání na prohlížeč, QR přihlášení, zrušení a chybové stavy; specifická dostupnost aplikace Deck/Notes na serveru se kontroluje samostatně.

Na šířce pod 600 logických bodů zobrazit jeden sloupec s jasným názvem a počtem karet, sousední sloupec naznačit jen pokud zbývá místo. Nad 600 použít více sloupců nebo seznam/detail. Přepínač pohledu uchová volbu pro nástěnku. Identita položky musí být stabilní při přesunu, nikoli její index v seznamu.

Rozestupy vycházejí z 4/8/16/24 bodů. Primární text 16, doplňkový 14, nadpis obrazovky 24; respektovat systémové zvětšení. Zaoblení karty 12, formuláře 16. Barva nástěnky slouží k orientaci; text vždy používá kontrastní plochu, nikoli libovolnou barvu serveru jako pozadí celého formuláře. Stav není vyjádřen jen barvou.

Každá obrazovka má stavy načítání, prázdný obsah, uložená kopie bez připojení, chyba s možností obnovy a odmítnuté oprávnění. U již uložených dat nesmí síťová chyba nahradit celý obsah nekonečným indikátorem.

Na Androidu podporovat systémové Zpět, na iOS návrat tahem tam, kde se neztratí editace. Výběr data a potvrzení destruktivní akce respektují platformu. Dotykové plochy alespoň 48 logických bodů, alternativy k tažení, popisky ikon a správné pořadí čtečky. Ověřit 200% text, TalkBack a VoiceOver. Kontrast běžného textu minimálně 4,5:1.

Zdroje: [Android: přístupnost](https://developer.android.com/guide/topics/ui/accessibility/apps), [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility). Konkrétní rozměry a rozložení výše jsou návrhem OwnDecku, ne výsledkem uživatelského měření.

## Výkon a testování

Cíle pro závěrečné měření: použitelný uložený seznam do 2 s na S21 a do 3 s na S9; 95. percentil snímku při scrollování do 16,7 ms při 60 Hz. Testovací nástěnka: 10 sloupců a 1 000 karet, bez hromadného načítání příloh. Časy jsou přijímací cíle, nikoli dosažené výsledky. Zaznamenat profil/release režim, OS, teplotu a opakování.

Automatické i fyzické testy S9/S21 probíhají průběžně na pozadí nad izolovanými revizemi a neblokují další vývoj. iOS se ověřuje samostatně; před dokončením musí důkazy pokrývat finální verzi. Přesné scénáře a důkazy jsou v [testovacím plánu](testing.md).
