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
| T-01 | FR-01 | Új mérés: 128 / 82 / 72, mai nap, aktuális idő → Mentés | Megjelenik a táblázatban a mai napnál `🔄 v0.4.0` |
| T-02 | FR-01 | Új mérés, időpontot átállítod 06:15-re | A mérés 06:15-tel jelenik meg, helyes sorrendben |
| T-03 | FR-02 | Szisztolé 80, diasztolé 90 | Hibaüzenet: a szisztolé legyen nagyobb |
| T-04 | FR-02 | Szisztolé 400 | Hibaüzenet a tartományról |
| T-05 | FR-02 | Holnapi dátum | Nem választható / hibaüzenet |
| T-06 | FR-03 | Ugyanarra a napra 4. mérés | Figyelmeztetés a napi korlátról |
| T-07 | FR-04 | Mérés szerkesztése, pulzus 72 → 80 | A módosítás mindenhol látszik |
| T-08 | FR-04 | Mérés törlése | Megerősítést kér; utána eltűnik |
| T-09 | FR-06, FR-07 `🔄 v0.4.0` | Table, Week, majd Month | Csak a hét (hétfő–vasárnap) / a hónap mérései; átlag/min/max helyes |
| T-10 | FR-06 `🔄 v0.4.0` | ~~Egyéni időszak~~ → **All** | Minden mérés látszik, a legkorábbitól |
| T-11 | FR-08 `🔄 v0.4.0` | Charts, Week, egy napon 3 méréssel | Egy ábra, piros / kék; a napon egy pont (átlag) és egy min–max vonal |
| T-12 | FR-10 (v0.5.0-tól) | Referenciaérték átállítása 140/90-re | A vonal a grafikonon és a kiemelés a táblázatban követi |
| T-13 | FR-11 | PDF, „mindkettő”, 30 nap | Fejléc, összesítés, táblázat, két grafikon, oldalszám |
| T-14 | FR-12 | CSV export, megnyitás Excelben | Ékezetek és oszlopok helyesek |
| T-15 | FR-13 | Mentés → app törlése → újratelepítés → visszatöltés | Minden mérés visszajön, duplikáció nincs |
| T-16 | FR-13 | Ugyanazt a mentést kétszer visszatöltöd | Nem keletkezik duplikáció |
| T-17 | FR-14 | PDF megosztása e-mailben | A csatolmány megnyitható |
| T-18 | NFR-01 | Repülőgép üzemmódban minden funkció | Minden működik |
| T-19 | NFR-05 | Rendszer betűméret: legnagyobb; sötét téma | Olvasható, semmi nem lóg ki |
| T-20 | FR-01 `🆕 v0.3.1` | Új mérés pulzus nélkül; meglévő mérésből a pulzus törlése | Menthető; a táblázatban a pulzus helyén „–” `🔄 v0.4.0` |
| T-21 | NFR-06 `🆕 v0.3.1` | Meglévő mérésekkel az új verzió telepítése a régire | Minden korábbi mérés megvan, változatlan értékekkel |
| T-22 | FR-13 `🆕 v0.4.0` | Visszatöltés egy nem Pulzar-fájlból (pl. egy fénykép) | Hibaüzenet, semmi nem változik |
| T-23 | FR-06 `🆕 v0.4.0` | Table fekvő tájolásban, sok méréssel | Az egész nézet görgethető, a dátum nem lóg ki |
| T-25 | FR-06 `🆕 v0.4.0` | Charts-on és Table-ön húzás jobbra / balra, ‹ › gombok | Előző / következő hét (hónap, év); a jövőbe nem lapoz |
| T-26 | FR-08 `🆕 v0.4.0` | Charts, Month és Year; a Table-ön „All”, majd Charts | Napi, illetve heti átlagok pontokkal; „All” helyett az aktuális év |
| T-27 | FR-06 `🆕 v0.4.0` | Table: + gomb; sorra koppintás; hosszú megjegyzés | Új mérés felvehető; a sor megnyílik szerkesztésre; a megjegyzés egy sorban, teljes szöveg az űrlapon |
| T-24 | FR-13 `🆕 v0.4.0` | Mentés Google Drive-ra, majd visszatöltés onnan | A mentés megjelenik a Drive-on; visszatöltéskor „Already up to date” |

## Tesztkörök

*Itt gyűjtjük a kitöltött teszteket, verziónként (a legújabb felül).*

### v0.4.0 – visszajelzés a 0.4.0-dev.19 kézi tesztjéből (2026-10-08)

| Nézet | Észrevétel | Megoldás |
|---|---|---|
| Table | A dátum nem fér ki a telefon képernyőjére | Napi fejlécsor, a dátum oszlop megszűnt |
| Table | Fekvő módban az összesítő elfoglalja a képernyőt, nem görgethető | Az egész nézet egyben görgethető |
| Table, Charts | A „Custom” időszakra nincs szükség | „All” – minden mérés |
| Charts | A szisztolé és a diasztolé legyen egy ábrán; szisztolé piros, diasztolé kék | Közös grafikon, piros / kék, jelmagyarázattal |
| Charts | 7 nap helyett teljes hetek, és lapozás húzással az előző / következő hétre; Week / Month / Year / All | Naptári időszakok, ‹ › és húzás (Table-ön is) |
| Charts | Napi 3 mérésnél a pontok összezsúfolódnak; hetente 7 pont legyen | Egy pont = napi átlag + min–max vonal ([[ADR-011 Naptári időszakok és átlagolt grafikon]]) |
| Table | A táblázat mellett a Log fül fölösleges; a táblázatból lehessen rögzíteni | Log megszűnt; Table a főképernyő, jobb alul + gomb |
| Table | A 200 karakteres megjegyzés nem fér el | Egysoros, levágott megjegyzés ikonnal; koppintásra a teljes mérés |
| Charts | Az „All” nem ábrázolható jól | A Charts-on csak Week / Month / Year |
| Charts | Mérés nélküli napoknál az összekötő vonal zavaró | Csak pontok |

### v0.3.1 – 2026-10-08 (Preview 0.3.1-dev.13)

| ID | Eredmény | Megjegyzés |
|---|---|---|
| T-20 | ✅ | mentés pulzus nélkül, pulzus törlése szerkesztéskor |
| T-21 | ✅ | frissítés a 0.3.0-ra telepítve; minden korábbi mérés megmaradt |
| Saját ikon | ⏳ | a telepített appon megerősítendő |
| Automatikus tesztek (CI) | ✅ | 34 teszt, köztük az adatbázis-migráció |

### v0.2.0 – 2026-10-08 (Preview 0.2.0-dev.6)

A T-xx tesztesetek funkciói még nem készültek el; ebben a verzióban a telepítést és a vázat teszteltük.

| Ellenőrzés | Eredmény |
|---|---|
| APK letöltése és telepítése a Releases oldalról | ✅ |
| Az app „Pulzar” néven indul | ✅ |
| Navigáció: Log · Table · Charts | ✅ |
| Settings → About: verzió, licenc, figyelmeztetés | ✅ |
| Automatikus tesztek (CI) | ✅ 4/4 |
