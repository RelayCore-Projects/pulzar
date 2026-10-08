---
tipus: specifikacio
dokumentum_verzio: 0.4.0
statusz: jóváhagyva
frissitve: 2026-10-08
---

# Pulzar – Specifikáció

## Változástörténet

| Verzió | Dátum | Változás | Indok / forrás |
|---|---|---|---|
| 0.1.0 | 2026-10-08 | Első változat (koncepció) | Kiinduló igények, lásd [[#1. Cél]] |
| 0.1.1 | 2026-10-08 | Nyitott kérdések lezárva: FR-03, FR-10, FR-11, NFR-08 pontosítva; pulzus grafikon nem kerül a v1.0-ba | K-01…K-05 döntései, lásd [[#9. Nyitott kérdések]] |
| 0.2.0 | 2026-10-08 | Az alkalmazás felülete **angol**; FR-01, 02, 04, 06, 11, 12, 13, 16, NFR-03, képernyővázlatok igazítva | Új igény a fejlesztés közben, lásd [[ADR-005 Angol nyelvű felület]] |
| 0.3.1 | 2026-10-08 | A **pulzus opcionális**: FR-01, FR-02, FR-07, FR-12, adatmodell módosítva | Tesztelés közben talált követelmény-hiba: korábbi mérésekhez nincs mindig pulzus feljegyezve – GitHub #3 |
| 0.4.0 | 2026-10-08 | FR-06 (sorrend, kiemelés), FR-13 (törölt sorok, napi korlát), FR-14 (mentés helye) pontosítva | A megvalósítás során tisztázott részletek; [[ADR-010 Fájlkezelés és grafikon külső csomag nélkül]] |

> [!info] Hogyan jelöljük a változásokat ebben a dokumentumban
> - Minden módosítás új sort kap a fenti táblázatban (verzió, dátum, mi, miért).
> - A módosított követelmény mellé kerül egy jelölés: `🔄 v0.x.0`, az újak mellé `🆕 v0.x.0`.
> - A törölt követelményt nem töröljük, hanem áthúzzuk: ~~FR-xx …~~ `❌ v0.x.0`, és a változástörténetben megírjuk, miért.
> - A pontos szöveges különbséget a git őrzi (GitHub → a fájl *History* nézete).

---

## 1. Cél

Egyetlen felhasználó a saját vérnyomásértékeit **kézzel** rögzíti a telefonján, és ezeket
- **számszerűen** (táblázatban) meg tudja mutatni az orvosnak,
- **grafikusan** – külön a szisztolé és külön a diasztolé értékekről – meg tudja jeleníteni,
- **exportálni** tudja (PDF, CSV, teljes mentés).

Elsődleges platform: **Android** okostelefon. Későbbi cél: **Windows asztali** alkalmazás, amely ugyanazokat az adatokat tudja kezelni (v2, lásd [[02 Ütemterv]]).

## 2. Hatókör

### Benne van (v1.0)

- Mérés rögzítése, szerkesztése, törlése
- Napló lista
- Táblázatos nézet időszakszűréssel és összesítéssel
- Szisztolé és diasztolé grafikon
- PDF, CSV export; teljes mentés és visszatöltés
- Beállítások, névjegy

### Nincs benne (v1.0) – lehetséges későbbi bővítések: [[04 Ötletek]]

- Felhős tárolás, szinkronizálás, felhasználói fiók
- Több felhasználó (családtagok) kezelése
- Bluetooth vérnyomásmérő csatlakoztatása
- Emlékeztető értesítések
- iOS, web
- Bármilyen diagnózis, kiértékelés vagy egészségügyi tanács

## 3. Fogalmak

| Fogalom | Az appban (angol) | Jelentés |
|---|---|---|
| Szisztolé (SYS) | Systolic | Felső érték, Hgmm (mmHg) |
| Diasztolé (DIA) | Diastolic | Alsó érték, Hgmm (mmHg) |
| Pulzus (PUL) | Pulse | Szívverés / perc (bpm) |
| Hgmm | mmHg | Higanymilliméter, a vérnyomás mértékegysége |
| Mérés | Measurement | Egy időponthoz tartozó SYS + DIA + PUL (+ megjegyzés) |
| Napló | Log | A mérések listája |
| Időszak | Period | A megjelenítéshez / exporthoz választott dátumtartomány |

> [!note] Nyelv `🔄 v0.2.0`
> A dokumentáció magyar, **az alkalmazás felülete angol** ([[ADR-005 Angol nyelvű felület]]). Az angol feliratokat a követelmények idézőjelben adják meg.

---

## 4. Funkcionális követelmények

### 4.1 Bevitel

**FR-01 – Mérés rögzítése**
A felhasználó új mérést vehet fel a következő mezőkkel:

| Mező | Kötelező | Alapérték | Formátum |
|---|---|---|---|
| Dátum | igen | mai nap | NN/HH/ÉÉÉÉ (brit angol formátum) `🔄 v0.2.0` |
| Időpont | igen | aktuális idő | ÓÓ:PP (24 órás), **szabadon megadható** |
| Szisztolé | igen | – | egész szám, Hgmm |
| Diasztolé | igen | – | egész szám, Hgmm |
| Pulzus | ~~igen~~ **nem** `🔄 v0.3.1` | – | egész szám, /perc; üresen hagyható |
| Megjegyzés | nem | üres | szöveg, max. 200 karakter (pl. „gyógyszer után”, „bal kar”) |

A számmezőknél numerikus billentyűzet jelenik meg, és a mentés egy érintéssel elérhető.

**FR-02 – Ellenőrzés (validáció)**
Mentés csak érvényes adattal lehetséges; hiba esetén a mező alatt angol nyelvű üzenet jelenik meg. `🔄 v0.2.0`

| Szabály | Érték |
|---|---|
| Szisztolé tartomány | 50 – 300 Hgmm |
| Diasztolé tartomány | 30 – 200 Hgmm |
| Pulzus tartomány | 30 – 250 /perc – csak ha meg van adva `🔄 v0.3.1` |
| Logikai szabály | szisztolé > diasztolé |
| Időpont | nem lehet a jövőben |

> A tartományok csak az elgépelés kiszűrésére szolgálnak, nem orvosi határértékek.

**FR-03 – Napi korlát**
Egy naptári napra legfeljebb **3 mérés** rögzíthető. A negyedik mentési kísérletnél az app jelzi, hogy aznapra elérte a korlátot, és felajánlja egy meglévő mérés szerkesztését. A korlát **kemény**: negyedik mérés nem menthető. `🔄 v0.1.1` *(döntés: [[#9. Nyitott kérdések|K-02]])*

**FR-04 – Szerkesztés és törlés**
Bármely mérés minden mezője utólag szerkeszthető. A törlés megerősítést kér („Delete the measurement from 08/10/2026 07:30?”). `🔄 v0.2.0`

### 4.2 Megjelenítés

**FR-05 – Napló (főképernyő)**
A mérések napokra csoportosítva, a legfrissebb nap felül. Naponként a mérések időrendben: `07:30   128 / 82   72`. Érintéssel megnyílik a szerkesztés.

**FR-06 – Táblázatos nézet (orvosnak)**
- Időszak-választó: „7 days”, „30 days”, „90 days”, „Custom” (dátumtól–dátumig) `🔄 v0.2.0`
- Oszlopok: Dátum · Idő · Szisztolé · Diasztolé · Pulzus · Megjegyzés
- Nagy, jól olvasható betűméret; fekvő tájolásban is használható
- A referenciaértéket **elérő vagy meghaladó** értékek kiemelve (félkövér, piros), lásd FR-10 `🔄 v0.4.0`
- Sorrend: időrendben, a legkorábbi felül; az egy naphoz tartozó sorok közös háttérsávban `🆕 v0.4.0`
- Alapértelmezett időszak: 30 nap; a Table és a Charts nézet ugyanazt az időszakot használja `🆕 v0.4.0`

**FR-07 – Összesítés**
A táblázat fölött a kiválasztott időszakra: mérések száma, és SYS / DIA / PUL **átlaga, minimuma, maximuma**. A pulzus összesítése csak a pulzussal rögzített mérésekből készül; ha egy sincs, „–” jelenik meg. `🔄 v0.3.1`

**FR-08 – Szisztolé grafikon**
Vonal + pont diagram; vízszintes tengely: idő (a mérés valódi időpontja), függőleges tengely: Hgmm. Ugyanaz az időszak-választó, mint FR-06-ban.

**FR-09 – Diasztolé grafikon**
Mint FR-08, külön diagramon. A két grafikon egymás alatt, azonos időtengellyel.

**FR-10 – Referenciavonal**
Mindkét grafikonon szaggatott vízszintes vonal a beállított referenciaértéknél. Alapérték: **SYS 135, DIA 85 Hgmm** (az európai irányelv otthoni mérésre vonatkozó küszöbe), alapból bekapcsolva. Beállításokban módosítható vagy kikapcsolható. `🔄 v0.1.1` *(döntés: [[#9. Nyitott kérdések|K-03]])*

### 4.3 Export

**FR-11 – PDF export**
- Időszak: mint FR-06
- Tartalom választható: **táblázat**, **grafikon**, vagy **mindkettő**
- Fejléc: „Blood Pressure Log” `🔄 v0.2.0`, név – csak ha a beállításokban meg van adva (FR-15) –, időszak, készítés dátuma `🔄 v0.1.1` *(döntés: [[#9. Nyitott kérdések|K-04]])*
- Összesítő blokk (FR-07)
- Táblázat: minden mérés dátummal és időponttal
- Grafikon: SYS és DIA külön diagramon, referenciavonallal
- Lábléc: oldalszám, „Pulzar vX.Y.Z – not a medical device” `🔄 v0.2.0`
- Papírméret: A4, álló

**FR-12 – CSV export**
- Időszak: mint FR-06
- Kódolás: UTF-8 BOM-mal, elválasztó: pontosvessző (`;`) – így a magyar Excel helyesen nyitja meg
- Fejléc: `Date;Time;Systolic (mmHg);Diastolic (mmHg);Pulse (bpm);Note` `🔄 v0.2.0`
- Dátum: `2026-10-08` (ISO 8601, minden Excel egyértelműen értelmezi), idő: `07:30` `🔄 v0.2.0`
- Hiányzó pulzus: üres cella `🔄 v0.3.1`

**FR-13 – Teljes mentés és visszatöltés**
- Mentés: az összes adat egyetlen JSON-fájlba (`pulzar-backup-2026-10-08.json`) `🔄 v0.2.0`
- Visszatöltés: a fájl kiválasztása után az app megmutatja, hány mérést talált, és hány új; jóváhagyás után **összefésül** (azonos azonosítójú mérésből a később módosított marad, duplikáció nincs)
- Ez szolgál telefoncserére, adatvesztés elleni védelemre, és a v2 asztali alkalmazás első adatátviteli módjára is
- A mentés a logikailag törölt méréseket is tartalmazza, így egy törlés is átvihető másik eszközre; visszatöltéskor a telefonról semmi nem törlődik, kivéve ha a mentésben egy mérés **később** lett törölve `🆕 v0.4.0`
- Visszatöltéskor a napi 3 mérés korlátja (FR-03) nem érvényes – ez adat-visszaállítás `🆕 v0.4.0`
- Hibás vagy nem Pulzar-fájl esetén hibaüzenet, adat nem változik `🆕 v0.4.0`

**FR-14 – Megosztás**
Minden export után: *Megosztás* (Android megosztási menü: e-mail, Viber, Drive stb.) vagy *Mentés a Letöltések mappába*.
A teljes mentés (FR-13) a rendszer fájlválasztójával menthető bármilyen helyre – Letöltések, Google Drive stb. `🔄 v0.4.0`

### 4.4 Egyéb

**FR-15 – Beállítások**
Név a PDF-en (opcionális) · referenciaértékek (SYS, DIA, be/ki) · mentés / visszatöltés · téma (rendszer / világos / sötét).

**FR-16 – Névjegy**
Verziószám, licenc (MIT), link a repóra, és a figyelmeztetés: *„Pulzar is not a medical device and does not provide a diagnosis. Interpreting the values is up to your doctor.”* `🔄 v0.2.0`

---

## 5. Nem funkcionális követelmények

| ID | Követelmény |
|---|---|
| NFR-01 | **Offline működés.** A kiadott app nem kér internet-engedélyt; adat nem hagyja el a telefont, csak ha a felhasználó exportálja. |
| NFR-02 | **Helyi tárolás** SQLite adatbázisban ([[ADR-002 Helyi adattárolás]]). |
| NFR-03 | ~~**Magyar felület**, magyar dátum- és időformátum (ÉÉÉÉ.HH.NN., 24 órás).~~ `❌ v0.2.0` |
| NFR-03a | **Angol felület**, brit angol területi beállítás (`en_GB`): NN/HH/ÉÉÉÉ dátum, 24 órás idő, hétfővel kezdődő hét; exportban ISO 8601 dátum. A szövegek egy helyen legyenek, hogy később más nyelv (pl. magyar) is hozzáadható legyen. `🆕 v0.2.0` |
| NFR-04 | **Teljesítmény:** 10 évnyi adat (~11 000 mérés) mellett is gördülékeny lista, táblázat és grafikon; PDF 1 évre < 5 mp. |
| NFR-05 | **Olvashatóság:** követi a rendszer betűméretét; világos és sötét téma. |
| NFR-06 | **Adatbiztonság:** törlés csak megerősítéssel; adatbázis-séma változásnál automatikus, adatvesztés nélküli migráció. |
| NFR-07 | **Szinkronra felkészített adatmodell** (egyedi azonosító, időbélyegek, logikai törlés) – a v2 asztali összekötéshez. |
| NFR-08 | **Támogatott Android-verzió:** minimum Android 8.0 (minSdk 26), cél: a legfrissebb stabil Android (targetSdk). Elsődleges tesztelés Android 14+ eszközön. `🔄 v0.1.1` |

## 6. Adatmodell

**Measurement (mérés)**

| Mező | Típus | Leírás |
|---|---|---|
| `id` | UUID (szöveg) | Egyedi azonosító – eszközök között is egyedi |
| `measured_at` | dátum-idő (helyi idő) | A mérés időpontja |
| `systolic` | egész | Hgmm |
| `diastolic` | egész | Hgmm |
| `pulse` | egész, **opcionális** `🔄 v0.3.1` | /perc |
| `note` | szöveg, opcionális | max. 200 karakter |
| `created_at` | dátum-idő (UTC) | Létrehozás |
| `updated_at` | dátum-idő (UTC) | Utolsó módosítás – összefésülésnél ez dönt |
| `deleted_at` | dátum-idő (UTC), opcionális | Logikai törlés; a felületen nem látszik |

**Settings (beállítások)** – kulcs–érték párok: `patient_name`, `ref_systolic`, `ref_diastolic`, `ref_enabled`, `theme`.

**Mentésfájl (JSON) szerkezete**

```json
{
  "format": "pulzar-backup",
  "format_version": 1,
  "app_version": "1.0.0",
  "exported_at": "2026-10-08T07:30:00Z",
  "measurements": [
    {
      "id": "3f2b…",
      "measured_at": "2026-10-08T07:30:00",
      "systolic": 128, "diastolic": 82, "pulse": 72,
      "note": null,
      "created_at": "…", "updated_at": "…", "deleted_at": null
    }
  ]
}
```

## 7. Képernyők (vázlat)

```
┌─ Log ─────────────────────┐   ┌─ New measurement ────────┐
│ Log                  ⚙    │   │ ←                   Save │
│                           │   │                          │
│ Thursday, 8 October 2026  │   │ Date   [08/10/2026 ▾]    │
│  07:30   128 / 82   72    │   │ Time   [07:30 ▾]         │
│  13:10   131 / 85   75    │   │                          │
│                           │   │ Systolic   [ 128 ] mmHg  │
│ Wednesday, 7 October 2026 │   │ Diastolic  [  82 ] mmHg  │
│  07:20   125 / 80   70    │   │ Pulse      [  72 ] bpm   │
│  19:45   133 / 84   78    │   │                          │
│                     (＋)  │   │ Note       [           ] │
├───────────────────────────┤   └──────────────────────────┘
│   Log  │  Table  │ Charts │
└───────────────────────────┘

┌─ Table ───────────────────┐   ┌─ Charts ─────────────────┐
│ [7d][30d][90d][Custom]    │   │ [7d][30d][90d][Custom]   │
│ 32 measurements           │   │ Systolic (mmHg)          │
│       avg   min   max     │   │ 140┤      •              │
│ SYS   129   118   141     │   │ 135┤- - - - - - - - - -  │
│ DIA    83    76    90     │   │ 130┤ •─•   •─•  •        │
│ PUL    73    64    88     │   │ 120┤      ─         ─•   │
│───────────────────────────│   │ Diastolic (mmHg)         │
│ Date    Time  SYS DIA PUL │   │  90┤   •                 │
│ 08/10   07:30 128  82  72 │   │  85┤- - - - - - - - - -  │
│ 08/10   13:10 131  85  75 │   │  80┤ •─•  ─•─•  •─•      │
│               [Export ▾]  │   │               [Export ▾] │
└───────────────────────────┘   └──────────────────────────┘
```

Navigáció: alsó sáv – **Log**, **Table**, **Charts**; jobb fent **Settings** `🔄 v0.2.0`. Az *Export* gomb a táblázat és a grafikon nézetből is elérhető (PDF / CSV).

## 8. Tervezett technológia

Részletek és indoklás: [[ADR-001 Flutter]], [[ADR-002 Helyi adattárolás]]. A csomagok végleges kiválasztása a v0.2.0 során történik, és új ADR-be kerül.

| Terület | Tervezett megoldás |
|---|---|
| Keretrendszer | Flutter (stabil csatorna), Dart |
| Adatbázis | SQLite (pl. `drift` vagy `sqflite`) |
| Grafikon | pl. `fl_chart` |
| PDF | `pdf` + `printing` |
| Megosztás | `share_plus` |
| Fájlválasztás (visszatöltés) | `file_picker` |
| Lokalizáció | `flutter_localizations`, `en_GB` (később `intl` / ARB-fájlok, ha több nyelv lesz) `🔄 v0.2.0` |
| Automatikus fordítás | GitHub Actions → aláírt APK a GitHub Release-ben |

## 9. Nyitott kérdések

| ID | Kérdés | Javaslat | Döntés |
|---|---|---|---|
| K-01 | Mi legyen a legrégebbi támogatott Android-verzió (minSdk)? | A céleszköz verziója alapján, de legalább Android 8.0 | ✅ minSdk 26 (Android 8.0); tesztelés Android 14+ eszközön |
| K-02 | A napi 3 mérés kemény korlát legyen, vagy csak figyelmeztetés? | Kemény korlát (az eredeti igény szerint) | ✅ kemény korlát |
| K-03 | Referenciaérték a grafikonon | 135/85 Hgmm (az európai irányelv otthoni mérésre vonatkozó küszöbe) – a felhasználó a beállításokban átírhatja, pl. a kezelőorvos javaslata szerint | ✅ 135/85, alapból bekapcsolva |
| K-04 | Szerepeljen név a PDF-en? | Opcionális mező a beállításokban | ✅ opcionális mező; csak kitöltve jelenik meg |
| K-05 | Kell pulzus grafikon is? | v1.0-ban nem, ötletként felvéve | ✅ v1.0-ban nem; ötlet: Ö-002 |

## 10. Elfogadási feltételek (v1.0)

A v1.0 akkor kész, ha:
1. Minden FR-xx teljesül, és a hozzá tartozó kézi teszteset ([[05 Tesztelés]]) sikeres egy valódi Android-eszközön.
2. Nincs nyitott *kritikus* vagy *magas* súlyosságú hiba ([[06 Hibák]]).
3. Egy kipróbált teljes mentés → app törlése → újratelepítés → visszatöltés kör adatvesztés nélkül lefut.
4. A PDF-et kinyomtatva vagy telefonon megmutatva olvasható.
