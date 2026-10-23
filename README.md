# OwnDeck

OwnDeck je připravovaný klient Nextcloud Deck pro Android a iOS ve Flutteru.

Repozitář je zatím soukromý. Aktuálně obsahuje zadání, porovnání konkurence, analýzu API a návrh implementace. Funkční mobilní aplikace ještě není hotová.

Další práci řídí [TODO.md](TODO.md). Celkové pořadí je v [PLAN.md](PLAN.md).

- [Zadání a vzhled](docs/product.md)
- [Konkurence](docs/competition.md)
- [Co převzít z OwnTalk a OwnNotes](docs/reuse.md)
- [Nextcloud a Deck API](docs/nextcloud-api.md)
- [Soupis 86 verzovaných rout](docs/api-inventory.md)
- [Architektura a synchronizace](docs/architecture.md)
- [Testovací plán](docs/testing.md)
- [Identita a verze](docs/versioning.md)

Package name a bundle ID: `com.nkshub.nextclouddeck`. Verze je v `VERSION`. Naše distribuční buildy dostanou volitelné Sentry a Rybbit z CI; vlastní build může fungovat bez obou služeb.
