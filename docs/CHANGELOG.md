---
tipus: changelog
frissitve: 2026-10-08
---

# Változásnapló

Formátum: [Keep a Changelog](https://keepachangelog.com/), verziózás: [[03 Fejlesztési folyamat#Verziószámozás|szemantikus]].
Kategóriák: **Hozzáadva** · **Módosítva** · **Javítva** · **Eltávolítva** · **Biztonság**

## [Unreleased]

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
