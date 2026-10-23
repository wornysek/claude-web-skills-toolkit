---
name: frontend-security
description: "Client-side and supply-chain security for websites and web apps: XSS in React and other frameworks (dangerouslySetInnerHTML, user-controlled URLs, Markdown and CMS HTML), a nonce-based Content Security Policy and Trusted Types, third-party scripts and tag managers, iframes and postMessage, secrets and data in client bundles and source maps, browser storage, open redirects, and dependency security (lockfiles, audits, update bots, release age, install scripts, typosquatting, pinned CI actions). Use whenever you render user or CMS content, add a third-party script, embed or dependency, configure CSP or headers, or review frontend code for security. For server-side rules (auth, IDOR, validation, webhooks) use backend-security-auditor."
triggers:
  - "XSS / dangerouslySetInnerHTML / render HTML or Markdown"
  - "Content Security Policy / CSP / nonce / Trusted Types"
  - "add a third-party script / widget / tag manager / embed"
  - "npm audit / dependency update / is this package safe?"
  - "frontend security review"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  references: "OWASP XSS Prevention Cheat Sheet, OWASP Top 10, CSP Level 3"
---

# Frontend security

The browser runs everything the page loads: your code, every dependency in the bundle
and every third-party script. One XSS or one compromised package can read the page, act
as the user and exfiltrate data. Server rules live in `backend-security-auditor`; this
skill covers what reaches the browser.

## Process

1. **List what renders untrusted data:** user content, CMS content, URL parameters, third-party responses.
2. **List what executes third-party code:** scripts, tag managers, widgets, iframes, dependencies.
3. **Apply sections A–F** and fix findings in code.
4. **Add the guard rails:** CSP, dependency checks in CI, the toolkit's secrets guard hook.
5. **Report** using the output format at the end.

---

## A. XSS

React, Vue, Svelte and Angular escape text by default. XSS appears where that escaping is bypassed.

| ❌ Risk | ✅ Safe pattern |
|--------|----------------|
| `dangerouslySetInnerHTML={{ __html: userHtml }}` | render text, or sanitize with DOMPurify first (below) |
| `<a href={user.website}>` with `javascript:` URLs | allow only `http:`, `https:`, `mailto:` (below) |
| `ref.current.innerHTML = …`, `insertAdjacentHTML`, `document.write` | DOM APIs that set text: `textContent` |
| `eval`, `new Function`, `setTimeout("code")` | never with dynamic input |
| Markdown rendered to HTML with raw HTML enabled | a Markdown renderer with HTML disabled or `rehype-sanitize` |
| MDX from users | **never** — MDX is code; only trusted authors (`cms-content`) |
| `JSON.stringify(data)` inside `<script>` | escape `<` (`.replace(/</g, "\\u003c")`), see `seo-metadata` |
| Server-rendered templates with "unescaped" output (`{{{ }}}`, `|safe`, `v-html`) | escaped output; sanitize if HTML is required |

```ts
// lib/safe-html.ts — when HTML must be rendered (CMS rich text, email previews)
import DOMPurify from "isomorphic-dompurify";

export function sanitizeHtml(dirty: string): string {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: ["p", "br", "strong", "em", "a", "ul", "ol", "li", "h2", "h3", "blockquote", "code", "pre"],
    ALLOWED_ATTR: ["href", "title"],
    ALLOWED_URI_REGEXP: /^(https?:|mailto:)/i,
  });
}
```

```ts
// lib/safe-url.ts — for href/src values that come from users or external data
const ALLOWED_PROTOCOLS = new Set(["http:", "https:", "mailto:"]);

export function safeUrl(raw: string | null | undefined): string | undefined {
  if (!raw) return undefined;
  try {
    const url = new URL(raw, "https://placeholder.invalid");
    return ALLOWED_PROTOCOLS.has(url.protocol) ? raw : undefined;
  } catch {
    return undefined;
  }
}
```

## B. Content Security Policy

