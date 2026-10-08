# Pulzar

Egyszerű, offline vérnyomásnapló Androidra – a **RelayCore-Projects** egyik projektje.

> **Állapot:** koncepció (v0.1.0) – még nincs telepíthető app.

## Mit tud majd

- Kézi bevitel: dátum, időpont, szisztolé, diasztolé, pulzus, megjegyzés – naponta legfeljebb 3 mérés
- Táblázatos nézet választható időszakra, átlaggal, minimummal, maximummal – orvosnak megmutatható formában
- Külön grafikon a szisztolé és a diasztolé értékekről
- Export: PDF (táblázat és/vagy grafikon), CSV (Excelhez), teljes mentés és visszatöltés
- Minden adat csak a telefonon tárolódik, internetkapcsolat nélkül

Részletesen: [docs/01 Specifikáció.md](docs/01%20Specifikáció.md) · Ütemterv: [docs/02 Ütemterv.md](docs/02%20Ütemterv.md) · Változások: [docs/CHANGELOG.md](docs/CHANGELOG.md)

Az alkalmazás felülete **angol**, a projekt dokumentációja magyar.

## Technológia

[Flutter](https://flutter.dev) (Dart) – egy kódbázis Androidra, később Windows asztali alkalmazásra is.

## Repó felépítése

```
pulzar/
├── docs/        Obsidian vault – specifikáció, döntések, ötletek, tesztelés, changelog
├── README.md
└── LICENSE
```

A Flutter-projekt a v0.2.0 verzióban kerül a repó gyökerébe.

## Dokumentáció

A `docs/` mappa egy [Obsidian](https://obsidian.md) vault: Obsidianban *Open folder as vault* → `docs`.
A kiindulópont a `00 Kezdőlap.md`.

## Fontos

A Pulzar **nem orvostechnikai eszköz**. Személyes naplózásra készült; nem ad diagnózist vagy kezelési javaslatot.
A mért értékek értelmezése és a kezelés az orvos feladata.

## Licenc

[MIT](LICENSE) © 2026 RelayCore-Projects
