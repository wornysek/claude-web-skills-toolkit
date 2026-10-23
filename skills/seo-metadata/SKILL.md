---
name: seo-metadata
description: "Technical SEO and sharing metadata for web apps (Next.js App Router first, principles apply to any framework): titles and descriptions, the Metadata API, canonical URLs, Open Graph and social images, robots and noindex rules, sitemap.xml and robots.txt, hreflang for multilingual sites, JSON-LD structured data (with safe serialization), semantic HTML, status codes, redirects and verification. Use whenever you create or change a public page, a layout, routing, a blog or product page, a multilingual setup, or when the user asks about SEO, metadata, OG images, sharing previews, sitemap, robots or rich results."
triggers:
  - "SEO / meta tags / title and description"
  - "Open Graph / OG image / Twitter card / sharing preview"
  - "sitemap / robots.txt / noindex / canonical"
  - "structured data / JSON-LD / rich results"
  - "hreflang / multilingual URLs"
  - "new public page / blog / product page / landing page"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# SEO & Metadata

Search engines and social networks read the same thing: the HTML your server returns.
Generated apps often ship one `<title>` for the whole site, no descriptions, no social
images, indexable staging and admin pages, and client-only rendered content. This skill
sets the technical baseline. It does not cover keyword research or link building.

## Process

1. **Classify each route:** public and indexable (home, landing, docs, blog, product) or private / utility (dashboard, settings, admin, auth, checkout, search results, previews).
2. **Set the metadata** for every public route (sections 1–3) and **noindex** every private one (section 4).
3. **Add discovery files:** `sitemap.ts`, `robots.ts` (section 5).
4. **Add structured data** where it describes real, visible content (section 7).
5. **Verify** the rendered HTML and the tooling checks (section 10).

---

## 1. Titles and descriptions

- **Unique per page.** A title template keeps the brand at the end: `Pricing · Acme`.
- **Title:** about 50–60 characters, the most specific words first. No keyword stuffing.
- **Description:** about 140–160 characters, a real summary that makes someone click. It is not a ranking factor, but it is the snippet people read.
- Write both following `ux-writing-en` / `ux-writing-cs` and run the `deslop-en` / `deslop-cs` pass — generic marketing descriptions are ignored by users and often rewritten by search engines.
- The visible `<h1>` and the `<title>` describe the same thing, but don't have to be identical.

## 2. The Metadata API (Next.js App Router)

Root layout — defaults, title template and `metadataBase` (required for absolute OG URLs):

```tsx
// app/layout.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "https://example.com"),
  title: { default: "Acme — invoices for freelancers", template: "%s · Acme" },
  description: "Send an invoice in a minute and let Acme send the reminders.",
  applicationName: "Acme",
  openGraph: { type: "website", siteName: "Acme", locale: "en_US" },
  twitter: { card: "summary_large_image" },
  alternates: { canonical: "/" },
};
```

Static page:

```tsx
// app/pricing/page.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Pricing",
  description: "Free for up to 5 invoices a month. Paid plans add reminders, multiple currencies and team access.",
  alternates: { canonical: "/pricing" },
};
```

Dynamic page — metadata from data, with a real 404 for missing items:

```tsx
// app/blog/[slug]/page.tsx
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { getPost } from "@/lib/posts";

type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);
  if (!post) return {};
  return {
    title: post.title,
    description: post.excerpt,
    alternates: { canonical: `/blog/${post.slug}` },
    openGraph: {
      type: "article",
      title: post.title,
      description: post.excerpt,
      publishedTime: post.publishedAt.toISOString(),
      modifiedTime: post.updatedAt.toISOString(),
      authors: [post.author.name],
    },
  };
}

export default async function PostPage({ params }: Props) {
  const { slug } = await params;
  const post = await getPost(slug);
  if (!post) notFound(); // real 404 status, not a soft 404
  // ...
}
```

