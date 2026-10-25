---
name: frontend-design-guide
description: "Rules for building premium UI without the generic 'AI slop' look: typography and font choice, color harmony and contrast (no generic purple gradients), mandatory skeletons, well-crafted empty/error states, micro-interactions and a Tailwind CSS + shadcn/ui + Lucide icons architecture. Use whenever you create or modify a page, component, landing page, dashboard, form or design system in React/Next.js."
triggers:
  - "build a page / component / landing page / dashboard"
  - "make it prettier / more modern / more professional"
  - "design system / colors / fonts / typography"
  - "loading state / skeleton / empty state"
  - "button animations / hover effects / micro-interactions"
  - "Tailwind / shadcn / Lucide"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  complements: "frontend-design@claude-code-plugins (Anthropic)"
---

# Frontend Design Guide

The goal is UI that looks **intentionally designed**, not generated. Generic AI output is
recognizable at first glance: a purple-to-pink gradient, Inter everywhere, everything
centered, emoji instead of icons, three identical cards with an icon on top, and no states
other than the "happy path". This skill forbids that and replaces it with concrete rules.

The skill complements the official `frontend-design` plugin (Anthropic), which handles the
aesthetic direction; this file covers **concrete implementation standards** and the stack.

## Process

1. **Choose an aesthetic direction** and write it down in one sentence before any code (with Impeccable installed, record it in `DESIGN.md` — `impeccable-workflow`) (e.g. "Technical, dense, monochrome with one sharp green accent, inspired by a terminal"). Do not start without a direction.
2. **Set up tokens** (colors, fonts, radius, shadows) in CSS variables — not ad hoc in components.
3. **Build components** from shadcn/ui (see the `shadcn-ui` skill), styled through tokens; for distinctive sections pick patterns and registry components with `component-registries`.
4. **Implement all states** (loading, empty, error, success, disabled) — not just ideal data.
5. **Go through the checklist** at the end of this file and run the `vercel-web-guidelines` audit.

---

## 1. Typography

### Choosing fonts
- At most **2 families**: one for text, one for display (headings) or mono (data/code).
- Choose based on the product's character, not out of habit. Inter/Roboto/Arial as the only choice without a reason = generic output.

| Character | Text | Display / accent |
|-----------|------|------------------|
| Technical, developer tool | Geist, IBM Plex Sans | Geist Mono, JetBrains Mono |
| Modern SaaS, clean | Manrope, Plus Jakarta Sans | General Sans, Satoshi |
| Editorial, premium | Source Serif 4, Newsreader | Fraunces, Instrument Serif |
| Gaming, entertainment, energetic | Sora, Outfit | Space Grotesk, Clash Display |
| Friendly, consumer | DM Sans, Nunito Sans | Bricolage Grotesque |

- Load fonts via `next/font` (self-hosting, no layout shift, `display: "swap"`), not via a `<link>` to Google Fonts.
- Fonts must support the **diacritics of your target languages** (`subsets: ["latin", "latin-ext"]` for Central European languages).

```tsx
// app/layout.tsx
import { Manrope, Space_Grotesk } from "next/font/google";

const sans = Manrope({ subsets: ["latin", "latin-ext"], variable: "--font-manrope", display: "swap" });
const display = Space_Grotesk({ subsets: ["latin", "latin-ext"], variable: "--font-space-grotesk", display: "swap" });

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${sans.variable} ${display.variable}`} suppressHydrationWarning>
      <body className="font-sans antialiased">{children}</body>
    </html>
  );
}
```

### Typography rules
- A scale with a fixed ratio (e.g. 1.25): `text-sm` 14 → `text-base` 16 → `text-xl` 20 → `text-2xl` 24 → `text-3xl` 30 → `text-5xl` 48.
- Body text: `leading-relaxed` (1.625) to `leading-7`; headings: `leading-tight` (1.25) and `tracking-tight` from `text-3xl` up.
- Line length of **45–75 characters** (`max-w-prose` or `max-w-[65ch]`).
- Numbers in tables and statistics: `tabular-nums`.
- Hierarchy is built with size **and** weight **and** color, not just one of them.
- No `text-justify` (gaps between words), no all-caps for text longer than 3 words.

---

## 2. Color harmony

### Palette rules
- **60 / 30 / 10:** 60 % neutral surface, 30 % secondary (cards, panels), 10 % accent.
- **One accent hue** for primary actions; other colors only semantic (`destructive`, `success`, `warning`).
- Neutrals are **slightly tinted** towards the accent (warm/cool gray), not pure `#808080`.
- Define colors in **OKLCH** — uniform perceived lightness, easy generation of shades.
- Dark mode is not an inverted light version: the background is not `#000` but a dark tinted gray; the accent gets lighter and less saturated.

