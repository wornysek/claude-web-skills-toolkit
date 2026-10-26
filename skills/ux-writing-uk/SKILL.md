---
name: ux-writing-uk
description: "Rules for writing Ukrainian UI copy and web copy (тексти українською) that is clear, specific and natural: buttons, form labels and hints, error messages, empty states, dialogs, success messages, emails and landing pages, plus Ukrainian-specific rules — ви vs. ти, feminitives and gender-neutral phrasing, the vocative case and other cases with inserted variables, impersonal -но/-то forms, four plural categories, euphony (у/в, і/й, з/із/зі), Russianisms and calques, Ukrainian typography, apostrophe and character hygiene, number/date/currency formats, Cyrillic font coverage, the uk language code and the state-language law for websites and apps. Use whenever the user-facing text you write or change is in Ukrainian. For English, Czech or German text use ux-writing-en, ux-writing-cs or ux-writing-de instead."
triggers:
  - "напиши / покращ тексти українською, мікрокопі"
  - "кнопка / повідомлення про помилку / порожній стан / діалог українською"
  - "лендинг українською / заголовок / CTA"
  - "ви чи ти / фемінітиви / відмінки / множина"
  - "Ukrainian UI copy / translate the UI to Ukrainian"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: uk
---

# UX Writing (Ukrainian) — microcopy and web copy in Ukrainian

This skill is the Ukrainian counterpart of `ux-writing-en`, `ux-writing-cs` and
`ux-writing-de`. The instructions are in English; all examples are Ukrainian. The general
principles are the same — clear before clever, specific before generic, never invent facts —
but Ukrainian adds its own problems: seven cases including the vocative, gendered past tense,
four plural forms, euphony rules, a strong risk of Russianisms and calques, and an apostrophe
that is part of words. `deslop-uk` is the editing pass that follows.

## Process

1. **Understand the moment:** who is reading, what they are trying to do, what happens next.
2. **Check the project's form of address and gender style** (sections 1–2). If they are not defined, ask once and record the answer in `CLAUDE.md` or the glossary.
3. **Collect the facts.** **Never invent** numbers, prices, deadlines, guarantees or references — use a visible `[TODO: реальне число]`.
4. **Write** following the rules below. Translate meaning, not words — the text must not read like a translation from English or Russian.
5. **Check grammar traps** (sections 3–4, 12–13): variables, plurals, euphony, Russianisms.
6. **Run `deslop-uk`** on everything you wrote.
7. **Report** changed strings in the output format at the end of this file.

---

## 1. Form of address: *ви* or *ти*

Choose **one** for the whole product and use it everywhere — UI, errors, emails, help pages.

| | *ви* (formal) | *ти* (informal) |
|---|---|---|
| Typical for | banking, public services, B2B, healthcare, most e-commerce | consumer apps, communities, young and informal brands |
| Instruction | «Введіть електронну пошту.» | «Введи електронну пошту.» |
| Possessive | «ваш акаунт» | «твій акаунт» |
| Question | «Зберегти зміни?» works for both — prefer forms without a pronoun | |

- In UI write *ви*, *ваш* in **lowercase**. The capitalized *Ви* is a courtesy form for personal letters and official correspondence; if the brand uses it, use it consistently.
- Buttons in the infinitive (section 5) and impersonal forms («Зміни збережено») work with both.
- Never mix *ви* and *ти* on one screen or in one flow.

## 2. Gender: feminitives and neutral phrasing

Ukrainian nouns for people and the past tense are gendered.

- **Prefer direct address and impersonal forms** — they avoid gender completely: «Ви ввійшли в акаунт» (plural past is neutral), «Зміни збережено», «Запрошення надіслано».
- **With *ти*, avoid the past tense** that reveals gender («Ти увійшов / увійшла») — use impersonal forms: «Вхід виконано», or the present: «Ти в акаунті».
- **Feminitives** are part of the 2019 orthography (*авторка, редакторка, керівниця, майстриня*). Use them when the person's gender is known (profile setting, the person's own choice) — not as a guess.
- For groups and roles in UI use neutral or collective words where possible: «команда», «учасники та учасниці» only where a pair form reads naturally, «особа» in forms.
- Decide the style once (feminitives yes/no in role names, pair forms or not) and record it in the glossary.

## 3. Inserted variables and cases

