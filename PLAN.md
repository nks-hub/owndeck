# OwnDeck: plán práce

OwnDeck je mobilní klient Nextcloud Deck pro Android a iOS. Sdílí ovládací vzory s OwnTalk a OwnNotes.

## Pořadí

1. Ověřit existující řešení v OwnTalk a OwnNotes.
2. Porovnat Trello, přímé klienty Deck a další správce úkolů podle skutečných mobilních scénářů.
3. Zmapovat veřejné Deck API i související Nextcloud rozhraní; oddělit stabilní smlouvu, skutečné chování serveru a nejistoty.
4. Sepsat funkce, obrazovky, přístupnost, práci bez připojení, ochranu dat a přijímací podmínky.
5. Vybrat převzatelné části, připnout závislosti a vytvořit aplikaci pro obě platformy.
6. Implementovat přihlášení, účty, nástěnky, sloupce, karty, spolupráci, přílohy a synchronizaci.
7. Integrovat Sentry a Rybbit včetně nastavení soukromí a ověření doručení událostí.
8. Automatické testy spouštět neblokujícím způsobem na pozadí a nezávislé sady souběžně nad neměnnou revizí; po vývoji dokončit integrační testy a ověřit sestavení obou platforem.
9. Průběžně ověřovat kandidáty z odděleného pracovního stromu na fyzických Samsung Galaxy S9 a S21, na pozadí samostatně pro každý telefon. iOS ověřovat zvlášť na dostupném cílovém zařízení. Před dokončením musí výsledky pokrývat finální revizi.

## Důkazy dokončení

Každý test a sestavení musí uvést revizi. Automatické testy, emulátor, simulátor a skutečný telefon jsou odlišné důkazy. Nedostupné zařízení není splněný test. Obdobně konfigurace měření není důkaz doručení do Sentry nebo Rybbit.

Výstupy analýzy jsou v `docs/`. Stav jednotlivých kroků je v [TODO.md](TODO.md). Ověřené zdroje uvádět přímo u příslušných závěrů. Přístupy, lokální konfigurace a interní provozní záznamy patří mimo Git.
