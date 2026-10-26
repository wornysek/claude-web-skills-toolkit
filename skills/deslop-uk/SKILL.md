---
name: deslop-uk
description: "Editing pass that removes 'AI slop' from Ukrainian text (тексти українською): empty phrases and buzzwords ('У сучасному швидкоплинному світі', 'вивести на новий рівень', 'безшовний', 'варто зазначити'), calques from English ('зробити різницю', 'в кінці дня', 'не соромтеся'), Russianisms and surzhyk ('приймати участь', 'являється', 'на протязі'), bureaucratic style ('здійснити оплату', 'з метою', 'в рамках'), formulaic structures, broken euphony (у/в, і/й), typography and character problems (English quotes, Title Case, wrong apostrophes, Russian letters, Latin i instead of Cyrillic і) and invented specifics — keeping meaning, facts, links and code intact. Use on any Ukrainian prose you write or edit and whenever the user says 'deslop', 'звучить як ШІ', 'звучить як переклад', 'скороти' or 'перепиши природно'. For English, Czech or German text use deslop-en, deslop-cs or deslop-de instead."
triggers:
  - "deslop / /deslop-uk <файл>"
  - "звучить як ШІ / ChatGPT / як переклад"
  - "перепиши природно / по-людськи"
  - "скороти / відредагуй цей текст"
  - "перевір український README / документацію / анонс"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: uk
---

# Deslop (Ukrainian) — remove AI writing tells from Ukrainian text

This skill is the Ukrainian counterpart of `deslop-en`, `deslop-cs` and `deslop-de`. The
instructions are in English; the tells and examples are Ukrainian. Machine-written Ukrainian
has three layers of problems: the same empty marketing patterns as in English, phrases
**translated word for word from English**, and **Russianisms and surzhyk** that slip in when a
model's Ukrainian is weaker than its Russian. Add bureaucratic style and broken euphony, and
the text sounds like nobody wrote it.

The goal is text that is **specific, direct, true and sounds like it was written in Ukrainian**.

## When to use

- As the last step after writing any Ukrainian text (`ux-writing-uk` ends with this pass).
- When the user asks: `/deslop-uk README.uk.md`, «звучить як ШІ», «звучить як переклад».
- Before publishing Ukrainian web copy, documentation, emails or announcements.

## Process

1. **Read the whole text** and name its purpose and reader in one sentence.
2. **Scan for tells** from sections A–F (the grep helper below finds most word-level ones).
3. **Rewrite each finding** into the specific statement it stood for, or delete it. If a fact is missing, insert `[TODO: …]` — **never invent** numbers, names or references.
4. **Re-read for meaning and grammar:** no facts changed; *ви / ти* and the gender style are consistent; cases, euphony and the apostrophe are correct.
5. **Report** in the output format at the end of this file.

---

## A. Empty phrases and buzzwords

| Category | Tells | Replace with |
|----------|-------|--------------|
| Openers | «У сучасному швидкоплинному світі», «У сучасному цифровому світі», «Ласкаво просимо у світ …», «Давайте зануримося», «Зануримося в …», «Незалежно від того, чи ви … чи …», «Уявіть собі …» | Start with the point |
| Buzzwords | революційний, інноваційний, унікальний, безшовний, комплексний, надійне рішення, «ключовий» everywhere, «вивести на новий рівень», «гейм-чейнджер» | The concrete property or result |
| Unlock / discover | «Розкрийте весь потенціал», «Розблокуйте …», «Відкрийте для себе …» as a CTA | Say what the user gets or does: «Переглянути ціни» |
| Overused emphasis | «Варто зазначити, що …», «Важливо пам’ятати, що …», «відіграє ключову роль», «є невід’ємною частиною», «має вирішальне значення» | Delete, or say why it matters |
| Closers | «Підсумовуючи», «Отже, …» opening the last paragraph, «Сподіваюся, це допоможе!», «Не соромтеся звертатися» | End when the content ends; «Напишіть нам на …» |
| Fake enthusiasm | «Чудове запитання!», «Абсолютно!», «Раді повідомити, що …», exclamation marks | Neutral statement |
| Intensifiers | дійсно, справді, абсолютно, неймовірно, надзвичайно, безумовно | Delete, or use a number |
| Condescending | просто, легко, звичайно, очевидно | Delete |
| Stacked transitions | «Крім того», «Більше того», «Окрім цього», «Таким чином», «Варто також додати» in every paragraph | Usually delete |

