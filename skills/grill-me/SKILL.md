---
name: grill-me
description: "Interviews the user in rounds about a loose idea, plan or decision until it is clear enough to commit to: maps the open decisions as a tree, asks every question whose prerequisites are already settled in one numbered round with a recommended answer for each, looks up facts itself instead of asking, and stops when nothing is left assumed. Stateless: writes no files; the result is a clearer idea and a short recap in the chat. Works on any subject — a feature, a product direction, a business call, a piece of writing. Use when the user says 'grill me', asks to stress-test, challenge or poke holes in an idea, or has a vague idea they can't decide on. To also record terms and decisions in the repo use /grill-with-docs; when the answers are in someone else's head use /to-questionnaire; for a stack choice use tech-stack-advisor; to design a feature that is ready to build use the superpowers brainstorming flow, if installed."
argument-hint: "[idea, plan or decision]"
triggers:
  - "grill me / stress-test my idea / poke holes in this"
  - "I have an idea but I'm not sure / help me decide"
  - "challenge my plan before I commit"
  - "vyzpovídej mě / rozeber mi ten nápad"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  based-on: "grilling and grill-me from mattpocock/skills (MIT) — see NOTICE.md"
---

# Grill me

An idea you can't commit to is usually a handful of decisions you haven't noticed you are
making. This skill finds them and puts them to the user in an order that never asks
something that depends on an answer not given yet. It needs no repository and writes no
files: the result is a clearer idea in the user's head and a short recap in the chat.

## Method

1. **Restate the idea** in one or two sentences, and what "ready to commit" means here. If the scope is too big for one session (a whole product, a migration), propose splitting it first and grill one part.
2. **Map the decision tree.** Every decision branches into the decisions that hang off it. Keep the tree in the conversation, not in a file.
3. **Ask in rounds.** The **frontier** is every open decision whose prerequisites are settled. Ask the whole frontier in one round — numbered, each with your recommended answer — then wait. A question whose answer depends on another question in the same round belongs to a later round.
4. **Recompute after each round.** Settled decisions push the frontier outward: new questions appear, others disappear. Ask the next round.
5. **Stop when the frontier is empty** — every branch visited, nothing silently assumed — and end with the recap (below). Don't act on the result until the user confirms it.

## Round format

```markdown
❓ **Q1 – Who is the first version for?** Existing customers only, or open sign-up?
Open sign-up adds abuse protection, pricing and onboarding to the scope.

➡️ Existing customers only — it halves the scope and you already know them.

---

❓ **Q2 – …**
```

- **Word each question so that "yes" accepts your recommendation**; list the options when there are several real ones.
- **Recommend honestly:** your best judgment with a one-line reason, not the easiest option.
- **Number continuously across rounds** (Q1–Q6, then Q7–Q11), so answers like "7 no, 8 yes" are unambiguous.
- Ask in the user's language. Rounds, not one question at a time — unless the user asks for one at a time.

## Facts are your job, decisions are the user's

- **Never ask for what you can look up:** the repository, configuration, documentation, current versions or prices. Read it yourself; for broad searches use a sub-agent so the conversation stays focused.
- **Don't block the round on a lookup:** only the questions that depend on it wait; ask the rest now.
- **Decisions belong to the user** — scope, priorities, trade-offs, taste, risk. Put each one to them and wait.

## Keep it honest

- **Passivity check:** if the user has accepted every recommendation for two rounds, say so and ask which decisions they actually care about. A plan they only nodded at is your plan, not theirs.
- **"I don't know" is an answer.** Record it as an open risk, or as a question for someone who knows (`/to-questionnaire`) — don't turn it into a guess.
- **Ungrillable questions** — "how should this feel?", "one long form or three steps?" — can't be settled by talking. Stop asking, suggest a quick throwaway prototype or mockup, and come back for a one-line answer.
- **Scope drift:** when answers keep adding scope, name it and ask whether it belongs to this idea or a later one.
- **Contradictions:** when an answer conflicts with an earlier one or with a fact you found, point it out and ask which is right.

## Ending

When the frontier is empty, write the recap in the chat — no file:

```markdown
## Where we landed
**The idea in one sentence:** …
**Decisions:** 1. … 2. … 3. …
**Deliberately out of scope:** …
**Open risks and unknowns:** … (and who could answer them)
**Next step:** …
```

Ask whether it matches the user's understanding. Then, only if the user wants: record the
terms and hard decisions in the repo (`/grill-with-docs`), ask someone else
(`/to-questionnaire`), or build — with the superpowers plugin installed, its brainstorming
and planning flow turns the settled idea into a spec. Hand over the recap; don't re-ask what
is already settled.

## Rules

- Stateless: no files, no branches, no code during the session.
- Don't start implementing until the user confirms the recap.
- Stack choices go to `tech-stack-advisor`, which has its own questions and scoring; a UI design brief goes to Impeccable `shape` (`impeccable-workflow`).

## Related skills

- `grill-with-docs` — the same interview with a glossary and ADRs written into the repo.
- `to-questionnaire` — when the answers are in someone else's head.
- `tech-stack-advisor`, `impeccable-workflow` — specialised interviews for the stack and for design.

*Method adapted from `grilling` and `grill-me` in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — see `NOTICE.md`.*
