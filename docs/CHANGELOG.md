---
tipus: changelog
frissitve: 2026-10-15
---

# Változásnapló

Formátum: [Keep a Changelog](https://keepachangelog.com/), verziózás: [[03 Fejlesztési folyamat#Verziószámozás|szemantikus]].
Kategóriák: **Hozzáadva** · **Módosítva** · **Javítva** · **Eltávolítva** · **Biztonság**

## [Unreleased]

## [1.0.0] – 2026-10-15 – Első stabil kiadás

A Pulzar első stabil kiadása; a kód azonos a 0.5.1-gyel.

### Mit tud
- Mérés rögzítése (dátum, időpont, szisztolé, diasztolé, opcionális pulzus, megjegyzés), szerkesztés, törlés; naponta legfeljebb 3 mérés
- Táblázat napokra bontva, hét / hónap / év / összes időszak, összesítés (átlag, min, max)
- Grafikon: a szisztolé és a diasztolé napi (évnél heti) átlaga, állítható referenciavonalakkal
- PDF-jelentés választott időszakra, nyomtatható, opcionálisan névvel
- Teljes mentés és visszatöltés (pl. Google Drive-ra)
- Offline: minden adat csak a telefonon

### Eltávolítva
- A tervezett CSV export (FR-12) – nem kell; minden adat a teljes mentésben van

## [0.5.1] – 2026-10-15 – PDF dátumoszlop

### Javítva
- PDF: a táblázat dátuma („2026.10.15 (Wednesday)”) a hosszabb napneveknél új sorba tört – a dátumoszlop szélesebb lett; automatikus teszt őrzi, hogy minden nap neve kiférjen

## [0.5.0] – 2026-10-15 – PDF-jelentés és beállítások

### Hozzáadva
- **PDF export** (FR-11): a fejléc PDF ikonjáról, **szabadon választott időszakra** (*From* – *To*, gyorsgombok: *Last 30 days*, *Last 3 months*, *All*); grafikon és / vagy táblázat; A4, nyomtatható: fejléc névvel és időszakkal, összesítő, átlagos értékek grafikonja, minden mérés időrendben, a fejléc minden oldalon, oldalszám
- A PDF mentése a rendszer fájlválasztójával, utána **Open**: megnyitás a telefon PDF-nézegetőjében, onnan nyomtatás vagy megosztás (FR-14)
- **Beállítások** (FR-15): név a PDF-en; **referenciaértékek** be/ki és állítható értékek (alap: 135 / 85) – a szaggatott vonalak az appban és a PDF-ben ezeket követik
- [[ADR-012 PDF a pdf csomaggal]]; betűtípus: DejaVu Sans Condensed (ékezetes nevek és megjegyzések: ő, ű, č, š…)
- Új automatikus tesztek: beállítások, PDF-adatok, PDF elkészítése (egy év napi 3 méréssel is), export képernyő, adatbázis-frissítés v2 → v3

### Módosítva
- A Preview kézi tesztje alapján: a referencia fölötti értékek **nincsenek kiemelve** (táblázat, PDF); a PDF táblázatában a dátum `2026.10.15 (Thursday)` formátumú
- Adatbázis-séma 3-as verzió: új `settings` tábla; a mérések nem változnak (NFR-06)
- CI: a feloldott `pubspec.lock` a Preview kiadásra is felkerül (Ö-011)
- [[02 Ütemterv]]: a v1.0 hatóköre véglegesítve; a CSV export (Ö-016), a téma választás (Ö-017) és a lefúrás (Ö-015) a v1.0 után

## [0.4.0] – 2026-10-08 – Mentés, táblázat, grafikon

### Hozzáadva
- **Mentés és visszatöltés** (FR-13): minden mérés egy JSON-fájlba, a hely szabadon választható (Letöltések, Google Drive…); visszatöltés előnézettel és összefésüléssel
- **Táblázat** (FR-06, FR-07): naptári időszakok (hét, hónap, év, összes) lapozással, összesítés (átlag, min, max), a referenciaértéket elérő értékek kiemelve
- **Grafikon** (FR-08, FR-10): szisztolé (piros) és diasztolé (kék) pontok egy ábrán; egy pont = napi átlag (évnél heti átlag); szaggatott referenciavonalak (135 / 85); koppintásra a nap / hét mérései
- [[ADR-009 Gyorsabb CI]], [[ADR-010 Fájlkezelés és grafikon külső csomag nélkül]], [[ADR-011 Naptári időszakok és átlagolt grafikon]]
- Új automatikus tesztek: időszak, összesítés, mentés / visszatöltés, táblázat, grafikon, SQLite visszatöltés

### Módosítva
- CI: tesztek és APK-fordítás párhuzamosan, Gradle-gyorsítótár, csak 64 bites ARM APK (kisebb, gyorsabb)
- A kézi teszt alapján: a táblázat napi fejlécsorokkal, egyben görgethető (fekvő módban is); „Custom” helyett „All” időszak; a szisztolé (piros) és a diasztolé (kék) egy grafikonon
- A második visszajelzés alapján: naptári hetek / hónapok / évek lapozással (‹ › és húzás); a grafikonon napi átlagok
- Időszakváltáskor a grafikon nézet a tetejére ugrik
- A lefúrás (*Show week* / *Show month*) kimaradt ebből a verzióból – az automatikus teszt hibát talált benne; a következő verzióban jön (Ö-015)
- A negyedik visszajelzés alapján: a táblázatban érintésre részletek lap, hosszú nyomásra szerkesztés; a grafikonon a min–max vonal megszűnt, koppintásra kiemelés és a mérések listája, kisebb pontok az évben
- A harmadik visszajelzés alapján: a **Log fül megszűnt**, a **Table a főképernyő** (+ gomb jobb alul, sorra koppintva szerkesztés, megjegyzés egy sorban ikonnal); a grafikonon **csak pontok**, és nincs „All”

## [0.3.1] – 2026-10-08 – Opcionális pulzus

### Javítva
- A pulzus opcionális lett: üresen hagyható új mérésnél és szerkesztéskor is; a naplóban ilyenkor nem jelenik meg (#3)

### Módosítva
- Adatbázis-séma 2-es verzió: a `pulse` oszlop opcionális. A meglévő mérések frissítéskor automatikusan, adatvesztés nélkül átkerülnek (első migráció, NFR-06)
- CI: SQLite a tesztgépen, hogy az adatbázis-migráció automatikusan tesztelhető legyen
- [[02 Ütemterv]]: átütemezés – nagyobb verziók, a mentés előrehozva a 0.4.0-ba

## [0.3.0] – 2026-10-08 – Mérés rögzítése

### Hozzáadva
- Mérés rögzítése: dátum, szabadon megadható időpont, szisztolé, diasztolé, pulzus, megjegyzés (FR-01)
- Bevitel ellenőrzése: tartományok, szisztolé > diasztolé, időpont nem lehet a jövőben (FR-02)
- Napi 3 mérés korlát; elérésekor felajánlja a nap meglévő méréseinek szerkesztését (FR-03)
- Szerkesztés és törlés megerősítéssel; a törlés logikai (FR-04, NFR-07)
- Napló lista napokra csoportosítva, „Today” / „Yesterday” jelöléssel (FR-05)
- Helyi SQLite adatbázis – [[ADR-007 Adattárolás megvalósítása]]
- Saját alkalmazásikon: piros szív EKG-vonallal, sötét háttéren; adaptív és témázott (Android 13+) változat – [[ADR-008 Alkalmazásikon]]
- Automatikus tesztek: validáció, formázás, csoportosítás, napi korlát, teljes rögzítés / szerkesztés / törlés folyamat

### Módosítva
- CI: a `flutter analyze` stílusjavaslatai (info) nem állítják meg a fordítást, a hibák és figyelmeztetések igen

## [0.2.0] – 2026-10-08 – Projektváz és automatikus kiadás

### Hozzáadva
- Flutter projektváz: alsó navigáció (Log · Table · Charts), helyőrző nézetek, Settings, About (verzió, licenc, figyelmeztetés)
- Első automatikus tesztek (`test/widget_test.dart`)
- [[ADR-005 Angol nyelvű felület]]
- Android platformfájlok (`flutter create`, Flutter 3.47.6); `minSdk 26`, alkalmazásnév: Pulzar
- CI: elemzés, tesztek, aláírt APK minden pushnál; Preview előzetes kiadás; végleges kiadás `v*` címkére – [[ADR-006 Fordítás, aláírás és kiadás a GitHub Actionsben]]
- [[05 Tesztelés]]: telepítési útmutató

### Módosítva
- Az alkalmazás felülete angol (`en_GB`); a dokumentáció magyar marad – [[01 Specifikáció]] 0.2.0

## [0.1.1] – 2026-10-08 – Koncepció lezárva

### Módosítva
- [[01 Specifikáció]] 0.1.1: a nyitott kérdések (K-01…K-05) lezárva
  - FR-03: a napi 3 mérés kemény korlát
  - FR-10: referenciavonal alapból 135/85 Hgmm, bekapcsolva
  - FR-11: név a PDF-en csak akkor, ha a beállításokban meg van adva
  - NFR-08: minSdk 26 (Android 8.0), tesztelés Android 14+ eszközön
  - Pulzus grafikon nem kerül a v1.0-ba (Ö-002 marad ötlet)

## [0.1.0] – 2026-10-08 – Koncepció

### Hozzáadva
- Projekt indítása a RelayCore-Projects szervezetben, MIT licenccel
- [[01 Specifikáció]] első változata: FR-01…16, NFR-01…08, adatmodell, képernyővázlatok, nyitott kérdések K-01…05
- [[02 Ütemterv]] a 0.1.0 → 1.0.0 → 2.x verziókra
- [[03 Fejlesztési folyamat]]: verziózás, ágak, commitok, kiadás, a változások dokumentálása
- Döntések: [[ADR-001 Flutter]], [[ADR-002 Helyi adattárolás]], [[ADR-003 Nyilvános repó és MIT licenc]], [[ADR-004 Repó- és vault-szerkezet]]
- [[04 Ötletek]], [[05 Tesztelés]], [[06 Hibák]], sablonok
- `.gitignore`: mért adatok, exportok, aláíró kulcsok és a privát jegyzetek (`docs/_privat/`) kizárása
- Szabály: mi kerülhet a nyilvános repóba ([[03 Fejlesztési folyamat#Mi kerülhet a nyilvános repóba]])
