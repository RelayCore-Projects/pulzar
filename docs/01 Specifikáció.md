---
tipus: specifikacio
dokumentum_verzio: 0.1.0
statusz: jóváhagyásra vár
frissitve: 2026-10-08
---

# Pulzar – Specifikáció

## Változástörténet

| Verzió | Dátum | Változás | Indok / forrás |
|---|---|---|---|
| 0.1.0 | 2026-10-08 | Első változat (koncepció) | Kiinduló igények, lásd [[#1. Cél]] |

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

| Fogalom | Jelentés |
|---|---|
| Szisztolé (SYS) | Felső érték, Hgmm |
| Diasztolé (DIA) | Alsó érték, Hgmm |
| Pulzus (PUL) | Szívverés / perc |
| Hgmm | Higanymilliméter, a vérnyomás mértékegysége |
| Mérés | Egy időponthoz tartozó SYS + DIA + PUL (+ megjegyzés) |
| Időszak | A megjelenítéshez / exporthoz választott dátumtartomány |

---

## 4. Funkcionális követelmények

### 4.1 Bevitel

**FR-01 – Mérés rögzítése**
A felhasználó új mérést vehet fel a következő mezőkkel:

| Mező | Kötelező | Alapérték | Formátum |
|---|---|---|---|
| Dátum | igen | mai nap | ÉÉÉÉ.HH.NN. |
| Időpont | igen | aktuális idő | ÓÓ:PP (24 órás), **szabadon megadható** |
| Szisztolé | igen | – | egész szám, Hgmm |
| Diasztolé | igen | – | egész szám, Hgmm |
| Pulzus | igen | – | egész szám, /perc |
| Megjegyzés | nem | üres | szöveg, max. 200 karakter (pl. „gyógyszer után”, „bal kar”) |

A számmezőknél numerikus billentyűzet jelenik meg, és a mentés egy érintéssel elérhető.

**FR-02 – Ellenőrzés (validáció)**
Mentés csak érvényes adattal lehetséges; hiba esetén a mező alatt magyar nyelvű üzenet jelenik meg.

| Szabály | Érték |
|---|---|
| Szisztolé tartomány | 50 – 300 Hgmm |
| Diasztolé tartomány | 30 – 200 Hgmm |
| Pulzus tartomány | 30 – 250 /perc |
| Logikai szabály | szisztolé > diasztolé |
| Időpont | nem lehet a jövőben |

> A tartományok csak az elgépelés kiszűrésére szolgálnak, nem orvosi határértékek.

**FR-03 – Napi korlát**
Egy naptári napra legfeljebb **3 mérés** rögzíthető. A negyedik mentési kísérletnél az app jelzi, hogy aznapra elérte a korlátot, és felajánlja egy meglévő mérés szerkesztését. *(Nyitott kérdés: [[#9. Nyitott kérdések|K-02]])*

**FR-04 – Szerkesztés és törlés**
Bármely mérés minden mezője utólag szerkeszthető. A törlés megerősítést kér („Biztosan törlöd a 2026.10.08. 07:30 mérést?”).

### 4.2 Megjelenítés

**FR-05 – Napló (főképernyő)**
A mérések napokra csoportosítva, a legfrissebb nap felül. Naponként a mérések időrendben: `07:30   128 / 82   72`. Érintéssel megnyílik a szerkesztés.

**FR-06 – Táblázatos nézet (orvosnak)**
- Időszak-választó: *utolsó 7 nap*, *30 nap*, *90 nap*, *egyéni (dátumtól–dátumig)*
- Oszlopok: Dátum · Idő · Szisztolé · Diasztolé · Pulzus · Megjegyzés
- Nagy, jól olvasható betűméret; fekvő tájolásban is használható
- A referenciaérték feletti értékek kiemelve (félkövér), lásd FR-10

**FR-07 – Összesítés**
A táblázat fölött a kiválasztott időszakra: mérések száma, és SYS / DIA / PUL **átlaga, minimuma, maximuma**.

**FR-08 – Szisztolé grafikon**
Vonal + pont diagram; vízszintes tengely: idő (a mérés valódi időpontja), függőleges tengely: Hgmm. Ugyanaz az időszak-választó, mint FR-06-ban.

**FR-09 – Diasztolé grafikon**
Mint FR-08, külön diagramon. A két grafikon egymás alatt, azonos időtengellyel.

**FR-10 – Referenciavonal**
Mindkét grafikonon szaggatott vízszintes vonal a beállított referenciaértéknél. Alapérték: **SYS 135, DIA 85 Hgmm** *(nyitott kérdés: [[#9. Nyitott kérdések|K-03]])*. Beállításokban módosítható vagy kikapcsolható.

### 4.3 Export

**FR-11 – PDF export**
- Időszak: mint FR-06
- Tartalom választható: **táblázat**, **grafikon**, vagy **mindkettő**
- Fejléc: „Vérnyomásnapló”, név (ha be van állítva, [[#9. Nyitott kérdések|K-04]]), időszak, készítés dátuma
- Összesítő blokk (FR-07)
- Táblázat: minden mérés dátummal és időponttal
- Grafikon: SYS és DIA külön diagramon, referenciavonallal
- Lábléc: oldalszám, „Pulzar vX.Y.Z – nem orvostechnikai eszköz”
- Papírméret: A4, álló

**FR-12 – CSV export**
- Időszak: mint FR-06
- Kódolás: UTF-8 BOM-mal, elválasztó: pontosvessző (`;`) – így a magyar Excel helyesen nyitja meg
- Fejléc: `Dátum;Idő;Szisztolé (Hgmm);Diasztolé (Hgmm);Pulzus (/perc);Megjegyzés`
- Dátum: `2026.10.08`, idő: `07:30`

**FR-13 – Teljes mentés és visszatöltés**
- Mentés: az összes adat egyetlen JSON-fájlba (`pulzar-mentes-2026-10-08.json`)
- Visszatöltés: a fájl kiválasztása után az app megmutatja, hány mérést talált, és hány új; jóváhagyás után **összefésül** (azonos azonosítójú mérésből a később módosított marad, duplikáció nincs)
- Ez szolgál telefoncserére, adatvesztés elleni védelemre, és a v2 asztali alkalmazás első adatátviteli módjára is

**FR-14 – Megosztás**
Minden export után: *Megosztás* (Android megosztási menü: e-mail, Viber, Drive stb.) vagy *Mentés a Letöltések mappába*.

### 4.4 Egyéb

**FR-15 – Beállítások**
Név a PDF-en (opcionális) · referenciaértékek (SYS, DIA, be/ki) · mentés / visszatöltés · téma (rendszer / világos / sötét).

**FR-16 – Névjegy**
Verziószám, licenc (MIT), link a repóra, és a figyelmeztetés: *„A Pulzar nem orvostechnikai eszköz, nem ad diagnózist. Az értékek értelmezése az orvos feladata.”*

---

## 5. Nem funkcionális követelmények

| ID | Követelmény |
|---|---|
| NFR-01 | **Offline működés.** A kiadott app nem kér internet-engedélyt; adat nem hagyja el a telefont, csak ha a felhasználó exportálja. |
| NFR-02 | **Helyi tárolás** SQLite adatbázisban ([[ADR-002 Helyi adattárolás]]). |
| NFR-03 | **Magyar felület**, magyar dátum- és időformátum (ÉÉÉÉ.HH.NN., 24 órás). |
| NFR-04 | **Teljesítmény:** 10 évnyi adat (~11 000 mérés) mellett is gördülékeny lista, táblázat és grafikon; PDF 1 évre < 5 mp. |
| NFR-05 | **Olvashatóság:** követi a rendszer betűméretét; világos és sötét téma. |
| NFR-06 | **Adatbiztonság:** törlés csak megerősítéssel; adatbázis-séma változásnál automatikus, adatvesztés nélküli migráció. |
| NFR-07 | **Szinkronra felkészített adatmodell** (egyedi azonosító, időbélyegek, logikai törlés) – a v2 asztali összekötéshez. |
| NFR-08 | **Támogatott Android-verzió:** nyitott, [[#9. Nyitott kérdések\|K-01]]. |

## 6. Adatmodell

**Measurement (mérés)**

| Mező | Típus | Leírás |
|---|---|---|
| `id` | UUID (szöveg) | Egyedi azonosító – eszközök között is egyedi |
| `measured_at` | dátum-idő (helyi idő) | A mérés időpontja |
| `systolic` | egész | Hgmm |
| `diastolic` | egész | Hgmm |
| `pulse` | egész | /perc |
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
┌─ Napló ───────────────────┐   ┌─ Új mérés ───────────────┐
│ Pulzar               ⚙    │   │ ← Új mérés        Mentés │
│                           │   │                          │
│ 2026.10.08. csütörtök     │   │ Dátum   [2026.10.08. ▾]  │
│  07:30   128 / 82   72    │   │ Idő     [07:30 ▾]        │
│  13:10   131 / 85   75    │   │                          │
│                           │   │ Szisztolé   [ 128 ] Hgmm │
│ 2026.10.07. szerda        │   │ Diasztolé   [  82 ] Hgmm │
│  07:20   125 / 80   70    │   │ Pulzus      [  72 ] /perc│
│  19:45   133 / 84   78    │   │                          │
│                     (＋)  │   │ Megjegyzés [           ] │
├───────────────────────────┤   └──────────────────────────┘
│ Napló │ Táblázat │ Grafikon│
└───────────────────────────┘

┌─ Táblázat ────────────────┐   ┌─ Grafikon ───────────────┐
│ [7 nap][30 nap][90][Egyéni]│   │ [7 nap][30 nap][90][Egyéni]│
│ 32 mérés                  │   │ Szisztolé (Hgmm)         │
│      átlag  min  max      │   │ 140┤      •              │
│ SYS   129   118  141      │   │ 135┤- - - - - - - - - -  │
│ DIA    83    76   90      │   │ 130┤ •─•   •─•  •        │
│ PUL    73    64   88      │   │ 120┤      ─         ─•   │
│───────────────────────────│   │ Diasztolé (Hgmm)         │
│ Dátum      Idő  SYS DIA PUL│   │  90┤   •                 │
│ 10.08.   07:30  128  82  72│   │  85┤- - - - - - - - - -  │
│ 10.08.   13:10  131  85  75│   │  80┤ •─•  ─•─•  •─•      │
│               [Export ▾]  │   │               [Export ▾] │
└───────────────────────────┘   └──────────────────────────┘
```

Navigáció: alsó sáv – **Napló**, **Táblázat**, **Grafikon**; jobb fent **Beállítások**. Az *Export* gomb a táblázat és a grafikon nézetből is elérhető (PDF / CSV).

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
| Lokalizáció | `intl`, magyar |
| Automatikus fordítás | GitHub Actions → aláírt APK a GitHub Release-ben |

## 9. Nyitott kérdések

| ID | Kérdés | Javaslat | Döntés |
|---|---|---|---|
| K-01 | Mi legyen a legrégebbi támogatott Android-verzió (minSdk)? | A céleszköz verziója alapján, de legalább Android 8.0 | *nyitott* |
| K-02 | A napi 3 mérés kemény korlát legyen, vagy csak figyelmeztetés? | Kemény korlát (az eredeti igény szerint) | *nyitott* |
| K-03 | Referenciaérték a grafikonon | 135/85 Hgmm (az európai irányelv otthoni mérésre vonatkozó küszöbe) – a felhasználó a beállításokban átírhatja, pl. a kezelőorvos javaslata szerint | *nyitott* |
| K-04 | Szerepeljen név a PDF-en? | Opcionális mező a beállításokban | *nyitott* |
| K-05 | Kell pulzus grafikon is? | v1.0-ban nem, ötletként felvéve | *nyitott* |

## 10. Elfogadási feltételek (v1.0)

A v1.0 akkor kész, ha:
1. Minden FR-xx teljesül, és a hozzá tartozó kézi teszteset ([[05 Tesztelés]]) sikeres egy valódi Android-eszközön.
2. Nincs nyitott *kritikus* vagy *magas* súlyosságú hiba ([[06 Hibák]]).
3. Egy kipróbált teljes mentés → app törlése → újratelepítés → visszatöltés kör adatvesztés nélkül lefut.
4. A PDF-et kinyomtatva vagy telefonon megmutatva olvasható.
