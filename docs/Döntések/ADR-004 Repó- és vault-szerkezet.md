---
tipus: adr
azonosito: ADR-004
statusz: elfogadva
datum: 2026-10-08
---

# ADR-004 – Repó- és vault-szerkezet

## Kontextus
A dokumentációt Obsidianban szeretnénk vezetni, és verziózni a kóddal együtt.

## Döntés
- Az Obsidian vault a repó **`docs/`** mappája
- A Flutter-projekt a repó gyökerébe kerül (0.2.0-tól)
- Commit és feltöltés: GitHub Desktop
- Személyes jegyzetek a `docs/_privat/` mappába kerülnek, ami **nem** kerül fel a gitre
- A `.obsidian` beállítások verziózottak, a személyes állapotfájlok (`workspace.json`) nem

## Következmények
- A dokumentáció és a kód változásai ugyanabban a commitban követhetők.
- Az Obsidian a kódfájlokat nem látja, csak a `docs/` tartalmát.
- A CHANGELOG a `docs/` mappában van, hogy Obsidianban is látható legyen; a README erre hivatkozik.
