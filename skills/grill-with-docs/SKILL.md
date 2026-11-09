---
name: grill-with-docs
description: "The grill-me interview plus a paper trail in the repository: while the user's plan or design is grilled, every resolved term goes straight into the project glossary (docs/glossary.md) and every hard-to-reverse, non-obvious decision with a real trade-off is offered as an ADR in docs/adr/. Reads the existing glossary, ADRs and code first and flags answers that contradict them. Writes nothing else: no spec, no notes, no recap file. Runs only when the user types /grill-with-docs; for an interview without files use grill-me."
argument-hint: "[plan, feature or design]"
disable-model-invocation: true
triggers:
  - "/grill-with-docs"
  - "grill me and record the decisions"
  - "build the glossary / write ADRs while we decide"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  based-on: "grill-with-docs and domain-modeling from mattpocock/skills (MIT) — see NOTICE.md"
---

# Grill with docs

The same interview as `grill-me`, but the answers that a future reader will need are
written down in the repository the moment they are settled: **terms** go into the glossary,
**hard decisions** go into ADRs. Everything else stays in the conversation.

## Setup

1. **Load `grill-me`** with the Skill tool and run its method — rounds, frontier, recommended answers, facts vs. decisions, recap. Its "stateless" rule is the one thing this skill overrides: it writes the two kinds of files below and nothing else.
2. **Read what exists:** `docs/glossary.md`, the titles of `docs/adr/*.md` (and any ADR the topic touches), `CLAUDE.md`, and the code the topic is about. The interview starts from them, not from zero.
3. Monorepo with separate domains: each app or package can have its own `docs/glossary.md` and `docs/adr/`; system-wide decisions go to the root. Say which one you are writing to; ask when the topic spans several.

## Added to the interview

- **Challenge against the glossary.** When the user uses a term differently from the glossary, say so at once: "The glossary defines *cancellation* as the whole order; you seem to mean one item. Which is it?"
- **Sharpen fuzzy words.** Overloaded words ("account", "user", "item", "status") get a precise term: "Do you mean the customer, who pays, or the member, who signs in?"
- **Test boundaries with concrete scenarios.** Invent edge cases that force a precise answer: "A customer cancels one item of an order that has already shipped partially — what happens?"
- **Cross-check with the code.** When the user says how something works, check whether the code agrees and point out a contradiction: "The code cancels whole orders, but you said partial cancellation is possible. Which is right — and is this a decision or a bug?"

## The glossary: `docs/glossary.md`

One glossary per project, shared with the UI wording from the `ux-writing-*` skills. This
skill writes the **Domain terms** section; the **UI wording** section belongs to the writing
skills. Create the file when the first term is resolved, not before.

```markdown
# Glossary

## Domain terms

**Order**:
A customer's request for one or more products, placed in one checkout.
_Avoid_: purchase, transaction

**Customer**:
The person or organization that pays for orders.
_Avoid_: client, account, user

## UI wording

| Use | Don't use |
|-----|-----------|
```

- **Write a term as soon as it is resolved**, in the same turn — never in a batch at the end.
- **Be opinionated:** one canonical term; the synonyms go under `_Avoid_`.
- **One or two sentences:** what the thing *is*, not what it does or how it is stored.
- **Only this project's concepts.** No general programming terms (timeout, cache, DTO), no implementation details, no decisions — the glossary is not a spec.
- Group terms under `###` subheadings once natural clusters appear.
- When a term changes meaning, update the definition and check where the old meaning is still used (code, UI wording, ADRs) — list what needs changing; don't rename code without asking.

## ADRs: `docs/adr/NNNN-slug.md`

Offer an ADR only when **all three** hold:

1. **Hard to reverse** — changing your mind later costs real time or money.
2. **Surprising without context** — a future reader would ask "why on earth did they do it this way?"
3. **A real trade-off** — there were genuine alternatives and one was chosen for specific reasons.

If one is missing, skip it: an easy decision gets reversed, an obvious one needs no
explanation. Typical candidates: the architectural shape, how parts of the system talk to
each other, technology with lock-in (database, auth provider, hosting region), what is
deliberately out of scope, deliberate deviations from the obvious path ("plain SQL instead
of an ORM because…"), constraints invisible in the code (compliance, a partner's SLA), and
alternatives rejected for non-obvious reasons.

**Offer it inside the next round** as a normal question ("❓ Record this as ADR 0004? ➡️ Yes —
it's a one-way door"), not as a separate interruption. Number it after the highest existing
file in the folder, four digits, short slug; create `docs/adr/` with the first ADR. The format
is the one `tech-stack-advisor` uses, kept short — a few sentences per section is a complete ADR:

```markdown
# ADR 0004: Orders are cancelled as a whole

- Status: accepted
- Date: YYYY-MM-DD

## Context
Why the decision was needed, in two or three sentences.

## Decision
What was decided, and the alternatives that were rejected and why.

## Consequences
What becomes easier or harder; what we must now do or never do.

## Revisit when
A concrete trigger, if there is one ("a customer needs partial refunds"). Otherwise omit.
```

A decision that reverses an earlier ADR gets a new ADR; the old one's status becomes
`superseded by ADR NNNN`.

## What is not written

No spec, design document, meeting notes, decision log or recap file. The recap stays in the
chat, as in `grill-me`. A design spec for implementation comes from the superpowers
brainstorming flow, if installed; a stack decision from `tech-stack-advisor`.

## Ending

The `grill-me` recap, followed by what changed on disk:

```markdown
**Written:** docs/glossary.md (+3 terms: Order, Customer, Fulfilment; changed: Cancellation) · docs/adr/0004-orders-cancelled-whole.md
**Contradictions found in the code:** OrderService allows partial cancellation (src/orders/service.ts:88) — decide: change the code or the decision.
```

Don't commit; the user reviews the files.

## Related skills

- `grill-me` — the interview this skill runs.
- `ux-writing-en` (`-cs`, `-de`, `-uk`) — the UI wording section of the same glossary.
- `tech-stack-advisor` — stack decisions and the full ADR for them.
- `to-questionnaire` — when an answer is in someone else's head.

*Adapted from `grill-with-docs` and `domain-modeling` in [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — see `NOTICE.md`.*