A strict, nonce-based CSP turns most XSS into a blocked script. Start with
`Content-Security-Policy-Report-Only`, collect reports, then enforce.

```ts
// src/proxy.ts (Next.js 16; in Next.js 15 the file is middleware.ts and the function is `middleware`)
import { NextResponse, type NextRequest } from "next/server";

export function proxy(request: NextRequest) {
  const nonce = Buffer.from(crypto.randomUUID()).toString("base64");
  const isDev = process.env.NODE_ENV === "development";
  const csp = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${isDev ? " 'unsafe-eval'" : ""}`,
    `style-src 'self' 'nonce-${nonce}'`,
    "img-src 'self' blob: data:",
    "font-src 'self'",
    "connect-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
    "upgrade-insecure-requests",
  ].join("; ");

  const requestHeaders = new Headers(request.headers);
  requestHeaders.set("x-nonce", nonce);
  requestHeaders.set("Content-Security-Policy", csp);

  const response = NextResponse.next({ request: { headers: requestHeaders } });
  response.headers.set("Content-Security-Policy", csp);
  return response;
}
```

- Next.js reads the nonce from the request header and applies it to its own scripts; pass it to your `<Script nonce>` tags. A nonce-based CSP makes pages dynamically rendered.
- If the project already has a proxy (e.g. `next-intl`), compose both into one function.
- Add every third-party origin explicitly (`connect-src`, `img-src`, `frame-src`) — never `*` or `'unsafe-inline'` for scripts.
- Add `report-to` / `report-uri` and review the reports.
- **Trusted Types** (`require-trusted-types-for 'script'`) blocks DOM XSS sinks in Chromium-based browsers; enable it once the code base passes in report-only mode.
- Static hosts without a server: use a hash-based CSP or at least `object-src 'none'; base-uri 'self'; frame-ancestors 'none'`.

## C. Third-party scripts, iframes and messaging

- **Every third-party script is full access to your page.** Keep a list (owner, purpose, data it sees), load the minimum, and remove what isn't used.
- **Tag managers** are a back door for anyone with access to them: restrict who can publish, review changes, and disallow custom HTML tags where possible.
- **Pin and verify** scripts from CDNs with Subresource Integrity (`integrity="sha384-…" crossorigin="anonymous"`) or self-host them.
- **Iframes** for embeds and untrusted content use `sandbox` with only the needed flags and a separate origin for user-generated HTML.
- **`postMessage`:** always check `event.origin` against an allowlist and validate `event.data` with a schema; send with an explicit target origin, never `"*"`.
- **Links** to other sites with `target="_blank"` get `rel="noopener noreferrer"`.
- **Clickjacking:** `frame-ancestors 'none'` (or a list of allowed parents).

```ts
window.addEventListener("message", (event) => {
  if (event.origin !== "https://widget.example.com") return;
  const message = WidgetMessageSchema.safeParse(event.data);
  if (!message.success) return;
  // ...
});
```

## D. Secrets and data in the client

- **Everything in the bundle is public.** Only publishable keys go to the client (e.g. a Stripe publishable key, an analytics site ID). Secrets never get a `NEXT_PUBLIC_` / `VITE_` / `PUBLIC_` prefix.
- **Source maps:** don't serve them publicly in production; upload them privately to the error tracker (`deploy-and-ops`).
- **No sensitive data in browser storage:** no tokens or personal data in `localStorage` / `sessionStorage` / IndexedDB (session cookies per `backend-security-auditor` A1). Clear user-specific caches on sign-out.
- **No personal data in URLs** (they leak to logs, analytics and the `Referer` header).
- **Server Components and props:** whatever is passed to client components is in the HTML — trim it on the server.
- **Open redirects:** a `?next=` or `?returnTo=` parameter accepts only relative paths starting with `/` and not `//`.
- The toolkit's guard hook (`./install.sh --hooks`) blocks secrets before they are written to files.

## E. Dependencies and supply chain

Popular npm packages have been compromised (maintainer account takeovers, malicious
updates, self-spreading install-script worms). Treat every dependency as code you ship.

