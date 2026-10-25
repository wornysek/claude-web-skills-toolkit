---
name: magic-animations
description: "Using the 21st.dev MCP (formerly Magic MCP) — search, get_component, inspiration, AI generation, logos — and the toolkit's motion rules for any animated component: performance (transform/opacity, lazy heavy backgrounds, LCP never waits for animation), accessibility (prefers-reduced-motion, no flashing, pausable motion) and code review of downloaded components. Use when the user mentions 21st.dev, Magic MCP or /ui, or when you add motion — animated backgrounds, text effects, scroll or hover animations — to a page. Which pattern and component a section should use, from 21st.dev or other registries, is decided with component-registries."
triggers:
  - "21st.dev / Magic MCP / /ui / 21st component"
  - "add animations / motion / bring the page to life"
  - "animated background / text effect / scroll animation"
  - "button animation / shimmer / hover effect"
  - "reduced motion / animation performance"
metadata:
  type: external-mcp-server
  author: "21st.dev"
  source: "https://21st.dev/mcp"
  repository: "https://github.com/21st-dev/magic-mcp"
  cli: "@21st-dev/cli"
  license: "ISC (magic-mcp), MIT (@21st-dev/cli); the service requires an account and an API key"
  wrapper-license: "MIT (claude-web-skills-toolkit)"
---

# 21st.dev MCP — interactive hero sections, backgrounds and animations

