---
tipus: utemterv
frissitve: 2026-10-08
---

# Ütemterv

Minden verzió egy lezárt, kipróbálható lépés. A verziószámozás szabályai: [[03 Fejlesztési folyamat#Verziószámozás]].

| Verzió | Tartalom | Fázis | Állapot |
|---|---|---|---|
| **0.1.x** | Koncepció: specifikáció, döntések, projektdokumentáció | Koncepció | 🟢 kész (0.1.1) |
| 0.2.0 | Flutter projektváz, alap navigáció, GitHub Actions: automatikus, aláírt APK minden kiadásnál | Fejlesztés | 🟢 kész |
| 0.3.0 | Adatbázis, mérés rögzítése / szerkesztése / törlése, validáció, napi korlát, napló lista (FR-01…05) | Fejlesztés | 🟢 kész |
| 0.3.1 | Javítás: a pulzus opcionális, első adatbázis-migráció (#3) | Hibajavítás | 🟢 kész |
| 0.4.0 `🔄` | **Mentés / visszatöltés** (FR-13) · **táblázat**, időszak-választó, összesítés (FR-06, 07) · **grafikonok**, referenciavonal (FR-08…10) · gyorsabb CI | Fejlesztés | 🟢 kész |
| 0.5.0 `🔄` | **PDF és CSV export**, megosztás, beállítások (FR-11, 12, 14, 15); lefúrás a grafikonon (Ö-015) | Fejlesztés | 🟡 következő |
| ~~0.6.0~~ | ~~PDF és CSV export, mentés / visszatöltés, megosztás, beállítások, névjegy (FR-11…16)~~ → beolvadt a 0.4.0-ba és a 0.5.0-ba | – | ⛔ |
| 0.9.0 | Kiadásra jelölt: teljes kézi tesztkör valódi eszközön | Tesztelés | ⚪ tervezett |
| 0.9.x | Hibajavítások a tesztkör alapján | Hibajavítás | ⚪ tervezett |
| **1.0.0** | Első stabil kiadás | Kiadás | ⚪ tervezett |
| 2.x | Windows asztali alkalmazás + adatcsere / szinkron a telefonnal | – | 💭 ötlet |

**Jelmagyarázat:** 💭 ötlet · ⚪ tervezett · 🟡 folyamatban · 🟢 kész · 🔴 elakadt · ⛔ elvetve / beolvasztva

> [!note] Átütemezés – 2026-10-08
> A 0.4.0-tól **nagyobb verziók**: a fejlesztési folyamat (ág → CI → Preview → teszt → PR → címke) bevált, a kézi teszt gyors, a fordítás viszont egy-egy körben 8–10 perc. A **mentés előrekerült** a 0.4.0-ba, mert már valódi adatok vannak az appban. A régi 0.4.0 / 0.5.0 / 0.6.0 tartalma két verzióba (0.4.0, 0.5.0) rendeződött; a v1.0 tartalma nem változott.

A 0.2.0-tól minden verzióhoz telepíthető APK készül; a kézi teszt és a visszajelzés alapján lépünk tovább.

## Mérföldkő-napló

Ide kerül, mikor zárult le egy verzió (dátum + rövid megjegyzés). A részletes tartalom a [[CHANGELOG]]-ban.

- 2026-10-08 – Projekt indítása, repó és vault létrehozva
- 2026-10-08 – 0.1.1: nyitott kérdések lezárva, koncepció jóváhagyva
- 2026-10-08 – 0.2.0: projektváz, angol felület, CI, aláírt APK; első telepítés valódi telefonra sikeres
- 2026-10-08 – 0.3.0: mérés rögzítése, szerkesztése, törlése, napi korlát, napló lista, saját ikon; kézi teszt hiba nélkül
- 2026-10-08 – 0.3.1: a pulzus opcionális (#3), első adatbázis-migráció; T-20, T-21 sikeres
- 2026-10-08 – Átütemezés: nagyobb verziók, a mentés előrehozva a 0.4.0-ba
- 2026-10-08 – 0.4.0: mentés / visszatöltés, táblázat (főképernyő), naptári időszakok, napi átlagos grafikon; négy kézi tesztkör visszajelzése beépítve
