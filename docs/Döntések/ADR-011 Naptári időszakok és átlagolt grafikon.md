---
tipus: adr
azonosito: ADR-011
statusz: elfogadva
datum: 2026-10-08
---

# ADR-011 – Naptári időszakok és átlagolt grafikon

## Kontextus
A 0.4.0-dev kézi tesztje után két igény merült fel:
1. A gördülő „utolsó 7 nap” helyett **teljes hetek** (hétfő–vasárnap), hónapok, évek kellenek, és ezek között **lapozni** lehessen – a grafikonon húzással.
2. Napi 3 mérésnél a grafikonon a pontok hármas csoportokban zsúfolódnak, köztük nagy hézaggal; heti nézetben **7 pont** legyen, akárhány mérés volt naponta.

## Lehetőségek (2. pont)
| | Előny | Hátrány |
|---|---|---|
| **Napi átlag + napi min–max vonal** | Napi 1–3 mérésnél is egységes; a szórás is látszik; az otthoni vérnyomás értékelése is átlagokkal dolgozik | Az egyes mérések nem látszanak a grafikonon (csak a táblázatban) |
| Három grafikon (reggel / dél / este) | Napszakonként külön trend | Az időpont szabadon megadható, nincs fix napszak; 1–2 mérésnél nem egyértelmű, hová kerül |
| Minden mérés, a nap közepére igazítva | Minden érték látszik | Továbbra is zsúfolt |

## Döntés
- **Időszakok:** Week (hétfő–vasárnap) · Month · Year · All; ‹ › gombok és húzás (jobbra: előző, balra: következő). A jövőbe és a legkorábbi mérés elé nem lehet lapozni. A Table és a Charts ugyanazt az időszakot mutatja. Alapértelmezés: az aktuális hét.
- **Grafikon:** egy pont = egy időegység **átlaga**, halvány függőleges vonal a legkisebb–legnagyobb értékkel:

| Időszak | Egy pont |
|---|---|
| Week, Month | nap |
| Year | hét |
| All | hónap |

- A táblázat és az összesítő **változatlanul az egyes méréseket** mutatja.

## Következmények
- Az „aktuális idő” cserélhető lett (`AppServices.clock`), így a naptári határok rögzített dátummal tesztelhetők.
- A PDF-export grafikonja (v0.5.0) ugyanezt a logikát használja.
- Ötlet marad: koppintásra a pont részletei (Ö-013).
