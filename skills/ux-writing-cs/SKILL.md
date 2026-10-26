---
name: ux-writing-cs
description: "Rules for writing Czech UI copy and web copy (texty v češtině) that is clear, specific and natural: buttons, form labels and hints, error messages, empty states, confirmation dialogs, success messages, emails and landing pages, plus Czech-specific grammar for interfaces — tykání vs. vykání, gender-neutral phrasing, declension of inserted variables, plural forms with verb agreement, Czech typography, number and date formats, sorting and common calques from English. Use whenever the user-facing text you write or change is in Czech. For English, German or Ukrainian text use ux-writing-en, ux-writing-de or ux-writing-uk instead."
triggers:
  - "napiš / vylepši texty, textace, microcopy v češtině"
  - "české tlačítko / chybová hláška / prázdný stav / potvrzovací dialog"
  - "landing page česky / hero text / CTA"
  - "tykání nebo vykání / skloňování / plurály"
  - "Czech UI copy / translate the UI to Czech"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: cs
---

# UX Writing (Czech) — microcopy and web copy in Czech

This skill is the Czech counterpart of `ux-writing-en`. The instructions are in English;
all examples are Czech. The general principles are the same — clear before clever,
specific before generic, never invent facts — but Czech adds grammar problems that
English UIs don't have: declension, grammatical gender, four plural forms and a choice
between *tykání* and *vykání*. `deslop-cs` is the editing pass that follows.

## Process

1. **Understand the moment:** who is reading, what they are trying to do, what happens next.
2. **Check the project's form of address** (section 1). If none is defined, ask once or pick one and write it into `CLAUDE.md`.
3. **Collect the facts.** **Never invent** numbers, prices, deadlines, guarantees or references — use a visible `[TODO: skutečné číslo]`.
4. **Write** following the rules below. Translate meaning, not words — Czech text must not read like translated English.
5. **Check grammar traps** (sections 2–4): variables, gender, plurals.
6. **Run `deslop-cs`** on everything you wrote.
7. **Report** changed strings in the output format at the end of this file.

---

## 1. Form of address: *tykání* or *vykání*

Choose **one** for the whole product and use it everywhere — buttons, errors, emails,
notifications, help pages.

| | *Vykání* (formal "vy") | *Tykání* (informal "ty") |
|---|---|---|
| Typical for | public services, finance, B2B, healthcare, e-commerce | games, communities, apps for young audiences, informal brands |
| Instruction | „Zadejte e-mail“ | „Zadej e-mail“ |
| Possessive | „váš účet“ | „tvůj účet“ |
| Question | „Chcete změny uložit?“ | „Chceš změny uložit?“ |

- In UI, *vy / váš* is written in **lowercase**. Capitalized *Vy / Váš* belongs only in personal letters.
- Buttons in the infinitive (section 5) work with both forms, which is one reason the infinitive is the convention.
- Never mix the two forms on one screen.

## 2. Gender-neutral phrasing

Czech past tense and many adjectives carry gender. You usually don't know the user's
gender, so avoid forms that require it.

| ❌ Gendered | ✅ Neutral |
|------------|-----------|
| „Byl jste úspěšně přihlášen.“ | „Přihlášení proběhlo úspěšně.“ / „Vítejte zpět.“ |
| „Jste si jistý?“ | State the consequence instead (section 8). |
| „Uživatel/ka byl/a přidán/a.“ | „Člen týmu je přidaný.“ — or a noun phrase: „Nový člen týmu: {name}“ |
| „Zapomněl jste heslo?“ | „Zapomenuté heslo?“ |
| „Byl jste odhlášen z důvodu nečinnosti.“ | „Kvůli nečinnosti jsme vás odhlásili.“ |

Don't use slashes (`přihlášen/a`) — they are hard to read and to translate.

## 3. Inserted variables and declension

Czech declines nouns, but inserted values (names, project names, cities) stay in the
nominative. Build sentences so the variable **is** in the nominative.

