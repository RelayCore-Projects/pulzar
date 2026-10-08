---
tipus: kezdolap
projekt: Pulzar
aktualis_verzio: 0.1.1
fazis: Koncepció
frissitve: 2026-10-08
---

# Pulzar – projekt kezdőlap

Egyszerű, offline vérnyomásnapló Androidra. **RelayCore-Projects** · repó: [RelayCore-Projects/pulzar](https://github.com/RelayCore-Projects/pulzar)

## Hol tartunk

| | |
|---|---|
| Aktuális verzió | **0.1.1 – Koncepció lezárva** |
| Fázis | Koncepció → *Fejlesztés* → Tesztelés → Hibajavítás → Kiadás |
| Következő lépés | v0.2.0 – Flutter projektváz + automatikus APK-fordítás |

## Dokumentumok

1. [[01 Specifikáció]] – mit tud az app, képernyők, adatmodell, követelmények
2. [[02 Ütemterv]] – verziók és mérföldkövek
3. [[03 Fejlesztési folyamat]] – verziózás, ágak, commitok, kiadás, a változások dokumentálása
4. [[04 Ötletek]] – ide írd, ami eszedbe jut
5. [[05 Tesztelés]] – tesztstratégia és kézi tesztlista
6. [[06 Hibák]] – hogyan jelentsünk és kövessünk hibát
7. [[CHANGELOG]] – verziónként mi változott
8. **Döntésnapló** (miért döntöttünk így):
   - [[ADR-001 Flutter]]
   - [[ADR-002 Helyi adattárolás]]
   - [[ADR-003 Nyilvános repó és MIT licenc]]
   - [[ADR-004 Repó- és vault-szerkezet]]

## Privát jegyzetek

A `_privat` mappa csak ezen a gépen létezik, **nem kerül fel a GitHubra**. Ide kerül minden személyes adat. Szabályok: [[03 Fejlesztési folyamat#Mi kerülhet a nyilvános repóba]].

## Sablonok

A `Sablonok` mappában: új ötlet, új döntés (ADR), hibajegyzet.
Beszúrás: parancspaletta (`Ctrl+P`) → *Templates: Insert template*.

## Szabály röviden

> Minden változás nyomot hagy: **ötlet** → [[04 Ötletek]], **döntés** → új ADR, **követelmény-módosítás** → [[01 Specifikáció]] változástörténete, **kiadott változás** → [[CHANGELOG]].
> Részletek: [[03 Fejlesztési folyamat#A változások dokumentálása]].