- **Before adding a package:** is it needed (native APIs, an existing dependency)? Check the exact name (typosquatting), maintainers, weekly downloads, last release, repository, open security advisories and install scripts.
- **Lockfile committed**; CI installs with `npm ci` / `pnpm install --frozen-lockfile` — never a fresh resolve.
- **Audit in CI:** `npm audit --audit-level=high` (or `pnpm audit`) and `npm audit signatures` (registry signatures and provenance).
- **Install scripts:** pnpm 10+ doesn't run dependency lifecycle scripts unless allowed (`onlyBuiltDependencies`); with npm consider `ignore-scripts=true` and allow the few packages that need a build step explicitly.
- **Release age:** don't install versions published minutes ago — most malicious releases are caught within days.
- **Update bot** with grouping, a minimum release age and auto-merge only for low-risk updates that pass CI:

```json
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "minimumReleaseAge": "3 days",
  "lockFileMaintenance": { "enabled": true },
  "packageRules": [
    { "matchUpdateTypes": ["patch", "minor"], "matchCurrentVersion": "!/^0/", "automerge": true },
    { "matchDepTypes": ["devDependencies"], "groupName": "dev dependencies" }
  ]
}
```

```yaml
# pnpm-workspace.yaml (pnpm) — refuse versions younger than 3 days (value in minutes)
minimumReleaseAge: 4320
```

- **CI actions** are dependencies too: pin third-party GitHub Actions to a full commit SHA, give workflows `permissions: contents: read` by default (`deploy-and-ops`).
- **Remove unused dependencies** regularly (`knip`, `depcheck`).

## F. Browser hardening headers

Set with the other security headers (`backend-security-auditor` F2):

| Header | Value |
|--------|-------|
| `Content-Security-Policy` | section B |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | disable what you don't use: `camera=(), microphone=(), geolocation=(), payment=()` |
| `Cross-Origin-Opener-Policy` | `same-origin` (check OAuth popups and payment windows) |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains` (add `preload` deliberately) |

---

## Checklist

- [ ] No `dangerouslySetInnerHTML` / `v-html` / `innerHTML` with unsanitized data; HTML sanitized with an allowlist.
- [ ] User-controlled URLs pass `safeUrl`; redirects accept only relative paths.
- [ ] Markdown rendering has raw HTML disabled or sanitized; no MDX from untrusted authors.
- [ ] A nonce- or hash-based CSP is enforced (after report-only); third-party origins listed explicitly.
- [ ] Third-party scripts listed with owners; SRI or self-hosting; tag manager access restricted.
- [ ] `postMessage` checks origin and validates data; iframes sandboxed; `frame-ancestors` set.
- [ ] No secrets in the bundle or browser storage; source maps not public.
- [ ] Lockfile + frozen install in CI; audit and signature checks; minimum release age; install scripts controlled.
- [ ] Update bot configured; GitHub Actions pinned and least-privilege.

## Output format

```markdown
## Frontend security review: app/

| # | Severity | Area | Finding | File:line | Fix |
|---|----------|------|---------|-----------|-----|
| 1 | 🔴 Critical | XSS | Comment body rendered with `dangerouslySetInnerHTML` | components/comment.tsx:22 | render as text / `sanitizeHtml` |
| 2 | 🟠 High | XSS | Profile website used directly in `href` | components/profile-card.tsx:15 | `safeUrl()` |
| 3 | 🟠 High | Supply chain | CI uses `npm install` without a lockfile check | .github/workflows/ci.yml:18 | `npm ci` + `npm audit --audit-level=high` |
| 4 | 🟡 Medium | CSP | No CSP header | src/proxy.ts | nonce-based CSP, report-only first |
```

## Related skills

- `backend-security-auditor` (server side, cookies, headers), `deploy-and-ops` (CI permissions, source maps), `cms-content` (rich text and MDX), `seo-metadata` (JSON-LD escaping), `gdpr-privacy` (third-party data flows).
