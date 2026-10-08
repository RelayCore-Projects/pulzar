---
tipus: adr
azonosito: ADR-009
statusz: elfogadva
datum: 2026-10-08
---

# ADR-009 – Gyorsabb CI

## Kontextus
Egy teljes kör (tesztek → APK → Preview) 8–10 perc volt; a tesztek és a fordítás egymás után futottak, a Gradle minden alkalommal mindent letöltött, és az APK mindhárom processzortípusra (≈48 MB) készült. A tesztelés gyors, így a fordítás lett a szűk keresztmetszet ([[02 Ütemterv]], átütemezés).

## Döntés
1. **Párhuzamos feladatok:** `test` és `apk` egyszerre fut; a `publish` (Preview / Release) csak akkor, ha **mindkettő** sikeres – hibás kód továbbra sem jut ki.
2. **Gradle-gyorsítótár** (`setup-java` `cache: gradle`) a Flutter-gyorsítótár mellé.
3. **Csak 64 bites ARM** (`--target-platform android-arm64`): minden mai telefon ilyen; az APK kb. harmad akkora.

## Következmények
- Emulátoron (x86_64) és nagyon régi, 32 bites telefonon ez az APK nem fut. Ha valaha kell, a `ci.yml`-ben a `--target-platform` bővíthető.
- Ha egy fordítás nem kell (pl. csak dokumentáció változott), a CI akkor is lefut – ez szándékos, így minden commitnak van telepíthető APK-ja.
