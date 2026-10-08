---
tipus: adr
azonosito: ADR-007
statusz: elfogadva
datum: 2026-10-08
---

# ADR-007 – Az adattárolás megvalósítása

## Kontextus
[[ADR-002 Helyi adattárolás]] szerint SQLite-ot használunk. Most a konkrét megoldást kell kiválasztani. Szempontok: kevés függőség, kódgenerálás nélkül (a fejlesztői gépeken nincs Flutter SDK, minden ellenőrzés a CI-ban fut), jól tesztelhető legyen.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| **sqflite** | Kiforrott, egyszerű, nincs kódgenerálás | Kézzel írt SQL, nincs típusellenőrzés a lekérdezéseken |
| drift | Típusos lekérdezések, beépített migráció | Kódgenerálás (`build_runner`) kell, több mozgó alkatrész |
| Isar / Hive | Gyors, egyszerű API | Nem SQL; a fenntartottságuk bizonytalan volt |

## Döntés
- **sqflite**, egyetlen `measurements` táblával (séma: [[01 Specifikáció#6. Adatmodell]]), `schemaVersion = 1`.
- **Tároló-absztrakció** (`MeasurementRepository`): az app SQLite-ot használ, a tesztek memóriában tárolnak (`InMemoryMeasurementRepository`).
- Az üzleti szabályok (validáció, napi korlát, logikai törlés) a `MeasurementStore`-ban vannak, nem az adatbázisban – így tesztelhetők adatbázis nélkül.
- UUID és dátumformázás saját, kis függvényekkel – külső csomag nélkül.

## Következmények
- Sémaváltozásnál a `schemaVersion` nő, és `onUpgrade` migrációt kell írni (NFR-06). A migráció tranzakcióban fut: hiba esetén semmi nem változik.
- **Sématörténet:** 1 – v0.3.0 · 2 – v0.3.1: `pulse` opcionális (#3), tábla-újraépítéssel
- Minden migrációhoz automatikus teszt tartozik (`test/sqlite_migration_test.dart`), ami a régi sémából indul.
- Az SQLite réteget a CI-ban `sqflite_common_ffi` teszteli (v0.3.1-től); a valódi eszközt a kézi teszt (T-01…T-08, T-21) fedi.
