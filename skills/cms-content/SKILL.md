---
name: cms-content
description: "Content-driven websites — blogs, documentation, marketing sites, news and knowledge bases: choosing Markdown/MDX in the repo vs. a headless or git-based CMS, structured content modelling, validated frontmatter, MDX safety, rendering rich text safely, static generation with on-demand revalidation from CMS webhooks, draft and preview mode, image handling, editorial workflow and scheduling, localization of content, blog and docs features (RSS, tags, authors, search, versioning, broken-link checks). Use whenever you build or change a content site, blog, docs, CMS integration, content model or editorial workflow. For page-level metadata use seo-metadata; for writing the content use ux-writing-en / ux-writing-cs."
triggers:
  - "blog / documentation site / knowledge base / marketing site"
  - "headless CMS / Sanity / Payload / Strapi / Contentful / Storyblok"
  - "MDX / Markdown content / frontmatter"
  - "preview / draft mode / revalidate content"
  - "content model / editorial workflow / scheduled publishing"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Content sites & CMS

Content sites live longer than their code. The decisions that matter are who edits the
content, how it is structured, how fast changes go live, and whether the site stays fast
and safe as content grows.

## Process

1. **Who edits?** Choose the content source (section 1).
2. **Model the content** as structured data (section 2).
3. **Render** statically with safe rich text (sections 3–4) and **revalidate** on changes (section 5).
4. **Preview** drafts securely (section 6), handle **images** (section 7).
5. **Workflow, localization, site features** (sections 8–10).

---

## 1. Content source

| Who edits | Recommendation |
|-----------|----------------|
| Developers only (docs, dev blog) | **Markdown / MDX in the repository** — reviewed in pull requests, versioned with the code |
| Non-developers, occasionally, with developer review | a **git-based CMS** (editing UI that commits to the repo) |
| Marketing or editorial teams, often, with previews and roles | a **headless CMS** (hosted or self-hosted) |
| Existing WordPress team | WordPress as headless CMS, or keep it — don't migrate without a reason |

Criteria: editors' skills, preview needs, localization, roles and approvals, scheduled
publishing, volume, budget, hosting and data location (`tech-stack-advisor`).

## 2. Content modelling

- **Structured fields, not one big rich-text blob:** title, slug, summary, hero image (+ alt), body, author (reference), tags (references), SEO title and description, publish date.
- **References** instead of copied text (authors, categories, reusable call-to-action blocks).
- **Page builders with limits:** a fixed set of section types (hero, feature grid, FAQ, CTA) that map to designed components — not free-form layout that breaks the design system.
- **Validation in the schema:** required fields, max lengths for titles and descriptions, **required alt text** for images, unique slugs.
- **Slugs are stable;** changing one creates a redirect (`seo-metadata`).

```ts
// content schema for Markdown/MDX frontmatter (validated at build time)
import { z } from "zod";

export const PostFrontmatter = z.object({
  title: z.string().min(5).max(90),
  description: z.string().min(50).max(160),
  slug: z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
  publishedAt: z.coerce.date(),
  updatedAt: z.coerce.date().optional(),
  author: z.string(),
  tags: z.array(z.string()).max(5).default([]),
  draft: z.boolean().default(false),
  image: z.object({ src: z.string(), alt: z.string().min(1) }).optional(),
});
```

- Invalid frontmatter **fails the build** — no broken pages in production.

## 3. MDX and rich text safety

- **MDX is code.** It can import components and run JavaScript at build or render time. Only trusted authors write MDX; content from users or external sources is **never** compiled as MDX (`frontend-security`).
- Expose a small, explicit set of components to MDX (`Callout`, `CodeBlock`, `Image`, `Video`) instead of the whole component library.
- **Rich text from a CMS** is rendered from its structured format (portable text, JSON AST) with serializers; if the CMS returns HTML, sanitize it with an allowlist.
- Code blocks are highlighted at build time (no client-side highlighting library).

## 4. Rendering

- **Static generation** for all published content; pages are HTML on a CDN.
- Large sites generate the most visited pages at build time and the rest on first request with caching.
- Lists (blog index, tag pages) paginate; no page renders thousands of items.

## 5. Revalidation from CMS webhooks

```ts
// app/api/revalidate/route.ts
import { revalidateTag } from "next/cache";
import { z } from "zod";
import { verifyHmacSha256 } from "@/lib/webhooks";
import { env } from "@/lib/env";

const CmsEvent = z.object({ type: z.enum(["post", "page", "author"]), slug: z.string().max(200) });

export async function POST(req: Request) {
  const rawBody = await req.text();
  if (!verifyHmacSha256(rawBody, req.headers.get("x-signature-256"), env.CMS_WEBHOOK_SECRET)) {
    return new Response(null, { status: 401 });
  }
  const event = CmsEvent.parse(JSON.parse(rawBody));
  // Next.js 16 takes a cache profile as the second argument; Next.js 15: revalidateTag(tag)
  revalidateTag(`${event.type}:${event.slug}`, "max");
  revalidateTag(`${event.type}:list`, "max");
  return Response.json({ revalidated: true });
}
```

