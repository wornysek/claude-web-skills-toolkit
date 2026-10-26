---
name: deslop-en
description: "Editing pass that removes 'AI slop' from English text: buzzwords, filler, hedging, fake enthusiasm, formulaic structures (rule of three, 'it's not X, it's Y', em-dash overuse, emoji bullets, recap conclusions) and invented specifics, while keeping meaning, facts, links and code intact. Use on any English prose you write or edit — UI copy, landing pages, READMEs, docs, changelogs, PR descriptions, commit messages, emails, announcements — and whenever the user says 'deslop', 'it sounds like AI', 'make it sound human', 'tighten this' or 'rewrite this naturally'. For Czech or German text use deslop-cs or deslop-de instead."
triggers:
  - "deslop / /deslop-en <file>"
  - "it sounds like AI / ChatGPT"
  - "make it sound human / natural"
  - "tighten / shorten / edit this text"
  - "review README / docs / changelog / announcement / PR description"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  language: en
---

# Deslop (English) — remove AI writing tells

AI-generated text has recognizable tells: the same buzzwords, the same sentence shapes,
the same fake enthusiasm. Readers spot them in seconds and start trusting the content
less. This skill is an **editing pass**: find the tells, rewrite them into specific
statements, and verify that meaning and facts did not change.

The goal is not to sound casual. The goal is text that is **specific, direct and true**.

For Czech text use `deslop-cs`, for German `deslop-de`. In a mixed document, edit each part with the skill for its language.

## When to use

- As the last step after writing any English text (`ux-writing-en` ends with this pass).
- When the user asks: `/deslop-en README.md`, "this sounds like AI", "make it more human".
- Before committing a README, docs page, changelog or PR description.

## Process

1. **Read the whole text** and name its purpose and reader in one sentence.
2. **Scan for tells** from sections A–D (the grep helper below finds most word-level ones).
3. **Rewrite each finding:** replace the vague phrase with the specific claim it stood for, or delete it. If the specific fact is missing, insert `[TODO: …]` — **never invent** numbers, names or quotes.
4. **Re-read for meaning:** no facts added, removed or changed; technical terms, links, code, commands and numbers are exactly as before.
5. **Report** in the output format at the end of this file.

---

## A. Words and phrases

| Category | Tells | Replace with |
|----------|-------|--------------|
| Buzzwords | delve, leverage, utilize, seamless, robust, cutting-edge, state-of-the-art, game-changer, revolutionize, elevate, unlock, unleash, empower, supercharge, streamline, harness, holistic, synergy, best-in-class, world-class, next-level, transformative, innovative | The concrete action or property: *use*, *works without X*, *survives Y*, *takes 2 clicks instead of 5* |
| Grand nouns | landscape, realm, tapestry, testament, journey, ecosystem (when not literal), paradigm | Name the actual thing |
| Overused adjectives | pivotal, crucial, vital, essential, comprehensive, meticulous, intricate, nuanced, myriad, plethora | Delete, or state why it matters |
| Openers and filler | "In today's fast-paced world", "In the ever-evolving world of", "When it comes to", "It's worth noting that", "It's important to note", "Let's dive in", "Let's explore", "Whether you're a X or a Y", "Look no further", "At the end of the day" | Start with the point |
| Closers | "In conclusion", "In summary", "Overall,", "I hope this helps!", "Happy coding!", "Feel free to reach out" | End when the content ends |
| Fake enthusiasm | "Great question!", "Absolutely!", "Exciting news!", exclamation marks | Neutral statement |
| Hedging stacks | "may potentially", "could possibly", "it seems that it might", "arguably" | One honest qualifier, or none |
| Intensifiers | very, really, truly, incredibly, extremely, highly, deeply, absolutely | Delete, or use a number |
| Condescending | simply, just, easily, obviously, of course | Delete |
| Stacked transitions | Furthermore, Moreover, Additionally, Notably, Importantly, Ultimately | Usually delete; the order already shows the logic |
| Wordy | in order to, a wide range of, a variety of, due to the fact that, is able to | to, (name them), (name them), because, can |

## B. Structural tells

- **Rule of three everywhere:** "fast, secure, and scalable". Use the real number of items — two or four are fine.
- **Contrast framing:** "It's not just X, it's Y", "This isn't about X — it's about Y", "not only… but also". State Y directly.
- **Em-dash overuse:** more than about one per paragraph. Use commas, periods or parentheses.
- **Dramatic reveals:** "The result? …", "Here's the thing:", "The best part?". Just say it.
- **Rhetorical questions** opening sections ("Tired of slow deploys?").
- **Bolded lead-in on every bullet** ("**Speed:** …") for short or simple lists.
- **Emoji bullets and emoji headings** (🚀 ✨ 💡 🔥 ✅ on every line).
- **Over-structuring:** headings for a three-paragraph text, bullets for what is really a narrative.
- **Uniform rhythm:** every paragraph is claim → elaboration → summary, every sentence the same length. Vary it; short sentences are allowed.
- **Recap conclusions** repeating the introduction.
- **Signposting:** "In this article we will…", "As mentioned above", "Let's take a look at".
- **Unrequested symmetry:** Pros/Cons, Before/After, Do/Don't tables when one sentence would do.
- **Title Case Headings** in products or docs that use sentence case.

