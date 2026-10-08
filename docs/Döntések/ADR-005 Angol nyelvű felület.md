---
tipus: adr
azonosito: ADR-005
statusz: elfogadva
datum: 2026-10-08
---

# ADR-005 – Angol nyelvű felület

## Kontextus
A koncepció (0.1.x) magyar felületet írt elő (NFR-03). A v0.2.0 fejlesztése közben új igény merült fel: **a projekt és a dokumentáció maradjon magyar, de az alkalmazás felülete legyen angol.**

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| **Angol felület, szövegek egy helyen** | Megfelel az igénynek; később más nyelv is hozzáadható | A PDF / CSV is angol lesz |
| Teljes többnyelvűség most (angol + magyar, ARB-fájlok) | Mindkét nyelv azonnal | Több munka és tesztelés olyasmire, amire most nincs igény |
| Magyar felület (eredeti terv) | – | Nem felel meg az új igénynek |

## Döntés
- A felület **angol**, területi beállítás: **`en_GB`** – így a dátum NN/HH/ÉÉÉÉ, az idő 24 órás, a hét hétfővel kezdődik (európai szokás).
- Exportban (CSV, fájlnevek) **ISO 8601** dátum (`2026-10-08`).
- A PDF és a CSV feliratai is angolok (az app nyelvét követik).
- Magyar nyelv: ötletként felvéve ([[04 Ötletek]], Ö-009).

## Következmények
- [[01 Specifikáció]]: NFR-03 helyett NFR-03a; több FR felirata módosult (`🔄 v0.2.0` jelölés).
- [[04 Ötletek]]: Ö-006 (angol felület) okafogyottá vált → Ö-009 (magyar felület).