- Tag data fetches by content type and slug so a change revalidates exactly the affected pages and lists.
- The webhook is authenticated (signature or secret) — otherwise anyone can force rebuilds (`backend-security-auditor` G2).

## 6. Draft and preview mode

```ts
// app/api/draft/route.ts
import { timingSafeEqual } from "node:crypto";
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";
import { env } from "@/lib/env";

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*(?:\/[a-z0-9]+(?:-[a-z0-9]+)*)*$/; // no leading slash → no open redirect

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const secret = Buffer.from(searchParams.get("secret") ?? "");
  const expected = Buffer.from(env.PREVIEW_SECRET);
  const slug = searchParams.get("slug") ?? "";
  if (secret.length !== expected.length || !timingSafeEqual(secret, expected) || !SLUG.test(slug)) {
    return new Response("Invalid preview link", { status: 401 });
  }
  (await draftMode()).enable();
  redirect(`/${slug}`);
}
```

- Draft content is fetched only when draft mode is enabled; preview pages are `noindex` and never cached publicly.
- Editors see a visible "Preview" banner with an "Exit preview" link.

## 7. Images

- Use the CMS image CDN (resizing, formats, focal point) or `next/image` with explicit `remotePatterns` for the CMS domain.
- **Alt text is required** in the content model; decorative images can be marked as such (`a11y-auditor`).
- Upload limits and formats are set in the CMS; huge originals are resized on delivery (`web-performance`).

## 8. Editorial workflow

- Roles: author, editor, publisher; drafts, review and approval for important pages.
- **Scheduled publishing** with time zones handled; unpublishing removes pages from lists and the sitemap (and redirects if needed).
- Version history and restore; who changed what and when.
- Content checklists in the CMS: SEO title and description, alt texts, links, tone (`ux-writing-*`, `deslop-*`).

## 9. Localization

- Decide per type: translated (same structure in every locale) vs. locale-specific (different content).
- Each locale has its own slug; `hreflang` alternates link translations (`seo-metadata`, `i18n-setup`).
- Missing translations fall back deliberately (show the default language with a note, or hide the page) — never mix languages within a page.

## 10. Site features

**Blogs and news:** RSS/Atom feed, author pages, tags with limits, related posts, reading time, publish and updated dates shown, `Article` structured data, social images per post.

**Documentation:** navigation from the content structure, previous/next links, "Edit this page" links, versioned docs for versioned products, copy buttons on code blocks, search (static index such as Pagefind for static sites, or a hosted search for large docs).

**All content sites:**
- Sitemap and feeds generated from published content only (`seo-metadata`).
- **Broken-link check** in CI (e.g. lychee) for internal and external links.
- 404 page with search and popular links; redirects for moved content.

## Checklist

- [ ] Content source fits the editors; decision recorded.
- [ ] Structured content model with validation, required alt text, stable slugs.
- [ ] MDX only from trusted authors with an explicit component set; CMS rich text rendered safely.
- [ ] Static generation; tag-based revalidation from authenticated webhooks.
- [ ] Draft mode protected by a secret, slug validated, previews noindex and uncached.
- [ ] Images through a CDN with sizes and formats; alt text present.
- [ ] Roles, scheduling, history; localization strategy per content type.
- [ ] Feeds, sitemap, structured data, search and broken-link checks in place.

## Output format

```markdown
## Content site review: blog

| # | Finding | File | Fix |
|---|---------|------|-----|
| 1 | Revalidation endpoint has no authentication | app/api/revalidate/route.ts | HMAC signature from the CMS |
| 2 | Preview route redirects to any `slug` (open redirect) | app/api/draft/route.ts | slug regex without leading slash |
| 3 | Images without alt text in 40 posts | CMS model `post.image` | make `alt` required, backfill |
| 4 | Frontmatter not validated, build passes with missing titles | content.config.ts | Zod schema, fail the build |
```

## Related skills

- `seo-metadata` (metadata, sitemap, structured data, redirects), `ux-writing-en` / `ux-writing-cs` / `ux-writing-de` and `deslop-*` (content quality), `i18n-setup` (localized routes), `frontend-security` (MDX and HTML safety), `web-performance` (images, static delivery), `a11y-auditor` (alt text, headings), `tech-stack-advisor` (CMS choice).