| ❌ Needs a declined variable | ✅ Variable stays in nominative |
|------------------------------|--------------------------------|
| „Pozvánka od {name}“ (needs genitive: *od Martina*) | „{name} vás zve do projektu {project}.“ |
| „{name} přidal komentář“ (gendered past tense) | „{name} přidává komentář“ (present) / „Nový komentář: {name}“ |
| „Ahoj {name},“ (needs vocative: *Martine, Jano*) | „Dobrý den,“ / „Ahoj,“ / „Vítejte zpět“ |
| „Doručíme do {city}“ (needs genitive) | „Místo doručení: {city}“ |
| „Faktura pro {company}“ (accusative is usually fine — but check) | „Odběratel: {company}“ when unsure |

Present tense ("{name} vás zve") is gender-neutral and avoids the past participle.

## 4. Plurals and agreement

`Intl.PluralRules("cs")` has four categories: `one` (1), `few` (2–4), `many` (decimals,
e.g. 1,5), `other` (0, 5+). **Put the whole phrase in each branch**, including the verb,
because the verb agrees with the number too:

```
{count, plural,
  one {# úkol byl dokončen}
  few {# úkoly byly dokončeny}
  many {# úkolu bylo dokončeno}
  other {# úkolů bylo dokončeno}
}
```

Prepositions change the case, so they belong inside the branch as well:

```
{minutes, plural,
  one {za # minutu}
  few {za # minuty}
  many {za # minuty}
  other {za # minut}
}
```

- Never concatenate: `"Máte " + n + " úkolů"` is wrong for 1–4.
- Never `n === 1 ? … : …` — Czech needs all four forms.
- For zero, consider a dedicated message: `=0 {Žádné úkoly}`.

---

## 5. Buttons and links

- **Infinitive + object:** „Vytvořit projekt“, „Odeslat fakturu“, „Uložit změny“.
  Not „OK“, „Odeslat“ without an object where it's ambiguous, „Ano“, „Klikněte zde“.
- **The button repeats the dialog's action:** „Smazat projekt?“ → [Zrušit] [Smazat projekt].
- **Link text names the destination:** „Zobrazit ceník“, not „zde“ or „tento odkaz“.
- **Length:** ideally up to 3 words; Czech is longer than English, so leave room.
- **Progress label:** a neutral noun works with both forms of address: „Ukládání…“, „Odesílání…“ — and the button is disabled.
- **Same action, same word, everywhere:**
  - *Smazat* = permanently. *Odebrat* = from a list, the item still exists.
  - *Přihlásit se / Odhlásit se* — not „Login“, „Zalogovat“, „Logout“.
  - *Uložit* = keeps changes. *Odeslat* = hands it over to someone else.

## 6. Forms

- **Labels:** short noun phrases, always visible: „Název firmy“, „E-mail“.
- **Hints** before the user makes an error: „3–32 znaků: písmena, číslice a pomlčky.“
- **Placeholders** only as examples: „např. studio-acme“.
- **Optional fields:** „(nepovinné)“.
- **Explain sensitive questions:** „Telefon použijeme jen pro informace o doručení.“
- **Checkboxes** as positive statements: „Chci dostávat novinky e-mailem.“
- **Section headings** say what they are for: „Fakturační údaje“, „Doručení“.

## 7. Error messages

**Formula:** what happened + (why, if it helps) + what to do next. No codes alone, no
blame, no „Jejda!“, no „Chyba:“ prefix, no capitals, no exclamation marks.
Examples use *vykání*; for *tykání* switch the verb forms.

