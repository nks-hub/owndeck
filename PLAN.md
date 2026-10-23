# OwnDeck: plán práce

Zadání: mobilní klient Nextcloud Deck pro Android a iOS po vzoru OwnTalk a OwnNotes. Pracovní název je OwnDeck. Začátek práce: 24. 10. 2026. Složka projektu byla prázdná.

## Pořadí

1. Ověřit existující řešení v OwnTalk, OwnNotes a MCP Memory.
2. Porovnat Trello, přímé klienty Deck a další správce úkolů podle skutečných mobilních scénářů.
3. Zmapovat veřejné Deck API i související Nextcloud rozhraní; oddělit stabilní smlouvu, skutečné chování serveru a nejistoty.
4. Sepsat funkce, obrazovky, přístupnost, práci bez připojení, ochranu dat a přijímací podmínky.
5. Vybrat převzatelné části, připnout závislosti a vytvořit aplikaci pro obě platformy.
6. Implementovat přihlášení, účty, nástěnky, sloupce, karty, spolupráci, přílohy a synchronizaci.
7. Integrovat Sentry a Rybbit včetně nastavení soukromí a ověření doručení událostí.
8. Po vývoji spustit automatické a integrační testy, opravit nálezy a ověřit sestavení obou platforem.
9. Jako poslední krok ověřit hotového kandidáta na fyzických Samsung Galaxy S9 a S21; iOS ověřit zvlášť na dostupném cílovém zařízení.

## Důkazy dokončení

Každý test a sestavení musí uvést revizi. Automatické testy, emulátor, simulátor a skutečný telefon jsou odlišné důkazy. Nedostupné zařízení není splněný test. Obdobně konfigurace měření není důkaz doručení do Sentry nebo Rybbit.

Výstupy analýzy jsou v `docs/`. Stav jednotlivých kroků je v [TODO.md](TODO.md). Ověřené zdroje uvádět přímo u příslušných závěrů. Repozitář se připravuje pro zveřejnění: přístupy, lokální konfigurace a interní provozní záznamy patří mimo Git.
