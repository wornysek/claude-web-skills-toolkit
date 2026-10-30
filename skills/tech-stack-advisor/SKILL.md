---
name: tech-stack-advisor
description: "Decision process for choosing a tech stack for a new web project or a major new dependency: gathering requirements, classifying the project (content site, web app, SPA, API, realtime, e-commerce, mobile + web, AI features), choosing each layer (framework, UI, database, ORM, auth, payments, email, storage, jobs, search, hosting, observability, testing) with a sensible default and explicit reasons to deviate, scoring trade-offs, verifying that the choices are current and maintained, and recording the result as an architecture decision record (ADR). Use when the user starts a new project, asks 'what should I use for…', compares frameworks, databases, auth providers or hosting, or considers migrating to another stack."
triggers:
  - "new project / what stack should I use?"
  - "Next.js or Astro / React or Vue / Prisma or Drizzle?"
  - "which database / auth provider / hosting / payment provider?"
  - "should we migrate to …?"
  - "architecture for an MVP / SaaS / e-shop / internal tool"
  - "jaký tech stack zvolit / na čem to postavit?"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Tech Stack Advisor

Choosing a stack is choosing which problems you will have. Agents tend to answer this
question from habit or hype: the newest framework, microservices for an MVP, three
databases on day one. This skill replaces that with a short, repeatable process that
ends in **one recommendation, one alternative and a written decision**.

The defaults below reflect what the toolkit's other skills assume (React, Next.js,
Tailwind CSS, shadcn/ui, Postgres, TypeScript). They are starting points, not rules —
the requirements decide.
When Astro is chosen, `frontend-design-guide`, `web-performance` and `seo-metadata` list
the Astro equivalents (Fonts API, `astro:assets`, islands, head and sitemap).

## Process

1. **Gather requirements** (section 1) — ask only what you can't infer from the repository or the conversation.
2. **Classify the project** into an archetype (section 2) and take its baseline.
3. **Decide each layer** (section 3): keep the default unless a requirement says otherwise.
4. **Score the real alternatives** where the decision is close (section 4).
5. **Verify** that every choice is current, maintained and licensed acceptably (section 5).
6. **Record** the decision as an ADR and offer the scaffold commands (section 6).

---

## 1. Requirements

Ask at most about eight questions, grouped in one message. Skip anything the repository or
the user already answered; state your assumptions for the rest.

| Area | Question |
|------|----------|
| Product | What is being built, and what is the one thing it must do well? |
| Users and scale | How many users at launch and in a year? Where are they? Peak traffic? |
| Content vs. app | Mostly content (pages, docs, blog) or mostly interaction (accounts, forms, dashboards)? |
| SEO | Do public pages need to rank in search or have rich sharing previews? |
| Data | Relational (users, orders, permissions)? Files? Full-text search? Analytics? |
| Auth | Email/password, social login, magic links, B2B organizations, SSO/SAML? |
| Realtime and offline | Live updates, chat, collaboration, offline use? |
| Team | Which languages and frameworks does the team already know? How many people maintain it? |
| Constraints | Budget, required hosting or region (e.g. EU data residency), compliance (GDPR, PCI, HIPAA), deadline |
| Lifetime | Prototype for a week, or a product maintained for years? |

**In an existing repository** the current stack is the default answer. Recommend a change only
for a measured problem (performance, cost, missing capability, security) — never for novelty.

## 2. Archetypes and baselines

