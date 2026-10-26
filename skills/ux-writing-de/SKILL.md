---
name: ux-writing-de
description: "Rules for writing German UI copy and web copy (Texte auf Deutsch) that is clear, specific and natural: buttons, form labels and hints, error messages, empty states, dialogs, success messages, emails and landing pages, plus German-specific rules — du vs. Sie, gender-inclusive language, inserted variables and cases, plurals, long compound words and text expansion, legally required button wording in Germany, German typography and number/date formats (DIN 5008, Intl), nominal style and plain language, and regional variants (de-DE, de-AT, de-CH). Use whenever the user-facing text you write or change is in German. For English, Czech or Ukrainian text use ux-writing-en, ux-writing-cs or ux-writing-uk instead."
triggers:
  - "deutsche Texte schreiben / verbessern / Microcopy auf Deutsch"
  - "Button-Text / Fehlermeldung / leerer Zustand / Bestätigungsdialog auf Deutsch"
  - "Landingpage auf Deutsch / Hero-Text / CTA"
  - "du oder Sie / gendern / geschlechtergerechte Sprache"
  - "German UI copy / translate the UI to German"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: de
---

# UX Writing (German) — microcopy and web copy in German

This skill is the German counterpart of `ux-writing-en` and `ux-writing-cs`. The
instructions are in English; all examples are German. The general principles are the same —
clear before clever, specific before generic, never invent facts — but German adds its own
problems: the choice between *du* and *Sie*, gender-inclusive language, long compound words,
a strong pull towards nominal and bureaucratic style, and legally prescribed button texts in
Germany. `deslop-de` is the editing pass that follows.

## Process

1. **Understand the moment:** who is reading, what they are trying to do, what happens next.
2. **Check the project's form of address and gender-inclusive style** (sections 1–2). If they are not defined, ask once and record the answer in `CLAUDE.md` or the glossary.
3. **Collect the facts.** **Never invent** numbers, prices, deadlines, guarantees or references — use a visible `[TODO: echte Zahl]`.
4. **Write** following the rules below. Translate meaning, not words — German text must not read like translated English.
5. **Check grammar and layout traps** (sections 3–4, 12): variables, plurals, long words.
6. **Run `deslop-de`** on everything you wrote.
7. **Report** changed strings in the output format at the end of this file.

---

## 1. Form of address: *du* or *Sie*

Choose **one** for the whole product and use it everywhere — UI, errors, emails, help pages.

| | *Sie* (formal) | *du* (informal) |
|---|---|---|
| Typical for | banking, insurance, public services, B2B, healthcare, most e-commerce | consumer apps, developer tools, communities, young and informal brands |
| Instruction | „Geben Sie Ihre E-Mail-Adresse ein.“ | „Gib deine E-Mail-Adresse ein.“ |
| Possessive | „Ihr Konto“ | „dein Konto“ |
| Question | „Möchten Sie die Änderungen speichern?“ | „Möchtest du die Änderungen speichern?“ |

- *Sie*, *Ihr*, *Ihnen* are **always capitalized** in the formal address.
- *du*, *dein*, *dich* are written in lowercase in UI text (capitalized *Du* is allowed in letters and emails, but stay consistent).
- Buttons in the infinitive (section 5) work with both forms.
- Never mix *du* and *Sie* on one screen or in one flow.

## 2. Gender-inclusive language

German nouns for people are gendered (*der Nutzer*, *die Nutzerin*). Decide the project's
approach once and record it in the glossary.

| Approach | Example | Notes |
|----------|---------|-------|
| **Direct address** (best in UI) | „Sie haben 3 neue Nachrichten.“ instead of „Der Nutzer hat …“ | removes most person nouns |
| **Neutral forms** | Team, Mitglieder, Person, Nutzende, Teilnehmende, „alle, die …“ | readable, accessible, no special characters |
| **Pair forms** | „Kundinnen und Kunden“ | clear but long — fine in running text, too long for labels |
| **Gender characters** | „Nutzer*innen“, „Nutzer:innen“ | not part of the official orthography (Rat für deutsche Rechtschreibung, 2023); some public bodies restrict them; screen readers read them inconsistently |