| ❌ Generic | ✅ Specific |
|-----------|------------|
| Neplatný vstup | Použijte 3–32 písmen, číslic nebo pomlček. |
| Povinné pole | Zadejte název firmy. |
| Chyba 500 / Něco se pokazilo | Objednávku se nepodařilo dokončit. Nic jsme vám nestrhli – zkuste to za chvíli znovu. |
| Neautorizováno | Platnost přihlášení vypršela. Přihlaste se znovu. |
| Přístup odepřen | Fakturaci mohou měnit jen správci pracovního prostoru. |
| Nenalezeno | Tento projekt jsme nenašli. Možná byl smazán. |
| Konflikt | Projekt s tímto názvem už existuje. Zvolte jiný název. |
| Soubor je příliš velký | Soubor má 8 MB. Nahrajte soubor do 5 MB. |
| Nepodporovaný formát | Nahrajte obrázek ve formátu PNG, JPG nebo WebP. |
| Překročen limit požadavků | Za poslední hodinu jste si vyžádali 5 kódů. Další můžete zkusit po 14:30. |
| Chyba sítě | Jste offline. Jakmile se připojení obnoví, zkusíme to znovu. |

- A generic server error gets a next step and a reference: „Pokud se to opakuje, napište podpoře a uveďte kód `req-7f3a`.“
- **Don't leak security details** (see `backend-security-auditor`): „Nesprávný e-mail nebo heslo“, not „Účet s tímto e-mailem neexistuje“.
- Never show raw exceptions or English library messages to Czech users.

## 8. Empty states, dialogs and success messages

Empty states (variants from `frontend-design-guide`):

| Variant | Headline | Body | Action |
|---------|----------|------|--------|
| First use | „Zatím tu nejsou žádné projekty“ | „V projektu máte úkoly, soubory i lidi pohromadě.“ | „Vytvořit projekt“ |
| No results | „Filtru „Po splatnosti“ neodpovídá žádná faktura“ | „Zkuste jiný filtr nebo filtry zrušte.“ | „Zrušit filtry“ |
| No access | „Fakturaci spravuje správce“ | „Požádejte správce pracovního prostoru o přístup.“ | „Zobrazit správce“ |

Confirmation dialogs:
- Title as a question with the object: „Smazat tento projekt?“
- Body with concrete consequences in active voice: „Smažeme projekt i všech 12 úkolů v něm. Tuto akci nelze vrátit.“
- Buttons: [Zrušit] [Smazat projekt] — never „Ano / Ne“.
- Instead of „Jste si jistí?“ say what will happen.

Success messages and emails:
- Specific result + next step: „Objednávku jsme přijali. Až ji odešleme, pošleme vám e-mail.“
- Toasts: one sentence, optionally one action („Vrátit zpět“, „Zobrazit“).
- No celebration of trivial actions („🎉 Uloženo!“).
- Email subject states the result: „Platba byla přijata“.

## 9. Landing page copy

- **Headline:** a specific outcome for a specific audience, up to ~10 words.
- **Subheadline:** how it works or the proof, up to ~25 words.
- **CTA:** infinitive + object: „Vyzkoušet zdarma“, „Zobrazit ceník“.
- **Benefits over features**, and only claims that are true and measured.
- **Proof must be real:** never invent references, user counts or ratings.

> ❌ „Odemkněte ultimátní zážitek z fakturace. Revoluce ve způsobu, jak dostáváte zaplaceno!“
>
> ✅ „Fakturace pro freelancery, kteří nechtějí nahánět platby. Fakturu vystavíte za minutu, upomínky odejdou samy.“

## 10. Glossary

| Use | Don't use |
|-----|-----------|
| přihlásit se / odhlásit se | login, zalogovat, logout |
| e-mail (pick one spelling and keep it) | mail, E-mail, email and e-mail mixed |
| smazat (permanently) | odstranit, vymazat — unless you define a difference |
| člen týmu | uživatel, seat (in user-facing copy) |
| nastavení | settings, konfigurace (in user-facing copy) |
| seznam povolených / blokovaných | whitelist / blacklist |

---

## 11. Czech typography and formats

