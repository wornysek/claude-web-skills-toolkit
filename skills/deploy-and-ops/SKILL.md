---
name: deploy-and-ops
description: "Deployment and operations for websites and web apps: environments (local, preview, staging, production) and configuration, secrets per environment, a CI pipeline (lint, types, tests, build, audit, E2E), continuous deployment and preview deployments, database migrations in the release, rollbacks and feature flags, domains, DNS and TLS, self-hosting with Docker, observability (health checks, error tracking with releases, structured logs, uptime monitoring, alerts), backups and restore drills, incidents, account security and cost controls. Use whenever you set up or change CI/CD, hosting, domains, environment variables, monitoring, logging or backups, or prepare a launch. For choosing the hosting provider use tech-stack-advisor."
triggers:
  - "deploy / CI/CD / GitHub Actions / pipeline"
  - "preview deployments / staging / production"
  - "environment variables / secrets per environment"
  - "domain / DNS / SSL / HTTPS / redirect www"
  - "monitoring / logging / alerts / uptime / Sentry"
  - "backups / restore / rollback / incident / go-live checklist"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Deploy & ops

A web project is finished when it can be released safely, observed in production,
rolled back in minutes and restored after a disaster. This skill covers the path from a
pull request to production and what keeps production healthy.

## Process

1. **Environments and configuration** (sections 1–2).
2. **CI** that blocks broken changes (section 3), **CD** with previews (section 4).
3. **Release safety:** migrations, rollbacks, flags (sections 5–6).
4. **Domains and TLS** (section 7), optionally **self-hosting** (section 8).
5. **Observability** (section 9), **backups** (section 10), **incidents** (section 11).
6. **Accounts, access and costs** (section 12), then the launch checklist.

---

## 1. Environments

| Environment | Purpose | Data | Indexing |
|-------------|---------|------|----------|
| Local | development | seed data (`database-design`) | — |
| Preview | one per pull request, for review and E2E | seed / anonymized | `noindex` |
| Staging (optional) | release candidate, close to production | anonymized copy | `noindex`, often password-protected |
| Production | users | real | indexed |

- Environments differ only in configuration, not in code paths (`if (env === "staging")` is a smell).
- Previews never use production databases, payment live keys or real email sending.
- Every non-production URL sends `X-Robots-Tag: noindex` (`seo-metadata`).

## 2. Configuration and secrets

- All configuration through environment variables, **validated at startup** with a schema (`backend-security-auditor` G4) — the app refuses to start with missing or malformed config.
- Secrets live in the host's or a dedicated secret store, scoped per environment (preview ≠ production). Test keys in previews, live keys only in production.
- `.env.example` in the repo lists every variable with a placeholder and a comment; real `.env*` files are gitignored.
- Rotate secrets on staff changes and after any leak; know how to rotate each one without downtime.
- Build-time vs. runtime: client-exposed variables (`NEXT_PUBLIC_*`) are baked into the build — changing them needs a rebuild.

## 3. CI pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4 # pin third-party actions to a full commit SHA
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npx tsc --noEmit
      - run: npm test --if-present
      - run: npm run build
      - run: npm audit --audit-level=high

  e2e:
    needs: check
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
          cache: npm
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --project=chromium
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

- **Required checks** on the main branch; no direct pushes; at least one review for production code.
- Add the project's extra gates: `i18n:check` (`i18n-setup`), Lighthouse CI (`web-performance`), axe tests (`a11y-auditor`).
- Keep CI fast (< 10 minutes): caching, parallel jobs, only the browsers you need.
- Workflows get the **least privileges** (`permissions:` per job); deployments to cloud accounts use OIDC federation instead of long-lived keys.

## 4. Continuous deployment and previews

- `main` deploys to production automatically after CI passes; every pull request gets a preview URL.
- **Immutable builds:** the artifact tested in CI is the one deployed — no rebuild with different inputs.
- Each deploy is tagged with the **release** (commit SHA) so errors and logs map to a version.
- Post-deploy **smoke test**: hit `/api/health` and the home page; roll back automatically or alert on failure.
- Deploy freezes for risky periods are written down (sales events, launches), not remembered.

## 5. Database migrations in the release

- Migrations run as a **separate, explicit step** before the new code goes live (`prisma migrate deploy`, `drizzle-kit migrate`) — never automatically on every app start of many instances.
- Every migration is **backward compatible with the currently running code** (expand → migrate code → contract — `database-design`), so a rollback of the code doesn't need a rollback of the schema.
- Take a backup or snapshot before destructive migrations.

## 6. Rollbacks and feature flags

- Know the rollback path for each platform (instant rollback to the previous deployment, previous container tag) and **practice it**.
- Ship risky features behind **feature flags** (per user, percentage, environment) and release by turning the flag on; remove flags after rollout.
- A rollback is the default response to a bad release; fix forward only when it is quick and safe.

## 7. Domains, DNS and TLS

| Record | Example | Notes |
|--------|---------|-------|
| Apex | `example.com A / ALIAS / ANAME → host` | per host instructions |
| www | `www.example.com CNAME → host` | redirect one to the other (301/308), keep one canonical |
| CAA | `example.com CAA 0 issue "letsencrypt.org"` | only the CAs you use |
| Email | SPF, DKIM, DMARC TXT records | `transactional-email` |
| Verification | TXT records for search consoles, providers | remove stale ones |

