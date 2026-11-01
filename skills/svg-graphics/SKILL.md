---
name: svg-graphics
description: "Creating and shipping SVG for websites: choosing SVG vs. an icon set vs. a raster image, hand-writing clean SVG (viewBox, grid, currentColor, strokes), custom icons that match Lucide, decorative patterns, textures and backgrounds, spot illustrations, logo drafts and wordmarks, embedding (inline, img, sprite with use, React components via SVGR, Astro SVG components), theming and dark mode, optimization with SVGO 4, animation (line drawing, transforms, reduced motion), accessibility, the security of user-uploaded SVG, favicon sets and PNG exports, and tracing raster images. Use when the user asks for an icon, illustration, logo, pattern, background, divider, favicon or SVG animation, when SVG files are added or optimized, or when users can upload SVG. Photos, raster images, AI-generated images, video, Lottie and 3D are in visual-assets; motion rules are in magic-animations."
triggers:
  - "draw / create an icon, illustration, logo, pattern or background"
  - "SVG / optimize SVG / SVGO / SVGR / sprite"
  - "favicon / app icon from a logo"
  - "animate an SVG / line drawing animation"
  - "users upload SVG / SVG XSS"
  - "nakresli ikonu / logo / ilustraci / SVG"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# SVG graphics

SVG is code, so an agent can write, review and optimize it directly. Hand-written SVG from
an agent usually goes wrong in the same ways: random coordinates, strokes of different
weights, hard-coded colors that disappear in dark mode, no `viewBox`, colliding IDs, 200 KB
of path data inlined on every page, and confident copies of brand logos drawn from memory.
This skill sets the standard for SVG that looks deliberate and ships safely.

## Process

1. **Choose the format and the source** — SVG or raster, existing asset or new (section 1).
2. **Draw on a grid with tokens** (sections 2–4).
3. **Embed** the way that fits the use (section 5).
4. **Optimize** (section 6), make it **accessible** (section 7), **animate** only with a purpose (section 8).
5. **Check** at real sizes, in light and dark mode (section 11).

---

## 1. Format and source

| Need | Use | Not |
|------|-----|-----|
| UI icon | **Lucide** first — the project's only icon set (`frontend-design-guide`); a custom icon only when Lucide has nothing close, drawn to its rules (section 3) | a second icon set, emoji |
| Logos of other companies ("works with", integrations, payment methods) | the brand's official press kit; Simple Icons (the icon data is CC0, but the logos stay trademarks — follow each brand's guidelines); `search_logo` in the 21st.dev MCP (`magic-animations`) | a logo redrawn from memory |
| The project's own logo | the designer's vector file; an agent may draft a wordmark or monogram (section 4.3) | — |
| Patterns, textures, dividers, decorative backgrounds, spot illustrations | SVG | large PNGs |
| Photos, screenshots, painterly or photorealistic images, 3D | raster (`visual-assets`) | SVG with an embedded base64 image |
| Data charts | a chart library that renders SVG | hand-drawn bars with made-up values |

A wrong third-party logo is a trademark problem and makes the site look fake. If no
official file is available, use the company name in text.

## 2. Clean SVG

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M4 7h16" />
  <path d="M4 12h10" />
  <circle cx="18" cy="17" r="3" />