### Contrast (WCAG 2.2 AA) — MUST
- Every text and UI color pair meets the contrast thresholds in `a11y-auditor` (section 7) — they are defined there once.
- When choosing tokens, check the risky pairs explicitly in both modes: `text-muted-foreground` on `bg-background` and `bg-muted`, placeholders, disabled states, input borders and focus rings.
- Information is never conveyed **by color alone** (ticket status = color + text/icon).

### Forbidden patterns (anti-AI slop)
- ❌ `bg-gradient-to-r from-purple-500 to-pink-500`, `from-indigo-500 via-purple-500 to-pink-500` and any purple-blue-pink gradient as the default "modern" look.
- ❌ Gradient text (`bg-clip-text text-transparent`) on more than one element per page.
- ❌ Glassmorphism (`backdrop-blur` + translucent white cards) as the main style of all surfaces.
- ❌ Neon shadows (`shadow-purple-500/50`) and a "glow" on every button.
- ❌ Emoji as UI icons (🚀 ✨ 🔥) — use Lucide.
- ❌ Three identical "icon on top + heading + two lines of text" cards as the only structure of the page (alternatives: the pattern menu in `component-registries`).
- ❌ Everything centered (`text-center` on the whole page).
- ❌ Lorem ipsum and generic copy ("Revolutionize your workflow") — write real content in the product's language (rules in `ux-writing-en` / `ux-writing-cs`, editing pass in `deslop-en` / `deslop-cs`).

A gradient is allowed if it is **intentional, subtle and on-brand** (e.g. two close shades of
the accent, noise/grain, a radial light in the hero section) and you can explain why it is there.

### Tokens (Tailwind CSS v4 + shadcn/ui)

```css
/* app/globals.css */
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

:root {
  --radius: 0.625rem;
  --background: oklch(0.985 0.002 145);
  --foreground: oklch(0.21 0.015 145);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.21 0.015 145);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.21 0.015 145);
  --primary: oklch(0.52 0.15 150);
  --primary-foreground: oklch(0.985 0.01 150);
  --secondary: oklch(0.955 0.006 145);
  --secondary-foreground: oklch(0.25 0.015 145);
  --muted: oklch(0.955 0.006 145);
  --muted-foreground: oklch(0.47 0.015 145);
  --accent: oklch(0.94 0.03 150);
  --accent-foreground: oklch(0.25 0.05 150);
  --destructive: oklch(0.577 0.245 27.325);
  --border: oklch(0.91 0.006 145);
  --input: oklch(0.91 0.006 145);
  --ring: oklch(0.52 0.15 150);
}

.dark {
  --background: oklch(0.17 0.01 145);
  --foreground: oklch(0.96 0.005 145);
  --card: oklch(0.205 0.012 145);
  --card-foreground: oklch(0.96 0.005 145);
  --popover: oklch(0.205 0.012 145);
  --popover-foreground: oklch(0.96 0.005 145);
  --primary: oklch(0.72 0.16 150);
  --primary-foreground: oklch(0.17 0.02 150);
  --secondary: oklch(0.26 0.012 145);
  --secondary-foreground: oklch(0.96 0.005 145);
  --muted: oklch(0.26 0.012 145);
  --muted-foreground: oklch(0.72 0.012 145);
  --accent: oklch(0.3 0.04 150);
  --accent-foreground: oklch(0.96 0.005 145);
  --destructive: oklch(0.704 0.191 22.216);
  --border: oklch(1 0 0 / 10%);
  --input: oklch(1 0 0 / 15%);
  --ring: oklch(0.72 0.16 150);
}

@theme inline {
  /* Variables from next/font have their own names to avoid a circular reference */
  --font-sans: var(--font-manrope);
  --font-display: var(--font-space-grotesk);
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
}

@layer base {
  * {
    @apply border-border outline-ring/50;
  }
  body {
    @apply bg-background text-foreground;
  }
}
```

