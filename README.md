# Pulzar

Egyszerű, offline vérnyomásnapló Androidra – a **RelayCore-Projects** egyik projektje.

> **Aktuális kiadás:** v1.0.0 (első stabil kiadás) · [Letöltés (Releases)](https://github.com/RelayCore-Projects/pulzar/releases/latest)

## Mit tud

- **Rögzítés:** dátum, szabadon megadható időpont, szisztolé, diasztolé, pulzus (opcionális), megjegyzés (legfeljebb 200 karakter); naponta legfeljebb 3 mérés
- **Táblázat** (főképernyő): napokra bontva, hét / hónap / év / összes időszak, lapozás ‹ › gombokkal vagy húzással; átlag / minimum / maximum; érintésre a mérés részletei, hosszú nyomásra szerkesztés
- **Grafikon:** a szisztolé (piros) és a diasztolé (kék) napi átlaga pontokkal (évnél heti átlag), szaggatott referenciavonalakkal; koppintásra a nap (hét) mérései
- **PDF-jelentés az orvosnak:** szabadon választott időszakra (dátumtól–dátumig, gyorsgombok: utolsó 30 nap, 3 hónap, összes), grafikonnal és / vagy táblázattal, A4-en nyomtatható, opcionálisan névvel. Mentés után *Open*: megnyitás, nyomtatás, megosztás a telefon PDF-nézegetőjéből
- **Referenciaértékek:** alapból 135 / 85 mmHg, a beállításokban átállítható vagy kikapcsolható (szaggatott vonal a grafikonon és a PDF-ben)
- **Mentés és visszatöltés:** minden mérés egy fájlba (pl. Google Drive-ra), visszatöltés előnézettel és összefésüléssel
- Minden adat **csak a telefonon** tárolódik; az app nem kér internet-engedélyt

A projekt a v1.0.0-val **lezárult**. Későbbi lehetőségek az [Ötletek](docs/04%20Ötletek.md) között.

Az alkalmazás felülete **angol**, a projekt dokumentációja magyar.

## Telepítés és frissítés

1. Telefonon nyisd meg a [Releases](https://github.com/RelayCore-Projects/pulzar/releases/latest) oldalt, és töltsd le a `pulzar-x.y.z.apk` fájlt
2. Nyisd meg → engedélyezd a telepítést ebből a forrásból → *Telepítés*
3. Frissítés: az új APK-t a régire telepítsd – **ne töröld előtte az appot**, mert az adatok is törlődnek
4. Kényelmesebb frissítés: az [Obtainium](https://github.com/ImranR98/Obtainium) appban add hozzá a repó címét, és szól az új verziókról

Készíts rendszeresen mentést: *Settings → Backup and restore → Save backup…*

Követelmény: Android 8.0 vagy újabb, 64 bites telefon.

## Technológia

[Flutter](https://flutter.dev) (Dart), SQLite (`sqflite`), PDF: [`pdf`](https://pub.dev/packages/pdf). Natív plugin nélkül: a fájlkezelés az Android saját fájlválasztójával, a grafikon saját rajzolással készül. A döntések indoklása: [`docs/Döntések`](docs/Döntések).

## Repó felépítése

```
pulzar/
├── lib/         Az alkalmazás forráskódja (Dart): models, domain, data, state, screens, widgets
├── test/        Automatikus tesztek
├── android/     Android-specifikus fájlok
├── .github/     CI: tesztek, APK-fordítás, kiadás
├── assets/      Arculat (ikon forrásképe), a PDF betűtípusa (DejaVu Sans Condensed)
├── tool/        Segédszkriptek (ikongenerálás, CI-tesztannotációk)
├── docs/        Obsidian vault – specifikáció, döntések, ötletek, tesztelés, changelog
├── pubspec.yaml Függőségek és verziószám
├── README.md
└── LICENSE
```


## Fejlesztés

Minden változás külön ágon készült; a CI ([GitHub Actions](.github/workflows/ci.yml)) minden feltöltésnél lefuttatja a teszteket, aláírt APK-t fordít és frissíti a Preview kiadást. Kiadás: Pull Request a `main`-be, majd `vX.Y.Z` címke → automatikus GitHub Release. Részletek: [Fejlesztési folyamat](docs/03%20Fejlesztési%20folyamat.md).

## Dokumentáció

A `docs/` mappa egy [Obsidian](https://obsidian.md) vault: Obsidianban *Open folder as vault* → `docs`.
A kiindulópont a `00 Kezdőlap.md`.

## Fontos

A Pulzar **nem orvostechnikai eszköz**. Személyes naplózásra készült; nem ad diagnózist vagy kezelési javaslatot.
A mért értékek értelmezése és a kezelés az orvos feladata.

## Licenc

[MIT](LICENSE) © 2026 RelayCore-Projects