- **Recommended default:** direct address and neutral forms; pair forms where a person noun is unavoidable.
- If the brand uses a gender character, use **one** character consistently — never mix `*`, `:`, `_` and generic masculine.
- Organizations of blind and visually impaired people prefer neutral formulations over special characters for screen-reader users (`a11y-auditor`).

## 3. Inserted variables and grammar

German past participles don't change with gender, so „{name} hat dich eingeladen“ works for
everyone. The traps are **cases, articles and the genitive**.

| ❌ Fragile | ✅ Robust |
|-----------|----------|
| „{name}s Profil“ (breaks for names ending in -s, -x, -z: „Hans’ Profil“) | „Profil von {name}“ / „Profil: {name}“ |
| „Der {item} wurde gelöscht.“ (article depends on the noun's gender) | „Das Element ‚{item}‘ wurde gelöscht.“ / „Projekt ‚{name}‘ gelöscht.“ |
| „Sehr geehrter Herr {lastName},“ (assumes gender) | „Guten Tag {fullName},“ (*Sie*) / „Hallo {firstName},“ (*du*) |
| „Sie haben {count} neue Nachricht(en).“ | an ICU plural (section 4) |

- Put a fixed noun before the variable (Projekt, Datei, Element) so the article and adjective endings are known.
- Product and brand names keep their own spelling and are not declined.

## 4. Plurals

`Intl.PluralRules("de")` has two categories, `one` and `other`. Use ICU messages — never
`count === 1 ? … : …` inside the sentence, and never concatenation:

```
{count, plural,
  =0 {Keine Projekte}
  one {# Projekt}
  other {# Projekte}
}
```

- Keep the whole phrase in each branch when the noun changes its case: `{minutes, plural, one {vor # Minute} other {vor # Minuten}}` — or let `Intl.RelativeTimeFormat("de")` produce „vor 5 Minuten“.
- Agreement of verbs and adjectives belongs in the branch too: „1 Datei wurde hochgeladen“ / „3 Dateien wurden hochgeladen“.

---

## 5. Buttons and links

- **Infinitive + object:** „Projekt erstellen“, „Änderungen speichern“, „Jetzt kostenlos testen“. Not „OK“, „Absenden“ without context, „Ja“, „Hier klicken“.
- **The button repeats the dialog's action:** „Projekt löschen?“ → [Abbrechen] [Projekt löschen].
- **Link text names the destination:** „Preise ansehen“, not „hier“ or „mehr“.
- **Progress label:** „Wird gespeichert …“, „Wird gesendet …“ — and the button is disabled.
- **Same action, same word:**
  - *löschen* = permanently; *entfernen* = from a list, the item still exists.
  - *anmelden / abmelden* (sign in / out) and *registrieren* or *Konto erstellen* (sign up) — not „einloggen“, „Login“ as a verb, „ausloggen“ mixed with them.
  - *speichern* = keeps changes; *senden* / *absenden* = hands something over.

**Legally required wording in Germany** (`ecommerce`, `[LEGAL: verify]`):
- **Order button:** labelled „zahlungspflichtig bestellen“ or an equally unambiguous wording such as „kostenpflichtig bestellen“ or „jetzt kaufen“ for a real purchase (§ 312j Abs. 3 BGB). Without it, no contract is formed. Courts have rejected labels like „Weiter zur Zahlung“ or „Abonnieren“.
- **Cancellation button** for contracts concluded online (subscriptions): a clearly labelled button such as „Verträge hier kündigen“, leading directly to a confirmation page with a button such as „jetzt kündigen“ (§ 312k BGB). It must be reachable without signing in, and the confirmation page must not contain retention offers.

## 6. Forms

- **Labels:** short noun phrases: „Firmenname“, „E-Mail-Adresse“ (compounds with English parts are hyphenated: *E-Mail-Adresse*, *Login-Daten*).
- **Hints** before errors happen: „3–32 Zeichen: Buchstaben, Ziffern und Bindestriche.“
- **Placeholders** only as examples: „z. B. studio-acme“.
- **Optional fields:** „(optional)“.
- **Explain sensitive questions:** „Ihre Telefonnummer nutzen wir nur für Lieferinformationen.“
- **Checkboxes** as positive statements: „Ich möchte den Newsletter erhalten.“
- **Section headings** say what they are for: „Rechnungsadresse“, „Lieferung“.

## 7. Error messages

**Formula:** what happened + (why, if it helps) + what to do next. No codes alone, no blame,
no „Hoppla!“, no „Fehler:“ prefix, no capitals, no exclamation marks. Examples use *Sie*;
for *du* switch the verb forms and possessives.

| ❌ Generic | ✅ Specific |
|-----------|------------|
| Ungültige Eingabe | Verwenden Sie 3–32 Buchstaben, Ziffern oder Bindestriche. |
| Pflichtfeld | Geben Sie Ihren Firmennamen ein. |
| Ein Fehler ist aufgetreten | Ihre Bestellung konnte nicht abgeschlossen werden. Es wurde nichts abgebucht – versuchen Sie es in einer Minute erneut. |
| Nicht autorisiert | Ihre Sitzung ist abgelaufen. Bitte melden Sie sich erneut an. |
| Zugriff verweigert | Nur Admins des Arbeitsbereichs können die Abrechnung ändern. |
| Nicht gefunden | Dieses Projekt wurde nicht gefunden. Möglicherweise wurde es gelöscht. |
| Konflikt | Ein Projekt mit diesem Namen gibt es bereits. Wählen Sie einen anderen Namen. |
| Datei zu groß | Die Datei ist 8 MB groß. Laden Sie eine Datei bis 5 MB hoch. |
| Nicht unterstütztes Format | Laden Sie ein Bild im Format PNG, JPG oder WebP hoch. |
| Zu viele Anfragen | Sie haben in der letzten Stunde 5 Codes angefordert. Versuchen Sie es nach 14:30 Uhr erneut. |
| Netzwerkfehler | Sie sind offline. Sobald die Verbindung wieder steht, versuchen wir es erneut. |

- A generic server error gets a next step and a reference: „Wenn das Problem bleibt, schreiben Sie unserem Support und nennen Sie den Code `req-7f3a`.“
- **Don't leak security details** (`backend-security-auditor`): „E-Mail-Adresse oder Passwort ist falsch.“, not „Zu dieser E-Mail-Adresse gibt es kein Konto.“
- Use „bitte“ sparingly — once in a sentence that asks the user to act again is fine; on every line it sounds like a form from an office.

## 8. Empty states, dialogs, success messages, emails

Empty states (variants from `frontend-design-guide`):

| Variant | Headline | Body | Action |
|---------|----------|------|--------|
| First use | „Noch keine Projekte“ | „In Projekten haben Sie Aufgaben, Dateien und Ihr Team an einem Ort.“ | „Projekt erstellen“ |
| No results | „Keine Rechnungen für den Filter ‚Überfällig‘“ | „Ändern Sie den Filter oder setzen Sie die Filter zurück.“ | „Filter zurücksetzen“ |
| No access | „Die Abrechnung verwaltet Ihr Admin“ | „Bitten Sie einen Admin des Arbeitsbereichs um Zugriff.“ | „Admins anzeigen“ |

Confirmation dialogs:
- Title as a question with the object: „Dieses Projekt löschen?“
- Body with concrete consequences in active voice: „Wir löschen das Projekt und alle 12 Aufgaben darin. Das lässt sich nicht rückgängig machen.“
- Buttons: [Abbrechen] [Projekt löschen] — never „Ja / Nein“; instead of „Sind Sie sicher?“ say what will happen.

Success messages and emails:
- Specific result + next step: „Bestellung eingegangen. Sobald sie versandt ist, schicken wir Ihnen eine E-Mail.“
- Toasts: one sentence, optionally one action („Rückgängig“, „Anzeigen“).
- No celebration of trivial actions („🎉 Gespeichert!“).
- Email subject states the result: „Ihre Zahlung ist eingegangen“.

## 9. Landing page copy

- **Headline:** a specific outcome for a specific audience, up to ~8 words (German words are longer).
- **Subheadline:** how it works or the proof, up to ~20 words.
- **CTA:** infinitive + object: „Kostenlos testen“, „Preise ansehen“.
- **Proof must be real:** never invent references, user counts or ratings.

> ❌ „Revolutionieren Sie Ihre Rechnungsstellung und heben Sie Ihr Business auf das nächste Level!“
>
> ✅ „Rechnungen für Selbstständige, die nicht hinter Zahlungen herlaufen wollen. In einer Minute erstellt – Zahlungserinnerungen verschicken wir automatisch.“

## 10. Glossary

| Use | Don't use |
|-----|-----------|
| anmelden / abmelden | einloggen, ausloggen, „Login“ as a verb |
| registrieren / Konto erstellen | signen, „Sign-up“ in running text |
| Konto (or Account — pick one) | Konto and Account mixed |
| E-Mail-Adresse | Email-Adresse, eMail, E-mail |
| löschen (permanently) | entfernen, wenn löschen gemeint ist |
| Einstellungen | Settings, Konfiguration (in user-facing copy) |
| hochladen / herunterladen | uploaden / downloaden |
| Passwort (or Kennwort — pick one) | both mixed |
| Zulassungsliste / Sperrliste | Whitelist / Blacklist |

---

## 11. German typography and formats

- **Quotes:** „so“, inner quotes ‚so‘. In Switzerland «so» and ‹so›. Never English "quotes".
- **Dash:** a dash in a sentence is an en dash with spaces („ – “); ranges use an en dash without spaces: „10–12 Uhr“, „3–16 Zeichen“. The English em dash („—“) is not used.
- **Numbers:** decimal comma „1,5“; thousands „1.234“ (as `Intl.NumberFormat("de-DE")` formats them) — DIN 5008 also allows grouping with spaces („1 234“); pick one.
- **Currency:** de-DE „12,50 €“; de-AT „€ 12,50“; de-CH „CHF 12.50“ with an apostrophe for thousands („1’234.50“) — always via `Intl.NumberFormat(locale, { style: "currency", currency })`.
- **Dates:** „26.10.2026“ or „26. Oktober 2026“ (ISO „2026-10-26“ is also correct); in Austria „Jänner“ instead of „Januar“ — `Intl.DateTimeFormat` handles it.
- **Times:** „14:30 Uhr“, full hours „15 Uhr“.
- **Percent and units:** with a (non-breaking) space: „50 %“, „5 MB“.
- **Abbreviations** like „z. B.“, „d. h.“ have a space inside; in UI prefer writing them out.
- **ß and ss:** ß after long vowels and diphthongs („Straße“, „groß“), ss after short vowels („dass“, „muss“); Swiss German uses only „ss“.
- **Capitalization:** nouns and nominalized verbs are capitalized („das Speichern“); headings and buttons otherwise use sentence case — never English Title Case („Jetzt Kostenlos Testen“).
- **No comma before „und“ in lists** („A, B und C“) and no apostrophe for plurals or genitives („FAQs“, „Annas Profil“ — not „FAQ’s“, „Anna’s“).

## 12. Long words and text expansion

- German UI text is often **30–35 % longer** than English; plan for it — no fixed button widths, labels that can wrap.
- **Compound words** („Benachrichtigungseinstellungen“) break layouts on mobile. Set `lang="de"` and `hyphens: auto` for running text, add soft hyphens (`­`) to known long words in headings and buttons, and use `overflow-wrap: anywhere` only as a last resort.
- Prefer shorter words in navigation and buttons: „Datenschutz“ instead of „Datenschutzbestimmungen“, „Benachrichtigungen“ instead of „Benachrichtigungseinstellungen“ inside a settings menu, where the context is clear.
- Hyphenate compounds with English or abbreviated parts for readability: „E-Mail-Adresse“, „PDF-Export“, „Single-Sign-on“.

## 13. Plain language

German tempts writers into nominal style and long sentences with the verb at the very end.
Write like you speak to a person.

| ❌ Nominal / bureaucratic | ✅ Verb / active |
|--------------------------|-----------------|
| „Die Durchführung der Überprüfung erfolgt automatisch.“ | „Wir prüfen das automatisch.“ |
| „Wir stellen Ihnen die Rechnung zur Verfügung.“ | „Sie erhalten die Rechnung als PDF.“ |
| „Die Zahlung erfolgt per Lastschrift.“ | „Sie zahlen per Lastschrift.“ |
| „Bitte beachten Sie, dass Änderungen erst nach dem Speichern wirksam werden.“ | „Änderungen gelten nach dem Speichern.“ |
| „bezüglich Ihrer Anfrage“ | „zu Ihrer Anfrage“ |
| „im Rahmen der Registrierung“ | „bei der Registrierung“ |
| „eine Entscheidung treffen“ | „entscheiden“ |

- One statement per sentence; bring the verb forward; split long sentences.
- **Leichte Sprache:** public bodies in Germany must offer key information on their website in Leichte Sprache and German Sign Language (§ 4 BITV 2.0) `[LEGAL: verify]`. Leichte Sprache follows its own rule set and should be checked by people from the target group — don't improvise it.

## 14. Regional variants

- Default to **de-DE** with neutral vocabulary; localize for **de-AT** and **de-CH** when the market matters: formats via `Intl` (section 11), „ss“ instead of „ß“ and «…» quotes for Switzerland, legal pages per country.
- Don't mix variants in one interface; set `<html lang="de-CH">` etc. for the variant you serve (`i18n-setup`).

---

## Output format

```markdown
## Copy changes: app/projects

| Location | Before | After | Rule |
|----------|--------|-------|------|
| new-project-form.tsx:84 (button) | Absenden | Projekt erstellen | Buttons: infinitive + object |
| new-project-form.tsx:31 (error) | Ungültige Eingabe | Verwenden Sie 3–32 Buchstaben, Ziffern oder Bindestriche. | Errors: say how to fix |
| profile-header.tsx:12 | {name}s Profil | Profil von {name} | Variables: no genitive -s |
| checkout.tsx:140 (button) | Weiter zur Zahlung | Zahlungspflichtig bestellen | § 312j BGB `[LEGAL]` |

**Form of address:** Sie · **Gender-inclusive style:** direct address + neutral forms · **Open TODOs:** `[TODO: echte Zahl]` in page.tsx:14
```

## Behavior rules

- Never invent facts, numbers, references, prices or deadlines. A visible `[TODO: …]` beats a plausible fake.
- Keep the project's form of address and gender-inclusive style; if they are not defined, ask once and record the answers.
- Don't mix German with English or Czech in one UI; English strings follow `ux-writing-en`, Czech strings `ux-writing-cs`, Ukrainian strings `ux-writing-uk`.
- If the project has an i18n layer, change strings in the message files, with ICU plurals (`i18n-setup`).
- After writing, always run `deslop-de`.
- Related skills: `ux-laws`, `frontend-design-guide`, `backend-security-auditor`, `ecommerce` (legal button wording), `a11y-auditor`.