- In components use **only semantic classes** (`bg-primary`, `text-muted-foreground`), never `bg-green-600` or hex values.
- The palette above is an example; for each project derive your own from the brand accent and verify the contrast.

---

## 3. Component states

Every component that works with data has **five states**: loading, empty, error, success
(data) and a partial/disabled state. Implementing only the "happy path" = unfinished work.

### 3.1 Loading — mandatory skeletons
- The skeleton copies the **exact layout** of the final content (same heights, widths, number of lines) → zero layout shift (CLS).
- A spinner only for actions inside a button or short operations without a known layout.
- For fast responses, show the skeleton with a ~150–200 ms delay so it doesn't flicker.
- In the Next.js App Router: `loading.tsx` at the segment level and `<Suspense fallback={<…Skeleton />}>` around slow parts.

```tsx
// components/tickets/ticket-list-skeleton.tsx
import { Skeleton } from "@/components/ui/skeleton";

export function TicketListSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <ul className="divide-y rounded-lg border" aria-busy="true" aria-label="Loading tickets">
      {Array.from({ length: rows }, (_, i) => (
        <li key={i} className="flex items-center gap-4 p-4">
          <Skeleton className="size-10 rounded-full" />
          <div className="flex-1 space-y-2">
            <Skeleton className="h-4 w-2/5" />
            <Skeleton className="h-3 w-1/4" />
          </div>
          <Skeleton className="h-6 w-20 rounded-full" />
        </li>
      ))}
    </ul>
  );
}
```

### 3.2 Empty states — well-crafted
Distinguish three situations — each has a different text and a different action:

| Situation | Heading | Action |
|-----------|---------|--------|
| No data yet | "You don't have any tickets yet" | "Create a ticket" (primary) |
| No results for the filter | "Nothing matches the "open" filter" | "Clear filters" |
| No permission / unavailable | "Only workspace admins can see billing" | "Request access" |

```tsx
// components/empty-state.tsx
import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

type EmptyStateProps = {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: React.ReactNode;
  className?: string;
};

export function EmptyState({ icon: Icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div className={cn("flex flex-col items-center rounded-lg border border-dashed px-6 py-12 text-center", className)}>
      <div className="mb-4 flex size-12 items-center justify-center rounded-full bg-muted">
        <Icon className="size-6 text-muted-foreground" aria-hidden="true" />
      </div>
      <h3 className="font-display text-lg font-semibold tracking-tight">{title}</h3>
      <p className="mt-1 max-w-sm text-sm text-muted-foreground">{description}</p>
      {action ? <div className="mt-6">{action}</div> : null}
    </div>
  );
}
```

```tsx
<EmptyState
  icon={Inbox}
  title="You don't have any tickets yet"
  description="If you need help with your account or want to report a problem, create a ticket and the team will get back to you within 24 hours."
  action={<Button asChild><Link href="/tickets/new"><Plus aria-hidden="true" /> Create a ticket</Link></Button>}
/>
```

### 3.3 Error states
- Explain **what happened** and **what the user can do** ("Try again", contact support).
- Never show a raw error (`Error: ECONNREFUSED`, a stack trace).
- Filled-in data is **not lost** on error.
- In Next.js: `error.tsx` at the segment level with a `reset()` button.

