---
tipus: folyamat
frissitve: 2026-10-08
---

# Fejlesztési folyamat

## A szoftverfejlesztés lépései ebben a projektben

```
 Ötlet ──► Koncepció ──► Fejlesztés ──► Tesztelés ──► Hibajavítás ──► Kiadás
  (04)       (01, ADR)     (git ág)       (05)           (06)          (tag, APK)
   ▲                                                                     │
   └─────────────────────── visszajelzés, új ötletek ◄───────────────────┘
```

1. **Ötlet** – bármi, ami eszedbe jut → [[04 Ötletek]]
2. **Koncepció** – ha egy ötletet megvalósítunk: a [[01 Specifikáció]] módosul (új / módosított FR), és ha választani kell több megoldás közül, új döntés (ADR) a `Döntések` mappában
3. **Fejlesztés** – külön git ágon, kis lépésekben
4. **Tesztelés** – automatikus tesztek + kézi tesztlista a telefonon → [[05 Tesztelés]]
5. **Hibajavítás** – hibajegy a GitHubon → javítás → újratesztelés → [[06 Hibák]]
6. **Kiadás** – verziócímke, automatikusan fordított APK, [[CHANGELOG]] frissítése

## Verziószámozás

[Szemantikus verziózás](https://semver.org): `FŐ.AL.JAVÍTÁS`, pl. `1.2.3`

| Rész | Mikor nő | Példa |
|---|---|---|
| FŐ | Nem visszafelé kompatibilis változás (pl. új mentésfájl-formátum, amit a régi app nem tud olvasni) | 1.4.2 → **2.0.0** |
| AL | Új funkció, visszafelé kompatibilis | 1.4.2 → 1.**5**.0 |
| JAVÍTÁS | Csak hibajavítás | 1.4.2 → 1.4.**3** |

A `0.x` verziók fejlesztési állapotot jelölnek; az `1.0.0` az első stabil kiadás.

## Git ágak

| Ág | Mire |
|---|---|
| `main` | Mindig működő, kiadható állapot. Közvetlenül nem fejlesztünk rajta. |
| `feature/<rövid-név>` | Új funkció, pl. `feature/grafikon` |
| `fix/<rövid-név>` vagy `fix/<issue-szám>` | Hibajavítás, pl. `fix/12-csv-ekezet` |
| `docs/<rövid-név>` | Csak dokumentáció |

Menet: ág létrehozása → commitok → **Pull Request** a GitHubon → átnézés → beolvasztás a `main`-be → az ág törlése.
GitHub Desktopban: *Current branch → New branch*, majd a végén *Create Pull Request*.

## Commit-üzenetek

Rövid, egyértelmű, előtaggal:

| Előtag | Jelentés | Példa |
|---|---|---|
| `feat:` | új funkció | `feat: diasztolé grafikon` |
| `fix:` | hibajavítás | `fix: CSV ékezetek Excelben (#12)` |
| `docs:` | dokumentáció | `docs: K-02 döntés rögzítése` |
| `test:` | tesztek | `test: validáció határértékei` |
| `refactor:` | átszervezés funkcióváltozás nélkül | `refactor: adatbázis réteg szétválasztása` |
| `chore:` | karbantartás, beállítások | `chore: függőségek frissítése` |

A `(#12)` a GitHub-hibajegy számára hivatkozik; a GitHub automatikusan összeköti őket.

## Kiadás

1. A `main` naprakész, a tesztek zöldek
2. [[CHANGELOG]]: az „Unreleased” rész átnevezése a verziószámra + dátum
3. Verziószám emelése a `pubspec.yaml`-ban (0.2.0-tól)
4. Címke (tag) létrehozása: `v0.3.0` → a GitHub Actions automatikusan lefordítja és aláírja az APK-t, és csatolja a GitHub Release-hez
5. [[02 Ütemterv]]: állapot 🟢, mérföldkő-napló bejegyzés
6. APK letöltése a telefonra, telepítés, kézi teszt

## A változások dokumentálása

Az alapelv: **semmi ne vesszen el, és mindig kiderüljön, mi, mikor és miért változott.**

| Mi történt | Hová írjuk | Hogyan |
|---|---|---|
| Eszedbe jutott valami | [[04 Ötletek]] | Új sor a táblázatban, állapot: 💭 – vagy sablon: `Sablonok/Ötlet` |
| Egy ötletet megvalósítunk | [[04 Ötletek]] + [[01 Specifikáció]] | Az ötlet állapota → ⚪ tervezett, melyik verzióban; a specifikációba új FR `🆕 v0.x.0` jelöléssel |
| Meglévő funkció módosul | [[01 Specifikáció]] | A követelmény mellett `🔄 v0.x.0`, és új sor a változástörténetben (mi + miért) |
| Funkció kikerül | [[01 Specifikáció]] | Áthúzás, `❌ v0.x.0`, indok a változástörténetben |
| Választani kell több megoldás közül | `Döntések/ADR-xxx` | Sablon: `Sablonok/Döntés (ADR)`; a régi döntést nem töröljük, hanem „felülírva: ADR-yyy” jelölést kap |
| Hiba | GitHub Issue (+ opcionálisan [[06 Hibák]]) | Sablon: `Sablonok/Hiba` |
| Kiadott verzió | [[CHANGELOG]] | Hozzáadva / Módosítva / Javítva / Eltávolítva |

Minden dokumentum tetején a `frissitve` mező mutatja az utolsó módosítás dátumát; a sor szintű különbséget a git őrzi (GitHub → fájl → *History*).

## Mi kerülhet a nyilvános repóba

A repó nyilvános, ezért a `docs/` mappába csak **semleges, bárkire érvényes** tartalom kerül.

| Nem kerülhet fel | Hová kerül helyette |
|---|---|
| Nevek, elérhetőségek, saját eszköz adatai, helyi elérési utak | `docs/_privat/` (nem verziózott) |
| Egészségügyi vonatkozású személyes megjegyzések, orvosi javaslatok | `docs/_privat/` |
| Valódi mérési adatok, exportok, mentések | sehova a repóban (a `.gitignore` kizárja) |
| Aláíró kulcsok, jelszavak, tokenek | GitHub Secrets, illetve biztonságos helyi mentés |

Commit előtt GitHub Desktopban mindig nézd át a *Changes* listát: ha olyan fájl szerepel benne, ami nem oda való, ne commitold.