</svg>
```

- **Always a `viewBox`; no fixed `width` and `height` in reusable files** — size with CSS (`size-4`, `size-6`, `w-full`). Files used as `<img>` get `width`/`height` on the `<img>` tag instead.
- **Colors from the page:** `currentColor` for single-color graphics (the icon takes the text color); multi-color graphics get their colors through classes or CSS (`class="fill-primary"`, `style="fill: var(--primary)"`) so they follow the tokens and dark mode. No hard-coded hex values in graphics that live inside the UI.
- **Coordinates on the grid:** whole numbers or one decimal; path data rounded to at most two decimals.
- **Simple elements where they fit** — `<circle>`, `<rect rx>`, `<line>` are readable and editable; paths for everything else.
- `<g>` only when it carries shared attributes or a transform.
- **No fonts inside SVG** used as files: convert logo text to paths, or keep text in HTML over the graphic.
- **No embedded raster images** (`<image href="data:…">`) — it defeats the point of SVG.
- **No global `<style>` selectors in inline SVG** — they leak into the page. Scope them to a class or use attributes.
- **Unique IDs** for gradients, masks, clip paths and filters: two inline graphics with `id="gradient"` on one page break each other. Prefix them (section 6) or generate them with React `useId()`.
- Remove editor leftovers (`inkscape:*`, `sodipodi:*`, `data-name`, comments, empty groups, hidden layers) — SVGO does it (section 6).

## 3. Custom icons that match Lucide

Lucide's design principles: a **24 × 24 canvas**, at least **1 px of padding**, **2 px strokes**,
round caps and joins, no fill.

- Same visual weight as the neighbors: compare the new icon next to three or four Lucide icons at 16 and 24 px.
- Few nodes, simple geometry; straight horizontal and vertical lines on whole-number coordinates stay crisp at 2 px.
- Same component API as Lucide icons, hidden from screen readers by default (the button or link carries the label):

```tsx
// components/icons/invoice-check.tsx
import type { SVGProps } from "react";

export function InvoiceCheck(props: SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      {...props}
    >
      <path d="M6 3h9l3 3v15H6z" />
      <path d="m9 14 2 2 4-4" />
    </svg>
  );
}
```

- Keep custom icons together (`components/icons/`), named like Lucide icons (kebab-case files, PascalCase components).

## 4. Patterns, illustrations and logos

### 4.1 Patterns, textures and backgrounds

Grid or dot patterns with `<pattern>` (HTML/Astro syntax; in JSX use `className` and `strokeWidth`):

```html
<svg aria-hidden="true" class="pointer-events-none absolute inset-0 -z-10 size-full text-border">
  <defs>
    <pattern id="hero-grid" width="32" height="32" patternUnits="userSpaceOnUse">
      <path d="M32 0H0v32" fill="none" stroke="currentColor" stroke-width="1" />
    </pattern>
  </defs>
  <rect width="100%" height="100%" fill="url(#hero-grid)" />
</svg>
```

Grain or noise with `feTurbulence`, saved as a small file and tiled as a CSS background:

```svg
<!-- public/textures/grain.svg — background-image: url(/textures/grain.svg) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <filter id="grain">
    <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" stitchTiles="stitch" />
  </filter>
  <rect width="100%" height="100%" filter="url(#grain)" opacity="0.08" />
