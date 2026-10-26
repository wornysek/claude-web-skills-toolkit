---
name: deslop-de
description: "Editing pass that removes 'AI slop' from German text (Texte auf Deutsch): empty phrases and buzzwords ('In der heutigen schnelllebigen Welt', 'auf das nächste Level heben', 'nahtlos', 'bahnbrechend'), Anglicisms and calques ('Sinn machen', 'in 2026', 'einen Unterschied machen', 'realisieren' for 'bemerken'), nominal and bureaucratic style ('Durchführung', 'erfolgt', 'zur Verfügung stellen'), formulaic structures, English typography in German text (Title Case, em dashes, English quotes, Oxford comma, apostrophe errors), inconsistent du/Sie and gendering, and invented specifics — keeping meaning, facts, links and code intact. Use on any German prose you write or edit — UI texts, web copy, README, documentation, emails, announcements — and whenever the user says 'deslop', 'klingt nach KI', 'klingt übersetzt', 'kürzen' or 'natürlicher formulieren'. For English, Czech or Ukrainian text use deslop-en, deslop-cs or deslop-uk instead."
triggers:
  - "deslop / /deslop-de <Datei>"
  - "klingt nach KI / ChatGPT / wie übersetzt"
  - "natürlicher formulieren / menschlicher klingen"
  - "Text kürzen / straffen / redigieren"
  - "deutsche README / Doku / Ankündigung prüfen"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: de
---

# Deslop (German) — remove AI writing tells from German text

This skill is the German counterpart of `deslop-en` and `deslop-cs`. The instructions are
in English; the tells and examples are German. German AI text has two layers of problems:
the same empty marketing patterns as in English, and English **translated word for word** —
calques, English typography and capitalization — on top of a bureaucratic nominal style
that German writers are trained to avoid in web copy.

The goal is text that is **specific, direct, true and sounds like it was written in German**.

## When to use

- As the last step after writing any German text (`ux-writing-de` ends with this pass).
- When the user asks: `/deslop-de README.de.md`, „klingt nach KI“, „klingt übersetzt“.
- Before publishing German web copy, documentation, emails or announcements.

## Process

1. **Read the whole text** and name its purpose and reader in one sentence.
2. **Scan for tells** from sections A–E (the grep helper below finds most word-level ones).
3. **Rewrite each finding** into the specific statement it stood for, or delete it. If a fact is missing, insert `[TODO: …]` — **never invent** numbers, names or references.
4. **Re-read for meaning and grammar:** no facts changed; *du* / *Sie* and the gender-inclusive style are consistent; cases and articles are correct.
5. **Report** in the output format at the end of this file.

---

## A. Empty phrases and buzzwords

| Category | Tells | Replace with |
|----------|-------|--------------|
| Openers | „In der heutigen schnelllebigen Welt“, „In der heutigen digitalen Welt“, „Willkommen in der Welt von …“, „Tauchen wir ein“, „Lassen Sie uns eintauchen“, „Egal, ob Sie … oder …“, „Stellen Sie sich vor …“ | Start with the point |
| Buzzwords | revolutionär, bahnbrechend, innovativ, nahtlos, robust, ganzheitlich, maßgeschneidert, umfassend, „integraler Bestandteil“, „Mehrwert bieten“, „Synergien nutzen“, „auf das nächste Level heben“, „Game-Changer“ | The concrete property or result |
| Unlock / unleash | „Erschließen Sie das volle Potenzial“, „Entfesseln Sie …“, „Entdecken Sie …“ as a CTA | Say what the user gets or does: „Preise ansehen“ |
| Overused emphasis | „von entscheidender Bedeutung“, „spielt eine zentrale Rolle“, „unerlässlich“, „Es ist wichtig zu beachten, dass …“, „Grundsätzlich gilt …“, „Nicht zuletzt …“ | Delete, or say why it matters |
| Closers | „Zusammenfassend lässt sich sagen“, „Insgesamt“, „Fazit:“ for a short text, „Ich hoffe, das hilft!“, „Zögern Sie nicht, uns zu kontaktieren“ | End when the content ends; „Schreiben Sie uns an …“ |
| Fake enthusiasm | „Großartige Frage!“, „Absolut!“, „Wir freuen uns, Ihnen mitteilen zu können, dass …“, exclamation marks | Neutral statement |
| Intensifiers | wirklich, absolut, unglaublich, extrem, äußerst, definitiv | Delete, or use a number |
| Condescending | einfach, ganz einfach, kinderleicht, natürlich, selbstverständlich | Delete |
| Stacked transitions | „Darüber hinaus“, „Zudem“, „Des Weiteren“, „Außerdem“, „Im Zuge dessen“, „Angesichts dessen“ in every paragraph | Usually delete |