- HTTPS everywhere, certificates renewed automatically; HTTP redirects to HTTPS; HSTS once everything (including subdomains) works over HTTPS — `preload` only deliberately.
- Lower the TTL a day before a DNS migration; raise it afterwards.
- **Registrar account:** 2FA, registrar lock, auto-renew, a shared ops contact — an expired domain takes everything down, email included.
- Subdomains for user content or other apps are separate origins (cookies, CSP).

## 8. Self-hosting (containers)

```dockerfile
# Dockerfile — Next.js with output: "standalone" in next.config.ts
FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:24-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:24-alpine AS run
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S app && adduser -S app -G app
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
USER app
EXPOSE 3000
CMD ["node", "server.js"]
```

- Run as a non-root user; no secrets in the image (inject at runtime); scan images for vulnerabilities.
- A reverse proxy or the platform terminates TLS; set `trust proxy` / forwarded-header handling correctly (rate limiting depends on the real client IP).
- Multiple instances need shared state for sessions, rate limits, caches and websockets (`realtime`).

## 9. Observability

**Health check** (for the platform, the load balancer and uptime monitoring):

```ts
// app/api/health/route.ts
export async function GET() {
  try {
    await db.$queryRaw`SELECT 1`;
    return Response.json({ status: "ok", release: process.env.RELEASE_SHA ?? null }, { headers: { "Cache-Control": "no-store" } });
  } catch {
    return Response.json({ status: "degraded" }, { status: 503, headers: { "Cache-Control": "no-store" } });
  }
}
```

**Structured logs** with request IDs and redaction:

```ts
// lib/logger.ts
import pino from "pino";

export const logger = pino({
  level: process.env.LOG_LEVEL ?? "info",
  base: { service: "web", release: process.env.RELEASE_SHA },
  redact: {
    paths: ["req.headers.cookie", "req.headers.authorization", "*.password", "*.token", "*.email"],
    censor: "[redacted]",
  },
});
```

- **Error tracking** (e.g. Sentry) with the release, environment and privately uploaded source maps; PII scrubbing per `gdpr-privacy`.
- **Uptime monitoring** from outside your infrastructure for the home page, sign-in and the health endpoint; alerts to a channel someone watches.
- **Alerts on symptoms users feel:** error rate, p95 latency, failed payments or sign-ins, queue backlog — not on every CPU spike. Every alert has an owner and a runbook link.
- **Dashboards:** traffic, errors, latency (p50/p95), Core Web Vitals (`web-performance`), background job failures.
- **Log retention** follows `gdpr-privacy` (short for access logs, no personal data where not needed).
- A public **status page** for products with paying users.

## 10. Backups and restore

- Define **RPO** (how much data you may lose) and **RTO** (how long you may be down) per system.
- Databases: automated daily backups plus point-in-time recovery where available; retention per policy; encrypted; stored in a different account or region (3-2-1).
- Object storage: versioning or replication for user uploads.
- **A backup that was never restored is not a backup:** run a restore drill at least quarterly into a separate environment and record the time it took.
- Backups contain personal data — access is restricted and deletion requests expire with the backup cycle (`gdpr-privacy`).

## 11. Incidents

- Severity levels with examples (SEV1: site down or data exposed; SEV2: key feature broken; SEV3: degraded).
- A short runbook: who decides, how to roll back, where logs and dashboards are, who communicates.
- Communicate early on the status page; for personal data breaches the legal clock starts (`gdpr-privacy`: 72 hours).
- After every SEV1/SEV2: a blameless postmortem with causes, timeline and tracked follow-ups.

## 12. Accounts, access and costs

- 2FA on hosting, registrar, DNS, CI, package registry, email provider, payment provider and error tracker accounts.
- Least privilege; shared accounts replaced by teams; offboarding removes access the same day.
- Budgets and spend alerts on every paid service; caps or rate limits on anything billed per request (AI APIs, image transforms, email).
- Know every recurring cost and who pays it.

---

## Launch checklist

- [ ] Environments separated; previews `noindex` and on test keys; config validated at startup.
- [ ] CI: lint, types, tests, build, audit, E2E; required checks on `main`; least-privilege workflows.
- [ ] CD with previews and post-deploy smoke tests; releases tagged with the commit SHA.
- [ ] Migrations run as a separate step and are backward compatible; rollback practiced.
- [ ] Domain: HTTPS, one canonical host, CAA, email DNS, registrar lock and auto-renew.
- [ ] Health endpoint, error tracking with releases, structured redacted logs, uptime monitoring, alerts with owners.
- [ ] Backups automated, off-site, and a restore drill done; RPO/RTO written down.
- [ ] Incident runbook and status page; 2FA everywhere; spend alerts on paid services.

## Output format

```markdown
## Ops review: production readiness

| # | Area | Finding | Fix | Priority |
|---|------|---------|-----|----------|
| 1 | Backups | Daily DB backups, never restored | quarterly restore drill, document RTO | 🔴 |
| 2 | CI | No required checks on main | branch protection + required `check` and `e2e` | 🔴 |
| 3 | Monitoring | Errors not tagged with release | `RELEASE_SHA` in Sentry and logs | 🟠 |
| 4 | DNS | No CAA record | `CAA 0 issue "letsencrypt.org"` | 🟡 |
```

## Related skills

- `tech-stack-advisor` (choosing hosting), `database-design` (migrations, seeds), `backend-security-auditor` (env validation, headers), `frontend-security` (supply chain, CI pinning), `web-performance` (Lighthouse CI, CDN), `transactional-email` (email DNS), `gdpr-privacy` (logs, backups, breaches), `seo-metadata` (noindex for previews).