</svg>
```

- **Subtle and behind the content:** low contrast, `aria-hidden`, `pointer-events: none`. A pattern must not reduce text contrast below the `a11y-auditor` thresholds.
- **Filters cost paint time:** tile a small texture instead of one filter over the whole screen, and never animate `feTurbulence` or blur.
- **Blobs, waves and generative shapes** are generated once and stored — not randomized on every render (hydration mismatches, layout jumps).
- `preserveAspectRatio="xMidYMid slice"` for backgrounds that must fill their box; the default (`meet`) for illustrations that must stay whole.

### 4.2 Spot illustrations

- **Define a mini style before drawing** and keep it across the site: 3–5 token colors, stroke or flat fill, stroke width, corner radius, level of detail. Record it in `DESIGN.md`.
- Good uses: empty states (`frontend-design-guide`), feature explanations, onboarding steps, error pages — simple, one or two accent colors.
- **Be honest about limits:** complex scenes, characters and hands written path by path look amateurish. Use a designer, an illustration library with a clear license, or a raster/AI image in a fixed style (`visual-assets`).

### 4.3 Logo drafts

An agent can draft a **wordmark** (type-based), a **monogram** or a **simple geometric mark** as a
starting point. A final logo needs a designer and a trademark search `[LEGAL: trademark search
in the target markets before using the logo]`.

- Text converted to paths; the font's license allows logo use.
- Deliver the set: horizontal and stacked lockups, the mark alone, a single-color `currentColor` version, versions for light and dark backgrounds, clear space and minimum size.
- Test at 16 px (favicon) and in one color — if the mark doesn't survive that, simplify it.

## 5. Embedding

| Method | Use for | Notes |
|--------|---------|-------|
| Inline `<svg>` or a component | icons, graphics using `currentColor` or tokens, animated and interactive graphics | styleable from the page; adds to the HTML size — keep it small |
| `<img src="/….svg">` | large illustrations, logos with fixed colors | cached separately, scripts never run, page CSS can't style it; needs `width`, `height` and `alt` |
| CSS `background-image` | decorative patterns and textures only | invisible to screen readers |
| Sprite with `<symbol>` + `<use href="/icons.svg#name">` | many repeated custom icons in non-React pages | one cached file; an external sprite must be same-origin |
| React component (SVGR) | React/Next.js projects with many custom SVG files | config below |
| Astro SVG component | Astro | `import Logo from "../assets/logo.svg"` → `<Logo width={32} height={32} fill="currentColor" />`, inlined at build; not usable inside React islands — pass it in as children |

SVGR in Next.js with Turbopack (`npm i -D @svgr/webpack`):

```js
// next.config.mjs
const nextConfig = {
  turbopack: {
    rules: {
      "*.svg": { loaders: ["@svgr/webpack"], as: "*.js" },
    },
  },
};

export default nextConfig;
```

- With this rule every imported `.svg` becomes a component; SVG files referenced by URL from `public/` still work with `<img>`. `next/image` doesn't optimize SVG (it serves it unoptimized), so a plain `<img>` is fine for SVG files.
- Vite: `vite-plugin-svgr` and `import Logo from "./logo.svg?react"`.

## 6. Optimization (SVGO 4)

```js
// svgo.config.mjs — run: npx svgo -rf src/assets/svg
export default {
  multipass: true,
  plugins: [
    "preset-default", // since SVGO 4 it keeps viewBox and <title>
    "removeDimensions", // drops width/height, keeps viewBox — size with CSS
    { name: "prefixIds", params: { delim: "-" } }, // prefixes IDs with the file name: no collisions when inlined
  ],
};
```

- **Budgets:** an icon under 1 KB; an inline illustration ideally under 10–20 KB. Bigger graphics go into an `<img>` file (cached) or become raster.
- **Compare visually after optimizing** — path merging and conversion can change the rendering in rare cases. Keep the editable source (design file or `*.source.svg`) and generate the optimized file from it.
- SVGO keeps `<title>` and `aria-*` attributes by default since version 4; don't add `removeTitle` back for meaningful graphics.

## 7. Accessibility

The rules are in `a11y-auditor`; the patterns:

```html
<!-- Decorative -->
<svg aria-hidden="true" viewBox="0 0 24 24">…</svg>

<!-- Meaningful inline graphic: a role and an accessible name -->
<svg role="img" aria-labelledby="growth-title" viewBox="0 0 120 40">
  <title id="growth-title">Revenue grew 12 % in Q3</title>
  …
</svg>

