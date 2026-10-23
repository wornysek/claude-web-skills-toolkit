# claude-web-skills-toolkit

**English** · [Čeština](README.cs.md)

> A standardized set of skills, official plugins, MCP servers and audit rules for
> **Claude Code** and other AI agents. One command, and your agent writes web code that is
> **secure, usable and doesn't look like AI slop**.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Shell](https://img.shields.io/badge/install-bash-blue)
![Claude Code](https://img.shields.io/badge/Claude%20Code-skills%20%2B%20MCP-orange)

```bash
git clone https://github.com/wornysek/claude-web-skills-toolkit.git ~/claude-web-skills-toolkit
cd ~/my-project
bash ~/claude-web-skills-toolkit/install.sh --all
```

---

## Contents

- [Why this toolkit](#why-this-toolkit)
- [What's inside](#whats-inside)
- [Skills and tools](#skills-and-tools)
- [Installation](#installation)
- [Integrating into an existing project](#integrating-into-an-existing-project)
- [How skills work](#how-skills-work)
- [Slop & secrets guard hook](#slop--secrets-guard-hook)
- [Toolkit security](#toolkit-security)
- [Updating and uninstalling](#updating-and-uninstalling)
- [Contributing](#contributing)
- [License and attribution](#license-and-attribution)

---

## Why this toolkit

AI agents can now generate a working web application in minutes. Without rules, though,
they keep producing the same kinds of problems:

| Problem | What it looks like | What the toolkit does about it |
|---------|--------------------|--------------------------------|
| **AI slop in design** | Purple-to-pink gradients, Inter everywhere, everything centered, emoji instead of icons, no loading/empty states, components written from scratch | `frontend-design-guide` bans generic patterns and enforces design tokens, skeletons and empty states. `shadcn-ui` makes the agent take components from the registry. The official `frontend-design` plugin provides an aesthetic direction. `magic-animations` adds deliberate, performance-aware animations. |
| **Insecure code** | Tokens in `localStorage`, missing ownership checks (IDOR), `req.body` written straight to the DB, OAuth without `state`, webhooks without signature verification, stack traces in production, API keys pasted into source files | `backend-security-auditor` contains strict MUST rules for auth, IDOR, validation, the database, API responses, headers and production, including ready-made secure code patterns and a final "Security Gate". The optional guard hook blocks secrets before they are written to a file. |
| **Ignored UX** | Four equally prominent buttons, tiny touch targets, no feedback after a click, a form that loses its data after an error | `ux-laws` turns 20 UX laws (Hick, Fitts, Doherty < 400 ms, Peak-End…) into verifiable *Implementation Checks*. `vercel-web-guidelines` runs an automated design audit (spacing, grid, contrast). |
| **AI slop in text** | "Unlock seamless synergy", "Something went wrong", "Submit", invented "10,000+ happy users", emoji headings, "it's not just X, it's Y" | `ux-writing-en` / `ux-writing-cs` set rules for buttons, errors, empty states, landing copy and localization; the Czech skill adds declension, plurals, *tykání / vykání* and typography. `deslop-en` / `deslop-cs` are the editing passes that remove AI writing tells without changing facts. The guard hook flags them automatically after every edit. <!-- guard:allow --> |
| **Invisible or non-compliant** | One title for the whole site, no social previews, indexable admin and staging pages, analytics firing before consent, no way to export data or delete an account | `seo-metadata` covers titles, canonicals, OG images, sitemap, robots, hreflang and JSON-LD. `gdpr-privacy` covers data minimization, consent without dark patterns, data subject rights, retention and PII in logs. |

Quality is also **verified at runtime**: `webapp-testing` generates and runs Playwright E2E
tests, `chrome-devtools` reads errors from a real browser console, `superpowers-debugging`
enforces a deterministic fix process that never masks errors, and the optional
[slop & secrets guard](#slop--secrets-guard-hook) checks every file Claude writes.

## What's inside

```
claude-web-skills-toolkit/
├── README.md                      # documentation in English
├── README.cs.md                   # documentation in Czech
├── LICENSE
├── .gitignore
├── .gitattributes                 # LF line endings for install.sh, even on Windows
├── install.sh                     # installer (interactive / --all)
├── hooks/
│   ├── slop-secrets-guard.sh      # Claude Code hook: blocks secrets, flags AI writing tells
│   └── settings.example.json      # hook registration for .claude/settings.json
└── skills/
    ├── ux-laws/                   # custom — 20 UX laws
    ├── backend-security-auditor/  # custom — backend security rules
    ├── frontend-design-guide/     # custom — anti-AI-slop UI rules
    ├── webapp-testing/            # custom — Playwright E2E
    ├── ux-writing-en/             # custom — English UI and web copy
    ├── ux-writing-cs/             # custom — Czech UI and web copy
    ├── deslop-en/                 # custom — removes AI writing tells (English)
    ├── deslop-cs/                 # custom — removes AI writing tells (Czech)
    ├── tech-stack-advisor/        # custom — choosing a stack, recorded as an ADR
    ├── i18n-setup/                # custom — multilingual apps: routing, messages, formatting
    ├── seo-metadata/              # custom — technical SEO and sharing metadata
    ├── gdpr-privacy/              # custom — GDPR and privacy engineering
    ├── shadcn-ui/                 # wrapper — shadcn MCP server
    ├── vercel-web-guidelines/     # wrapper — Vercel Labs agent skills
    ├── chrome-devtools/           # wrapper — Chrome DevTools MCP
    ├── magic-animations/          # wrapper — 21st.dev MCP
    └── superpowers-debugging/     # wrapper — superpowers plugin
```

**Custom skills** contain the complete rule set. **Wrapper skills** for external tools
contain the source, author, license, exact installation steps, JSON configuration and,
most importantly, **behavior rules**: when and how Claude should use the tool. The external
tool itself (plugin, MCP server) is installed with `install.sh` or manually.

## Skills and tools

| Skill / tool | Type | Original author · license | Manual installation | When to use (triggers) |
|--------------|------|---------------------------|---------------------|------------------------|
| [`ux-laws`](skills/ux-laws/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT (inspired by *Laws of UX*, Jon Yablonski) | `cp -R skills/ux-laws .claude/skills/` | UI design or review, forms, navigation, onboarding, "UX audit", low conversion |
| [`backend-security-auditor`](skills/backend-security-auditor/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/backend-security-auditor .claude/skills/` | API endpoint, server action, OAuth/OIDC sign-in, passwords, sessions, admin routes, user-generated content, upload, webhook, "is this secure?" |
| [`frontend-design-guide`](skills/frontend-design-guide/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/frontend-design-guide .claude/skills/` | New page/component, "make it look better", fonts, colors, skeleton, empty state |
| [`webapp-testing`](skills/webapp-testing/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/webapp-testing .claude/skills/` | "Test the form", E2E tests, validation, error messages, redirect after submission |
| [`ux-writing-en`](skills/ux-writing-en/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/ux-writing-en .claude/skills/` | Any English user-facing text: buttons, errors, empty states, landing page, onboarding, emails |
| [`ux-writing-cs`](skills/ux-writing-cs/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/ux-writing-cs .claude/skills/` | Any Czech user-facing text; *tykání / vykání*, declension, plurals, Czech typography |
| [`deslop-en`](skills/deslop-en/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/deslop-en .claude/skills/` | `/deslop-en <file>`, "it sounds like AI", READMEs, docs, PR descriptions, commit messages |
| [`deslop-cs`](skills/deslop-cs/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/deslop-cs .claude/skills/` | `/deslop-cs <file>`, Czech text that sounds like AI or like a translation |
| [`tech-stack-advisor`](skills/tech-stack-advisor/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/tech-stack-advisor .claude/skills/` | New project, "what should I use for…", comparing frameworks, databases, auth or hosting, migrations |
| [`i18n-setup`](skills/i18n-setup/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/i18n-setup .claude/skills/` | Adding a language, locale routing, message files, ICU plurals, formatting, language switcher, missing translations |
| [`seo-metadata`](skills/seo-metadata/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/seo-metadata .claude/skills/` | New public page, metadata, OG images, sitemap, robots, noindex, hreflang, JSON-LD |
| [`gdpr-privacy`](skills/gdpr-privacy/SKILL.md) | Custom Markdown skill | claude-web-skills-toolkit · MIT | `cp -R skills/gdpr-privacy .claude/skills/` | Sign-up, forms with personal data, cookies, analytics, consent, account export/deletion, logging |
| [Slop & secrets guard](hooks/slop-secrets-guard.sh) | Claude Code Hook | claude-web-skills-toolkit · MIT | `./install.sh --hooks` | Runs automatically on every Write/Edit: blocks secrets, reports AI writing tells |
| `frontend-design` (plugin) | Official Plugin | Anthropic (P. Rajasekaran, A. Bricken) · © Anthropic PBC, Commercial ToS | `claude plugin marketplace add anthropics/claude-code`<br>`claude plugin install frontend-design@claude-code-plugins` | Building frontends with a strong aesthetic direction; complements `frontend-design-guide` |
| [`superpowers-debugging`](skills/superpowers-debugging/SKILL.md) → `superpowers` | Official Plugin | Jesse Vincent (obra) · MIT · distributed via Anthropic's `claude-plugins-official` | `claude plugin install superpowers@claude-plugins-official` | Bug, failing test, exception, regression, "the fix didn't work" |
| [`shadcn-ui`](skills/shadcn-ui/SKILL.md) | External MCP Server | shadcn · MIT · recommended by Colton Dean | `npx shadcn@latest mcp init --client claude` | Form, button, dialog, menu, table, select, toast — any UI component |
| [`vercel-web-guidelines`](skills/vercel-web-guidelines/SKILL.md) | External Agent Skill | Vercel Labs · MIT | `npx skills add vercel-labs/agent-skills` | After generating a page; "review my UI", "audit design", spacing, grid, contrast |
| [`chrome-devtools`](skills/chrome-devtools/SKILL.md) | External MCP Server | Google Chrome DevTools team · Apache-2.0 | `claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest` | Page is broken, console errors, failed requests, screenshots, performance (LCP/CLS/INP) |
| [`magic-animations`](skills/magic-animations/SKILL.md) | External MCP Server | 21st.dev · ISC (magic-mcp) / MIT (CLI) · commercial service with an API key | `npx @21st-dev/cli@latest init --client claude --write`<br>or `claude mcp add --transport http --scope user 21st https://21st.dev/api/mcp --header "x-api-key: $API_KEY_21ST"` | Interactive hero sections, animated backgrounds, button animations, "bring the page to life" |

> **Note on 21st.dev:** upstream has replaced Magic MCP with the unified 21st MCP, and old
> API keys have been revoked. The previously documented command
> `npx @21st-dev/cli@latest install claude --api-key <YOUR_API_KEY>` has been replaced by
> `npx @21st-dev/cli@latest init --client claude`. Get a new key at https://21st.dev/mcp.

## Installation

### Requirements

| Tool | Why | Check |
|------|-----|-------|
| [Claude Code](https://claude.com/claude-code) | plugins, MCP server registration | `claude --version` |
| Node.js 20+ and `npx` | shadcn, Vercel skills, chrome-devtools-mcp | `node -v`, `npx -v` |
| Bash 3.2+ | `install.sh` and the guard hook (macOS, Linux, Git Bash or WSL on Windows) | `bash --version` |
| Google Chrome | Chrome DevTools MCP | — |
| Node.js or Python 3 | only for merging the hook into an existing `.claude/settings.json` | `node -v` / `python3 --version` |

`install.sh` checks that `claude` and `npx` are available and skips, with a clear message,
any component whose tool is missing.

### Running the installer

Run the script **from the root of the project** you are integrating the toolkit into —
project-level configuration (`.mcp.json`, `.claude/skills/`) is created in the current
working directory.

```bash
# 1. Clone the toolkit (once)
git clone https://github.com/wornysek/claude-web-skills-toolkit.git ~/claude-web-skills-toolkit

# 2. Go to your project
cd ~/projects/my-web-app

# 3a. Choose components interactively
bash ~/claude-web-skills-toolkit/install.sh

# 3b. Or install everything at once without prompts
bash ~/claude-web-skills-toolkit/install.sh --all
```

On macOS/Linux you can also run the script directly (`chmod +x install.sh && ./install.sh`).

### `install.sh` options

| Option | What it does |
|--------|--------------|
| *(no options)* | Interactive menu for choosing components |
| `--all` | Installs everything and answers YES to prompts (does not overwrite existing skills without `--force`) |
| `--plugins` | Adds the `anthropics/claude-code` marketplace and installs `frontend-design@claude-code-plugins` and `superpowers@claude-plugins-official` |
| `--chrome` | `claude mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest` |
| `--shadcn` | `npx shadcn@latest mcp init --client claude` (writes `.mcp.json` in the project) |
| `--vercel` | `npx skills add vercel-labs/agent-skills` (non-interactive: `web-design-guidelines`, `react-best-practices`, `writing-guidelines` for Claude Code) |
| `--magic` | Registers the 21st.dev MCP (key from `API_KEY_21ST`, otherwise a hidden prompt; skipped without a key) |
| `--mcp` | Shortcut for `--chrome --shadcn --magic` |
| `--skills` | Copies `skills/*` into `./.claude/skills/` |
| `--hooks` | Installs the slop & secrets guard into `./.claude/hooks/` and registers it in `./.claude/settings.json` (merged, with a `.bak` backup) |
| `--global` | With `--skills`: copies into `~/.claude/skills/` (available in every project) |
| `--force` | Overwrites skills (and a modified hook script) that already exist |
| `-y`, `--yes` | Answers YES to all prompts |
| `--dry-run` | Only prints the commands, runs nothing |
| `-h`, `--help` / `-v`, `--version` | Help / version |

Examples:

```bash
# Only the markdown skills into the project, overwriting older versions
bash ~/claude-web-skills-toolkit/install.sh --skills --force

# See what would happen
bash ~/claude-web-skills-toolkit/install.sh --all --dry-run

# Plugins and Chrome DevTools, skills globally for all projects
bash ~/claude-web-skills-toolkit/install.sh --plugins --chrome --skills --global

# CI / non-interactive environment (key from a CI secret variable)
API_KEY_21ST="$CI_SECRET_21ST" bash ~/claude-web-skills-toolkit/install.sh --all
```

The script is **idempotent**: marketplaces, plugins and MCP servers that are already
registered are skipped. It prints a summary at the end and exits with a non-zero code if
anything failed.

### Verifying the installation

Restart Claude Code and run in your project:

```text
/plugin      → frontend-design, superpowers
/mcp         → chrome-devtools, shadcn, 21st (status: connected)
/skills      → ux-laws, backend-security-auditor, frontend-design-guide, webapp-testing, …
/hooks       → PreToolUse and PostToolUse entries for slop-secrets-guard.sh
```

## Integrating into an existing project

1. **Run the installer in the project root:**

   ```bash
   cd ~/projects/my-web-app
   bash ~/claude-web-skills-toolkit/install.sh --all
   ```

2. **Commit the shared configuration** so the whole team gets it:

   ```bash
   git add .claude/skills .claude/hooks .claude/settings.json .mcp.json
   git commit -m "chore: add claude-web-skills-toolkit skills, hooks and MCP config"
   ```

   The `.mcp.json` created by shadcn contains no secrets. If you add a server that needs a key
   (e.g. 21st.dev), use variable expansion `${API_KEY_21ST}` — never the key value itself.

3. **Enable the plugins for the team** in `.claude/settings.json`:

   ```json
   {
     "extraKnownMarketplaces": {
       "claude-code-plugins": {
         "source": { "source": "github", "repo": "anthropics/claude-code" }
       }
     },
     "enabledPlugins": {
       "frontend-design@claude-code-plugins": true,
       "superpowers@claude-plugins-official": true
     },
     "permissions": {
       "allow": ["WebFetch(domain:raw.githubusercontent.com)"]
     }
   }
   ```

4. **Add the standards to the project's `CLAUDE.md`** so the agent follows them even when they
   are not mentioned explicitly:

   ```markdown
   ## Quality standards (claude-web-skills-toolkit)

   - New projects and major new dependencies are decided with `tech-stack-advisor` and recorded in `docs/adr/`.
   - UI: follow the `frontend-design-guide` and `ux-laws` skills; use components from the shadcn registry only (`shadcn-ui`).
   - After generating or changing a page, run the `vercel-web-guidelines` audit.
   - Write user-facing text following `ux-writing-en` or `ux-writing-cs` (by language), then run `deslop-en` / `deslop-cs`. Never invent numbers or testimonials.
   - Every public page gets metadata per `seo-metadata`; every feature touching personal data follows `gdpr-privacy`.
   - No hard-coded user-facing strings: messages, plurals and formatting follow `i18n-setup`.
   - Every endpoint, server action, webhook and upload goes through `backend-security-auditor`, including the Security Gate.
   - Verify forms and critical flows with Playwright tests following `webapp-testing`, and actually run the tests.
   - Fix bugs following `superpowers-debugging`: reproduce → root cause → clean fix → verify.
   - Verify runtime errors in the browser with `chrome-devtools`.
   ```

5. **Extend the project's `.gitignore`** with local and secret files (see the toolkit's
   [`.gitignore`](.gitignore) for inspiration):

   ```gitignore
   .env
   .env.*
   !.env.example
   .claude/settings.local.json
   CLAUDE.local.md
   playwright/.auth/
   ```

6. **Keep secrets in environment variables only** (e.g. `API_KEY_21ST` in your shell profile
   or a secrets manager), never in the repository.

## How skills work

Every skill is a folder with a `SKILL.md` file that starts with YAML frontmatter:

```yaml
---
name: backend-security-auditor
description: "Strict security audit and rules for full-stack backends ... Use whenever you write or review an API endpoint ..."
triggers:
  - "API endpoint / route handler / server action"
  - "sign-in / OAuth2 / OpenID Connect / session / cookies / passwords"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
---
```

- **`name`** and **`description`** are the fields Claude Code uses to load a skill. Claude
  sees the descriptions of all skills and loads a skill's full content when the task matches
  its description. That is why the descriptions also contain the trigger keywords.
- **`triggers`** is an extra field used by this toolkit: a human-readable list of situations
  for documentation and for agents/tools that understand it. Claude Code ignores it, which is
  harmless.
- A skill can also be invoked explicitly: *"Use the backend-security-auditor skill on app/api."*
  or as a slash command: `/deslop-en README.md`.
- **Language-specific skills** come in pairs (`ux-writing-en` / `ux-writing-cs`,
  `deslop-en` / `deslop-cs`). Each is self-contained, and its description says which language
  it is for, so the agent picks the right one by the language of the text. All skill
  instructions are in English; the Czech skills use Czech examples.
- Location: `./.claude/skills/<name>/SKILL.md` (project, shared via git) or
  `~/.claude/skills/<name>/SKILL.md` (personal, all projects).

## Slop & secrets guard hook

Skills are rules the agent reads; a hook is code that runs on every edit, whether the
agent remembered the rules or not. [`hooks/slop-secrets-guard.sh`](hooks/slop-secrets-guard.sh)
registers two checks for the `Write`, `Edit` and `MultiEdit` tools:

| Check | Event | What it does |
|-------|-------|--------------|
| `secrets` | `PreToolUse` | **Blocks** the edit if the new text contains something that looks like a secret: private keys, AWS/GitHub/GitLab/Slack/Stripe/Google/OpenAI/Anthropic/SendGrid/npm tokens, JWTs, passwords in connection strings, hard-coded credentials. Local `.env` files are skipped; `.env.example` is checked. Values are never printed, only the type and a masked preview. |
| `slop` | `PostToolUse` | **Reports** English and Czech AI writing tells in Markdown, HTML, text, UI code and translation files back to Claude, which then rewrites them with `deslop-en` / `deslop-cs`. Single words are checked only in prose files, so code identifiers like `unlock()` don't trigger it. |

- **False positives:** add `guard:allow` to the line (e.g. `<!-- guard:allow -->` or `// guard:allow`).
  A file containing `slop-guard: off` is skipped by the slop check; `SKILL.md` files are always skipped.
- **Dependencies:** only Bash, `grep` and `awk` — no Node.js or `jq` needed at runtime.
- **Install:** `./install.sh --hooks`, or copy the script to `.claude/hooks/` and the `hooks`
  block from [`hooks/settings.example.json`](hooks/settings.example.json) into `.claude/settings.json`.
- It is a safety net, not a replacement for secret scanning in CI (e.g. gitleaks, GitHub secret scanning).

## Toolkit security

- `install.sh` **does not download or run** anything other than the official commands listed
  in the table above; it prints every command before running it (`--dry-run` only prints them).
- The 21st.dev API key is read from an environment variable or a hidden prompt, masked in the
  output, and stored only in Claude Code's user configuration (`~/.claude.json`), never in the
  project.
- The script never overwrites existing skills without `--force` or confirmation, and only
  deletes the target skill folder inside `.claude/skills/`.
- `--hooks` merges into an existing `.claude/settings.json` without touching other keys, keeps a
  `settings.json.bak` backup, and leaves the file unchanged if it isn't valid JSON.
- Plugins and MCP servers can run code (hooks, commands). Install only what you trust and
  review upstream changes before updating.
- MCP servers that work with a browser or the web (chrome-devtools, 21st.dev) process untrusted
  content — the wrapper skills include rules against prompt injection.

## Updating and uninstalling

```bash
# Update the toolkit and the skills in your project
git -C ~/claude-web-skills-toolkit pull
bash ~/claude-web-skills-toolkit/install.sh --skills --force

# Update the plugin catalogs (then update the plugins themselves in Claude Code via /plugin)
claude plugin marketplace update claude-code-plugins
claude plugin marketplace update claude-plugins-official

# Uninstall the plugins
claude plugin uninstall frontend-design@claude-code-plugins
claude plugin uninstall superpowers@claude-plugins-official

# Remove the MCP servers
claude mcp remove chrome-devtools --scope user
claude mcp remove 21st --scope user
# shadcn: remove the "shadcn" entry from the project's .mcp.json

# Remove the guard hook (then delete its two entries from "hooks" in .claude/settings.json)
rm .claude/hooks/slop-secrets-guard.sh

# Remove the markdown skills from the project
rm -rf .claude/skills/{ux-laws,backend-security-auditor,frontend-design-guide,webapp-testing,ux-writing-en,ux-writing-cs,deslop-en,deslop-cs,tech-stack-advisor,i18n-setup,seo-metadata,gdpr-privacy,shadcn-ui,vercel-web-guidelines,chrome-devtools,magic-animations,superpowers-debugging}
```

## Contributing

1. Fork the repository and create a branch (`feat/new-skill`).
2. Add a `skills/<skill-name>/SKILL.md` folder with YAML frontmatter (`name` matching the
   folder name, lowercase with hyphens; `description` with clear triggers; `triggers`;
   `metadata` with author and license).
3. For external tools, state the original author, license, exact installation command, JSON
   configuration and behavior rules. Verify installation commands against the current upstream
   documentation.
4. If the skill needs installation, add a step to `install.sh` (idempotent, with `--dry-run`).
5. Check the script: `bash -n install.sh` and `bash install.sh --all --dry-run`.
6. Open a Pull Request describing the problem the skill solves.

## License and attribution

The code and custom skills in this repository are licensed under [MIT](LICENSE). The wrapper
skills describe third-party tools that are installed from their official sources and are
governed by their own licenses:

| Tool | Author | License | Source |
|------|--------|---------|--------|
| frontend-design (plugin) | Anthropic | © Anthropic PBC, Commercial Terms of Service | https://github.com/anthropics/claude-code |
| claude-plugins-official (marketplace) | Anthropic | Apache-2.0 | https://github.com/anthropics/claude-plugins-official |
| superpowers | Jesse Vincent (obra) and contributors | MIT | https://github.com/obra/superpowers |
| shadcn/ui + shadcn MCP | shadcn | MIT | https://github.com/shadcn-ui/ui |
| agent-skills (web-design-guidelines) | Vercel Labs | MIT | https://github.com/vercel-labs/agent-skills |
| skills CLI | Vercel Labs | MIT | https://github.com/vercel-labs/skills |
| chrome-devtools-mcp | Google Chrome DevTools team | Apache-2.0 | https://github.com/ChromeDevTools/chrome-devtools-mcp |
| 21st MCP / magic-mcp | 21st.dev | ISC (magic-mcp), MIT (@21st-dev/cli) | https://github.com/21st-dev/magic-mcp |
| Laws of UX (inspiration for `ux-laws`) | Jon Yablonski | website content © the author; the skill is an original wording | https://lawsofux.com |

Product names and trademarks belong to their respective owners. This project is not
officially affiliated with Anthropic, Vercel, Google, shadcn or 21st.dev.
