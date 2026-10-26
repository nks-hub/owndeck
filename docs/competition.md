# Konkurence a použitelné vzory

Stav průzkumu: 24. 10. 2026. Závěry vycházejí z dokumentace výrobců a zdrojových repozitářů. Nejde o vlastní měření rychlosti ani fyzický test konkurenčních aplikací. Ceny a počty instalací nejsou podkladem rozhodnutí.

| Produkt | Ověřená vlastnost | Co z toho použít | Omezení pro OwnDeck |
|---|---|---|---|
| Trello | Mobilní Inbox zachytí úkol před zařazením do nástěnky. Planner pracuje s kalendářem. | Rychlé přidání a oddělení každodenní práce od správy nástěnek. | Deck nemá stejný serverový Inbox ani kalendářní plánovač. Rychlé přidání musí vybrat cílovou nástěnku/sloupec; místní koncept musí být viditelně místní. |
| Nextcloud Deck Android | Veřejný nativní Android klient a přímá integrace s Deck. | Referenční chování stejného serveru, chyby kompatibility a práce s účty. | Android implementaci nepřenášet mechanicky do iOS. Používat jako zdroj scénářů. |
| Deck NG | Výrobce uvádí klienta Deck a vyžaduje Nextcloud 28+. | Kontrola očekávání uživatele dalšího samostatného klienta. | Odkazovaný GitHub v době kontroly vrátil 404. To nedokazuje ukončení produktu; dostupný zdroj není vhodný základ pro převzetí. |
| Deck pro iOS / React Native | GitHub projektu odkazuje na Framagit. | Sledovat rozdíly iOS ovládání a ověření přihlášení. | Stav údržby ani úplnost funkcí nejsou tímto odkazem prokázané. |
| Todoist | Mobilní přepínání seznamu a nástěnky, sloupce a filtry. | Jeden datový model se dvěma pohledy; filtrovaná práce bez opisování karet. | Nevytvářet vlastní prioritní či opakované úkoly bez odpovídajícího modelu Deck. |
| Asana | iOS dokumentuje práci bez připojení včetně komentářů a viditelných neodeslaných změn. | Zřetelný stav čekajícího zápisu, přehled vlastních úkolů. | Serverové real-time chování Asany nelze slibovat pro Deck. |
| Vikunja | Seznam, Kanban, tabulka, Gantt, vztahy a sdílení. | Přepínání pohledů a přehled termínů bez kopírování dat. | Gantt a opakování vyžadují vlastní rozsah a nejsou potřebné k základnímu klientu Deck. |

## Rozhodnutí pro produkt

Největší přínos OwnDecku má být ve společné kvalitě Android/iOS, návaznosti na rodinu Own aplikací a čitelné synchronizaci. Uživatel musí poznat rozdíl mezi uložením do telefonu, uložením na server a konfliktem. Přenos textu do vlastního Nextcloudu musí fungovat nezávisle na měření používání.

Na telefonu bude jeden sloupec s možností přepnutí a alternativní seznam. Široký Kanban s několika sloupci má smysl na tabletu nebo na šířku. Přetažení bude mít alternativu „Přesunout“, aby nebylo nutné přesně táhnout přes hranu obrazovky.

Rychlé vytvoření karty si zapamatuje poslední cíl v daném účtu. Nemá potichu vytvářet nástěnku Inbox na uživatelově serveru. „Moje úkoly“ sdruží přiřazené karty a termíny; při neúplné místní kopii přizná rozsah výsledků.

Název karty, dva řádky obsahu, označený termín, štítky a stav synchronizace mají přednost před velkou ilustrací. Prázdná nástěnka nabídne přidání sloupce; prázdný filtr nabídne zrušení filtru. Destruktivní akce mají potvrzení nebo skutečně dostupné vrácení změny.

## Zdroje

Praktické zapracování po review z 25. 10. 2026 je rozdělené do U01–U17 a F01 v `TODO.md`: souhrn karty s termínem, štítky a lidmi; rychlé zachycení s cílem; kombinované filtry přímo v nástěnce; jeden přesunový postup; interaktivní Markdown checklist; jasné čekání a řešení konfliktu. Stav zdrojového kódu a stav E2E se vedou zvlášť v `docs/review-redesign.md`. Hromadné operace, kalendář a příjem systémového sdílení jsou samostatné navazující návrhy F02–F05, nikoli tvrzení o už hotových funkcích.

- [Trello Inbox](https://support.atlassian.com/trello/docs/trello-inbox/)
- [Trello: filtry přímo v nástěnce](https://support.atlassian.com/trello/docs/filtering-for-cards-on-a-board/)
- [Trello: metadata termínů](https://support.atlassian.com/trello/docs/adding-dates-to-cards/)
- [Trello: checklist a průběh dokončení](https://support.atlassian.com/trello/docs/adding-checklists-to-cards/)
- [Trello: přesuny a hromadné akce](https://support.atlassian.com/trello/docs/moving-cards-or-lists/)
- [Trello Planner na mobilu](https://support.atlassian.com/trello/docs/use-trello-planner-on-mobile/)
- [Nextcloud Deck Android](https://github.com/stefan-niedermann/nextcloud-deck)
- [Deck NG v Google Play](https://play.google.com/store/apps/details?id=net.meltzow.deckng)
- [Deck React Native](https://github.com/StCyr/deck-react-native)
- [Todoist: nástěnky](https://www.todoist.com/help/todoist/features/use-the-board-layout-in-todoist-AiAVsyEI)
- [Asana pro iOS](https://help.asana.com/s/article/asana-for-ios?language=en_US)
- [Vikunja: pohledy](https://vikunja.io/help/views/)
- [Vikunja: funkce](https://vikunja.io/features/)