| Archetype | Typical examples | Baseline |
|-----------|------------------|----------|
| Content site | marketing site, blog, docs, portfolio | **Astro** (or Next.js static export) + MDX; a headless CMS only if non-developers edit content; static hosting / CDN |
| Web app with public pages | SaaS, marketplace, community, customer portal | **Next.js (App Router) + TypeScript + Tailwind + shadcn/ui**, Postgres + an ORM, an auth library or provider, Vercel or a container host |
| App without SEO | editor, heavy dashboard, internal tool | **Vite + React** (TanStack Router / Query) + a separate API, or Next.js if the team already uses it |
| API / backend service | public API, integration service, worker | **TypeScript with Hono or Fastify** — or the team's strongest language (Go, Python with FastAPI); Postgres; OpenAPI spec |
| Realtime / collaboration | chat, live cursors, multiplayer, live dashboards | the web app baseline + a **long-running server or a managed realtime service** (websockets don't live in serverless functions); CRDTs (e.g. Yjs) for collaborative editing |
| E-commerce | shop, subscriptions, digital goods | **a hosted commerce platform first**; custom or headless only for needs it can't meet; Stripe or a merchant of record for payments |
| Mobile + web | consumer app on phones and the web | **Expo (React Native)** + shared TypeScript packages — or a PWA if offline, push and app stores aren't essential |
| AI features | chat, summaries, semantic search | the web app baseline; model calls on the server with streaming; **Postgres + pgvector** before a dedicated vector database |

Projects often combine archetypes (a content site plus an app). Prefer one framework that
covers both over two stacks, unless the parts have separate teams or very different needs.

## 3. Layer by layer

Each row is a default with the reason to deviate. Vendors are examples, not endorsements —
check current pricing, limits and features before choosing (section 5).

| Layer | Default | Deviate when… |
|-------|---------|---------------|
| Language | TypeScript (strict) end to end | the team's expertise or the domain is elsewhere (data science → Python, high-throughput services → Go) |
| Framework | Next.js for apps with public pages; Astro for content sites; Vite + React for SPAs | the team knows Nuxt, SvelteKit or Remix / React Router well — framework familiarity beats small technical differences |
| UI | Tailwind CSS + shadcn/ui + Lucide | an existing design system or component library must be used |
| Database | PostgreSQL (managed: Neon, Supabase, RDS, Cloud SQL …) | single-user / local-first / tiny apps → SQLite (or libSQL); truly document-shaped data → a document store; never Redis as the primary store |
| ORM / query builder | Prisma (schema-first, migrations, DX) or Drizzle (SQL-close, lightweight, edge-friendly) | heavy SQL / reporting → a query builder or plain parameterized SQL |
| Auth | a maintained library (Auth.js, Better Auth) or a provider (Clerk, Auth0, Supabase Auth) | B2B with SSO/SAML and SCIM → a provider built for it (e.g. WorkOS); **never** custom crypto or password storage — see `backend-security-auditor` |
| Payments | Stripe | selling globally to consumers and not wanting to handle VAT/sales tax yourself → a merchant of record (Paddle, Lemon Squeezy) |
| Email | a transactional provider (Resend, Postmark, Amazon SES) + React Email templates | high-volume marketing → a dedicated marketing platform, kept separate from transactional mail |
| File storage | S3-compatible object storage (S3, Cloudflare R2) | never the app server's disk on serverless or multi-instance hosting |
| Background jobs and cron | the platform's cron + a job service or queue (Inngest, Trigger.dev, BullMQ with Redis) | trivial periodic tasks → platform cron alone; never long work inside a request handler |
| Search | Postgres full-text search | typo tolerance, facets, instant search at scale → Meilisearch, Typesense or Algolia |
| Realtime | a managed service (Ably, Pusher, Supabase Realtime, Liveblocks) | you already run long-lived servers → websockets on your own server |
| Hosting | Vercel / Netlify for Next.js and static sites; Fly.io, Railway or Render for containers and websockets | enterprise, existing cloud contracts or strict compliance → AWS / GCP / Azure; EU users and GDPR concerns → EU regions everywhere (`gdpr-privacy`) |
| Observability | Sentry for errors + structured logs from the platform | high traffic or many services → OpenTelemetry and a log/metrics backend |
| Analytics | a privacy-friendly tool, loaded after consent | product analytics with funnels → a product analytics tool, still behind consent |
| Testing | Vitest (unit) + Playwright (E2E) — see `webapp-testing` | the framework ships its own preferred runner |
| Tooling | pnpm or npm, ESLint + Prettier (or Biome), TypeScript strict, GitHub Actions CI | a monorepo with several apps → workspaces first, a build orchestrator (Turborepo, Nx) only when builds get slow |

## 4. Scoring close decisions

When two options are both reasonable, score them instead of arguing. Weights come from the
requirements (1 = minor, 3 = critical); scores from 1 (poor) to 5 (excellent).

```markdown
| Criterion | Weight | Next.js | Astro |
|-----------|--------|---------|-------|
| Fits the requirements (content + small app area) | 3 | 4 | 4 |
| Team familiarity | 3 | 5 | 2 |
| Ecosystem and maturity | 2 | 5 | 4 |
| Operational complexity | 2 | 3 | 5 |
| Cost at expected scale | 1 | 4 | 5 |
| Lock-in / reversibility | 1 | 3 | 4 |
| **Weighted total** | | **50** | **45** |
```

- Show the arithmetic; let the user change weights.
- **Team familiarity** and **operational complexity** are usually underrated. A familiar, slightly worse tool ships sooner than a perfect unfamiliar one.
- Mark **one-way doors** — decisions expensive to reverse (database engine, auth provider and its user IDs, proprietary hosting features, data residency). Spend the time there; decide two-way doors quickly.

## 5. Verify before recommending

Your knowledge of versions and products may be out of date. Before the final answer:

- **Current major version** and its status: check the official docs or the package registry (`npm view <package> version`, release notes). Don't recommend deprecated tools or setups (e.g. Create React App is deprecated — use Vite or a framework).
- **Maintenance:** recent releases, active maintainers, open security advisories.
- **License:** permissive for your use? Some tools have moved to source-available licenses.
- **Pricing and limits** of managed services at the expected scale, including what happens on the free tier's limits.
- **Compatibility:** the chosen pieces work together (framework version ↔ auth library ↔ ORM ↔ hosting runtime).

If you can't verify something, say so in the recommendation instead of presenting it as fact.

## 6. Output: recommendation and ADR

Answer in this shape:

```markdown
## Recommendation: <project>

**Archetype:** web app with public pages · **Assumptions:** ~2,000 users in year one, EU customers, 2 developers who know React

| Layer | Choice | Why |
|-------|--------|-----|
| Framework | Next.js (App Router), TypeScript | public pages need SEO; the team knows React |
| UI | Tailwind CSS + shadcn/ui | matches the toolkit's design and component skills |
| Database | PostgreSQL (managed, EU region) + Drizzle | relational data, GDPR data residency |
| Auth | Better Auth (email + Google) | no SSO needed; users stay in our database |
| Payments | Stripe | subscriptions, EU cards, invoices |
| Hosting | Vercel (EU functions region) | zero-ops for a 2-person team |

**Alternative:** Astro + a small API, if the app part stays under a few screens.
**One-way doors:** database engine, auth user IDs, hosting region.
**Not chosen and why:** microservices (one team, one product), MongoDB (relational data).
**Toolkit skills that apply:** frontend-design-guide, shadcn-ui, backend-security-auditor, seo-metadata, gdpr-privacy, i18n-setup, webapp-testing.
**Verified:** versions and pricing checked on <date>; unverified: <items>.
```

Then write the decision to `docs/adr/0001-tech-stack.md`:

```markdown
# ADR 0001: Tech stack

- Status: proposed
- Date: YYYY-MM-DD

## Context
What we are building, for whom, at what scale, under which constraints.

## Decision
| Layer | Choice | Reason | Alternatives considered |
|-------|--------|--------|-------------------------|

## Consequences
What becomes easy, what becomes hard, what it costs, what we must learn.

## Revisit when
Concrete triggers: "more than 50,000 monthly users", "a customer needs SAML SSO", "hosting costs exceed X".
```

Finally, offer the official scaffold command for the chosen framework (e.g. `npx create-next-app@latest`, `npm create astro@latest`, `npm create vite@latest`) and **ask before running it** — it creates files in the user's directory.

---

## Anti-patterns

- **Microservices, Kubernetes or event buses for an MVP** run by a small team.
- **A NoSQL database "because it scales"** for relational data.
- **GraphQL, tRPC and REST together**, or GraphQL without several clients that need it.
- **Several databases from day one** (Postgres + Mongo + Redis + a vector DB) before any of them is a bottleneck.
- **Edge runtime for everything** when the database is in one region anyway.
- **Monorepo tooling** for a single app.
- **Choosing by trend:** "it's what everyone on social media uses this month".
- **Rewriting a working stack** without a measured problem and a migration plan.
- **Hidden costs:** recommending paid services without stating the pricing model and limits.

## Behavior rules

- Give **one recommendation and at most one alternative**, not a menu of ten options.
- State assumptions explicitly; ask only the questions that would change the answer.
- In an existing project, respect the existing stack unless there is a measured reason to change; never switch frameworks, ORMs or providers silently while implementing a feature.
- Flag one-way doors and costs clearly.
- Prefer boring, well-documented technology; spend novelty only where it gives the product a real advantage.
- Verify versions and status (section 5) — say what you could not verify.
- Related skills: `database-design`, `auth-flows`, `deploy-and-ops`, `ecommerce`, `cms-content`, `realtime`, `ai-features` (per-area decisions), `backend-security-auditor` (auth and data choices), `gdpr-privacy` (regions, processors), `seo-metadata` (rendering strategy), `i18n-setup` (multilingual routing), `frontend-design-guide` and `shadcn-ui` (UI layer).