## B. Calques from English

| ❌ Calque | ✅ Ukrainian |
|----------|-------------|
| «зробити різницю» (make a difference) | «змінити ситуацію», «мати значення» |
| «в кінці дня» (at the end of the day) | «зрештою», or delete |
| «адресувати проблему» | «розв’язати проблему», «взятися за проблему» |
| «Не соромтеся писати нам» (don't hesitate) | «Напишіть нам» |
| «Насолоджуйтесь …» (enjoy) | delete, or say what is ready |
| «Майте чудовий день!» | delete |
| «реалізувати» (= realize, notice) | «усвідомити», «зрозуміти» |
| «в 2026» | «у 2026 році» |
| «на щоденній основі» | «щодня» |
| «бути в курсі» everywhere | «знати», «стежити» |

## C. Russianisms and surzhyk

| ❌ | ✅ |
|----|----|
| приймати участь | брати участь |
| являється | є |
| слідуючий | наступний |
| на протязі | протягом |
| вибачаюсь | перепрошую, вибачте |
| на рахунок (= regarding) | щодо |
| в якості | як |
| співпадати | збігатися |
| міроприємство | захід |
| відмітити (= mark) | позначити |
| рахувати (= consider) | вважати |
| любий (= any) | будь-який |
| самий кращий | найкращий |
| получити | отримати |
| Добро пожалувати | Ласкаво просимо, Вітаємо |
| в рамках | у межах, під час |
| згідно наказу | згідно з наказом, відповідно до наказу |

## D. Bureaucratic style (канцелярит)

| ❌ Nominal / passive | ✅ Verb / active |
|---------------------|-----------------|
| «здійснити оплату» | «оплатити» |
| «провести перевірку» | «перевірити» |
| «надати інформацію» | «повідомити», «розповісти» |
| «з метою покращення» | «щоб покращити» |
| «у разі необхідності» | «якщо потрібно» |
| «у зв’язку з тим, що» | «бо», «оскільки» |
| «є можливість» | «можна» |
| «Звертаємо вашу увагу, що …» | state it directly |
| «Оплата здійснюється карткою.» | «Ви платите карткою.» |

## E. Structural, euphony and typography tells

- **Contrast framing:** «Йдеться не лише про X — йдеться про Y», «не тільки …, а й …» in every paragraph. State Y directly.
- **Rule of three:** «швидко, безпечно та надійно». Use the real number of items.
- **Dramatic reveals and rhetorical questions:** «Результат?», «Знайомо?», «І найкраще?»
- **Emoji bullets and headings**, a bolded lead-in on every bullet, recap conclusions.
- **Broken euphony:** «в Вашому акаунті», «файли і папки» after a vowel, «з списку» — follow the у/в, і/й, з/із/зі rules (`ux-writing-uk` section 12).
- **Em dashes:** the dash itself is normal Ukrainian punctuation — but one in every sentence is still a machine tell.
- **English typography and capitalization:**
  - English quotes "…" → «…»; Title Case Headings → sentence case;
  - decimal point «1.5» → «1,5»; dates «10/26/2026» → «26.10.2026»;
  - Oxford comma «A, B, і C» → «A, B і C».
- **Character problems:**
  - wrong or missing apostrophe: «пять», «мята», mixed `'` and `’`;
  - Russian letters in Ukrainian text: *ы, э, ъ, ё*;
  - Latin *i* in place of Cyrillic *і* (looks identical, breaks search);
  - «ua» used as a language code instead of «uk».
- **Inconsistent address:** *ви* and *ти* in the same text; random capitalized *Ви*.
- **Gender guesses:** «Ти увійшов», «Шановний користувачу» — prefer impersonal forms (`ux-writing-uk`).

## F. Content tells

- **Vague claims:** «підвищує вашу ефективність» → наскільки, як виміряно? If unknown: `[TODO: виміряне покращення]`.
- **Invented specifics:** made-up statistics, references, logos, user counts. **Never.**
- **«створений для того, щоб …»** instead of what it actually does.
- **Unearned superlatives:** «найкращий», «найпотужніший», «ультимативний».
- **Talking about the reader's feelings:** «Ми всі через це проходили», «Ви не самотні».

---

## Rewriting rules

- **Replace, don't just delete.** Each phrase stood in for a claim. Find it and write it.
- **Verbs over nouns**, active over passive, impersonal forms («збережено») instead of long passive constructions.
- **Keep the author's voice, terminology, form of address and gender style.** Don't add jokes or opinions.
- **Meaning is sacred:** facts, links, code, commands, numbers and quotes stay exactly as they were.
- **Context matters:** «надійний» about a bridge or «комплексні числа» in maths are terms, not slop; established loanwords («фідбек» in a casual product, «email») follow the project's glossary.
- **Never translate during deslop.** Ukrainian stays Ukrainian; other languages go to their own `deslop-*` skill.
- **Check grammar after rewriting:** cases, agreement with numbers, euphony, the apostrophe.

## Grep helper

Word-level tells (Cyrillic case folding depends on the grep locale, so both capitalizations are listed):

```bash
grep -rnE "([Уу] сучасному|[Зз]ануримося|[Вв]арто зазначити|[Вв]ажливо пам.ятати|на новий рівень|[Нн]е соромтеся|[Пп]ідсумовуючи|[Сс]подіваюся, це допоможе|відіграє ключову роль|невід.ємною частиною|безшовн|[Рр]озкрийте (весь )?потенціал|приймати участь|приймає участь|(^|[[:space:]«„(])являється|на протязі|слідуюч|міроприємств|в рамках|здійсн(ити|ює|юється) оплат|з метою)" --include="*.md" --include="*.mdx" --include="*.tsx" --include="*.json" .
```

(«являється» is matched only as a separate word — «з’являється» is correct Ukrainian.)

Character and typography problems in Ukrainian files:

```bash
grep -rnE "[ыэъёЫЭЪЁ]|\"[^\"]+\"|\b(пять|мята|сімя|обєкт)\b" --include="*.uk.md" --include="uk.json" .
```

The grep finds candidates, not verdicts — read each hit in context. Run it with a UTF-8
locale (`LC_ALL=C.UTF-8` or `en_US.UTF-8`) so the bracket expressions match Cyrillic letters.
The toolkit's optional hook (`./install.sh --hooks`) runs a word-level check automatically
after every edit.

## Examples

**Web copy**

> ❌ «У сучасному швидкоплинному світі безшовне та надійне рішення відіграє ключову роль. Виведіть свою команду на новий рівень!»
>
> ✅ «Спринти, завдання й блокери на одній дошці. Ви одразу бачите, хто над чим працює й хто на кого чекає. [TODO: одне реальне число з бета-тесту]»

**Announcement**

> ❌ «Раді повідомити, що в рамках останнього оновлення було здійснено низку покращень з метою оптимізації вашого досвіду.»
>
> ✅ «Нова версія швидше експортує великі проєкти, а CSV-файли тепер зберігають порядок стовпців.»

**UI text**

> ❌ «Ви успішно вийшли з системи. Не соромтеся повертатися будь-коли!»
>
> ✅ «Ви вийшли з акаунта. Увійти знову можна будь-коли.»

## Output format

For a single text, return the rewritten text followed by a short list of what changed.
For files:

```markdown
## Deslop: README.uk.md

| Line | Tell | Before | After |
|------|------|--------|-------|
| 3 | Empty phrase | «У сучасному швидкоплинному світі …» | (deleted, starts with the point) |
| 12 | Russianism | «приймати участь» | «брати участь» |
| 20 | Bureaucratic style | «здійснити оплату» | «оплатити» |
| 31 | Characters | «пять» (no apostrophe) | «п’ять» |

**Changed:** 9 · **Kept on purpose:** 1 («надійний» about infrastructure, line 44) · **Open TODOs:** 1
```

## Related skills

- `ux-writing-uk` — rules for writing Ukrainian UI and web copy in the first place.
- `deslop-en`, `deslop-cs`, `deslop-de` — the same pass for English, Czech and German text.
- `frontend-design-guide` — the visual counterpart (and Cyrillic font coverage).