Ukrainian declines nouns in seven cases, including the **vocative** used for addressing a
person. Inserted values stay in the nominative, so build sentences where that is correct.

| ❌ Needs a declined variable | ✅ Variable stays in nominative |
|------------------------------|--------------------------------|
| «Вітаємо, {name}!» (needs the vocative: *Олено, Андрію*) | «Вітаємо!» / «Вітаємо в Acme!» |
| «Запрошення від {name}» (needs the genitive) | «{name} запрошує вас до проєкту {project}» / «Запрошення: {name}» |
| «{name} додав коментар» (gendered past tense) | «{name} додає коментар» / «Новий коментар: {name}» |
| «Доставимо в {city}» (needs the accusative/locative) | «Місто доставки: {city}» |
| «Профіль {name}» (genitive) | «Профіль: {name}» |

- Present tense and impersonal forms («Вас запрошено до проєкту {project}») are gender-neutral.
- Brand and product names keep their spelling; many foreign names are indeclinable anyway.

## 4. Plurals

`Intl.PluralRules("uk")` has four categories — and they differ from Czech:

| Category | Numbers | Example |
|----------|---------|---------|
| `one` | 1, 21, 31, 101 … (not 11) | 1 файл |
| `few` | 2–4, 22–24 … (not 12–14) | 2 файли |
| `many` | 0, 5–20, 25–30, 11–14 … | 5 файлів |
| `other` | fractions | 1,5 файла |

```
{count, plural,
  one {# файл}
  few {# файли}
  many {# файлів}
  other {# файла}
}
```

- Keep the whole phrase in each branch. Impersonal verbs make agreement easy: `{count, plural, one {Завантажено # файл} few {Завантажено # файли} many {Завантажено # файлів} other {Завантажено # файла}}`.
- Relative time comes from `Intl.RelativeTimeFormat("uk")` («5 хвилин тому») — don't build it by hand.
- Never `count === 1 ? … : …`, never concatenation (`i18n-setup`).

---

## 5. Buttons and links

- **Infinitive + object:** «Створити проєкт», «Зберегти зміни», «Спробувати безкоштовно». Not «ОК», «Надіслати» without context, «Так», «Натисніть тут».
- **The button repeats the dialog's action:** «Видалити проєкт?» → [Скасувати] [Видалити проєкт].
- **Link text names the destination:** «Переглянути ціни», not «тут» or «детальніше».
- **Progress label:** «Збереження…», «Надсилання…» — and the button is disabled.
- **Same action, same word:**
  - *видалити* = permanently; *прибрати зі списку* = the item still exists.
  - *увійти / вийти* (sign in / out), *зареєструватися* or *створити акаунт* (sign up) — not «залогінитися», «логін» as a verb.
  - *зберегти* = keeps changes; *надіслати* = hands something over.
  - **Upload vs. download:** «завантажити» is used for both and confuses people. Use «Додати файл» / «Вибрати файл» for uploads and «Завантажити» for downloads.

## 6. Forms

- **Labels:** short noun phrases: «Назва компанії», «Електронна пошта».
- **Hints** before errors happen: «Від 3 до 32 символів: літери, цифри та дефіси.»
- **Placeholders** only as examples: «наприклад, studio-acme».
- **Optional fields:** «(необов’язково)».
- **Explain sensitive questions:** «Номер телефону потрібен лише для повідомлень про доставку.»
- **Checkboxes** as positive statements: «Я хочу отримувати новини електронною поштою.»
- **Name fields:** accept apostrophes (all variants, section 11) and hyphens: «Мар’яна», «Олена-Марія».

## 7. Error messages

**Formula:** what happened + (why, if it helps) + what to do next. No codes alone, no blame,
no «Упс!», no «Помилка:» prefix, no capitals, no exclamation marks. Examples use *ви*.

