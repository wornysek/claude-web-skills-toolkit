---
name: ux-writing-en
description: "Rules for writing English UI copy and web copy that is clear, specific and human: button labels, form labels and hints, error messages, empty states, confirmation dialogs, success messages and notifications, onboarding, emails and landing page copy (headlines, subheadlines, CTAs), plus voice and tone, a glossary, mechanics and localization-safe strings. Use whenever the user-facing text you write or change is in English. For Czech text use ux-writing-cs instead."
triggers:
  - "write / improve the copy, wording, microcopy (English)"
  - "button label / error message / empty state / confirmation dialog"
  - "landing page headline / hero copy / CTA"
  - "onboarding texts / tooltips / notifications / emails"
  - "make the UI text clearer / friendlier"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: en
---

# UX Writing (English) — microcopy and web copy

Text is part of the interface. Generated UIs usually ship with copy that is generic
("Something went wrong", "Submit", "Welcome to our platform"), inconsistent (Log in /
Sign in / Login on three screens) or invented ("Trusted by 10,000+ teams"). This skill
sets the rules for writing English copy; `deslop-en` is the editing pass that follows.

For Czech copy use `ux-writing-cs`. If a product has both languages, use each skill for
its own strings.

## Process

1. **Understand the moment:** who is reading, what they are trying to do right now, what they already know, and what happens next.
2. **Collect the facts:** real product name, real limits, real deadlines, real numbers. **Never invent** facts, numbers, prices, deadlines, guarantees or testimonials — use a visible placeholder `[TODO: real number]` instead.
3. **Write** following the rules below.
4. **Check consistency** against the glossary (section 10).
5. **Run `deslop-en`** on everything you wrote.
6. **Report** changed strings in the output format at the end of this file.

---

## 1. Core principles

- **Clear before clever.** No puns or jokes in errors, forms or anything with consequences.
- **Specific before generic.** "Your order was placed" beats "Success!".
- **Front-load the key word.** "Invoice sent" not "The invoice has now been successfully sent".
- **One idea per sentence.** UI sentences ≤ 20 words, marketing sentences ≤ 25 words.
- **The user's words, not the database's.** "Order", not "transaction entity" or "record".
- **Active voice, "you" for the user, "we" for the product** — and keep it consistent.
- **Sentence case** for buttons, headings, menus, tabs and labels.
- **Digits for numbers** ("3 projects", not "three projects") — faster to scan.
- **Never blame the user.** "We couldn't find that page", not "You entered a wrong URL".

---

## 2. Voice and tone

The **voice** is constant (who the product is). The **tone** changes with the situation.
Define the voice once in three "this, not that" pairs and store it in the project's
`CLAUDE.md` or `docs/voice.md`, e.g.:

| We are | We are not |
|--------|------------|
| Direct | Curt |
| Friendly | Goofy |
| Confident | Boastful |

Tone by situation:

| Situation | Tone | Example |
|-----------|------|---------|
| Success | Warm, brief | "Invoice sent. We'll let you know when it's paid." |
| Error | Calm, helpful, no jokes | "We couldn't save your changes. Check your connection and try again." |
| Destructive action | Serious, explicit | "Delete this project? Its 12 tasks will be deleted too. This can't be undone." |
| Onboarding | Encouraging, concrete | "Start by creating a project — you can invite your team later." |
| Empty state | Helpful, motivating | "No invoices yet. Create one and send it straight from here." |
| Waiting | Reassuring, honest | "Your export is being prepared. Large exports can take a few minutes." |

---

## 3. Buttons and links

- **Verb + object:** "Create project", "Send invoice", "Save changes".
  Not "OK", "Submit", "Yes", "Click here", "Go".
- **The button repeats the dialog's action:** "Delete project?" → [Cancel] [Delete project].
- **Link text names the destination:** "Read the pricing details", not "here" or "this link".
- **Length:** up to ~3 words / 25 characters for buttons.
- **Progress label:** "Saving…", "Sending…" (with the `…` character), and the button is disabled.
- **Menu items that open a dialog** end with `…` ("Rename…").
- **Same action, same word, everywhere.** Distinguish deliberately:
  - *Delete* = destroys it permanently. *Remove* = takes it out of a list, it still exists.
  - *Sign in / Sign out* or *Log in / Log out* — pick one pair for the whole product.
  - *Save* = keeps changes. *Submit* / *Send* = hands it over to someone else.

