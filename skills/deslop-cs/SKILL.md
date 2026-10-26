---
name: deslop-cs
description: "Editing pass that removes 'AI slop' from Czech text (texty v češtině): buzzwords and empty phrases, calques from English ('odemkněte', 'adresovat problém', 'dává smysl'), officialese and nominal style ('za účelem', 'dochází k', 'provést úpravu'), formulaic structures, English typography in Czech text and invented specifics, while keeping meaning, facts, links and code intact. Use on any Czech prose you write or edit — UI texts, web copy, README, documentation, emails, announcements, social posts — and whenever the user says 'deslop', 'zní to jako AI', 'přepiš to lidsky', 'zkrať to' or 'zní to jako překlad'. For English, German or Ukrainian text use deslop-en, deslop-de or deslop-uk instead."
triggers:
  - "deslop / /deslop-cs <soubor>"
  - "zní to jako AI / ChatGPT / jako překlad"
  - "přepiš to lidsky / přirozeně"
  - "zkrať / učesej / zredaguj tento text"
  - "zkontroluj český README / dokumentaci / oznámení"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: cs
---

# Deslop (Czech) — remove AI writing tells from Czech text

This skill is the Czech counterpart of `deslop-en`. The instructions are in English; the
tells and examples are Czech. Czech AI text has two layers of problems: the same empty
marketing patterns as in English, and English **translated word for word** — calques,
English typography and a stiff, nominal style no Czech writer would use.

The goal is text that is **specific, direct, true and sounds like it was written in Czech**.

## When to use

- As the last step after writing any Czech text (`ux-writing-cs` ends with this pass).
- When the user asks: `/deslop-cs README.cs.md`, „zní to jako AI“, „přepiš to lidsky“.
- Before publishing Czech web copy, documentation, emails or announcements.

## Process

1. **Read the whole text** and name its purpose and reader in one sentence.
2. **Scan for tells** from sections A–E (the grep helper below finds most word-level ones).
3. **Rewrite each finding** into the specific statement it stood for, or delete it. If a fact is missing, insert `[TODO: …]` — **never invent** numbers, names or references.
4. **Re-read for meaning and grammar:** no facts changed; declension, agreement and the form of address (*tykání / vykání*) are consistent.
5. **Report** in the output format at the end of this file.

---

## A. Empty phrases and buzzwords

| Category | Tells | Replace with |
|----------|-------|--------------|
| Openers | „V dnešní rychle se měnící době“, „V dnešním digitálním světě“, „Pojďme se ponořit“, „Ponořme se do“, „Ať už jste X, nebo Y“ | Start with the point |
| Buzzwords | revoluční, inovativní, jedinečný, nepostradatelný, komplexní, robustní, bezproblémový, bezešvý, špičkový, „posune vaše … na další úroveň“ | The concrete property or result |
| Overused emphasis | klíčový, zásadní, důležitý (in every paragraph), „je důležité zmínit / poznamenat“, „stojí za zmínku“, „v neposlední řadě“ | Delete, or say why it matters |
| Closers | „Závěrem lze říci“, „Celkově vzato“, „Doufám, že vám to pomohlo“, „Neváhejte nás kontaktovat“ | End when the content ends; „Napište nám na …“ |
| Fake enthusiasm | „Skvělá otázka!“, „Máme pro vás skvělou zprávu!“, exclamation marks | Neutral statement |
| Intensifiers | opravdu, skutečně, naprosto, neuvěřitelně, maximálně, absolutně | Delete, or use a number |
| Condescending | jednoduše, prostě, snadno, samozřejmě | Delete |

## B. Calques from English

