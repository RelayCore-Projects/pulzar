# Pulzar

Egyszerű, offline vérnyomásnapló Androidra – a **RelayCore-Projects** egyik projektje.

> **Legutóbbi kiadás:** v0.4.0 · [Letöltés (Releases)](https://github.com/RelayCore-Projects/pulzar/releases/latest) · fejlesztői előnézet: [Preview](https://github.com/RelayCore-Projects/pulzar/releases/tag/preview)

## Mit tud

- **Rögzítés**: dátum, szabadon megadható időpont, szisztolé, diasztolé, pulzus (opcionális), megjegyzés – naponta legfeljebb 3 mérés
- **Táblázat** (főképernyő): napokra bontva, hét / hónap / év / összes időszak lapozással, átlag / minimum / maximum, a referenciaértéket (135/85) elérő értékek kiemelve; érintésre részletek, hosszú nyomásra szerkesztés
- **Grafikon**: a szisztolé (piros) és a diasztolé (kék) napi átlaga pontokkal (évnél heti átlag), referenciavonalakkal; koppintásra a nap mérései
- **Mentés és visszatöltés**: minden mérés egy fájlba (pl. Google Drive-ra), visszatöltés összefésüléssel
- Minden adat csak a telefonon tárolódik, internetkapcsolat nélkül

**Tervben (v0.5.0):** PDF és CSV export, beállítások (név a PDF-en, referenciaértékek), lefúrás a grafikonon. Részletek: [Ütemterv](docs/02%20Ütemterv.md)

Az alkalmazás felülete **angol**, a projekt dokumentációja magyar.

## Telepítés és frissítés

1. Telefonon nyisd meg a [Releases](https://github.com/RelayCore-Projects/pulzar/releases/latest) oldalt, és töltsd le a `pulzar-x.y.z.apk` fájlt
2. Nyisd meg → engedélyezd a telepítést ebből a forrásból → *Telepítés*
3. Frissítés: az új APK-t a régire telepítsd – **ne töröld előtte az appot**, mert az adatok is törlődnek
4. Kényelmesebb frissítés: az [Obtainium](https://github.com/ImranR98/Obtainium) appban add hozzá a repó címét, és szól az új verziókról

Készíts rendszeresen mentést: *Settings → Backup and restore → Save backup…*

Követelmény: Android 8.0 vagy újabb, 64 bites telefon.

## Technológia

[Flutter](https://flutter.dev) (Dart) – egy kódbázis Androidra, később Windows asztali alkalmazásra is.

## Repó felépítése

```
pulzar/
├── lib/         Az alkalmazás forráskódja (Dart): models, domain, data, state, screens, widgets
├── test/        Automatikus tesztek
├── android/     Android-specifikus fájlok
├── .github/     CI: tesztek, APK-fordítás, kiadás
├── assets/      Arculat (ikon forrásképe)
├── tool/        Segédszkriptek (pl. ikongenerálás)
├── docs/        Obsidian vault – specifikáció, döntések, ötletek, tesztelés, changelog
├── pubspec.yaml Függőségek és verziószám
├── README.md
└── LICENSE
```


## Fejlesztés

Minden változás külön ágon készül; a CI ([GitHub Actions](.github/workflows/ci.yml)) minden feltöltésnél lefuttatja a teszteket, aláírt APK-t fordít és frissíti a Preview kiadást. Kiadás: Pull Request a `main`-be, majd `vX.Y.Z` címke → automatikus GitHub Release. Részletek: [Fejlesztési folyamat](docs/03%20Fejlesztési%20folyamat.md).

## Dokumentáció

A `docs/` mappa egy [Obsidian](https://obsidian.md) vault: Obsidianban *Open folder as vault* → `docs`.
A kiindulópont a `00 Kezdőlap.md`.

## Fontos

A Pulzar **nem orvostechnikai eszköz**. Személyes naplózásra készült; nem ad diagnózist vagy kezelési javaslatot.
A mért értékek értelmezése és a kezelés az orvos feladata.

## Licenc

[MIT](LICENSE) © 2026 RelayCore-Projects
