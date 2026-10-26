---
name: component-registries
description: "Making pages distinctive with ready-made, high-quality components from the shadcn registry index and community registries (Magic UI, Aceternity UI, React Bits, Animate UI, Motion Primitives, Kokonut UI, Cult UI, Smooth UI, Skiper UI, Tailark, shadcnblocks, Kibo UI, AI Elements and others) and 21st.dev: a section-by-section menu of alternatives to the generic AI layout, choosing one signature moment per page, searching, previewing and installing with npx shadcn add @registry/item, adapting components to the project's tokens and copy, and checking quality, accessibility, performance, license and security. Use when building or redesigning heroes, feature sections, social proof, pricing, testimonials, CTAs, backgrounds, text effects or dashboards and the result would otherwise look like every other site. Base primitives come from shadcn-ui; the 21st.dev MCP tools and motion rules are in magic-animations; which sections a page needs is in landing-page."
triggers:
  - "the sites all look the same / make it more interesting / more unique"
  - "use ready-made components / component library / registry"
  - "Magic UI / Aceternity / React Bits / Animate UI / 21st.dev components"
  - "hero / bento grid / marquee / testimonials / pricing section design"
  - "background effect / text effect / interactive section"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Component registries — distinctive pages from proven components

Generated sites look alike for two reasons: every section uses the **same default
pattern** (centered hero, three icon cards, grey logo row, three pricing cards), and every
component is written from scratch in the same style. This skill breaks both: choose a
**deliberate pattern per section**, then build it from **proven components** of the
registry ecosystem — adapted to the project, not pasted in.

## Process

1. **Read the direction:** `DESIGN.md` / the aesthetic direction (`frontend-design-guide`, `impeccable-workflow`) and the section list (`landing-page`).
2. **Choose a pattern per section** from the menu below — never the default by habit. Write the plan as a table (output format at the end).
3. **Pick one signature moment** for the page: the one interactive or visual idea people remember (section 3).
4. **Search and preview** in 1–2 registries that fit the direction (sections 4–5).
5. **Evaluate** each candidate with the checklist (section 6) before installing.
6. **Install, then adapt** to tokens, fonts, copy and accessibility (section 7).
7. **Verify** in the browser and against the budgets (`chrome-devtools`, `web-performance`, `a11y-auditor`).

---

## 1. Pattern menu — alternatives to the defaults

| Section | Default to avoid as a habit | Alternatives (pick by the message) | Search terms |
|---------|-----------------------------|------------------------------------|--------------|
| **Hero** | centered headline, two buttons, gradient blob | split hero with the real product in a device or browser frame · interactive demo in the hero · large typographic hero with one text effect · editorial asymmetric grid · spotlight or lamp effect over a dark surface · scroll-driven story | `browser mockup`, `device mockup`, `spotlight`, `lamp`, `hero parallax`, `text animate`, `split text` |
| **Social proof** | grey logo row | logo or testimonial **marquee** · masonry "wall of love" · metric tickers with real numbers · short case-study cards with results | `marquee`, `number ticker`, `testimonials`, `avatar circles` |
| **Features** | three icon-on-top cards | **bento grid** with live mini-demos · sticky scroll feature tour · tabs with real screenshots · animated beam diagram of integrations · before/after comparison slider | `bento grid`, `sticky scroll`, `animated beam`, `tabs`, `compare` |
| **How it works** | 1-2-3 circles | steps with an animated progress line · terminal or code animation · interactive stepper · timeline | `terminal`, `timeline`, `stepper` |
| **Pricing** | three cards with the middle one highlighted | monthly/yearly toggle with animated numbers · usage slider calculator · comparison table with sticky header · one focused plan + enterprise contact | `pricing`, `number ticker`, `slider`, `comparison table` |
| **Testimonials** | carousel | marquee columns · one large quote with strong typography · video testimonials · quotes tied to metrics | `marquee`, `quote`, `testimonial` |
| **CTA** | gradient banner | inline CTA with the input in the section · animated border or beam around one card · big footer CTA with personality | `border beam`, `shine border`, `cta` |
| **Backgrounds** | blurred gradient blobs | subtle dot or grid pattern · noise texture · flickering or retro grid · one shader/WebGL background, used once | `dot pattern`, `grid pattern`, `flickering grid`, `retro grid`, `aurora`, `particles` |
| **Text** | gradient text everywhere | at most **one** effect per page: word rotate, typewriter, scramble, blur-in, shimmer | `word rotate`, `typing`, `scramble`, `blur text`, `shimmer text` |
| **App / dashboard** | hand-made cards and tables | official shadcn blocks (sidebar, dashboard, login) · data table pattern · kanban, gantt, calendar, editor components | `sidebar`, `dashboard`, `kanban`, `gantt`, `calendar` |
| **AI interfaces** | a textarea and a list | AI chat primitives: prompt input, message list, reasoning, sources | `prompt input`, `conversation`, `message` |
| **Icons and micro-interactions** | static icons | animated Lucide icons on hover or state change (same icon set) | `animated icons` |