| ❌ Generic | ✅ Specific |
|-----------|------------|
| Неправильне введення | Використайте від 3 до 32 літер, цифр або дефісів. |
| Обов’язкове поле | Введіть назву компанії. |
| Сталася помилка | Не вдалося оформити замовлення. Кошти не списано — спробуйте ще раз за хвилину. |
| Не авторизовано | Сеанс завершився. Увійдіть знову. |
| Доступ заборонено | Змінювати оплату можуть лише адміністратори робочого простору. |
| Не знайдено | Не вдалося знайти цей проєкт. Можливо, його видалено. |
| Конфлікт | Проєкт із такою назвою вже існує. Виберіть іншу назву. |
| Файл завеликий | Файл має 8 МБ. Додайте файл розміром до 5 МБ. |
| Непідтримуваний формат | Додайте зображення у форматі PNG, JPG або WebP. |
| Забагато запитів | За останню годину ви запросили 5 кодів. Спробуйте знову після 14:30. |
| Помилка мережі | Немає з’єднання з інтернетом. Щойно воно відновиться, ми спробуємо ще раз. |

- A generic server error gets a next step and a reference: «Якщо помилка повториться, напишіть у підтримку й укажіть код `req-7f3a`.»
- **Don't leak security details** (`backend-security-auditor`): «Неправильна електронна пошта або пароль.», not «Акаунта з такою поштою не існує.»

## 8. Empty states, dialogs, success messages, emails

Empty states (variants from `frontend-design-guide`):

| Variant | Headline | Body | Action |
|---------|----------|------|--------|
| First use | «Ще немає проєктів» | «У проєкті зібрані завдання, файли й команда.» | «Створити проєкт» |
| No results | «Немає рахунків за фільтром „Прострочені“» | «Змініть або скиньте фільтри.» | «Скинути фільтри» |
| No access | «Оплатою керує адміністратор» | «Попросіть адміністратора робочого простору надати доступ.» | «Показати адміністраторів» |

Confirmation dialogs:
- Title as a question with the object: «Видалити цей проєкт?»
- Body with concrete consequences: «Ми видалимо проєкт і всі 12 завдань у ньому. Цю дію не можна скасувати.»
- Buttons: [Скасувати] [Видалити проєкт] — never «Так / Ні»; instead of «Ви впевнені?» say what will happen.

Success messages and emails:
- Specific result + next step: «Замовлення прийнято. Щойно ми його надішлемо, ви отримаєте лист.»
- Toasts: one sentence, optionally one action («Скасувати», «Переглянути»).
- No celebration of trivial actions («🎉 Збережено!»).
- Email subject states the result: «Оплату отримано».

## 9. Landing page copy

- **Headline:** a specific outcome for a specific audience, up to ~10 words.
- **Subheadline:** how it works or the proof, up to ~25 words.
- **CTA:** infinitive + object: «Спробувати безкоштовно», «Переглянути ціни».
- **Proof must be real:** never invent references, user counts or ratings.

> ❌ «Розкрийте весь потенціал виставлення рахунків. Революція у способі отримання оплат!»
>
> ✅ «Рахунки для фрилансерів, які не хочуть нагадувати про оплату. Рахунок — за хвилину, нагадування надсилаються автоматично.»

## 10. Glossary

| Use | Don't use |
|-----|-----------|
| увійти / вийти | залогінитися, розлогінитися, «логін» as a verb |
| зареєструватися / створити акаунт | «сайнап», «реєстрація» as a button for signing up |
| акаунт (or обліковий запис — pick one) | both mixed |
| електронна пошта (or email — pick one) | імейл, мейл, мило |
| видалити (permanently) | прибрати, if deletion is meant |
| налаштування | настройки, сеттінги |
| проєкт (2019 orthography) | проект |
| Додати файл (upload) / Завантажити (download) | «завантажити» for both |
| список дозволених / список заблокованих | білий / чорний список |

---

## 11. Ukrainian typography and characters