## C. Content tells

- **Vague claims:** "improves performance" → by how much, measured how? If unknown: `[TODO: measured improvement]`.
- **Invented specifics:** fake statistics ("98% of users"), fake testimonials, fake customer logos, fake dates. **Never.** Use real data or a TODO.
- **Placeholder people and companies** (John Doe, Acme) in user-facing copy. Fine in code samples.
- **"Designed to" / "aims to"** instead of what it actually does.
- **Unearned superlatives:** the best, the most powerful, the ultimate.
- **Talking about the reader's feelings:** "We've all been there", "You're not alone".
- **Feature lists without a benefit**, or benefits without the mechanism behind them.

## D. Technical writing tells

- **README:** a wall of badges, an emoji per heading, "✨ Features" with 12 bullets, "PRs welcome! 🙌". Lead with what it does and how to run it.
- **Commit messages:** "This commit updates…", "Enhanced various things", bullet lists for a one-line change. Use the imperative, say what and why: `fix(auth): verify OAuth state before exchanging the code`.
- **PR descriptions:** restating the diff file by file, "This PR aims to…". Say what changed for the user, why, how it was tested, and the risk.
- **Code comments** narrating the obvious (`// loop through the array`). Comment the *why*, not the *what*.
- **Changelogs:** "Various improvements and bug fixes". List what users will notice.

---

## Rewriting rules

- **Replace, don't just delete.** Each buzzword stood in for a claim. Find the claim and write it.
- **Concrete nouns and verbs**, numbers with units, names of real things.
- **Keep the author's voice and terminology.** Don't over-casualize, don't add jokes, don't add new opinions.
- **Meaning is sacred:** facts, links, code, commands, numbers and quoted text stay exactly as they were.
- **Context matters:** a "robust estimator" in statistics or a "seamless" texture in graphics is a term, not slop. Flag patterns, not isolated legitimate uses.
- **Never translate during deslop.** English stays English.
- **Shorter is usually better, but not always:** don't cut steps a reader actually needs.

## Grep helper

Word-level tells:

```bash
grep -rniE "\b(delve|leverag|utiliz|seamless|robust|cutting-edge|game.?changer|revolutioni[sz]|elevat|unlock|unleash|empower|supercharg|streamlin|harness|holistic|synerg|next-level|transformative|tapestry|testament|myriad|plethora|in today.s|it.s worth noting|let.s dive)\w*" --include="*.md" --include="*.mdx" --include="*.tsx" --include="*.json" .
```

Em dashes per file (more than one per paragraph is a smell):

```bash
grep -c "—" README.md
```

The grep finds candidates, not verdicts — read each hit in context. The toolkit's
optional hook (`./install.sh --hooks`) runs a similar check automatically after every edit.

## Examples

**Landing page**

> ❌ "🚀 Unlock the full potential of your team! Our cutting-edge, seamless platform empowers you to effortlessly streamline your workflow — it's not just a tool, it's a game-changer."
>
> ✅ "Plan sprints, track tasks and see who's blocked — in one board your team will actually open. [TODO: one real metric from beta users]"

**PR description**

> ❌ "This PR aims to enhance the robustness of the authentication flow by leveraging best practices. Furthermore, it streamlines various aspects of the codebase."
>
> ✅ "The OAuth callback now rejects requests whose `state` doesn't match the cookie, which closes a login CSRF. Covered by a new E2E test (`auth.spec.ts`)."

**Release note**

> ❌ "Exciting news! We've meticulously crafted a myriad of improvements to elevate your experience."
>
> ✅ "Exports are now 3× faster for workspaces with more than 10,000 tasks, and CSV files keep your column order." — only with the numbers from the actual benchmark; otherwise `[TODO: measured speedup]`.

## Output format

For a single text, return the rewritten text followed by a short list of what changed.
For files:

```markdown
## Deslop: README.md

| Line | Tell | Before | After |
|------|------|--------|-------|
| 3 | Buzzword | "a seamless, robust toolkit" | "a toolkit that installs with one command" |
| 18 | Rule of three | "fast, secure, and scalable" | "secure by default" |
| 40 | Emoji headings | "## ✨ Features" | "## What's inside" |

**Changed:** 12 · **Kept on purpose:** 1 ("robust" in a statistics context, line 77) · **Open TODOs:** 1
```

## Related skills

- `ux-writing-en` — rules for writing English UI and web copy in the first place.
- `deslop-cs`, `deslop-de` — the same pass for Czech and German text.
- Vercel `writing-guidelines` (installed with `./install.sh --vercel`) — a full review of documentation against Vercel's writing handbook.
- `frontend-design-guide` — the visual counterpart (no generic gradients, no emoji icons).
