---
name: web-performance
description: "Web performance for websites and web apps: Core Web Vitals targets (LCP, INP, CLS) and budgets, field vs. lab measurement, LCP image and font loading, JavaScript size and code splitting, third-party scripts, long tasks and responsiveness, layout stability, rendering strategy (static, ISR, streaming), HTTP caching, CDN and compression, data-fetching waterfalls, and Lighthouse CI as a gate. Use whenever you build or change pages, add dependencies, images, fonts or third-party scripts, or when the user asks why something is slow, about Core Web Vitals, Lighthouse or page speed. For debugging a specific page in the browser use chrome-devtools."
triggers:
  - "the page is slow / speed it up"
  - "Core Web Vitals / LCP / INP / CLS / Lighthouse score"
  - "bundle size / too much JavaScript"
  - "images / fonts / third-party scripts slow the page"
  - "caching / CDN / performance budget"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Web performance

Performance is measured where users are: on mid-range phones over mobile networks. The
targets below are the **75th percentile of real users** (field data), not one fast run on
a developer laptop.

## Targets

| Metric | Good | What it measures |
|--------|------|------------------|
| **LCP** — Largest Contentful Paint | ≤ 2.5 s (landing pages: aim for ≤ 2.0 s) | when the main content appears |
| **INP** — Interaction to Next Paint | ≤ 200 ms | how fast the page reacts to every interaction |
| **CLS** — Cumulative Layout Shift | ≤ 0.1 | how much the layout jumps |
| TTFB — Time to First Byte | ≤ 0.8 s | server and network latency (diagnostic) |

Budgets — starting points, adjust per project and record them in the repo:

| Resource on the initial route | Budget |
|-------------------------------|--------|
| JavaScript (compressed) | ≤ 150–200 KB |
| LCP image | ≤ 200 KB, modern format, correctly sized |
| Fonts | ≤ 2 families, ≤ 4 files, self-hosted |
| Third-party scripts before interaction | 0 (load after interaction or idle) |

## Process

1. **Measure** field data (RUM, CrUX) and lab data (Lighthouse, DevTools trace) — know which metric is bad and on which pages.
2. **Find the cause** with a trace (`chrome-devtools`: `performance_start_trace` → `performance_analyze_insight`).
3. **Fix** the biggest cause first (sections 2–8).
4. **Verify** in the lab, then watch the field data after release.
5. **Protect** the result with budgets in CI (section 9).

---

## 1. Measuring

```tsx
// app/web-vitals.tsx — real-user metrics, rendered once in the root layout
"use client";
import { useReportWebVitals } from "next/web-vitals";

export function WebVitals() {
  useReportWebVitals((metric) => {
    const body = JSON.stringify({ name: metric.name, value: metric.value, rating: metric.rating, id: metric.id, page: location.pathname });
    navigator.sendBeacon("/api/vitals", body);
  });
  return null;
}
```

- Outside Next.js use the `web-vitals` library (`onLCP`, `onINP`, `onCLS`).
- Lab tools (Lighthouse) can't measure INP — they report Total Blocking Time as a proxy. Field data is the truth.
- Test with CPU and network throttling (mid-range phone, fast 4G), not only on desktop.
- RUM is analytics: consent rules apply when it uses identifiers (`gdpr-privacy`).

## 2. LCP — the main content quickly

- **Find the LCP element** (usually the hero image or heading) and make sure it is in the initial HTML, not rendered after client-side fetching.
- **LCP image:** high fetch priority (`priority` on `next/image` — newer versions rename it, check the docs — or `fetchpriority="high"`), never lazy-loaded, correct `sizes`, AVIF/WebP, served from a CDN.
- **Don't hide the LCP element behind animations** (`opacity: 0` until hydration) — see `magic-animations`.
- **Reduce TTFB:** static or cached pages, a CDN close to users, no slow database calls blocking the whole page (stream the slow parts with `Suspense`).
- **Preconnect** only to origins needed immediately (`<link rel="preconnect">`), at most 2–3.

```tsx
import Image from "next/image";
import hero from "@/public/hero.avif";

<Image src={hero} alt="Invoice dashboard on a laptop" priority sizes="(min-width: 1024px) 50vw, 100vw" />
```

## 3. Fonts

- Self-host via `next/font` (or `@font-face` with `font-display: swap` / `optional`); subset to the needed scripts (`latin`, `latin-ext`).
- Few weights; prefer one variable font over several static files.
- Fallback metrics adjusted (`size-adjust` — `next/font` does it) to avoid layout shift.
- No icon fonts — use SVG icons (Lucide).

## 4. JavaScript

