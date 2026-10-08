---
tipus: adr
azonosito: ADR-008
statusz: elfogadva
datum: 2026-10-08
---

# ADR-008 – Alkalmazásikon

## Kontextus
A v0.2.0-ban a Flutter alapértelmezett ikonja szerepelt ([[04 Ötletek]], Ö-010). Három változat készült (2026-10-08):

| | Leírás |
|---|---|
| A | Bordó háttér, fehér szív körvonal EKG-vonallal |
| B | Bordó háttér, csak fehér EKG-vonal |
| **C** | **Sötét háttér, piros szív, fehér EKG-vonal** |

## Döntés
A **„C” változat**.

| Elem | Érték |
|---|---|
| Háttér | `#201A1E` |
| Szív | `#D63042` |
| EKG-vonal | fehér |

Megvalósítás:
- **Adaptív ikon** (Android 8+): külön háttér és előtér, így minden telefon a saját formájára vághatja (kör, lekerekített négyzet stb.)
- **Témázott ikon** (Android 13+): egyszínű változat – fehér szív, kivágott EKG-vonallal; a rendszer a háttérkép színeire színezi
- **Régi stílusú** kerek ikon tartaléknak
- Minden méret egy szkriptből készül: `tool/generate_icons.py` (Pillow). A forráskép: `assets/branding/pulzar-icon-1024.png`

## Következmények
- Színváltozásnál elég a szkript elején a színeket átírni és újrafuttatni.
- Az app belsejében (pl. About) egyelőre Material ikon szerepel; ha kell, a forráskép ott is használható.