<!-- As a file: alt describes the purpose, empty for decoration -->
<img src="/illustrations/empty-inbox.svg" alt="" width="240" height="160" />
```

- **Icon-only buttons:** the label is on the button (`aria-label`), the icon stays `aria-hidden`.
- **Text belongs in HTML:** text inside SVG isn't translated by the i18n setup, doesn't reflow and is hard to resize.
- **Non-text contrast:** meaningful graphics and their parts meet the 3:1 threshold in `a11y-auditor` — in both themes.
- IDs referenced by `aria-labelledby` must be unique on the page (`useId()` in React).

## 8. Animation

Motion rules (durations, easing, budget, reduced motion) are in `magic-animations`; SVG specifics:

- **Animate `transform` and `opacity`** with CSS; for parts of an SVG set `transform-box: fill-box; transform-origin: center`.
- **Line drawing** with `pathLength="1"` on the path:

```css
.draw path {
  stroke-dasharray: 1;
  stroke-dashoffset: 1;
  animation: draw 1.2s ease-out forwards;
}
@keyframes draw {
  to { stroke-dashoffset: 0; }
}
@media (prefers-reduced-motion: reduce) {
  .draw path { animation: none; stroke-dashoffset: 0; }
}
```

- With Motion for React: `motion.path` with `initial={{ pathLength: 0 }}` and `animate={{ pathLength: 1 }}`.
- **Morphing** between shapes needs paths with compatible commands; otherwise use a morphing helper — or cross-fade two shapes.
- **Avoid SMIL** (`<animate>`) for new work: a CSS `prefers-reduced-motion` query doesn't stop it.
- Don't animate filters or very large paths; pause loops when off-screen.
- Designer-made complex animations (After Effects, interactive state machines) → Lottie or Rive (`visual-assets`).

## 9. User-uploaded SVG

An SVG file can contain `<script>`, `on*` event handlers, `javascript:` links, `<foreignObject>`
with HTML, and external references. Opened directly or inlined into a page, it runs in your
origin — stored XSS.

- **Safest:** don't accept SVG uploads (`backend-security-auditor`, file uploads). Accept PNG or WebP, or **rasterize** uploaded SVG on the server (sharp, resvg) and keep only the raster.
- **If SVG must be kept:** sanitize on the server, reject files over a size limit and files containing `<!DOCTYPE` or `<!ENTITY`, and serve them from a separate domain:

```ts
// lib/sanitize-svg.ts — npm i isomorphic-dompurify
import DOMPurify from "isomorphic-dompurify";

export function sanitizeSvg(svg: string): string {
  return DOMPurify.sanitize(svg, { USE_PROFILES: { svg: true, svgFilters: true } });
}
```

- Serve stored user SVG with `Content-Type: image/svg+xml`, `X-Content-Type-Options: nosniff` and `Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; sandbox`.
- **Display user SVG only through `<img>`** (scripts never run there) — never inline it with `dangerouslySetInnerHTML` or `set:html`.

## 10. Favicons, exports and tracing

Most sites need four files:

| File | Purpose |
|------|---------|
| `favicon.ico` (32 × 32) at the site root | older browsers and tools that request `/favicon.ico` |
| `icon.svg` | modern browsers; can adapt to dark mode |
| `apple-touch-icon.png` (180 × 180, solid background) | iOS home screen |
| manifest icons 192 / 512 px + maskable | installable apps — `pwa-mobile` |

A favicon that adapts to the browser theme (a standalone file can't read the page's tokens,
so the brand values are written in):

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <style>
    rect { fill: #14532d; }
    @media (prefers-color-scheme: dark) { rect { fill: #86efac; } }
  </style>
  <rect x="4" y="4" width="24" height="24" rx="6" />
</svg>
```

- **Next.js:** `app/favicon.ico`, `app/icon.svg` and `app/apple-icon.png` — the file conventions generate the tags. **Astro and others:** `<link rel="icon" href="/favicon.ico" sizes="32x32">`, `<link rel="icon" href="/icon.svg" type="image/svg+xml">`, `<link rel="apple-touch-icon" href="/apple-touch-icon.png">`.
- **Simplify the mark for 16–32 px:** fewer details, thicker strokes.

Exports from one SVG source (`npm i -D sharp png-to-ico`):