- `generateMetadata` and the page can share one cached data call (`React.cache` or the framework's fetch cache) — don't fetch twice.
- Other frameworks: the same fields as `<title>`, `<meta name="description">`, `<link rel="canonical">`, `<meta property="og:*">` in the server-rendered `<head>`.

## 3. Open Graph and social images

- Size **1200 × 630 px**, important content in the middle (platforms crop), text large enough to read on a phone.
- Every public page has an image: a page-specific one for content pages, the site default elsewhere.
- Generate them at build or request time instead of hand-making hundreds:

```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from "next/og";
import { getPost } from "@/lib/posts";

export const size = { width: 1200, height: 630 };
export const contentType = "image/png";
export const alt = "Blog post cover";

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const post = await getPost(slug);
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "flex-end",
          padding: 72,
          background: "#0f1411",
          color: "#f2f5f3",
        }}
      >
        <div style={{ fontSize: 28, opacity: 0.7 }}>Acme blog</div>
        <div style={{ fontSize: 64, fontWeight: 700, lineHeight: 1.1 }}>{post?.title ?? "Acme"}</div>
      </div>
    ),
    size,
  );
}
```

- Use the project's brand colors and fonts (`frontend-design-guide`), not a default gradient.
- Check previews with the platforms' own debuggers before launch (section 10).

## 4. Indexing rules: noindex, robots, canonicals

- **Noindex** everything that is private or has no value in search: dashboards, settings, admin, auth pages, checkout, internal search results, paginated filters, thank-you pages.

  ```tsx
  // app/(app)/layout.tsx — applies to the whole private segment
  export const metadata: Metadata = { robots: { index: false, follow: false } };
  ```

- **robots.txt does not remove pages from the index** — it only stops crawling. A page blocked in robots.txt can't show its `noindex` to the crawler. Use `noindex` to keep pages out; use robots.txt to save crawl budget on endless URL spaces.
- **Staging and preview deployments** must not be indexed: send `X-Robots-Tag: noindex` from the host or middleware for every non-production hostname, and verify with `curl -I`. Some hosts do this for preview URLs automatically — check, don't assume.
- **Canonical URL** on every indexable page: absolute (via `metadataBase`), one version of each URL (https, one hostname, consistent trailing slash, no tracking parameters).
- **Duplicate content** from filters and sorting (`?sort=price`) points its canonical to the clean URL.

## 5. sitemap.xml and robots.txt

```ts
// app/sitemap.ts
import type { MetadataRoute } from "next";
import { getAllPosts } from "@/lib/posts";

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "https://example.com";

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const posts = await getAllPosts();
  return [
    { url: `${SITE_URL}/`, lastModified: new Date() },
    { url: `${SITE_URL}/pricing`, lastModified: new Date() },
    ...posts.map((post) => ({ url: `${SITE_URL}/blog/${post.slug}`, lastModified: post.updatedAt })),
  ];
}
```

```ts
// app/robots.ts
import type { MetadataRoute } from "next";

const SITE_URL = process.env.NEXT_PUBLIC_SITE_URL ?? "https://example.com";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: "*", allow: "/", disallow: ["/api/", "/admin/"] },
    sitemap: `${SITE_URL}/sitemap.xml`,
  };
}
```

- The sitemap lists **only canonical, indexable, 200-status URLs** — no noindex pages, no redirects.
- `lastModified` is the real content change date, not "now" on every build for every URL.
- More than 50,000 URLs → split with `generateSitemaps`.

## 6. Multilingual sites (hreflang)

- One URL per language (`/en/pricing`, `/cs/cenik`), never the same URL switching language by cookie or IP.
- Every language version lists all versions, including itself, plus `x-default`:

```tsx
export const metadata: Metadata = {
  alternates: {
    canonical: "/en/pricing",
    languages: {
      en: "/en/pricing",
      cs: "/cs/cenik",
      "x-default": "/en/pricing",
    },
  },
};
```

- `<html lang>` matches the page language; `openGraph.locale` uses the `en_US` / `cs_CZ` format.
- Translated metadata follows the language's writing skill (`ux-writing-en` / `ux-writing-cs`).
- Locale routing, message files and a `generateMetadata` example with `getPathname` per locale: `i18n-setup`.

## 7. Structured data (JSON-LD)

Use structured data only for content that is **visible on the page and true**.

```tsx
// components/json-ld.tsx
import type { Thing, WithContext } from "schema-dts";

export function JsonLd({ data }: { data: WithContext<Thing> }) {
  return (
    <script
      type="application/ld+json"
      // Escaping "<" prevents a "</script>" inside the data from breaking out (XSS)
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data).replace(/</g, "\\u003c") }}
    />
  );
}
```

```tsx
<JsonLd
  data={{
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.title,
    datePublished: post.publishedAt.toISOString(),
    dateModified: post.updatedAt.toISOString(),
    author: { "@type": "Person", name: post.author.name },
    image: [`${SITE_URL}/blog/${post.slug}/opengraph-image`],
  }}
/>
```

| Page | Types |
|------|-------|
| Home | `Organization` (name, logo, `sameAs` profiles), `WebSite` |
| Article / blog post | `Article` or `BlogPosting`, `BreadcrumbList` |
| Product | `Product` with `Offer` (price, currency, availability) |
| Docs / nested pages | `BreadcrumbList` |
| Local business | `LocalBusiness` with real address and opening hours |
| Event | `Event` with date, location, offers |

- **Never** add `AggregateRating` or `Review` that isn't real and shown on the page — it violates search engine guidelines and can lead to a manual penalty.
- FAQ rich results are shown only for a limited set of authoritative sites; FAQ markup is fine but don't expect stars or dropdowns in results.
- Data in JSON-LD must match the visible content (same price, same date).

## 8. Content and HTML that search engines can read

- **Server-render indexable content** (SSG/SSR/ISR). Content that appears only after client-side fetching may be indexed late or not at all.
- **Semantic structure:** one `<h1>`, ordered headings, `<main>`, `<nav>`, `<article>`, real `<a href>` links (not `onClick` navigation).
- **Descriptive link text** and internal links between related pages.
- **Images:** meaningful `alt`, explicit `width`/`height` (or `next/image`), modern formats, lazy loading below the fold.
- **Performance is part of SEO:** Core Web Vitals (LCP < 2.5 s, INP < 200 ms, CLS < 0.1) — see `ux-laws` (Doherty) and `chrome-devtools`.

## 9. URLs, status codes and redirects

- URLs are lowercase, hyphenated, readable and stable: `/blog/how-to-send-invoices`, not `/post?id=8123`.
- Changing a URL → a **permanent redirect (308/301)** from the old one, and update internal links and the sitemap:

```ts
// next.config.ts
const nextConfig = {
  async redirects() {
    return [{ source: "/blog/old-slug", destination: "/blog/new-slug", permanent: true }];
  },
};

export default nextConfig;
```

- Missing content returns a **real 404** (`notFound()`), not a 200 page saying "not found".
- Removed for good → 410 if the framework/host allows it, otherwise 404.
- No redirect chains (A → B → C); point A directly to C.

## 10. Verification

```bash
# Rendered head of a page (what crawlers see)
curl -s https://example.com/pricing | grep -iE "<title>|name=\"description\"|rel=\"canonical\"|property=\"og:"

# Indexing headers on staging / preview
curl -sI https://staging.example.com | grep -i x-robots-tag

# Discovery files
curl -s https://example.com/robots.txt
curl -s https://example.com/sitemap.xml | head -40
```

- Lighthouse SEO audit (Chrome DevTools or the `chrome-devtools` MCP) — target 100.
- Rich Results Test / Schema Markup Validator for JSON-LD.
- Social preview debuggers of the platforms you care about for OG images.
- Search Console (or the equivalent for your market): submit the sitemap, watch coverage and Core Web Vitals reports.

---

## Checklist

- [ ] Every public page has a unique title (template with brand) and a real description.
- [ ] `metadataBase` is set; canonicals are absolute and consistent.
- [ ] Every public page has an OG image (1200 × 630) and `twitter.card = summary_large_image`.
- [ ] Private segments (app, admin, auth, checkout) have `robots: { index: false }`.
- [ ] Staging and previews send `X-Robots-Tag: noindex` (verified with `curl -I`).
- [ ] `sitemap.xml` lists only canonical, indexable 200 URLs with real `lastModified`.
- [ ] `robots.txt` points to the sitemap and doesn't block pages that rely on `noindex`.
- [ ] Multilingual pages have reciprocal `hreflang` with `x-default`.
- [ ] JSON-LD is escaped, valid, matches visible content and contains no fake reviews.
- [ ] Indexable content is server-rendered; one `<h1>`; real links.
- [ ] Missing pages return 404; changed URLs redirect permanently, without chains.

## Output format

```markdown
## SEO review: app/

| Route | Indexable | Title | Description | Canonical | OG image | Issues |
|-------|-----------|-------|-------------|-----------|----------|--------|
| / | yes | ✅ | ✅ | ✅ | ✅ | — |
| /pricing | yes | ✅ | ❌ missing | ✅ | default | add description |
| /dashboard | no | — | — | — | — | ❌ missing noindex |
| /blog/[slug] | yes | ✅ | ✅ | ✅ | ✅ generated | JSON-LD dateModified missing |

**Discovery:** sitemap ✅ · robots ✅ · staging noindex ❌ (no X-Robots-Tag on preview URLs)
```

## Related skills

- `ux-writing-en` / `ux-writing-cs` and `deslop-en` / `deslop-cs` — titles, descriptions and on-page copy.
- `frontend-design-guide` — OG image design with the project's tokens.
- `chrome-devtools` — Lighthouse and Core Web Vitals in a real browser.
- `backend-security-auditor` — JSON-LD and any user-provided metadata are untrusted input.
