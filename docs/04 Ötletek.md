---
tipus: otletek
frissitve: 2026-10-15
---

# Ötletek

Ide kerül minden, ami eszedbe jut – akkor is, ha nem biztos, hogy megvalósul. Semmit nem törlünk, csak az állapotát változtatjuk.

**Állapotok:** 💭 ötlet · 🔍 vizsgálandó · ⚪ tervezett (melyik verzióban) · 🟢 megvalósítva · ⛔ elvetve (indokkal)

Hosszabb ötlethez külön jegyzet: `Ctrl+P` → *Templates: Insert template* → **Ötlet**, és ide linkeld.

| ID | Dátum | Ötlet | Állapot | Verzió / megjegyzés |
|---|---|---|---|---|
| Ö-001 | 2026-10-08 | Windows asztali alkalmazás, összekötve a telefonos appal | 💭 | v2.x; első lépés a mentésfájl (FR-13) |
| Ö-002 | 2026-10-08 | Pulzus grafikon | 💭 | K-05 döntés: a v1.0-ba nem kerül (2026-10-08) |
| Ö-003 | 2026-10-08 | Emlékeztető értesítés a mérésre (pl. reggel, este) | 💭 | |
| Ö-004 | 2026-10-08 | Mérés körülményei: kar (bal/jobb), testhelyzet, gyógyszer bevétele előtt/után | 💭 | most a megjegyzés mezőben írható |
| Ö-005 | 2026-10-08 | Emlékeztető a rendszeres mentésre (pl. havonta) | 💭 | |
| Ö-006 | 2026-10-08 | Angol nyelvű felület | ⛔ | okafogyott: a felület alapból angol lett ([[ADR-005 Angol nyelvű felület]]); helyette Ö-009 |
| Ö-007 | 2026-10-08 | Bluetooth vérnyomásmérő csatlakoztatása | 💭 | nagy munka, mérőtípustól függ |
| Ö-008 | 2026-10-08 | Kezdőképernyő widget: utolsó mérés + gyors bevitel | 💭 | |
| Ö-009 | 2026-10-08 | Magyar nyelvű felület (választható nyelv) | 💭 | a szövegek már egy helyen vannak (NFR-03a) |
| Ö-012 | 2026-10-08 | Megjelenés áruházban (Google Play vagy F-Droid); addig frissítés **Obtainium**-mal a GitHub Releases-ből | 💭 | v1.0 után. Play: egyszeri regisztrációs díj, személyazonosság-ellenőrzés, új személyes fióknál zárt teszt ≥12 tesztelővel 14 napig, adatvédelmi tájékoztató, egészségügyi nyilatkozat, AAB formátum. F-Droid: ingyenes, nyílt forráskódú appoknak, ők fordítják. **Figyelni:** a Google fejlesztői hitelesítése 2026-tól négy országban él, 2027-ben világszerte jön – érintheti a GitHubról telepítést is |
| Ö-013 | 2026-10-08 | Grafikonon egy pontra koppintva az érték és időpont megjelenítése | 🟢 | v0.4.0 – a nap / hét összes mérése kártyán |
| Ö-015 | 2026-10-08 | Lefúrás a grafikonon: a kijelölt nap / hét kártyáján *Show week* / *Show month* | 💭 | a v0.4.0-ból kimaradt, mert az automatikus teszt hibát talált; `🔄 2026-10-15` döntés: nem kerül a v1.0-ba, a v1.0 után |
| Ö-014 | 2026-10-08 | Két ujjas (csippentős) nagyítás a grafikonon | 💭 | ütközik a húzásos lapozással; most helyette lefúrás (*Show week* / *Show month*) |
| Ö-011 | 2026-10-08 | Technikai: a `pubspec.lock` frissítése (az új csomagokat most a CI oldja fel) | 🟢 | v0.5.0: a CI a feloldott `pubspec.lock`-ot a Preview kiadásra is feltölti, onnan került vissza a repóba (a fejlesztői gépről a pub.dev nem érhető el); csomagfrissítés után ugyanígy |
| Ö-010 | 2026-10-08 | Saját alkalmazásikon (most a Flutter alap ikonja van) | 🟢 | v0.3.0 – „C” változat, [[ADR-008 Alkalmazásikon]] |
| Ö-016 | 2026-10-15 | CSV export (FR-12) Excelhez | 💭 | a v1.0 után; a v0.5.0-ban a PDF volt a fontos, az adatok a teljes mentésben (JSON) addig is megvannak |
| Ö-017 | 2026-10-15 | Téma választás a beállításokban (rendszer / világos / sötét, FR-15) | 💭 | a v1.0 után; most a telefon témáját követi |
| Ö-018 | 2026-10-15 | A beállítások (név, referenciaértékek) is kerüljenek bele a teljes mentésbe | 💭 | telefoncserénél most kézzel kell újra beállítani |
| Ö-019 | 2026-10-15 | Közvetlen *Print* / *Share* gomb a PDF mentése után | 💭 | most: *Open* → a PDF-nézegetőből nyomtatható / megosztható ([[ADR-012 PDF a pdf csomaggal]]) |
