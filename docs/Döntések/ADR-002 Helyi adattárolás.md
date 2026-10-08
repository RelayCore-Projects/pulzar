---
tipus: adr
azonosito: ADR-002
statusz: elfogadva
datum: 2026-10-08
---

# ADR-002 – Helyi adattárolás, felhő nélkül

## Kontextus
Egészségügyi jellegű, személyes adatokról van szó. Egyetlen felhasználó, egy telefon. Nincs szükség valós idejű szinkronra, de később asztali alkalmazással össze kell tudni kötni.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| **Helyi SQLite** | Nincs szerver, nincs fiók, nincs költség; az adat nem hagyja el a telefont | A telefon elvesztésével az adat is elveszhet, ha nincs mentés |
| Felhő (pl. Firebase) | Automatikus szinkron, mentés | Fiók, adatvédelmi kérdések, függőség egy szolgáltatótól |
| Saját szerver | Teljes kontroll | Üzemeltetés, biztonság, költség |

## Döntés
**Helyi SQLite adatbázis**, internet-engedély nélkül (NFR-01). Az adatvesztés ellen: teljes mentés JSON-fájlba és visszatöltés (FR-13).

## Következmények
- Az adatmodell már most szinkronra kész: UUID, `created_at`, `updated_at`, `deleted_at` (NFR-07).
- A v2 asztali összekötés első lépése a mentésfájl cseréje; valódi szinkron (pl. közös mappa vagy helyi Wi-Fi) később, külön ADR-ben.
- A felhasználót érdemes emlékeztetni a rendszeres mentésre ([[04 Ötletek]], Ö-005).
