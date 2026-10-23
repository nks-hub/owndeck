# Identita a verze

- Název aplikace: OwnDeck.
- Soukromý GitHub repozitář: `nks-hub/owndeck`.
- Android applicationId a namespace: `com.nkshub.nextclouddeck`.
- iOS bundle identifier: `com.nkshub.nextclouddeck`.
- Dart název aplikace: `nextclouddeck`.
- Výchozí vývojová verze: `0.1.0+1`. Nejde o vydaný build.

Verze má tvar `major.minor.patch+build`. Číslo buildu roste při každém distribučním sestavení a nikdy se znovu nepoužije. Stejný kandidát pro Android a iOS má stejnou verzi a zdrojovou revizi. `VERSION` je zdroj verze; `python tool/sync_version.py` jej před sestavením promítne do Flutter konfigurace, kterou přebírají obě platformy. Release tag `v0.1.0+1` smí vzniknout až pro ověřenou revizi, ne při založení projektu.

Kandidátní aplikace pro souběžné testování může používat příponu `.candidate`, podle vzoru OwnTalk a OwnNotes. Nesmí nahradit distribuční identifikátor ani načíst jeho místní data.

Sentry a Rybbit jsou volitelné. V běžném zdrojovém kódu nesmějí být jejich skutečné klíče ani adresy naší telemetrie. Naše distribuční CI je dodá při sestavení. Bez konfigurace se SDK nezapne a aplikace normálně funguje. Souhlas uživatele zůstává samostatnou podmínkou odesílání i v našem buildu.