The menu offers options, not rules: a calm, centered hero can be the right choice — when it
is chosen on purpose.

## 2. Composition rules

- **One signature moment per page** (section 3), at most **two or three animated sections**, everything else calm. Ten effects on one page look cheap and slow.
- **One or two registries per project** for marketing components, so the visual language stays consistent; base primitives always from `@shadcn` (`shadcn-ui`).
- **One motion language:** the same durations and easing for all components (put them into tokens); remove "bounce" and "elastic" easing unless the brand is playful.
- **Every effect carries the message:** an animated beam shows how integrations connect; a number ticker shows a real metric; decoration without meaning goes.
- **Mobile gets a simpler variant** (static image instead of WebGL, fewer particles) and **reduced motion** gets a static one (`magic-animations`).

## 3. The signature moment

Pick one, tied to what the product does:

- the product itself, live and interactive in the hero (a working mini-demo, a real editor, a live chart);
- a scroll-driven explanation of the core idea;
- a playful detail that matches the brand voice (a cursor effect, an easter egg, an animated mascot) — `delight` in `impeccable-workflow`;
- a striking visual (globe, 3D object, shader) **only** if it supports the story (global reach, physical product, technology).

## 4. Registries

All registries below are in the **shadcn registry index** — items install with the shadcn
CLI without extra configuration. The index lists ~500 registries with a health status and
ranking (`https://ui.shadcn.com/r/registries.json`). Vendors here are examples, not
endorsements; check health, maintenance and license at the time of use.