---

## 4. Forms

- **Labels:** short noun phrases, always visible ("Company name", "Email").
- **Hints** below the label explain format and limits **before** the user makes an error:
  "3–32 characters: letters, digits, hyphens."
- **Placeholders** show an example only ("e.g. acme-studio") — never instructions, never a label replacement.
- **Optional fields** are marked "(optional)" when most fields are required; don't rely on asterisks alone.
- **Explain sensitive questions:** "We ask for your phone number only to send delivery updates."
- **Checkboxes** are positive statements: "Email me product updates", not "Don't not email me".
- **Group** long forms into sections with headings that say what the section is for ("Billing details", "Delivery").

---

## 5. Error messages

**Formula:** what happened + (why, if it helps) + what to do next.
No error codes alone, no blame, no "Oops!", no "Error:" prefix, no ALL CAPS, no exclamation marks.

| ❌ Generic | ✅ Specific |
|-----------|------------|
| Invalid input | Use 3–32 letters, digits or hyphens. |
| Field required | Enter your company name. |
| Error 500 / Something went wrong | We couldn't place your order. Nothing was charged — try again in a minute. |
| Unauthorized | Your session has expired. Sign in again to continue. |
| Forbidden | Only workspace admins can change billing. |
| Not found | We couldn't find this project. It may have been deleted. |
| Conflict | A project with this name already exists. Choose another name. |
| File too large | This file is 8 MB. Upload a file up to 5 MB. |
| Unsupported file | Upload a PNG, JPG or WebP image. |
| Rate limit exceeded | You've requested 5 codes in the last hour. Try again after 2:30 PM. |
| Network error | You're offline. We'll retry when your connection is back. |

Rules:
- If you show a generic server error, add the next step and a reference: "If it keeps happening, contact support and mention code `req-7f3a`."
- **Don't leak security details** (consistent with `backend-security-auditor`): "Wrong email or password", not "No account uses this email".
- Field errors sit under the field and repeat what the hint asked for; the form-level summary links to the fields.
- Never show raw exceptions, stack traces or library messages (`ZodError`, `ECONNREFUSED`).

---

## 6. Empty states

Headline (what is missing) + one sentence (why it matters or what to do) + one action.
Use the three variants from `frontend-design-guide`:

| Variant | Headline | Body | Action |
|---------|----------|------|--------|
| First use | "No projects yet" | "Projects keep your tasks, files and people in one place." | "Create project" |
| No results | "No invoices match "Overdue"" | "Try another filter or clear the filters." | "Clear filters" |
| No access | "Billing is managed by your admin" | "Ask a workspace admin to give you access." | "See who's an admin" |

---

## 7. Confirmation dialogs and destructive actions

- **Title** is a question with the object: "Delete this project?"
- **Body** states concrete consequences: "The project and its 12 tasks will be deleted permanently. This can't be undone."
- **Buttons:** [Cancel] [Delete project] — never "Yes / No", never "OK / Cancel".
- For very destructive actions (deleting a workspace or an account) use **type to confirm** with the resource name.
- Don't ask for confirmation of harmless, reversible actions — offer "Undo" instead.

---

## 8. Success messages, notifications and emails

- Confirm the **specific result** and the **next step**: "Order placed. We'll email you when it ships."
- Toasts: one sentence, optionally one action ("Undo", "View").
- Don't celebrate trivial actions ("🎉 Saved!"). Save excitement for real milestones.
- The final screen of a key flow (Peak-End rule in `ux-laws`) gets real copy: what happened, what's next, when, where to check the status.
- Emails and push notifications: the subject or first line states the result ("Your payment was received"), the body says what to do next. One primary link.

---

## 9. Landing page copy

