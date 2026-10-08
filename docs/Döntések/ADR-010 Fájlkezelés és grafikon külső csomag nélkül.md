---
tipus: adr
azonosito: ADR-010
statusz: elfogadva
datum: 2026-10-08
---

# ADR-010 – Fájlkezelés és grafikon külső csomag nélkül

## Kontextus
A v0.4.0-hoz fájlmentés / -megnyitás (FR-13) és grafikon (FR-08 – FR-10) kell. A fejlesztői gépeken nincs Flutter SDK, minden fordítás a CI-ban történik, így egy függőségi vagy kompatibilitási hiba (pl. egy csomag nem fordul az új Android Gradle Pluginnal) teljes javítási kört jelent.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| Csomagok (`file_picker`, `share_plus`, `fl_chart`) | Kész, sokat tudnak | Verzió- és platformkompatibilitási kockázat; API-változások |
| **Saját, kis megoldás** | Nincs külső függőség; pontosan azt tudja, ami kell; tesztelhető | Több saját kód |

## Döntés
- **Fájlkezelés:** az Android **Storage Access Framework** saját csatornán (`MainActivity.kt` + `lib/platform/file_access.dart`). A felhasználó a rendszer fájlválasztójában dönti el, hová ment (Letöltések, Google Drive…), és honnan tölt vissza. Nem kell tárhely-engedély.
- **Grafikon:** saját `CustomPainter` (`lib/widgets/bp_chart.dart`): több adatsor egy ábrán (szisztolé piros, diasztolé kék), vonal + pontok, valós időtengely, rács, soronként szaggatott referenciavonal.
- A fájlkezelés egy cserélhető felületen (`FileAccess`) keresztül érhető el, így a tesztek valódi fájlrendszer nélkül futnak.

## Következmények
- A PDF / CSV exportnál (v0.5.0) ugyanez a mentési út használható; a „Megosztás” (FR-14) külön döntést igényel.
- Ha a grafikonnál később több kell (nagyítás, érintésre érték – Ö-013), újra mérlegelhető egy csomag.
