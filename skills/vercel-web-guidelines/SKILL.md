---
name: vercel-web-guidelines
description: "Design audit following the Vercel Web Interface Guidelines (the web-design-guidelines skill from vercel-labs/agent-skills), extended with checks for consistent spacing, grid alignment and color contrast. Use always after generating or changing a page or component, and when the user asks to 'review my UI', 'audit design', 'check accessibility', or for an accessibility or best-practices check."
triggers:
  - "after generating a page / component"
  - "design audit / design review"
  - "review my UI / audit design / check accessibility"
  - "check spacing / alignment / contrast"
  - "check the site against best practices"
metadata:
  type: external-agent-skill
  author: "Vercel Labs"
  source: "https://github.com/vercel-labs/agent-skills"
  upstream-skill: "web-design-guidelines"
  guidelines: "https://github.com/vercel-labs/web-interface-guidelines"
  license: MIT
  wrapper-license: "MIT (claude-web-skills-toolkit)"
---

# Vercel Web Interface Guidelines — design audit

| | |
|---|---|
| **Author / Source** | [Vercel Labs](https://github.com/vercel-labs/agent-skills) — `vercel-labs/agent-skills` |
| **Upstream skill** | `web-design-guidelines` (+ recommended `react-best-practices`) |
| **Rules** | [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) |
| **License** | MIT · this wrapper skill: MIT |
| **Type** | External agent skill (installed via the `skills` CLI, no MCP server) |

## Installation

Interactive choice of skills and agents:

```bash
npx skills add vercel-labs/agent-skills
```

Non-interactively, only the recommended skills for Claude Code (same as `./install.sh --vercel --yes`):

```bash
npx skills add vercel-labs/agent-skills --skill web-design-guidelines react-best-practices --agent claude-code --yes
```

Other useful `skills` CLI options: `--list` (lists available skills), `--global` (installs
into the user directory instead of the project), `--copy` (copies instead of symlinking).

After installation the skills are in the project's `.claude/skills/`:

```
.claude/skills/
├── web-design-guidelines/
│   └── SKILL.md
└── react-best-practices/
    └── SKILL.md
```

## Configuration

The upstream skill downloads the **current** rules from GitHub on every audit. So that
Claude Code does not ask for permission on every run, allow the domain in the project's
`.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:raw.githubusercontent.com)"
    ]
  }
}
```

Rule source loaded by the skill:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

## Behavior rules — MUST

**After every generation or substantial change of a page**, run the design audit before
declaring the work done. The audit has two parts:

### Part 1 — Vercel Web Interface Guidelines
1. Invoke the `web-design-guidelines` skill on the changed files (e.g. `app/whitelist/apply/**/*.tsx`).
2. The skill loads the current rules and lists findings in the `file:line` format.
3. Do not evaluate findings selectively — fix all of those that concern the changed code.

### Part 2 — Extended toolkit checks

#### 2a. Consistent spacing
- [ ] All spacing comes from the Tailwind scale (4px step). Arbitrary values (`mt-[13px]`, `gap-[7px]`) are a bug unless justified.
- [ ] Same relationships = same spacing: all cards in a grid have the same `p-*`, all page sections the same vertical rhythm (`py-16 md:py-24`).
- [ ] Spacing inside a group < spacing between groups (law of proximity).
- [ ] No "magic" compensations (`-mt-1`, `relative top-[2px]`) instead of fixing the alignment.

A quick heuristic for finding suspicious values:

```bash
grep -rnE '\b-?(m|p|gap|space-[xy]|inset|top|left|right|bottom)[trblxy]?-\[[0-9.]+(px|rem)\]' app components --include='*.tsx'
```

#### 2b. Grid alignment
- [ ] All pages use the same container (`mx-auto max-w-6xl px-4 sm:px-6 lg:px-8`).
- [ ] Section content shares the same left guide; heading, text and buttons start on the same axis.
- [ ] Grids use a consistent `gap`, and columns stack predictably at breakpoints (`grid-cols-1 sm:grid-cols-2 lg:grid-cols-3`).
- [ ] Elements in a row are aligned to a common baseline or center (`items-center` / `items-baseline`), icons optically centered with text.
- [ ] No horizontal scrolling at a width of 360 px.

#### 2c. Color contrast
- [ ] Text ≥ 4.5 : 1, large text ≥ 3 : 1, UI element boundaries and meaningful icons ≥ 3 : 1 (WCAG 2.2 AA).
- [ ] Verified in **both light and dark** mode, including the `hover`, `disabled` and `placeholder` states.
- [ ] Text over an image or gradient has sufficient contrast at its worst point (overlay `bg-black/50`).
- [ ] Information is not conveyed by color alone.

Verifying contrast in the browser (requires the `chrome-devtools` skill): open the page,
run `take_snapshot`, and for disputed elements read the computed colors via `evaluate_script`;
alternatively run an `@axe-core/playwright` test (the `webapp-testing` skill).

## Output format

```markdown
## Design audit: app/whitelist/apply

### Web Interface Guidelines
app/whitelist/apply/form.tsx:42 - input without an `autocomplete` attribute
app/whitelist/apply/form.tsx:88 - button has no visible focus state

### Spacing
components/apply-card.tsx:12 - `mt-[13px]` off the scale → `mt-3`

### Grid alignment
app/whitelist/apply/page.tsx:20 - section without the shared container (24px vs. 32px inset)

### Contrast
app/whitelist/apply/page.tsx:31 - `text-muted-foreground` on `bg-muted` = 3.9 : 1 (< 4.5 : 1) in dark mode

**Fixed:** 5/5 · **Remaining:** 0
```

## Related skills

- `frontend-design-guide` — the rules the design is built against.
- `ux-laws` — psychological principles (Proximity, Visual Hierarchy, Fitts).
- `chrome-devtools` — runtime verification of contrast, layout and the console.