## B. Anglicisms and calques

| ❌ Calque | ✅ German |
|----------|----------|
| „Das macht Sinn.“ | „Das ergibt Sinn.“ / „Das ist sinnvoll.“ |
| „in 2026“ | „2026“ / „im Jahr 2026“ |
| „am Ende des Tages“ | „letztlich“, or delete |
| „einen Unterschied machen“ | „etwas bewirken“, „einen Unterschied ausmachen“ |
| „realisieren“ (= notice) | „bemerken“, „erkennen“ |
| „ein Problem adressieren“ | „ein Problem angehen / ansprechen“ |
| „Das ist es wert.“ | „Es lohnt sich.“ |
| „kreieren“ | „erstellen“, „gestalten“ |
| „supporten“, „challengen“, „committen“ | „unterstützen“, „hinterfragen“, „sich verpflichten“ |
| „downloaden“, „uploaden“ | „herunterladen“, „hochladen“ |
| „Hab einen schönen Tag!“ | „Schönen Tag noch!“ — or delete |

## C. Nominal and bureaucratic style

| ❌ Nominal / passive | ✅ Verb / active |
|---------------------|-----------------|
| „Die Durchführung der Überprüfung erfolgt automatisch.“ | „Wir prüfen das automatisch.“ |
| „zur Verfügung stellen“ | „bereitstellen“, „geben“, „anbieten“ |
| „in Kenntnis setzen“ | „informieren“ |
| „Die Zahlung erfolgt per Kreditkarte.“ | „Sie zahlen per Kreditkarte.“ |
| „seitens des Kunden“ | „vom Kunden“ — better: „Sie“ |
| „bezüglich“, „hinsichtlich“ | „zu“, „über“ |
| „im Rahmen von“ | „bei“, „in“ |
| „zwecks Prüfung“ | „um … zu prüfen“ |
| „eine Entscheidung treffen“, „eine Prüfung vornehmen“ | „entscheiden“, „prüfen“ |
| „Bitte beachten Sie, dass …“ | state it directly |
| „Es wird empfohlen, …“ | „Wir empfehlen …“ |

- Very long sentences with the verb at the end (the *Satzklammer* stretched over a whole line) — split them and bring the verb forward.

## D. Structural and typography tells

- **Contrast framing:** „Es geht nicht nur um X – es geht um Y“, „Nicht nur …, sondern auch …“ in every paragraph. State Y directly.
- **Rule of three:** „schnell, sicher und zuverlässig“. Use the real number of items.
- **Dramatic reveals and rhetorical questions:** „Das Ergebnis?“, „Kennen Sie das?“, „Und das Beste?“
- **Emoji bullets and headings**, a bolded lead-in on every bullet, recap conclusions.
- **English typography in German text:**
  - English Title Case: „Jetzt Kostenlos Testen“ → „Jetzt kostenlos testen“;
  - English quotes "…" → „…“;
  - the em dash — → a spaced en dash – (and frequent dashes in general — Germans use commas more);
  - Oxford comma: „A, B, und C“ → „A, B und C“;
  - apostrophe errors: „FAQ’s“, „Anna’s Profil“ → „FAQs“, „Annas Profil“;
  - decimal point „1.5“ → „1,5“; „50%“ → „50 %“; dates „10/26/2026“ → „26.10.2026“.
- **Inconsistent address:** *du* and *Sie* in the same text; *Sie* not capitalized.
- **Inconsistent gendering:** generic masculine next to „Nutzer*innen“ next to „Nutzer:innen“ — use the project's style (`ux-writing-de`).

## E. Content tells