| Registry | Namespace | Strong for | License |
|----------|-----------|------------|---------|
| shadcn/ui blocks | `@shadcn` | app layouts: sidebars, dashboards, login, settings | MIT |
| Magic UI | `@magicui` | marketing effects: marquee, bento grid, number ticker, animated beam, patterns, device frames, text animations | MIT |
| Aceternity UI | `@aceternity` | bold hero and section effects: spotlight, lamp, 3D cards, parallax, beams, timelines | free items + paid Pro, Aceternity license |
| React Bits | `@react-bits` | hundreds of animated text effects, backgrounds (incl. WebGL) and interactive components | MIT + Commons Clause (use in products, don't resell the components) |
| Animate UI | `@animate-ui` | animated versions of shadcn/Radix primitives and icons | MIT + Commons Clause |
| Motion Primitives | `@motion-primitives` | small motion building blocks: text effects, morphing dialog, in-view reveals | MIT |
| Kokonut UI | `@kokonutui` | polished app and marketing components, AI inputs | MIT |
| Cult UI | `@cult-ui` | unusual, playful components | MIT |
| Smooth UI, Skiper UI | `@smoothui`, `@skiper-ui` | uncommon motion components | check the license |
| Tailark, Launch UI, shadcnblocks | `@tailark`, `@launchui`, `@shadcnblocks` | complete marketing blocks (heroes, features, pricing, footers) | free + paid tiers — check |
| Kibo UI | `@kibo-ui` | complex app components: kanban, gantt, calendar, editor | check the license |
| AI Elements, prompt-kit, assistant-ui | `@ai-elements`, `@prompt-kit`, `@assistant-ui` | AI chat interfaces (`ai-features`) | check the license |
| Billing SDK | `@billingsdk` | pricing tables, subscription and billing UI (`ecommerce`) | check the license |
| Animated icons | `@lucide-animated` and others | animated versions of the Lucide icon set | check the license |
| 21st.dev | via the 21st MCP (`magic-animations`) | a large community catalog of components and effects | per component author |

## 5. Search, preview, install

```bash
npx shadcn@latest search @magicui -q "marquee"     # find items in a registry
npx shadcn@latest view @magicui/marquee            # inspect files and dependencies before installing
npx shadcn@latest add @magicui/marquee             # install into components/ (adds the namespace to components.json)
npx shadcn@latest add dashboard-01                 # an official shadcn block
```

- With the shadcn MCP (`shadcn-ui`), search the same namespaces with `search_items_in_registries` and inspect with `view_items_in_registries`.
- 21st.dev: `search` and `get_component` through the 21st MCP (`magic-animations`).
- **Always look at the registry website's live preview** (light and dark, mobile width) before choosing — names don't tell you how a component feels.
- Install one item at a time and read what it added (files, dependencies, CSS variables, keyframes).

## 6. Evaluation checklist (before installing)

- [ ] **Fits the direction** of `DESIGN.md` and the section's message — not just "cool".
- [ ] **License** allows use in this product (commercial use, paid tiers, attribution); record it (section 7).
- [ ] **Maintained:** registry health in the index, recent updates, works with the project's React, Tailwind CSS and Next.js versions.
- [ ] **Dependencies** are acceptable: `motion` is fine; heavy ones (three.js, physics, large shaders) only for the signature moment and loaded lazily.
- [ ] **Accessibility:** keyboard operable, sensible semantics and ARIA, focus visible, works with reduced motion, no flashing (`a11y-auditor`).
- [ ] **Performance:** animates `transform`/`opacity`, no layout thrashing, pauses off-screen; stays within `web-performance` budgets.
- [ ] **SSR-safe:** no `window` access during render; client-only parts behind `"use client"` or dynamic import.
- [ ] **Security:** no external scripts, tracking, `eval` or `dangerouslySetInnerHTML` with dynamic data (`frontend-security`).

## 7. Adapting — make it yours

A registry component is a starting point. Before it ships:

- **Tokens, not hard-coded values:** replace colors with `bg-primary`, `text-muted-foreground`, borders with `border-border`; remove purple demo gradients (`frontend-design-guide` anti-slop list).
- **Typography and radius** from the project's fonts and `--radius`.
- **Real content:** replace demo text, logos and numbers with real ones or visible `[TODO: …]` placeholders — never keep fake testimonials or metrics (`ux-writing-*`).
- **Domain props and types:** rename generic props, remove unused variants, type everything.
- **Motion:** align durations and easing with the project's motion tokens; add the reduced-motion and mobile variants (`magic-animations`).
- **Location:** `components/marketing/…` or a domain folder; `components/ui/` stays for primitives.
- **Provenance** in a header comment, so licenses can be checked later:

```tsx
// Source: @magicui/marquee (MIT) — adapted: tokens, reduced motion, real logos
```

## Anti-patterns

- Installing a dozen flashy components and stacking them on one page.
- Mixing four registries' visual styles on one page.
- Keeping demo content, demo gradients or demo numbers.
- Heavy WebGL backgrounds behind text on mobile.
- Using paid components without a license, or copying components from websites without a license.
- Rebuilding a primitive that `@shadcn` already has (`shadcn-ui`).

## Output format

```markdown
## Section plan: / (direction: "calm, technical, one bold moment")

| Section | Pattern | Component | Why | Adaptations |
|---------|---------|-----------|-----|-------------|
| Hero | split, product in browser frame | `@magicui/safari` + shadcn `button` | shows the real product immediately | tokens, real screenshot, no gradient |
| Social proof | logo marquee | `@magicui/marquee` | 14 real customer logos, calm motion | pause on hover, reduced motion = static grid |
| Features | bento grid with mini-demos | `@magicui/bento-grid` | 5 features of different weight | live chart in the large tile |
| Signature | animated beam integration diagram | `@magicui/animated-beam` | explains "connects your tools" | 6 real integrations |
| Pricing | toggle + comparison table | shadcn `tabs`, `table` + `@magicui/number-ticker` | buyers compare details | annual savings shown |

**Registries used:** @shadcn, @magicui · **Licenses:** MIT · **New dependencies:** motion
```

## Related skills

- `landing-page` (which sections and why), `frontend-design-guide` (tokens, anti-slop), `impeccable-workflow` (shape, critique, polish, delight), `shadcn-ui` (primitives and MCP), `magic-animations` (21st.dev MCP and motion rules), `a11y-auditor`, `web-performance`, `frontend-security`, `ux-writing-en` / `ux-writing-cs` / `ux-writing-de`.
