---
name: impeccable-workflow
description: "How to use Impeccable (Paul Bakaus' design skill with /impeccable commands such as init, shape, craft, critique, audit, polish, bolder, quieter, typeset, layout, colorize, animate, delight) inside this toolkit: installation, which command to run at which stage of a project, how PRODUCT.md and DESIGN.md relate to the toolkit's skills, and which rules win when Impeccable's suggestions and the toolkit's hard requirements (accessibility, performance, security, stack) disagree. Use when starting the design of a new project or surface, when a design looks generic or 'not quite there', before handing off UI work, or when the user mentions Impeccable or its commands. The commands themselves come from the separately installed impeccable skill."
triggers:
  - "Impeccable / /impeccable <command>"
  - "the design is not perfect yet / looks generic / looks like AI"
  - "polish / critique / audit the design"
  - "make it bolder / quieter / more delightful"
  - "start the design of a new project or page"
metadata:
  type: external-agent-skill
  author: "Paul Bakaus"
  source: "https://github.com/pbakaus/impeccable"
  website: "https://impeccable.style"
  license: Apache-2.0
  wrapper-license: "MIT (claude-web-skills-toolkit)"
---

# Impeccable — design workflow

| | |
|---|---|
| **Author / Source** | [Paul Bakaus](https://github.com/pbakaus/impeccable) — [impeccable.style](https://impeccable.style) |
| **License** | Apache-2.0 · this wrapper skill: MIT |
| **Type** | External agent skill (`impeccable`) + project hooks + a local engine |
| **What it adds** | a design vocabulary of `/impeccable` commands, a project setup (`PRODUCT.md`, `DESIGN.md`), deterministic anti-pattern detection, live browser iteration |

Impeccable started from Anthropic's `frontend-design` skill and goes further: it records
the product context once, gives the agent precise commands for design work, and detects
typical AI-design tells automatically. This wrapper tells Claude **when** to use which
command in a toolkit project and how its output fits the toolkit's rules.

## Installation

```bash
npx impeccable install
```

Non-interactively for Claude Code in the current project (what `./install.sh --impeccable --yes` runs):

```bash
npx impeccable install --providers=claude --scope=project
```

Alternatives: the Claude Code plugin marketplace (`/plugin marketplace add pbakaus/impeccable`,
then install it from `/plugin`), or copying the Claude Code files from the repository. Update
with `npx impeccable update`. Check the upstream README for the current options.

**Before installing, know what it does:** the installer adds the `impeccable` skill and a
project hook for Claude Code, and the skill's launcher runs a self-contained engine binary
that is downloaded on first use into `~/.impeccable/bin/`. Review it like any other tool
that runs code on your machine (`frontend-security` — supply chain).

**Git:** Impeccable writes working files to `.impeccable/`. Shared artifacts (e.g. config,
design data, critiques) are meant to be committed, the rest (screenshots, live-mode state,
caches, per-developer config) not — copy the ignore block from the upstream README into the
project's `.gitignore`.

Then, inside Claude Code:

```text
/impeccable init
```

## Commands by project stage

All commands run through `/impeccable <command> [target]`; `/impeccable` alone lists the
current set. The upstream list evolves — the stages below map the main ones.

| Stage | Commands | Toolkit skills that set the constraints |
|-------|----------|-----------------------------------------|
| **Project start** | `init` (writes `PRODUCT.md`), `document` (writes `DESIGN.md` from existing code) | `tech-stack-advisor` (stack first), `frontend-design-guide` (tokens and stack) |
| **New page or surface** | `shape` (plan before code), `craft` (shape and build with visual iteration) | `landing-page` (sections), `component-registries` (patterns and components), `shadcn-ui` (primitives) |
| **Visual direction** | `typeset`, `layout`, `colorize`, `bolder`, `quieter`, `distill` | `frontend-design-guide` (tokens, Tailwind, shadcn) |
| **Motion and delight** | `animate`, `delight`, `overdrive` | `magic-animations` (motion performance and reduced motion), `web-performance` (budgets) |
| **Copy** | `clarify` | `ux-writing-en` / `ux-writing-cs`, then `deslop-en` / `deslop-cs` |
| **Robustness** | `harden`, `onboard`, `adapt` | `i18n-setup`, `frontend-design-guide` (states), `pwa-mobile` |
| **Review before handoff** | `critique` (UX review), `audit` (technical checks), `polish` (final pass) | `a11y-auditor`, `web-performance`, `ux-laws`, `vercel-web-guidelines` |
| **Iterate in the browser** | `live`, `generate` | `chrome-devtools` |

Recommended default loop for every new page:

1. `/impeccable shape <page>` — agree on the plan with the user.
2. Build it with the toolkit's stack (`frontend-design-guide`, `shadcn-ui`, `component-registries`).
3. `/impeccable critique <page>` and `/impeccable audit <page>` — fix what they find.
4. Run the toolkit's hard checks: `a11y-auditor`, `web-performance` budgets, `vercel-web-guidelines`.
5. `/impeccable polish <page>` — the final pass.

## Which rules win

| Topic | Source of truth |
|-------|-----------------|
| Product context, audience, voice | Impeccable `PRODUCT.md` |
| Visual direction of the project | Impeccable `DESIGN.md` — record the aesthetic direction required by `frontend-design-guide` there |
| Stack and implementation (Tailwind tokens, shadcn/ui, Lucide, file structure) | `frontend-design-guide`, `shadcn-ui` |
| Accessibility thresholds | `a11y-auditor` |
| Performance targets and budgets | `web-performance` |
| Security, privacy, consent | `backend-security-auditor`, `frontend-security`, `gdpr-privacy` |
| Copy | `ux-writing-*` / `deslop-*` |

- When an Impeccable suggestion conflicts with a hard requirement (contrast, focus visibility, reduced motion, a performance budget, a security rule), **the hard requirement wins** — find a design that satisfies both and say so.
- Purely aesthetic disagreements (a font, an accent color, density) follow `DESIGN.md` and the user's choice.
- Write the decisions into `DESIGN.md`, not only into the conversation, so later commands and other skills see them.

## Notes

- **Anthropic's `frontend-design` plugin:** Impeccable grew out of it. With Impeccable installed you can keep both, but if their guidance pulls in different directions, disable the plugin for the project (`enabledPlugins` in `.claude/settings.json`).
- **Hooks:** Impeccable's design hook and the toolkit's guard hook (`./install.sh --hooks`) run side by side; they check different things.
- **Pinned shortcuts:** `/impeccable pin audit` creates `/audit`; avoid pinning names that clash with other skills or built-in commands.

## Output format

When reporting design work, list what was run and what changed:

```markdown
## Design pass: /pricing

| Step | Result |
|------|--------|
| `/impeccable shape pricing` | plan agreed: comparison-led page, usage slider, one highlighted plan |
| Build | registry components: `@magicui/number-ticker`, shadcn `tabs`, `table` |
| `/impeccable critique pricing` | 4 findings — hierarchy of plan names, weak CTA contrast, FAQ too long, no annual savings shown |
| `/impeccable audit pricing` | 2 findings fixed (focus ring on toggle, layout shift from fonts) |
| Toolkit checks | a11y-auditor ✅ · web-performance ✅ (LCP 1.9 s lab) · vercel-web-guidelines ✅ |
| `/impeccable polish pricing` | spacing rhythm, icon alignment, final copy pass |

**Recorded in DESIGN.md:** accent usage rule, number formatting, pricing card density.
```

## Related skills

- `frontend-design-guide`, `component-registries`, `shadcn-ui`, `magic-animations`, `landing-page`, `ux-laws`, `a11y-auditor`, `web-performance`, `ux-writing-en` / `ux-writing-cs`.