| | |
|---|---|
| **Author / Source** | [21st.dev](https://21st.dev) — [21st-dev/magic-mcp](https://github.com/21st-dev/magic-mcp), [@21st-dev/cli](https://www.npmjs.com/package/@21st-dev/cli) |
| **License** | ISC (magic-mcp), MIT (CLI) · the service is commercial: search is free, downloading component code is limited, AI generation requires a subscription · this wrapper skill: MIT |
| **Type** | External MCP server (HTTP, user scope) |
| **API key** | https://21st.dev/mcp |

> **Upstream change:** Magic MCP (`@21st-dev/magic`) has been replaced by the unified **21st MCP**.
> Old keys from the Magic console have been revoked — generate a new one at https://21st.dev/mcp.
> Older guides mention `npx @21st-dev/cli@latest install claude --api-key <YOUR_API_KEY>`;
> the current CLI uses the `init` command (see below).

## Installation

**Recommended for Claude Code** — the key is read from an environment variable and stored
only in the user configuration (`~/.claude.json`), never in the repository:

```bash
read -rs -p "21st.dev API key: " API_KEY_21ST && export API_KEY_21ST && echo
claude mcp add --transport http --scope user 21st https://21st.dev/api/mcp --header "x-api-key: ${API_KEY_21ST}"
```

Or via the toolkit (key from the `API_KEY_21ST` variable; if it is not set, it asks with
hidden input):

```bash
./install.sh --magic
```

The official 21st CLI (writes/merges the configuration for Claude):

```bash
npx @21st-dev/cli@latest login
npx @21st-dev/cli@latest init --client claude --write
```

> Never put the API key directly into a command that is saved to shell history or a CI log,
> and never commit it. If the key ended up in a repository, revoke it immediately at
> https://21st.dev/mcp.

## Configuration

A project-level `.mcp.json` **without secrets** — Claude Code substitutes the value of the
`API_KEY_21ST` environment variable at startup, so the file can be committed safely:

```json
{
  "mcpServers": {
    "21st": {
      "type": "http",
      "url": "https://21st.dev/api/mcp",
      "headers": {
        "x-api-key": "${API_KEY_21ST}"
      }
    }
  }
}
```

Compatible (legacy) variant via the stdio proxy:

```json
{
  "mcpServers": {
    "21st-magic": {
      "command": "npx",
      "args": ["-y", "@21st-dev/magic@latest"],
      "env": {
        "API_KEY_21ST": "${API_KEY_21ST}"
      }
    }
  }
}
```

## MCP server tools

| Tool | Purpose | Note |
|------|---------|------|
| `search` | Search for components in the 21st.dev registry | free |
| `get_component` | Download a component's source code | metered (daily limit on a free account) |
| `get_inspiration` | Inspiration / variants for a brief | |
| `search_logo` | Brand SVG logos (one query per call) | free |
| `generate`, `iterate_generation` | AI UI generation | only with active AI access |
| `get_usage` | Account status, `aiGenerationEnabled` | check before `generate` |

The server still translates the legacy tool names (`21st_magic_component_builder`,
`21st_magic_component_inspiration`, `21st_magic_component_refiner`, `logo_search`), but use the new ones.

## Behavior rules

### When and where to add motion
Motion must have a purpose: guide attention to the CTA, explain a state change or
create an on-brand first impression. **Which pattern and which component** a section gets —
from 21st.dev or another registry — is decided with `component-registries` (pattern menu,
signature moment, registry catalog). This skill covers getting components from 21st.dev
and the rules every animated component must meet.

### Process
1. **Take the section plan** from `component-registries` (max. one signature effect, one background, CTA micro-animations).
2. `search` → pick 2–3 variants and show them to the user with a short justification, or choose the most suitable one based on the aesthetic direction (`frontend-design-guide`).
3. `get_component` → download the code. If `get_usage` reports an exhausted limit or disabled AI, do not repeat the call — use the `search` results as inspiration and implement it yourself on top of shadcn/ui.
4. **Review the code** before inserting it (see Security).
5. **Adapt** the component to the project: colors only via tokens (`bg-primary`, `text-foreground`), fonts from `--font-*`, remove hard-coded hex colors and purple gradients.
6. Install the dependencies the component needs (typically `motion`, `clsx`, `tailwind-merge`) and verify the build.
7. Verify performance and the console via the `chrome-devtools` skill.

### Performance — MUST
- Animate only `transform` and `opacity` (or `filter` on small elements). Never `width`, `height`, `top`, `left`, `box-shadow` in a loop.
- **The LCP element (hero heading) must not wait for an animation** — no `initial={{ opacity: 0 }}` on the main heading; animate secondary elements.
- Heavy backgrounds (canvas, WebGL, particles) are lazy-loaded (`next/dynamic` with `ssr: false`), paused outside the viewport (`IntersectionObserver`) and when the tab is hidden (`visibilitychange`).
- At most **one** heavy animated background per page; on mobile a simpler variant or a static image.
- After integration, Core Web Vitals stay within the `web-performance` targets, with no LCP regression compared to the static version.

### Accessibility — MUST
- Respect `prefers-reduced-motion`: a static variant without motion, only instant state changes.
- No flashing more than 3 times per second (WCAG 2.3.1).
- Auto-playing motion longer than 5 s must be pausable, or it must be purely decorative and subtle (WCAG 2.2.2).
- Decorative layers have `aria-hidden="true"` and `pointer-events-none`; they must not cover interactive elements.
- Text over an animated background meets the contrast thresholds in `a11y-auditor` in **every** frame of the animation.

### Security
- Downloaded code is third-party code: before inserting it, check that it contains no network calls, external `<script>`, `eval`/`new Function`, `dangerouslySetInnerHTML`, tracking or unexpected dependencies.
- The 21st.dev API key belongs only in the MCP configuration — never in the frontend, a committed `.env` file or a `NEXT_PUBLIC_*` variable.
- Respect the license of each component as stated in the registry.

## Example: hero with reduced-motion support

```tsx
// components/marketing/hero.tsx
"use client";

import Link from "next/link";
import dynamic from "next/dynamic";
import { motion, useReducedMotion } from "motion/react";
import { ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";

// Heavy background from 21st.dev, lazy-loaded and client-only
const AuroraBackground = dynamic(() => import("@/components/marketing/aurora-background"), { ssr: false });

export function Hero() {
  const reduceMotion = useReducedMotion();

  return (
    <section className="relative isolate overflow-hidden">
      {reduceMotion ? null : <AuroraBackground className="pointer-events-none absolute inset-0 -z-10" aria-hidden="true" />}

      <div className="mx-auto flex max-w-6xl flex-col items-start gap-6 px-4 py-24 sm:px-6 md:py-32 lg:px-8">
        {/* LCP element: rendered immediately, no intro animation */}
        <h1 className="font-display max-w-3xl text-4xl font-semibold tracking-tight text-balance sm:text-6xl">
          Invoicing for freelancers
        </h1>

        <motion.p
          className="max-w-xl text-lg text-muted-foreground"
          initial={reduceMotion ? false : { opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: 0.1, ease: "easeOut" }}
        >
          Send an invoice in a minute. Payment reminders go out automatically.
        </motion.p>

        <motion.div
          initial={reduceMotion ? false : { opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: 0.2, ease: "easeOut" }}
        >
          <Button asChild size="lg" className="group">
            <Link href="/signup">
              Start free trial
              <ArrowRight className="transition-transform motion-safe:group-hover:translate-x-0.5" aria-hidden="true" />
            </Link>
          </Button>
        </motion.div>
      </div>
    </section>
  );
}
```

## Example: shimmer button with Tailwind only

```css
/* app/globals.css */
@theme {
  --animate-shimmer: shimmer 2.5s linear infinite;
  @keyframes shimmer {
    from { background-position: 200% 0; }
    to { background-position: -200% 0; }
  }
}
```

```tsx
<Button
  size="lg"
  className="bg-[linear-gradient(110deg,var(--primary),45%,color-mix(in_oklch,var(--primary),white_25%),55%,var(--primary))] bg-[length:200%_100%] motion-safe:animate-shimmer"
>
  Start free trial
</Button>
```

## Related skills

- `frontend-design-guide` — the aesthetic direction and tokens the component is adapted to.
- `shadcn-ui` — the base primitives (Button, Card) under animated components.
- `chrome-devtools` — measuring the impact of animations on LCP/CLS/INP and checking the console.