### 3.4 Micro-interactions
- Duration **150–250 ms** for hover/press, 200–300 ms for opening panels; `ease-out` for entering, `ease-in` for exiting.
- Animate only `transform` and `opacity` (GPU), not `width`, `height`, `top`, `margin`.
- Every interactive element: `hover:`, `active:` (e.g. `active:scale-[0.98]`), `focus-visible:ring-[3px]`, `disabled:opacity-50`.
- Respect `prefers-reduced-motion`: use the `motion-safe:` / `motion-reduce:` variants.

```tsx
// Button with a loading state and press feedback
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";

export function SubmitButton({ pending, children }: { pending: boolean; children: React.ReactNode }) {
  return (
    <Button
      type="submit"
      disabled={pending}
      aria-busy={pending}
      className="motion-safe:transition-transform motion-safe:active:scale-[0.98]"
    >
      {pending ? <Loader2 className="animate-spin motion-reduce:animate-none" aria-hidden="true" /> : null}
      {pending ? "Submitting…" : children}
    </Button>
  );
}
```

---

## 4. Architecture: Tailwind CSS + shadcn/ui + Lucide

### Stack
- **Tailwind CSS v4** — configuration in CSS (`@theme`), no inline `style={{}}` for things a class can do.
- **shadcn/ui** — components are added via the CLI/MCP (`npx shadcn@latest add …`), live in `components/ui/` and are owned by the project.
- **Lucide** (`lucide-react`) — the only icon set in the project.
- `cn()` from `lib/utils.ts` (`clsx` + `tailwind-merge`) for composing classes.
- Component variants via `class-variance-authority` (cva), not via conditional class strings.

### Structure

```
app/
  (marketing)/page.tsx
  (app)/tickets/page.tsx
  (app)/tickets/loading.tsx
  (app)/tickets/error.tsx
components/
  ui/                 # shadcn/ui primitives — modify sparingly, via variants and tokens
  tickets/            # domain components composed from ui/*
  empty-state.tsx
lib/
  utils.ts            # cn()
```

### Icon rules (Lucide)
- Sizes: `size-4` (16 px) in text and buttons, `size-5` (20 px) in navigation, `size-6` (24 px) standalone.
- A consistent stroke width across the project (default 2, for a fine style `strokeWidth={1.5}` everywhere).
- Decorative icon: `aria-hidden="true"`. Icon-only button: `aria-label` (or `<span className="sr-only">`).
- Import individual icons (`import { Inbox } from "lucide-react"`), never the whole package.

### Layout and spacing
- Spacing only from the Tailwind scale (4px step); no arbitrary values except justified exceptions.
- Container: `mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8` — consistently on all pages.
- Mobile-first: base classes for mobile, `sm:`/`md:`/`lg:` for larger screens. Check a width of 360 px.
- Asymmetry and variety: alternate section density, use a 12-column grid, not just `grid-cols-3` everywhere.

---

## Pre-delivery checklist

- [ ] The aesthetic direction is named and the whole UI follows it.
- [ ] Fonts: max. 2 families, `next/font`, `latin-ext` where needed, type scale followed.
- [ ] None of the forbidden patterns from the "anti-AI slop" section.
- [ ] Colors only via semantic tokens; AA contrast verified in light and dark mode.
- [ ] Every data view has a skeleton, an empty state (all relevant variants) and an error state.
- [ ] Interactive elements have hover, active, focus-visible, disabled and loading states.
- [ ] Animations only `transform`/`opacity`, 150–300 ms, respecting `prefers-reduced-motion`.
- [ ] Components come from shadcn/ui, icons from Lucide with the correct ARIA attributes.
- [ ] The layout works at 360 px and 1440 px without horizontal scrolling.
- [ ] The `vercel-web-guidelines` audit, the `ux-laws` check and the `a11y-auditor` checks have been run; the page stays within the `web-performance` budgets.
