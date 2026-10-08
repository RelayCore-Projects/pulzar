---
tipus: adr
azonosito: ADR-003
statusz: elfogadva
datum: 2026-10-08
---

# ADR-003 – Nyilvános repó, MIT licenc

## Kontextus
A projekt a RelayCore-Projects GitHub-szervezetben fut. Privát repóra nincs szükség; a nyilvánosság referenciaként is hasznos.

## Döntés
- **Nyilvános** repó: `RelayCore-Projects/pulzar`
- **MIT licenc**, szerző: RelayCore-Projects

## Következmények
- Bárki láthatja és felhasználhatja a kódot; a licenc „as is” záradéka kizárja a felelősséget. A README és a Névjegy (FR-16) kiemeli: nem orvostechnikai eszköz.
- **Mért adat soha nem kerülhet a repóba**: a `.gitignore` kizárja az exportokat és mentéseket; tesztadat csak kitalált értékekkel, a `test/fixtures` mappában.
- **Aláíró kulcs soha nem kerülhet a repóba**: GitHub Secretsben tároljuk; a `.gitignore` kizárja a `*.jks`, `*.keystore`, `key.properties` fájlokat. A kulcsról biztonsági másolatot kell őrizni a repón kívül – ha elveszik, a frissítések nem települnek a régi verzióra.
- Nyilvános repóban a GitHub Actions szokásos futtatói ingyenesek.