- **Headline:** a specific outcome for a specific audience, ≤ 10 words.
- **Subheadline:** how it works, for whom, or the proof, ≤ 25 words.
- **Primary CTA:** verb + object ("Start free trial"); the secondary CTA is a lower commitment ("See pricing").
- **Benefits over features:** "Send an invoice in under a minute" beats "Advanced invoicing engine" — if the claim is true and measured.
- **Proof must be real:** real numbers, real quotes with permission, real logos. **Never invent** testimonials, user counts, ratings or partner logos.
- **Section headings say something:** "Get paid without chasing clients" — not "Features" or "Why choose us".
- **FAQ** answers real objections and questions from support, not marketing questions nobody asks.

Before / after:

> ❌ "Unlock the ultimate invoicing experience. Revolutionize how you get paid today!"
>
> ✅ "Invoices for freelancers who'd rather not chase payments. Send one in a minute, get reminders sent automatically."

---

## 10. Consistency: the glossary

Keep a glossary (in `CLAUDE.md` or `docs/glossary.md`) with the canonical term and the
synonyms you don't use. Check every new string against it.

| Use | Don't use |
|-----|-----------|
| project | workspace item, board, space (unless they are different things) |
| sign in / sign out | log in, login, log out |
| team member | user, seat, account (in user-facing copy) |
| delete | remove, erase, destroy (for permanent deletion) |
| allowlist / blocklist | whitelist / blacklist |

---

## 11. Mechanics

- **Sentence case** everywhere in UI; Title Case only for proper names.
- **Ellipsis character** `…`, not three dots.
- **Curly quotes** in UI text (“ ” and ’), straight quotes in code.
- **Dates and numbers** via `Intl.DateTimeFormat` / `Intl.NumberFormat` / `Intl.RelativeTimeFormat` — never hard-coded formats. Recent events relative ("2 hours ago") with the absolute date in a tooltip.
- **Units** with a non-breaking space ("5 MB").
- **Exclamation marks:** at most one per flow, only for real success.
- **Avoid** "simply", "just", "easy", "obviously" — they make struggling users feel bad.
- **Avoid directional and sensory instructions:** "Select *Save*", not "Click the green button on the right".
- **Alt text** describes the purpose of the image; decorative images get `alt=""`.
- **Inclusive language:** "they" for unknown people, no idioms that only work for one culture, no "guys" for a group.

---

## 12. Localization-safe strings

Even an English-only product should write strings that can be translated later. The
technical setup (routing, message files, formatting, CI checks) is in `i18n-setup`.

- **Never concatenate strings:** `"You have " + n + " projects"` breaks in languages with other plural rules. Use ICU MessageFormat (`next-intl`, `react-intl`, `i18next` with ICU):

  ```
  {count, plural,
    one {# project}
    other {# projects}
  }
  ```

- **Plural rules** come from `Intl.PluralRules`, not `n === 1 ? … : …`.
- **Leave room:** translated strings are often 20–35 % longer. Don't size buttons to the English text.
- **No text inside images.** No sentence split across components.
- **Give translators context:** a key like `projects.delete.confirmButton` plus a description, not a bare "Delete".

---

## Output format

```markdown
## Copy changes: app/projects

| Location | Before | After | Rule |
|----------|--------|-------|------|
| new-project-form.tsx:84 (button) | Submit | Create project | Buttons: verb + object |
| new-project-form.tsx:31 (error) | Invalid input | Use 3–32 letters, digits or hyphens. | Errors: say how to fix |
| page.tsx:12 (hero) | Unlock the ultimate experience | Invoices for freelancers who'd rather not chase payments. | Landing: specific outcome |

**Open TODOs:** `[TODO: real number]` in page.tsx:14 — needs a real figure from the team.
```

## Behavior rules

- Never invent facts, numbers, testimonials, prices, deadlines or guarantees. A visible `[TODO: …]` is always better than a plausible fake.
- Don't mix languages in one UI. Czech strings follow `ux-writing-cs`.
- If the project has an i18n layer, change strings there, not inline in components.
- After writing, always run `deslop-en`. For long-form docs, also the Vercel `writing-guidelines` skill (installed with `./install.sh --vercel`).
- Related skills: `ux-laws` (Recognition over Recall, Feedback Loops, Peak-End), `frontend-design-guide` (empty and error states), `backend-security-auditor` (error messages that don't leak information).