- **Vague claims:** „steigert Ihre Effizienz“ → um wie viel, wie gemessen? If unknown: `[TODO: gemessene Verbesserung]`.
- **Invented specifics:** made-up statistics, references, logos, user counts. **Never.**
- **„wurde entwickelt, um …“** instead of what it actually does.
- **Unearned superlatives:** „der beste“, „das leistungsstärkste“, „ultimativ“.
- **Talking about the reader's feelings:** „Wir alle kennen das“, „Sie sind nicht allein“.

---

## Rewriting rules

- **Replace, don't just delete.** Each phrase stood in for a claim. Find it and write it.
- **Verbs over nouns**, active over passive, short sentences with the verb early.
- **Keep the author's voice, terminology, form of address and gender-inclusive style.** Don't add jokes or opinions.
- **Meaning is sacred:** facts, links, code, commands, numbers and quotes stay exactly as they were.
- **Context matters:** „robust“ in statistics or engineering is a term; established loanwords („Feedback“, „Team“, „E-Mail“) are fine.
- **Never translate during deslop.** German stays German; English parts go to `deslop-en`, Czech parts to `deslop-cs`, Ukrainian parts to `deslop-uk`.
- **Check grammar after rewriting:** cases, articles, adjective endings, capitalization of nouns.

## Grep helper

Word-level tells:

```bash
grep -rniE "(in der heutigen (schnelllebigen|digitalen)|tauchen wir|eintauchen|nächste level|bahnbrechend|revolutionär|nahtlos|ganzheitlich|maßgeschneidert|integraler bestandteil|mehrwert bieten|synergien|von entscheidender bedeutung|zentrale rolle|es ist wichtig zu beachten|zusammenfassend lässt sich|zögern sie nicht|macht sinn|sinn machen|am ende des tages|einen unterschied machen|zur verfügung stellen|in kenntnis setzen|seitens|zwecks)" --include="*.md" --include="*.mdx" --include="*.tsx" --include="*.json" .
```

English typography in German files:

```bash
grep -rnE "\"[^\"]+\"|[0-9]%|—|, und |’s\b" --include="*.de.md" --include="de.json" .
```

The grep finds candidates, not verdicts — read each hit in context (code and JSON keys use
straight quotes legitimately; a comma before „und“ is correct before a new main clause).
The toolkit's optional hook (`./install.sh --hooks`) runs the word-level check automatically
after every edit.

## Examples

**Web copy**

> ❌ „In der heutigen schnelllebigen Welt ist eine nahtlose und robuste Lösung von entscheidender Bedeutung. Heben Sie Ihr Team auf das nächste Level!“
>
> ✅ „Sprints, Aufgaben und Blocker auf einem Board. Sie sehen sofort, wer woran arbeitet und wer auf wen wartet. [TODO: eine echte Zahl aus der Beta]“

**Announcement**

> ❌ „Wir freuen uns, Ihnen mitteilen zu können, dass im Rahmen des neuesten Updates zahlreiche Verbesserungen zur Verfügung gestellt wurden, die Ihr Erlebnis nachhaltig optimieren.“
>
> ✅ „Die neue Version exportiert große Projekte schneller, und CSV-Dateien behalten jetzt die Reihenfolge der Spalten.“

**UI text**

> ❌ „Sie wurden erfolgreich abgemeldet. Zögern Sie nicht, jederzeit zurückzukehren!“
>
> ✅ „Sie sind abgemeldet. Sie können sich jederzeit wieder anmelden.“

## Output format

For a single text, return the rewritten text followed by a short list of what changed.
For files:

```markdown
## Deslop: README.de.md

| Line | Tell | Before | After |
|------|------|--------|-------|
| 3 | Empty phrase | „In der heutigen schnelllebigen Welt …“ | (deleted, starts with the point) |
| 12 | Calque | „Das macht Sinn“ | „Das ergibt Sinn“ |
| 20 | Nominal style | „Die Zahlung erfolgt per Lastschrift“ | „Sie zahlen per Lastschrift“ |
| 31 | Typography | „Jetzt Kostenlos Testen“ | „Jetzt kostenlos testen“ |

**Changed:** 9 · **Kept on purpose:** 1 („robust“ as a statistics term, line 44) · **Open TODOs:** 1
```

## Related skills

- `ux-writing-de` — rules for writing German UI and web copy in the first place.
- `deslop-en`, `deslop-cs`, `deslop-uk` — the same pass for English, Czech and Ukrainian text.
- `frontend-design-guide` — the visual counterpart.
