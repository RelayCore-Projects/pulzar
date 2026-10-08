---
tipus: adr
azonosito: ADR-006
statusz: elfogadva
datum: 2026-10-08
---

# ADR-006 – Fordítás, aláírás és kiadás a GitHub Actionsben

## Kontextus
- A fejlesztői gépeken nincs Flutter SDK / Android SDK, és nem is kötelező (ADR-001).
- Minden változást valódi telefonon kell tudni kipróbálni, lehetőleg már a `main`-be olvasztás előtt.
- Az Android csak akkor telepít frissítést a meglévő appra, ha **ugyanazzal a kulccsal** van aláírva.

## Döntés
**Projektváz:** a `flutter create` egyszeri futtatása a GitHub gépén (bootstrap workflow, Flutter 3.47.6), utána kézi testreszabás.

**CI (`.github/workflows/ci.yml`)** minden pushnál:
1. `flutter analyze` + `flutter test` – ha bármelyik hibás, nincs APK
2. Aláírt release APK
3. Ágra pusholva → **„Preview” előzetes kiadás** a GitHub Releases oldalon (mindig csak a legutóbbi), verzió: `0.2.0-dev.<buildszám>`
4. `v*` címkére → **végleges GitHub Release** az APK-val, a kiadási jegyzet a [[CHANGELOG]] megfelelő szakasza. A címkének egyeznie kell a `pubspec.yaml` verziójával, különben a fordítás leáll.

**Verziószám az APK-ban:** versionName = a címke (vagy `x.y.z-dev.N`), versionCode = a commitok száma (mindig nő, így a frissítés mindig települ).

**Aláírás:** egyetlen release kulcs (PKCS12, RSA 4096, alias `pulzar`), GitHub Secretsben:

| Secret | Tartalom |
|---|---|
| `PULZAR_KEYSTORE_BASE64` | a kulcsfájl base64-kódolva |
| `PULZAR_KEYSTORE_PASSWORD` | a kulcstár jelszava |
| `PULZAR_KEY_ALIAS` | `pulzar` |

A kulcsfájl csak a fordítás idejére jön létre a GitHub gépén, utána törlődik. A kulcsról a repón kívül biztonsági másolat készül.

**Rögzített Android-beállítások:** `applicationId = hu.relaycore.pulzar` (soha nem változik), `minSdk = 26`, internet-engedély nincs (NFR-01).

## Következmények
- A Preview és a végleges kiadás ugyanazzal a kulccsal készül → a telefonon egymásra frissíthetők, adatvesztés nélkül.
- Nyilvános repóban az Actions ingyenes; a titkok fork-ból érkező PR-eknél nem érhetők el (ott csak a tesztek futnak).
- A Flutter verzió a `ci.yml`-ben rögzített (`FLUTTER_VERSION`); frissítése tudatos lépés, külön commitban.
