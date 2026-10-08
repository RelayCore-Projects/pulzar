---
tipus: adr
azonosito: ADR-001
statusz: elfogadva
datum: 2026-10-08
---

# ADR-001 – Flutter keretrendszer

## Kontextus
Elsődleges platform az Android, de később Windows asztali alkalmazás is kell, lehetőleg ugyanazzal a funkcionalitással. Kis csapat: egy fejlesztő és egy termékgazda/tesztelő, mobilfejlesztési előtapasztalat nélkül.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| **Flutter (Dart)** | Egy kódbázis Androidra és Windowsra; kiforrott grafikon- és PDF-csomagok; jó dokumentáció | A Dart új nyelv; nagyobb APK-méret |
| Natív Android (Kotlin + Jetpack Compose) | A „legandroidosabb” megoldás, kisebb APK | Az asztali verzióhoz külön technológia vagy nagy átalakítás kell |
| Kotlin Multiplatform + Compose Multiplatform | Android és asztal is | Az asztali rész kevésbé kiforrott, kisebb közösség |
| Webes app (PWA) | Bárhol fut | Gyengébb fájlkezelés, megosztás, offline tárolás Androidon |

## Döntés
**Flutter**, stabil csatorna.

## Következmények
- A v2 asztali verzió ugyanabból a kódból készülhet.
- A fordítás GitHub Actions-ben történik, a fejlesztői gépre nem kötelező Flutter SDK-t telepíteni.
- A csomagválasztást (adatbázis, grafikon, PDF) a v0.2.0 során külön ADR rögzíti.