| ❌ Calque | ✅ Czech |
|----------|---------|
| „Odemkněte…“ (unlock) | „Získejte…“, „Zpřístupněte…“ |
| „Pozvedněte…“ (elevate) | say what improves |
| „Objevte“, „Prozkoumejte“ as a CTA (discover, explore) | „Zobrazit…“, „Vyzkoušet…“ |
| „adresovat problém“ | „řešit problém“ |
| „dává to smysl“ (makes sense) | „je to logické“, „to sedí“ — or rephrase |
| „na konci dne“ (at the end of the day) | „nakonec“, or delete |
| „udělat rozdíl“ (make a difference) | say what changes |
| „Je to o…“ (it's about) | „Jde o…“ |
| „Ujistěte se, že…“ (make sure) | „Zkontrolujte, že…“ |
| „aplikovat“ (apply) | „použít“ |
| „zážitek“ for every experience | say what the user gets |
| „sdílet“ for "tell" („rádi bychom sdíleli…“) | „chceme vám říct“, „přinášíme“ |
| „Užijte si…“, „Mějte skvělý den!“ | (delete) |

## C. Officialese and nominal style

Czech AI text loves nouns and passive voice. Turn them back into verbs.

| ❌ Nominal / passive | ✅ Verb / active |
|---------------------|-----------------|
| „provést úpravu nastavení“ | „upravit nastavení“ |
| „dochází k chybě při ukládání“ | „ukládání selhává“ |
| „za účelem zvýšení bezpečnosti“ | „abychom zvýšili bezpečnost“ |
| „v rámci aktualizace bylo realizováno“ | „v aktualizaci jsme…“ |
| „je prováděno ověřování“ | „ověřujeme“ |
| „disponuje funkcí“ | „umí“, „má“ |
| „z hlediska výkonu“ | „výkonově“, or rephrase |
| „ohledně platby“ | „o platbě“, „k platbě“ |
| „zajistit“ in every sentence | the actual verb |

## D. Structural and typography tells

- **Contrast framing:** „Nejde jen o X, jde o Y“, „Nejen…, ale i…“ in every other sentence. State Y directly.
- **Rule of three:** „rychle, bezpečně a spolehlivě“. Use the real number of items.
- **Dramatic reveals and rhetorical questions:** „Výsledek? …“, „Už vás nebaví…?“, „Víte, co je nejlepší?“
- **Emoji bullets and headings**, a bolded lead-in on every bullet.
- **Recap conclusions** repeating the introduction.
- **English typography in Czech text:**
  - English quotes "…" instead of „…“;
  - the English em dash — instead of a spaced en dash –;
  - Title Case Headings („Jak To Funguje“) — Czech uses sentence case;
  - no space before % and units („50%“ means *padesátiprocentní*);
  - decimal point „1.5“ instead of „1,5“, dates „10/23/2026“ instead of „23. 10. 2026“;
  - one-letter prepositions (k, s, v, z, o, u, a, i) left at the end of a line.
- **Mixed form of address:** *tykání* and *vykání* on the same page.
- **Gender guesses:** „Byl jste přihlášen“, „Jste si jistý?“ — see `ux-writing-cs` for neutral phrasing.

## E. Content tells

- **Vague claims:** „zrychlí vaši práci“ → o kolik, jak měřeno? If unknown: `[TODO: naměřené zrychlení]`.
- **Invented specifics:** made-up statistics, references, logos, user counts. **Never.**
- **„Navrženo tak, aby…“** instead of what it actually does.
- **Unearned superlatives:** „nejlepší“, „nejvýkonnější“, „ultimátní“.
- **Talking about the reader's feelings:** „Všichni to známe“, „Nejste v tom sami“.

---

## Rewriting rules

- **Replace, don't just delete.** Each phrase stood in for a claim. Find it and write it.
- **Verbs over nouns**, active over passive, concrete over abstract.
- **Keep the author's voice, terminology and form of address.** Don't add jokes or opinions.
- **Meaning is sacred:** facts, links, code, commands, numbers and quotes stay exactly as they were.
- **Context matters:** „komplexní číslo“ in mathematics or „robustní“ in statistics is a term, not slop.
- **Never translate during deslop.** Czech stays Czech; English parts go to `deslop-en`, German parts to `deslop-de`, Ukrainian parts to `deslop-uk`.
- **Check grammar after rewriting:** declension, agreement with numbers, gender.

## Grep helper

Word-level tells:

```bash
grep -rniE "(v dnešní|pojďme se|ponořme|na další úroveň|revoluční|inovativní|nepostradateln|bezproblémov|bezešv|širok(ou|á) škál|stojí za zmínku|závěrem lze|neváhejte|odemkn|pozvedn|adresovat|dává to smysl|realizova|za účelem|dochází k|v neposlední řadě)" --include="*.md" --include="*.mdx" --include="*.tsx" --include="*.json" .
```

English typography in Czech files:

```bash
grep -rnE "\"[^\"]+\"|[0-9]%|—" --include="*.cs.md" --include="cs.json" .
```

The grep finds candidates, not verdicts — read each hit in context (code and JSON keys
use straight quotes legitimately). The toolkit's optional hook (`./install.sh --hooks`)
runs the word-level check automatically after every edit.

## Examples

**Web copy**

> ❌ „V dnešní rychle se měnící době je klíčové mít robustní a bezproblémový nástroj, který posune váš tým na další úroveň. Odemkněte jeho plný potenciál!“
>
> ✅ „Sprinty, úkoly a blokace na jedné tabuli. Hned vidíte, kdo na čem pracuje a kdo na koho čeká. [TODO: jedno skutečné číslo od beta uživatelů]“

**Announcement**

> ❌ „Máme pro vás skvělou zprávu! V rámci nejnovější aktualizace došlo k realizaci řady vylepšení za účelem zlepšení vašeho zážitku.“
>
> ✅ „Nová verze zrychluje export velkých projektů a CSV soubory teď zachovají pořadí sloupců.“

**UI text**

> ❌ „Byl jste úspěšně odhlášen. Neváhejte se kdykoliv vrátit!“
>
> ✅ „Odhlášení proběhlo. Přihlásit se můžete kdykoli znovu.“

## Output format

For a single text, return the rewritten text followed by a short list of what changed.
For files:

```markdown
## Deslop: README.cs.md

| Line | Tell | Before | After |
|------|------|--------|-------|
| 3 | Empty phrase | „V dnešní rychle se měnící době…“ | (deleted, starts with the point) |
| 12 | Calque | „Odemkněte všechny funkce“ | „Získejte přístup ke všem funkcím“ |
| 20 | Nominal style | „provést úpravu nastavení“ | „upravit nastavení“ |
| 31 | Typography | "takto" | „takto“ |

**Changed:** 9 · **Kept on purpose:** 1 („komplexní číslo“, line 44) · **Open TODOs:** 1
```

## Related skills

- `ux-writing-cs` — rules for writing Czech UI and web copy in the first place.
- `deslop-en`, `deslop-de`, `deslop-uk` — the same pass for English, German and Ukrainian text.
- `frontend-design-guide` — the visual counterpart.
