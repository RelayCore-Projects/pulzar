---
tipus: teszteles
frissitve: 2026-10-08
---

# Tesztelés

## Tesztszintek

| Szint | Mit ellenőriz | Ki / mikor |
|---|---|---|
| **Egységteszt** (unit) | Validáció, napi korlát, összesítés számítása, CSV/JSON előállítás, összefésülés | Automatikusan, minden commitnál (GitHub Actions) |
| **Widget-teszt** | Egy-egy képernyő viselkedése (pl. hibaüzenet érvénytelen értéknél) | Automatikusan |
| **Integrációs teszt** | Teljes folyamat: rögzítés → táblázat → export | Automatikusan, kiadás előtt |
| **Kézi elfogadási teszt** | A lenti tesztlista valódi Android-eszközön | Tesztelő, minden kiadott verziónál |

Ha egy automatikus teszt elbukik, a GitHubon piros ❌ jelenik meg a commit mellett, és nem adunk ki verziót.

## Telepítés a telefonra

1. Telefonon nyisd meg: **github.com/RelayCore-Projects/pulzar/releases**
   - **Preview** – a legutóbbi fejlesztői fordítás (bármelyik ágról)
   - **Pulzar x.y.z** – végleges kiadások
2. Az *Assets* alatt koppints a `pulzar-….apk` fájlra → letöltés
3. Nyisd meg a letöltött fájlt → első alkalommal az Android engedélyt kér a böngészőnek az „ismeretlen alkalmazások telepítéséhez” → engedélyezd → *Telepítés*
4. Frissítésnél ugyanígy: az új APK a régire települ, az adatok megmaradnak
5. A telepített verziót a *Settings → About* mutatja

> Ha a Google Play Protect figyelmeztet („ismeretlen fejlesztő”), az azért van, mert az app nem a Play Áruházból jön: *További részletek → Telepítés mindenképp*.

## Kézi tesztlista

Minden kiadásnál másold le a táblázatot a [[#Tesztkörök]] alá az adott verzióval, és töltsd ki: ✅ rendben · ❌ hiba (+ issue szám) · ➖ nem releváns.

| ID | Követelmény | Lépések | Elvárt eredmény |
|---|---|---|---|
| T-01 | FR-01 | Új mérés: 128 / 82 / 72, mai nap, aktuális idő → Mentés | Megjelenik a naplóban a mai napnál |
| T-02 | FR-01 | Új mérés, időpontot átállítod 06:15-re | A mérés 06:15-tel jelenik meg, helyes sorrendben |
| T-03 | FR-02 | Szisztolé 80, diasztolé 90 | Hibaüzenet: a szisztolé legyen nagyobb |
| T-04 | FR-02 | Szisztolé 400 | Hibaüzenet a tartományról |
| T-05 | FR-02 | Holnapi dátum | Nem választható / hibaüzenet |
| T-06 | FR-03 | Ugyanarra a napra 4. mérés | Figyelmeztetés a napi korlátról |
| T-07 | FR-04 | Mérés szerkesztése, pulzus 72 → 80 | A módosítás mindenhol látszik |
| T-08 | FR-04 | Mérés törlése | Megerősítést kér; utána eltűnik |
| T-09 | FR-06, FR-07 | Táblázat, 30 nap | Csak az időszak mérései; átlag/min/max helyes |
| T-10 | FR-06 | Egyéni időszak | Csak a tartomány mérései |
| T-11 | FR-08, FR-09 | Grafikon, 30 nap | Két külön diagram, helyes értékek és időpontok |
| T-12 | FR-10 | Referenciaérték átállítása 140/90-re | A vonal a grafikonon és a kiemelés a táblázatban követi |
| T-13 | FR-11 | PDF, „mindkettő”, 30 nap | Fejléc, összesítés, táblázat, két grafikon, oldalszám |
| T-14 | FR-12 | CSV export, megnyitás Excelben | Ékezetek és oszlopok helyesek |
| T-15 | FR-13 | Mentés → app törlése → újratelepítés → visszatöltés | Minden mérés visszajön, duplikáció nincs |
| T-16 | FR-13 | Ugyanazt a mentést kétszer visszatöltöd | Nem keletkezik duplikáció |
| T-17 | FR-14 | PDF megosztása e-mailben | A csatolmány megnyitható |
| T-18 | NFR-01 | Repülőgép üzemmódban minden funkció | Minden működik |
| T-19 | NFR-05 | Rendszer betűméret: legnagyobb; sötét téma | Olvasható, semmi nem lóg ki |
| T-20 | FR-01 `🆕 v0.3.1` | Új mérés pulzus nélkül; meglévő mérésből a pulzus törlése | Menthető; a naplóban nincs „bpm” |
| T-21 | NFR-06 `🆕 v0.3.1` | Meglévő mérésekkel az új verzió telepítése a régire | Minden korábbi mérés megvan, változatlan értékekkel |

## Tesztkörök

*Itt gyűjtjük a kitöltött teszteket, verziónként (a legújabb felül).*

### v0.2.0 – 2026-10-08 (Preview 0.2.0-dev.6)

A T-xx tesztesetek funkciói még nem készültek el; ebben a verzióban a telepítést és a vázat teszteltük.

| Ellenőrzés | Eredmény |
|---|---|
| APK letöltése és telepítése a Releases oldalról | ✅ |
| Az app „Pulzar” néven indul | ✅ |
| Navigáció: Log · Table · Charts | ✅ |
| Settings → About: verzió, licenc, figyelmeztetés | ✅ |
| Automatikus tesztek (CI) | ✅ 4/4 |