- **Quotes:** „takto“, inner quotes ‚takto‘. Never English "quotes" in Czech text.
- **One-letter prepositions and conjunctions** (k, s, v, z, o, u, a, i) must not end a line: join them to the next word with a non-breaking space (` `, `&nbsp;`). In React, keep it in the translation string or use a small helper.
- **Percent:** „50 %“ (with a space) means fifty percent; „50%“ means the adjective *padesátiprocentní*.
- **Units:** „5 MB“, „20 °C“ — with a non-breaking space.
- **Numbers:** decimal comma „1,5“, thousands separated by a non-breaking space „12 500“.
- **Currency:** „1 290 Kč“, „1 290,50 Kč“ — use `Intl.NumberFormat("cs-CZ", { style: "currency", currency: "CZK" })`.
- **Dates and times:** „23. 10. 2026“, „23. října 2026“, „14:30“ — use `Intl.DateTimeFormat("cs-CZ")`, never a hard-coded format. Month and day names are lowercase.
- **Ranges:** en dash without spaces „3–16 znaků“, „9:00–17:00“. A dash in a sentence is an en dash with spaces „ – “, not the English em dash „—“.
- **Ordinals:** „1. místo“, „2. krok ze 3“.
- **Capitalization:** sentence case in headings, buttons and menus — „Nastavení účtu“, never „Nastavení Účtu“.
- **Sorting:** Czech alphabet puts „ch“ after „h“ and handles diacritics; sort lists with `new Intl.Collator("cs").compare`, not the default string sort.
- **Length:** Czech strings are often 20–35 % longer than English ones — no fixed button widths.

## 12. Calques and officialese

Czech UI text often sounds translated from English. Write it the way a Czech person would say it.

| ❌ Calque / officialese | ✅ Natural Czech |
|------------------------|-----------------|
| „Klikněte zde“ | a link on the destination: „Zobrazit ceník“ |
| „Aplikovat filtry“ | „Použít filtry“ |
| „Odemkněte všechny funkce“ | „Získejte přístup ke všem funkcím“ |
| „Ujistěte se, že…“ | „Zkontrolujte, že…“ |
| „Váš účet byl úspěšně vytvořen.“ | „Účet je připravený.“ |
| „adresovat problém“ | „řešit problém“ |
| „realizovat platbu“ | „zaplatit“ |
| „za účelem ověření“ | „abychom ověřili“ |
| „dochází k chybě při ukládání“ | „ukládání selhává“ |
| „provést úpravu“ | „upravit“ |
| „Užijte si…“, „Mějte skvělý den!“ | (delete) |

---

## Output format

```markdown
## Copy changes: app/projects

| Location | Before | After | Rule |
|----------|--------|-------|------|
| new-project-form.tsx:84 (button) | Odeslat | Vytvořit projekt | Buttons: infinitive + object |
| new-project-form.tsx:31 (error) | Neplatný vstup | Použijte 3–32 písmen, číslic nebo pomlček. | Errors: say how to fix |
| notifications.ts:12 | {name} přidal komentář | {name} přidává komentář | Gender-neutral, variable in nominative |
| tasks.json:4 | Máte {n} úkolů | ICU plural with 4 branches | Plurals and agreement |

**Form of address:** vykání · **Open TODOs:** `[TODO: skutečné číslo]` in page.tsx:14
```

## Behavior rules

- Never invent facts, numbers, references, prices or deadlines. A visible `[TODO: …]` beats a plausible fake.
- Keep the project's form of address; if it is not defined, ask once and record the answer in `CLAUDE.md`.
- Don't mix Czech and English in one UI; English strings follow `ux-writing-en`, German strings `ux-writing-de`, Ukrainian strings `ux-writing-uk`.
- If the project has an i18n layer, change strings in the message files, with ICU plurals. The technical setup is in `i18n-setup`.
- After writing, always run `deslop-cs`.
- Related skills: `ux-laws`, `frontend-design-guide`, `backend-security-auditor`.