- **Quotes:** «так», inner quotes „так“. Never English "quotes".
- **Dash:** a dash in a sentence is an em dash with spaces (« — ») — that is standard Ukrainian. Ranges use an en dash without spaces: «5–7 днів», «9:00–18:00».
- **Apostrophe** is part of words (*м’ята, п’ять, з’єднання*). Pick one character — `’` (U+2019) or `ʼ` (U+02BC) — and use it everywhere; **normalize all variants** (`'`, `’`, `ʼ`) in search, slugs and name validation.
- **Character hygiene:** no Russian letters (*ы, э, ъ, ё*) in Ukrainian text; no Latin *i* in place of Cyrillic *і* (homoglyphs break search and screen readers). Ukrainian letters *ґ, є, і, ї* must be there.
- **Fonts:** the chosen fonts must include **Cyrillic** with *ґ, є, і, ї* and the apostrophe — many trendy display fonts are Latin-only. With `next/font` add `subsets: ["cyrillic"]` (`frontend-design-guide`).
- **Numbers:** decimal comma «1,5»; thousands separated by a non-breaking space «1 234».
- **Currency:** `Intl.NumberFormat("uk-UA", { style: "currency", currency: "UAH" })` gives «1 234,50 ₴»; «грн» after the number («1 234,50 грн») is common too — pick one.
- **Dates and times:** «26.10.2026», long «26 жовтня 2026 р.» — month names in the genitive inside dates, nominative («жовтень») in calendar headers; `Intl.DateTimeFormat("uk-UA")` handles both. 24-hour time «14:30».
- **Percent and units:** follow `Intl` consistently («50%»); units with a non-breaking space «5 МБ».
- **Capitalization:** sentence case in headings and buttons; months and days of the week in lowercase.
- **No comma before *і / й / та*** in simple lists («A, B і C»).

## 12. Euphony (милозвучність)

Ukrainian alternates some words to avoid clusters of consonants or vowels. Wrong choices
read as machine-made.

| Pair | Rule of thumb | Examples |
|------|---------------|----------|
| *у / в* | *в* between vowels and after a vowel before a vowel or one consonant; *у* between consonants and at the start before a consonant | «Вона в Україні», «Він у Києві», «У вас 3 нові повідомлення» |
| *і / й* | *й* after a vowel before a consonant; *і* between consonants and before *й, є, ї, ю, я* | «файли й папки», «Тарас і Олена» |
| *з / із / зі* | *з* before vowels and most consonants; *із* between consonants; *зі* before *з, с, ш, щ* + consonant | «з Олегом», «вийшов із дому», «зі списку» |

## 13. Russianisms and calques

| ❌ | ✅ |
|----|----|
| приймати участь | брати участь |
| являється | є |
| слідуючий | наступний |
| на протязі | протягом |
| на рахунок | щодо |
| в якості | як |
| співпадати | збігатися |
| міроприємство | захід |
| відмітити (= mark) | позначити |
| Добро пожалувати | Ласкаво просимо / Вітаємо |
| в 2026 | у 2026 році |
| здійснити оплату | оплатити |
| з метою | щоб |

The full list of AI and translation tells is in `deslop-uk`.

## 14. Language code and law

- The language code is **`uk`** (`uk-UA`), not `ua` (that is the country). Use it in `<html lang>`, `hreflang`, message files and routes (`i18n-setup`, `seo-metadata`).
- Ukrainian text is often **20–30 % longer** than English — no fixed button widths.
- **State-language law** `[LEGAL: verify]`: websites, social media pages and app interfaces of businesses that sell goods and services to consumers in Ukraine must be available in Ukrainian; versions in other languages may exist but must not contain more information than the Ukrainian one, and the Ukrainian version is the default for users in Ukraine (Art. 27 of the Law on the State Language).

---

## Output format

```markdown
## Copy changes: app/projects

| Location | Before | After | Rule |
|----------|--------|-------|------|
| new-project-form.tsx:84 (button) | Надіслати | Створити проєкт | Buttons: infinitive + object |
| new-project-form.tsx:31 (error) | Неправильне введення | Використайте від 3 до 32 літер, цифр або дефісів. | Errors: say how to fix |
| header.tsx:12 | Вітаємо, {name}! | Вітаємо в Acme! | Variables: no vocative |
| upload.tsx:20 | Завантажити файл | Додати файл | Upload vs. download |

**Form of address:** ви · **Gender style:** impersonal forms + feminitives when known · **Open TODOs:** `[TODO: реальне число]` in page.tsx:14
```

## Behavior rules

- Never invent facts, numbers, references, prices or deadlines. A visible `[TODO: …]` beats a plausible fake.
- Keep the project's form of address and gender style; if they are not defined, ask once and record the answers.
- Don't mix Ukrainian with other languages in one UI; English strings follow `ux-writing-en`, Czech `ux-writing-cs`, German `ux-writing-de`.
- If the project has an i18n layer, change strings in the message files, with ICU plurals (`i18n-setup`).
- After writing, always run `deslop-uk`.
- Related skills: `ux-laws`, `frontend-design-guide` (Cyrillic fonts), `backend-security-auditor`, `a11y-auditor`, `i18n-setup`.
