---
tipus: adr
azonosito: ADR-012
statusz: elfogadva
datum: 2026-10-15
---

# ADR-012 – PDF-jelentés a `pdf` csomaggal

## Kontextus
A v0.5.0 fő funkciója a nyomtatható PDF-jelentés (FR-11) szabadon választott időszakra. A név és a megjegyzés bármilyen nyelvű lehet (pl. ő, ű, č, š, ž), ezeket a PDF beépített betűtípusai nem ismerik, tehát betűtípust kell beágyazni. Az [[ADR-010 Fájlkezelés és grafikon külső csomag nélkül]] eddig minden külső csomagot került.

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| Saját PDF-író | Nincs új függőség | TrueType-beágyazás, Unicode-leképezés, tördelés, oldaltörés mind saját kód – nagy és hibalehetőséggel teli |
| **`pdf` csomag (DavBfr/dart_pdf)** | Széles körben használt, **tiszta Dart** (nincs natív kód, nincs engedély); táblázat oldaltöréssel, ismétlődő fejléccel; betűtípus-beágyazás csak a használt betűkkel | Új függőség (Apache-2.0); a forrása a GitHubon ellenőrizhető |
| `printing` csomag (közvetlen nyomtatás) | Rendszer nyomtatási ablaka | Natív plugin – éppen az a kockázat, amit az ADR-010 kerül |

## Döntés
- A PDF a **`pdf`** csomaggal készül (`pdf: ^3.11.0`), a kód: `lib/export/pdf_report.dart`; a tartalom tiszta adatként: `lib/domain/report.dart`.
- Betűtípus: **DejaVu Sans Condensed** (normál + félkövér) az `assets/fonts` mappában, licenc: `assets/fonts/LICENSE-DejaVu.txt` (Bitstream Vera, szabadon terjeszthető).
- A grafikon a PDF-ben is saját rajz (vonalak, pontok a vásznon), így ugyanúgy néz ki, mint az appban.
- **Nyomtatás:** a PDF a rendszer fájlválasztójával menthető (FR-14), majd *Open* gombbal megnyitható a telefon PDF-nézegetőjében – onnan nyomtatható vagy megosztható. Saját nyomtatás- és megosztás-funkció (plugin) nem kell.
- A PDF elkészítése cserélhető (`AppServices.renderPdf`), a felületi tesztek gyors helyettesítővel futnak; a valódi PDF-et külön tesztek készítik el (üres, egy hét, egy év napi 3 méréssel, több év).

## Következmények
- Az ADR-010 a fájlkezelésre és a grafikonra továbbra is érvényes; a PDF az első tudatos kivétel.
- Az APK kb. 1 MB-tal nagyobb (két betűfájl); a PDF-be csak a használt betűk kerülnek.
- A `pubspec.lock` frissítéséhez a CI a Preview kiadásra is feltölti a feloldott `pubspec.lock`-ot (Ö-011).