```js
// scripts/export-icons.mjs — run: node scripts/export-icons.mjs
import { mkdir, writeFile } from "node:fs/promises";
import sharp from "sharp";
import pngToIco from "png-to-ico";

const SOURCE = "assets/brand/mark.svg";
const render = (size) => sharp(SOURCE, { density: 384 }).resize(size, size);

await mkdir("public/icons", { recursive: true });
await mkdir("tmp", { recursive: true });
await render(180).flatten({ background: "#ffffff" }).png().toFile("public/apple-touch-icon.png");
for (const size of [192, 512]) {
  await render(size).png().toFile(`public/icons/icon-${size}.png`);
}
await render(32).png().toFile("tmp/favicon-32.png");
await writeFile("public/favicon.ico", await pngToIco("tmp/favicon-32.png"));
```

- The maskable icon needs extra padding around the mark (the safe zone) — `pwa-mobile`.
- **Tracing** a raster logo into SVG (Potrace for black and white, VTracer for color) gives a rough result. Use the trace as a reference and redraw clean shapes; don't ship the raw trace.

## 11. Checking

- Render at real sizes — 16, 24 and 48 px for icons, mobile and desktop widths for illustrations — in **light and dark mode**; screenshot with `chrome-devtools`.
- Custom icons next to Lucide icons and next to text: same weight, aligned to the text.
- After SVGO: visual comparison and file sizes against the budget.
- Decorative graphics hidden, meaningful ones named (axe, `a11y-auditor`).

---

## Checklist

- [ ] Existing assets checked first (Lucide, the brand's official logo files); no logos drawn from memory.
- [ ] Every SVG has a `viewBox`; reusable files have no fixed size.
- [ ] Colors via `currentColor` or tokens; works in light and dark mode.
- [ ] Custom icons follow the Lucide grid (24 px, 1 px padding, 2 px stroke).
- [ ] IDs are unique on the page (prefixed or `useId()`).
- [ ] Optimized with SVGO 4; within the size budget; visually unchanged.
- [ ] Decorative SVG `aria-hidden`; meaningful SVG has a role and a name; text lives in HTML.
- [ ] Animations use transform/opacity, respect reduced motion, no SMIL.
- [ ] User-uploaded SVG is rejected, rasterized, or sanitized and served from a separate domain through `<img>` only.
- [ ] Favicon set complete: `favicon.ico`, `icon.svg`, `apple-touch-icon.png` (manifest icons via `pwa-mobile`).

## Anti-patterns

- Brand logos redrawn from memory, or a trace shipped as the final logo.
- A complex illustration written path by path and shipped with wobbly lines.
- Emoji or a second icon set next to Lucide.
- Hard-coded `#000` strokes that vanish in dark mode.
- `width="1200" height="800"` without a `viewBox`.
- Hundreds of kilobytes of inline SVG repeated on every page.
- Random blobs regenerated on each render.
- User-uploaded SVG inlined into the page.
- Two inline graphics sharing `id="gradient"`.

## Output format

```markdown
## SVG: invoice-check icon + empty-state illustration

| Asset | File | Size | Embedding | Accessibility | Checked |
|-------|------|------|-----------|---------------|---------|
| invoice-check | components/icons/invoice-check.tsx | 0.4 KB | component, currentColor | aria-hidden (button has the label) | 16/24 px next to Lucide, light + dark |
| empty-invoices | public/illustrations/empty-invoices.svg | 6 KB | `<img>`, 240 × 160 | alt="" (decorative) | mobile + desktop, light + dark |

**Style:** 2 px stroke, round joins, tokens primary + muted-foreground · **SVGO:** −38 %
```

## Related skills

- `visual-assets` — photos, raster images, AI-generated images, mockups, video, Lottie, Rive, 3D.
- `frontend-design-guide` — Lucide rules, tokens, empty states and the aesthetic direction.
- `magic-animations` — motion rules and the animation budget; `search_logo` for brand logos.
- `a11y-auditor` — accessible names and contrast; `web-performance` — budgets and LCP.
- `backend-security-auditor` — file uploads; `pwa-mobile` — manifest and maskable icons.