- **Server Components by default** (App Router); `"use client"` only for interactive leaves, not whole pages.
- **Code-split** heavy, rarely used parts: `next/dynamic` / `import()` for editors, charts, maps, modals.
- **Check the bundle:** `@next/bundle-analyzer` (or the framework's analyzer) before and after adding a dependency. Prefer small libraries (`date-fns` functions over a whole date library; native `Intl` over formatting libraries).
- **No duplicated libraries** (two versions of the same package, lodash and lodash-es).
- **Hydration cost:** avoid huge client-side props (they are serialized into the HTML).
- **Polyfills** only for browsers you support.

## 5. Third-party scripts

Analytics, chat widgets, A/B testing, tag managers and embeds are the most common cause of
bad INP and LCP.

- Every third-party script has an owner, a purpose and a measured cost. Remove the ones nobody uses.
- Load with `next/script` and the latest possible strategy: `lazyOnload` for chat and widgets, `afterInteractive` only when needed early. Never `beforeInteractive` for marketing tools.
- **Facades** for heavy embeds: a static preview of the video or map, the real embed loads on click.
- Consent-gated scripts don't load before consent anyway (`gdpr-privacy`) — that also helps performance.

## 6. INP — responsiveness

- **Break up long tasks** (> 50 ms): process work in chunks and yield to the main thread.

```ts
// lib/yield.ts
type SchedulerLike = { yield?: () => Promise<void> };
const scheduler = (globalThis as { scheduler?: SchedulerLike }).scheduler;

export function yieldToMain(): Promise<void> {
  return scheduler?.yield ? scheduler.yield() : new Promise((resolve) => setTimeout(resolve, 0));
}

export async function processInChunks<T>(items: T[], work: (item: T) => void, chunkSize = 50) {
  for (let i = 0; i < items.length; i++) {
    work(items[i]);
    if ((i + 1) % chunkSize === 0) await yieldToMain();
  }
}
```

- **Give feedback first, compute later:** update the UI immediately (`useTransition`, `useOptimistic`), run expensive work after.
- **Debounce** input-driven work (search, filters) and **virtualize** long lists (hundreds of rows).
- Avoid layout thrashing (reading layout after writing styles in loops); animate only `transform` and `opacity`.
- Heavy computation goes to a Web Worker.

## 7. CLS — layout stability

- Images, videos and iframes have `width`/`height` or `aspect-ratio`.
- Reserve space for content that loads later: ads, embeds, banners, skeletons with the final size (`frontend-design-guide`).
- Never insert content above existing content after load (cookie banners overlay instead of pushing the page).
- Font fallbacks with matching metrics (section 3).

## 8. Rendering, caching and delivery

- **Choose per route:** static (marketing, docs), incremental / on-demand revalidation (catalogs, blogs), dynamic only where data is per user. Stream slow parts with `Suspense` instead of blocking the whole page.
- **Avoid waterfalls:** start independent requests in parallel (`Promise.all`), fetch on the server close to the data, don't fetch in a chain of client components.
- **HTTP caching:** fingerprinted static assets `Cache-Control: public, max-age=31536000, immutable`; HTML short or revalidated; API responses `private` / `no-store` when they contain user data.
- **CDN** in front of everything static; Brotli/gzip compression; HTTP/2 or HTTP/3.
- **Images** through an image CDN or `next/image` with explicit `remotePatterns`.
- **Database:** indexes and no N+1 queries (`database-design`) — a slow query is a slow TTFB.

## 9. Budgets in CI

```json
// lighthouserc.json — run with: npx @lhci/cli autorun
{
  "ci": {
    "collect": {
      "startServerCommand": "npm run start",
      "url": ["http://localhost:3000/", "http://localhost:3000/pricing"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }],
        "total-blocking-time": ["warn", { "maxNumericValue": 200 }]
      }
    },
    "upload": { "target": "temporary-public-storage" }
  }
}
```

- Run it on every pull request against a production build (`deploy-and-ops`).
- Add a bundle-size check (e.g. `size-limit`) so a new dependency can't silently add 100 KB.
- Lab scores fluctuate — use several runs and watch trends, and keep the field data dashboard as the final judge.

## Checklist

- [ ] Field data (RUM or CrUX) is collected; p75 LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 on key pages.
- [ ] The LCP element is in the initial HTML; the LCP image has high priority, correct size and format.
- [ ] Fonts self-hosted, subset, few files; no icon fonts.
- [ ] Interactive code is split; heavy features loaded on demand; the bundle analyzed after new dependencies.
- [ ] Third-party scripts minimal, loaded late, behind consent where required; heavy embeds behind facades.
- [ ] No long tasks on interaction; feedback immediate; long lists virtualized.
- [ ] Media has dimensions; late content has reserved space; nothing pushes content down.
- [ ] Rendering strategy chosen per route; no request waterfalls; caching headers correct; CDN and compression on.
- [ ] Lighthouse CI and a bundle-size check run in CI.

## Output format

```markdown
## Performance review: / (mobile, p75 field data)

| Metric | Before | Target | After (lab) |
|--------|--------|--------|-------------|
| LCP | 4.1 s | ≤ 2.5 s | 2.2 s |
| INP | 340 ms | ≤ 200 ms | 150 ms (TBT 120 ms) |
| CLS | 0.21 | ≤ 0.1 | 0.02 |

| # | Cause | File:line | Fix | Gain |
|---|-------|-----------|-----|------|
| 1 | Hero image lazy-loaded, 1.2 MB PNG | app/page.tsx:14 | `next/image` + `priority` + AVIF | LCP −1.6 s |
| 2 | Chat widget loaded `afterInteractive` | app/layout.tsx:30 | `lazyOnload` + facade | INP −150 ms |
| 3 | Cookie banner pushes content down | components/consent-banner.tsx:8 | fixed overlay | CLS −0.18 |
```

## Related skills

- `chrome-devtools` (traces and insights), `frontend-design-guide` (skeletons, motion), `magic-animations` (animation budget), `seo-metadata` (rendering for search), `database-design` (slow queries), `deploy-and-ops` (CI, CDN, caching).
