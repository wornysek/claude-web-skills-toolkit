---
name: backend-security-auditor
description: "Strict security audit and rules for full-stack backends (Next.js/Node.js/Express, Prisma/Drizzle/SQL, Supabase): OAuth2/OpenID Connect sign-in with state and PKCE, passwords, session cookies, admin routes, IDOR and data ownership, RLS, Zod validation, mass assignment, uploads, SQL injection, trimming API responses, CORS, security headers (the CSP lives in frontend-security), SSRF, rate limiting, webhook signatures (HMAC, Stripe, public-key) and error messages in production. Use whenever you write or review an API endpoint, server action, authentication, database query, upload, webhook or admin feature."
triggers:
  - "API endpoint / route handler / server action"
  - "sign-in / OAuth2 / OpenID Connect / session / cookies / passwords"
  - "admin panel / roles / permissions"
  - "orders / tickets / comments / any user-generated content"
  - "file upload / avatar / attachment"
  - "webhook from a payment or other provider"
  - "database query / Prisma / Drizzle / SQL / Supabase RLS"
  - "security review / security audit / is this secure?"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.1.0"
  references: "OWASP ASVS 4.0, OWASP API Security Top 10 (2023), CWE Top 25, OAuth 2.0 Security Best Current Practice (RFC 9700)"
---

# Backend Security Auditor

You are a security engineer. These rules are **mandatory** for all server-side code you
write or modify. They are not recommendations — breaking a rule marked **MUST** is a bug
that you fix before declaring the work done.

Reference architecture used in the examples: a multi-user web application with **OAuth2 /
OpenID Connect sign-in** (any provider), **orders**, **support tickets**, **comments**, file
uploads, an **admin area** and **webhooks** from a payment provider. Roles: `user`, `support`,
`moderator`, `admin`. The rules apply to any Node.js backend in general.

## Audit process

1. **Map the attack surface:** list all endpoints, server actions, webhooks, cron jobs and uploads within the scope of the change.
2. **For every entry point** answer: Who may call it? How is that enforced on the server? What input does it accept and where is it validated? What data does it return?
3. **Go through sections A–G** below and verify each rule against the actual code (not comments or documentation).
4. **Fix the findings** in the code. For every fix, add or update a test that would catch a regression.
5. **Output a report** in the format at the end of this file.

---

## A. Authentication and session

> Prefer a maintained auth library or provider (Auth.js, Better Auth, Arctic, Lucia-style
> session patterns, a managed identity provider) over hand-written auth. The code below shows
> what such a library must do — use it to **review** whatever is in the project.

### A1. No tokens in `localStorage` / `sessionStorage` — MUST
Session tokens, access tokens, refresh tokens and JWTs **must not** be accessible to
JavaScript. Any XSS would steal them immediately. The session lives exclusively in a cookie:

```
Set-Cookie: __Host-session=<opaque>; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=604800
```

- `HttpOnly` — unreadable from JS.
- `Secure` — HTTPS only.
- `SameSite=Lax` — blocks cross-site POST (CSRF). **Not `Strict`** when you use OAuth: the return from the provider is a cross-site top-level navigation, and with `Strict` the cookie would not be sent.
- `__Host-` prefix — the browser enforces `Secure`, `Path=/` and forbids the `Domain` attribute (protection against being overwritten from a subdomain).

```ts
// ❌ FORBIDDEN
localStorage.setItem("token", data.accessToken);
fetch("/api/tickets", { headers: { Authorization: `Bearer ${localStorage.getItem("token")}` } });

// ✅ The browser sends the cookie automatically; the frontend never sees the token
fetch("/api/tickets", { credentials: "same-origin" });
```

### A2. The session is an opaque random ID stored as a hash — MUST

```ts
// lib/session.ts
import "server-only";
import { createHash, randomBytes } from "node:crypto";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

const SESSION_COOKIE = "__Host-session";
const SESSION_TTL_SECONDS = 60 * 60 * 24 * 7;

const hashToken = (token: string) => createHash("sha256").update(token).digest("hex");

export async function createSession(userId: string) {
  const token = randomBytes(32).toString("base64url");
  await db.session.create({
    data: {
      tokenHash: hashToken(token),
      userId,
      expiresAt: new Date(Date.now() + SESSION_TTL_SECONDS * 1000),
    },
  });
  (await cookies()).set(SESSION_COOKIE, token, {
    httpOnly: true,
    secure: true,
    sameSite: "lax",
    path: "/",
    maxAge: SESSION_TTL_SECONDS,
  });
}

export async function getSessionUser() {
  const token = (await cookies()).get(SESSION_COOKIE)?.value;
  if (!token) return null;
  const session = await db.session.findUnique({
    where: { tokenHash: hashToken(token) },
    select: { expiresAt: true, user: { select: { id: true, name: true, role: true, bannedAt: true } } },
  });
  if (!session || session.expiresAt < new Date() || session.user.bannedAt) return null;
  return session.user;
}

export async function destroySession() {
  const store = await cookies();
  const token = store.get(SESSION_COOKIE)?.value;
  if (token) await db.session.deleteMany({ where: { tokenHash: hashToken(token) } });
  store.set(SESSION_COOKIE, "", { httpOnly: true, secure: true, sameSite: "lax", path: "/", maxAge: 0 });
}
```

- A new session is created **after every sign-in** (protection against session fixation).
- Sign-out **deletes the session on the server**, not just the cookie.
- A ban or role change takes effect immediately, because the role is read from the DB on every request, not from the cookie.

### A3. OAuth2 / OpenID Connect: `state`, PKCE and a fixed redirect URI — MUST
Without `state` the sign-in is vulnerable to login CSRF (the attacker signs the victim into
the attacker's account); without PKCE an intercepted authorization code can be redeemed.
The flow below is provider-agnostic — the endpoints come from the provider's documentation
(or its OpenID Connect discovery document).

```ts
// lib/oauth-provider.ts
import "server-only";
import { env } from "@/lib/env";

export const provider = {
  authorizeUrl: env.OAUTH_AUTHORIZE_URL,
  tokenUrl: env.OAUTH_TOKEN_URL,
  userInfoUrl: env.OAUTH_USERINFO_URL,
  clientId: env.OAUTH_CLIENT_ID,
  clientSecret: env.OAUTH_CLIENT_SECRET,
  redirectUri: env.OAUTH_REDIRECT_URI, // exact match with the URI registered at the provider
  scope: "openid email profile",        // minimization: request only what you use
} as const;

export const OAUTH_COOKIE_OPTIONS = { httpOnly: true, secure: true, sameSite: "lax", path: "/", maxAge: 600 } as const;
```

```ts
// app/api/auth/oauth/route.ts — start of sign-in
import { createHash, randomBytes } from "node:crypto";
import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { OAUTH_COOKIE_OPTIONS, provider } from "@/lib/oauth-provider";

export async function GET() {
  const state = randomBytes(32).toString("base64url");
  const codeVerifier = randomBytes(32).toString("base64url");
  const codeChallenge = createHash("sha256").update(codeVerifier).digest("base64url");

  const store = await cookies();
  store.set("__Host-oauth_state", state, OAUTH_COOKIE_OPTIONS);
  store.set("__Host-oauth_verifier", codeVerifier, OAUTH_COOKIE_OPTIONS);

  const url = new URL(provider.authorizeUrl);
  url.search = new URLSearchParams({
    client_id: provider.clientId,
    redirect_uri: provider.redirectUri,
    response_type: "code",
    scope: provider.scope,
    state,
    code_challenge: codeChallenge,
    code_challenge_method: "S256",
  }).toString();

  return NextResponse.redirect(url);
}
```

```ts
// app/api/auth/oauth/callback/route.ts — return from the provider
import { timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { NextResponse, type NextRequest } from "next/server";
import { z } from "zod";
import { OAUTH_COOKIE_OPTIONS, provider } from "@/lib/oauth-provider";
import { createSession } from "@/lib/session";
import { upsertOAuthUser } from "@/lib/users";

const TokenResponse = z.object({ access_token: z.string().min(1), token_type: z.string() });
// OpenID Connect userinfo; non-OIDC providers return other fields — adapt the schema, keep it strict
const UserInfo = z.object({
  sub: z.string().min(1).max(255),
  email: z.string().email().optional(),
  email_verified: z.boolean().optional(),
  name: z.string().max(200).optional(),
  picture: z.string().url().optional(),
});

function safeEqual(a: string, b: string) {
  const ab = Buffer.from(a);
  const bb = Buffer.from(b);
  return ab.length === bb.length && timingSafeEqual(ab, bb);
}

export async function GET(req: NextRequest) {
  const fail = () => NextResponse.redirect(new URL("/login?error=oauth", req.url));

  const code = req.nextUrl.searchParams.get("code");
  const state = req.nextUrl.searchParams.get("state");
  const store = await cookies();
  const expectedState = store.get("__Host-oauth_state")?.value;
  const codeVerifier = store.get("__Host-oauth_verifier")?.value;
  store.set("__Host-oauth_state", "", { ...OAUTH_COOKIE_OPTIONS, maxAge: 0 });
  store.set("__Host-oauth_verifier", "", { ...OAUTH_COOKIE_OPTIONS, maxAge: 0 });

  if (!code || !state || !expectedState || !codeVerifier || !safeEqual(state, expectedState)) return fail();

  const tokenRes = await fetch(provider.tokenUrl, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" },
    body: new URLSearchParams({
      client_id: provider.clientId,
      client_secret: provider.clientSecret,
      grant_type: "authorization_code",
      code,
      redirect_uri: provider.redirectUri,
      code_verifier: codeVerifier,
    }),
    signal: AbortSignal.timeout(5000),
  });
  if (!tokenRes.ok) return fail();
  const token = TokenResponse.safeParse(await tokenRes.json());
  if (!token.success) return fail();

  const meRes = await fetch(provider.userInfoUrl, {
    headers: { Authorization: `Bearer ${token.data.access_token}` },
    signal: AbortSignal.timeout(5000),
  });
  if (!meRes.ok) return fail();
  const me = UserInfo.safeParse(await meRes.json());
  if (!me.success) return fail();

  // Link by (provider, subject) — the stable ID from the provider, never from client parameters.
  // Use the email only if the provider says it is verified.
  const user = await upsertOAuthUser({
    provider: "oidc",
    subject: me.data.sub,
    email: me.data.email_verified ? me.data.email : undefined,
    name: me.data.name,
    avatarUrl: me.data.picture,
  });
  await createSession(user.id);

  return NextResponse.redirect(new URL("/dashboard", req.url));
}
```

- `redirect_uri` is a constant from configuration, **never** from a query parameter (open redirect / code theft).
- Allow a post-sign-in redirect (`?next=/...`) only to relative paths starting with `/` and not `//`.
- **Account linking:** identify users by `(provider, subject)`. Never merge accounts by an **unverified** email — that is an account takeover.
- With OpenID Connect, a library that validates the **ID token** (signature, `iss`, `aud`, `exp`, `nonce`) is better than calling the userinfo endpoint by hand.
- Discard the provider's access token once you have the identity. If you must keep it (API calls on the user's behalf), store it **encrypted** on the server and never return it to the frontend.
- `client_secret` lives only in the server environment — never in a variable with the `NEXT_PUBLIC_` prefix.

### A4. Passwords and account recovery — MUST (if the app has passwords)
- Hash with **Argon2id** (or bcrypt / scrypt) through a maintained library — never a fast hash (SHA-256, MD5) and never custom crypto.
- Minimum length 8 (better 12+), no composition rules, allow paste and password managers; optionally reject known-breached passwords.
- **Reset and verification tokens:** random, stored **hashed**, single-use, expiring (≤ 1 hour), invalidated after a password change; all other sessions are revoked after a reset.
- The same response for "email exists" and "email doesn't exist" on sign-in, sign-up and password reset (no account enumeration).
- Rate-limit sign-in, reset and verification endpoints per account **and** per IP (see G1). Offer 2FA (TOTP or passkeys) for accounts with privileges.

### A5. Protecting admin and staff routes — MUST
Authorization is enforced **on the server in every handler**. Middleware and hiding buttons
in the frontend are just UX, not security (see CVE-2025-29927 — bypassing Next.js middleware
with the `x-middleware-subrequest` header).

```ts
// lib/authz.ts
import "server-only";
import { getSessionUser } from "@/lib/session";

export type Role = "user" | "support" | "moderator" | "admin";

const ROLE_RANK: Record<Role, number> = { user: 0, support: 1, moderator: 2, admin: 3 };

export class HttpError extends Error {
  constructor(public readonly status: 401 | 403 | 404 | 409 | 413 | 415 | 422 | 429, message?: string) {
    super(message ?? String(status));
  }
}

export async function requireUser() {
  const user = await getSessionUser();
  if (!user) throw new HttpError(401);
  return user;
}

export async function requireRole(minimum: Role) {
  const user = await requireUser();
  if (ROLE_RANK[user.role as Role] < ROLE_RANK[minimum]) throw new HttpError(403);
  return user;
}
```

```ts
// app/api/admin/users/[id]/ban/route.ts
export async function POST(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  const moderator = await requireRole("moderator"); // first line of the handler, no exceptions
  const { id } = await params;
  // ...
}
```

- Every server action (`"use server"`) is a public HTTP endpoint — it calls `requireUser()`/`requireRole()` first.
- The role is read from the DB (see A2), never from a JWT claim, cookie or header the client can influence.
- Privileged actions (refunds, bans, role changes, deleting content) are written to an **audit log** (who, what, when, on which resource).

### A6. CSRF on state-changing requests — MUST
- State changes **never** via `GET` (no `GET /api/tickets/123/close`).
- `SameSite=Lax` + checking the `Origin` header on `POST`/`PUT`/`PATCH`/`DELETE` in APIs outside server actions (Next.js server actions check Origin themselves).

```ts
export function assertSameOrigin(req: Request) {
  const origin = req.headers.get("origin");
  if (!origin || origin !== env.APP_ORIGIN) throw new HttpError(403);
}
```

---

## B. IDOR and object-level authorization

### B1. Ownership is verified on the server — MUST
`resource.userId === user.id` (or the corresponding role) must hold. Ideally directly in the
query, so that someone else's record never leaves the database.

```ts
// ❌ IDOR: any signed-in user reads someone else's ticket by changing the ID in the URL
const ticket = await db.ticket.findUnique({ where: { id } });
return Response.json(ticket);

// ✅ The ownership filter is part of the query; staff see everything
const user = await requireUser();
const isStaff = user.role === "support" || user.role === "moderator" || user.role === "admin";
const ticket = await db.ticket.findFirst({
  where: { id, ...(isStaff ? {} : { authorId: user.id }) },
  select: ticketDetailSelect,
});
if (!ticket) throw new HttpError(404); // 404, not 403 — don't reveal that the record exists
```

Write a permission matrix for every resource and keep it next to the code. Example:

| Resource | Read | Create | Update | Delete |
|----------|------|--------|--------|--------|
| Order | owner, support, admin | signed-in user | owner while `pending`; staff (status) | admin (soft delete) |
| Internal note on a ticket | support, admin | support, admin | note author | admin |
| Ticket | owner, support, admin | signed-in user | owner (text), staff (status) | admin |
| Comment | public or per visibility | signed-in, not banned | author (time limit), moderator | author, moderator |

IDs referenced **inside** a request body are objects too: an order's `shippingAddressId`, a
comment's `parentId`, an invoice's `customerId` — check that each belongs to the user.

### B2. UUID v4 instead of sequential IDs — MUST
Publicly visible identifiers are `uuid` (v4, `crypto.randomUUID()`), not `1, 2, 3…`.
Sequential IDs make enumeration easy and reveal data volume. **A UUID does not replace
authorization** — it is only a second layer of defense next to B1.

```prisma
model Ticket {
  id        String   @id @default(uuid()) @db.Uuid
  authorId  String   @db.Uuid
  author    User     @relation(fields: [authorId], references: [id])
  status    TicketStatus @default(OPEN)
  createdAt DateTime @default(now())

  @@index([authorId])
}
```

### B3. Row Level Security as a safety net — MUST with Supabase / direct DB access
If the database is accessed from the client (Supabase) or by multiple services, enable RLS so
that a bug in the application layer does not expose other users' data.

```sql
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets FORCE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_staff(uid uuid) RETURNS boolean
  LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.users WHERE id = uid AND role IN ('support', 'moderator', 'admin'));
$$;

CREATE POLICY tickets_select ON public.tickets
  FOR SELECT USING (author_id = auth.uid() OR public.is_staff(auth.uid()));

CREATE POLICY tickets_insert ON public.tickets
  FOR INSERT WITH CHECK (author_id = auth.uid());

CREATE POLICY tickets_update_staff ON public.tickets
  FOR UPDATE USING (public.is_staff(auth.uid())) WITH CHECK (public.is_staff(auth.uid()));
```

- Outside Supabase, replace `auth.uid()` with `current_setting('app.user_id')::uuid` set within the transaction (`SET LOCAL app.user_id = ...`).
- The Supabase `service_role` key **never** goes to the frontend or into `NEXT_PUBLIC_*`.
- Every new table has RLS enabled in the same migration that creates it.

---

## C. Input validation

### C1. Every input goes through a Zod schema on the server — MUST
Body, query, route params, headers used in logic and webhook data. Client-side validation is
just UX.

```ts
// lib/schemas/order.ts
import { z } from "zod";

export const CreateOrderSchema = z
  .object({
    items: z
      .array(z.object({ productId: z.string().uuid(), quantity: z.number().int().min(1).max(99) }))
      .min(1)
      .max(50),
    shippingAddressId: z.string().uuid(),
    note: z.string().trim().max(500).optional(),
    termsAccepted: z.literal(true),
  })
  .strict(); // unknown keys => error, not silent ignoring

export const IdParamSchema = z.object({ id: z.string().uuid() });
```

```ts
// app/api/orders/route.ts
export async function POST(req: Request) {
  const user = await requireUser();
  const parsed = CreateOrderSchema.safeParse(await req.json().catch(() => null));
  if (!parsed.success) {
    return Response.json({ error: "validation_error", issues: parsed.error.flatten().fieldErrors }, { status: 422 });
  }
  // ... parsed.data is the only source of data for the write
}
```

- Every string has a `max()` length. Every number has `min()`/`max()`. Every array/collection has a `max()` item count.
- Validate IDs from the URL as `uuid()` before they reach a query.

### C2. No mass assignment, no client-supplied prices — MUST
**Never** save `req.body` (or a spread of it) directly to the database. The attacker adds
`"role": "admin"`, `"status": "paid"`, `"totalCents": 0` or `"customerId": "<someone else's id>"`.
Anything with business meaning — owner, status, price, discount, permissions — is decided by
the server.

```ts
// ❌ FORBIDDEN
await db.user.update({ where: { id: user.id }, data: await req.json() });
await db.order.create({ data: { ...body, customerId: user.id } });

// ✅ Explicit mapping; owner, status and prices come from the server
const input = CreateOrderSchema.parse(await req.json());
await assertAddressOwner(input.shippingAddressId, user.id); // B1 for IDs inside the body

const productIds = [...new Set(input.items.map((item) => item.productId))];
const products = await db.product.findMany({
  where: { id: { in: productIds }, active: true },
  select: { id: true, priceCents: true },
});
if (products.length !== productIds.length) throw new HttpError(422);
const price = new Map(products.map((product) => [product.id, product.priceCents]));

await db.order.create({
  data: {
    customerId: user.id,
    status: "pending",
    shippingAddressId: input.shippingAddressId,
    note: input.note ?? null,
    totalCents: input.items.reduce((sum, item) => sum + price.get(item.productId)! * item.quantity, 0),
    items: {
      create: input.items.map((item) => ({
        productId: item.productId,
        quantity: item.quantity,
        unitPriceCents: price.get(item.productId)!,
      })),
    },
  },
});
```

### C3. Uploads: size limit, MIME from magic bytes, re-encode — MUST

```ts
// app/api/tickets/[id]/attachments/route.ts
import { randomUUID } from "node:crypto";
import { fileTypeFromBuffer } from "file-type";
import sharp from "sharp";

const MAX_BYTES = 5 * 1024 * 1024; // 5 MB
const ALLOWED_MIME = new Set(["image/png", "image/jpeg", "image/webp"]);

export async function POST(req: Request, { params }: { params: Promise<{ id: string }> }) {
  const user = await requireUser();
  const { id } = IdParamSchema.parse(await params);
  await assertTicketOwnerOrStaff(id, user); // B1

  const declared = Number(req.headers.get("content-length") ?? "0");
  if (!declared || declared > MAX_BYTES + 64 * 1024) throw new HttpError(413);

  const form = await req.formData();
  const file = form.get("file");
  if (!(file instanceof File) || file.size === 0) throw new HttpError(422);
  if (file.size > MAX_BYTES) throw new HttpError(413);

  const buffer = Buffer.from(await file.arrayBuffer());
  const detected = await fileTypeFromBuffer(buffer); // reads magic bytes, ignores the extension and Content-Type
  if (!detected || !ALLOWED_MIME.has(detected.mime)) throw new HttpError(415);

  // Re-encoding strips EXIF (GPS), polyglot payloads and hidden content
  const safe = await sharp(buffer, { limitInputPixels: 40_000_000 }).rotate().webp({ quality: 85 }).toBuffer();
  const key = `tickets/${id}/${randomUUID()}.webp`; // random name, never the user's file name
  await storage.put(key, safe, { contentType: "image/webp" });

  return Response.json({ key }, { status: 201 });
}
```

- Also set a body size limit at the infrastructure level (reverse proxy `client_max_body_size`, `serverActions.bodySizeLimit`, `express.json({ limit: "100kb" })`).
- **No SVG or HTML** from users (stored XSS). If they are required, sanitize them and serve them from a different domain.
- Files are stored outside the web root (object storage) and served with `X-Content-Type-Options: nosniff`, and non-previewable types with `Content-Disposition: attachment`.
- Documents (PDF, office files) are scanned for malware before anyone else downloads them.

---

## D. Database

### D1. Parameterized queries only — MUST

```ts
// ❌ SQL injection
await db.$queryRawUnsafe(`SELECT * FROM posts WHERE title ILIKE '%${q}%'`);
await pool.query(`SELECT * FROM users WHERE email = '${email}'`);

// ✅ Parameters
await db.$queryRaw`SELECT id, title FROM posts WHERE title ILIKE ${"%" + q + "%"} LIMIT 50`;
await pool.query("SELECT id, name FROM users WHERE email = $1", [email]);
```

- `$queryRawUnsafe`, `$executeRawUnsafe`, Drizzle `sql.raw()`, Knex `raw()` with interpolation → forbidden for any user input.
- Dynamic identifiers (sort column, direction) only via an allowlist:

```ts
const SortSchema = z.object({
  sort: z.enum(["createdAt", "updatedAt", "title"]).default("createdAt"),
  dir: z.enum(["asc", "desc"]).default("desc"),
});
```

### D2. Dynamic ORM filters must not drop out — MUST
In Prisma, `undefined` in `where` means **"no filter"**. A missing session can therefore
return or delete all records.

```ts
// ❌ When session.userId === undefined, it returns ALL tickets of ALL users
const tickets = await db.ticket.findMany({ where: { authorId: session?.userId } });

// ❌ Empty filter = deletes the whole table
await db.post.deleteMany({ where: buildFilter(req.query) });

// ✅ The identity is verified and required, results are limited
const user = await requireUser();
const tickets = await db.ticket.findMany({
  where: { authorId: user.id },
  select: ticketListSelect,
  orderBy: { createdAt: "desc" },
  take: 50,
});
```

- Before every `updateMany`/`deleteMany`, verify that `where` contains at least one defined restricting key.
- With MongoDB, reject objects in place of scalars (`{ "$ne": null }`) — a Zod schema with `z.string()` handles this.

---

## E. Trimming API responses (Bloated APIs)

### E1. Return only what the UI displays — MUST
Never return a whole DB record. The following **must not** reach the frontend: password hashes,
session/OAuth tokens, API keys, other users' emails and IP addresses, internal staff notes,
fraud or moderation flags, purchase prices and margins, whole tables.

```ts
// lib/selects.ts
import type { Prisma } from "@prisma/client";

export const publicUserSelect = {
  id: true,
  name: true,
  avatarUrl: true,
} satisfies Prisma.UserSelect;

export const ticketListSelect = {
  id: true,
  subject: true,
  status: true,
  createdAt: true,
  author: { select: publicUserSelect },
} satisfies Prisma.TicketSelect;

// Order as seen by the customer — without internal notes, fraud score or supplier cost
export const orderForCustomerSelect = {
  id: true,
  status: true,
  totalCents: true,
  currency: true,
  createdAt: true,
  items: { select: { productId: true, quantity: true, unitPriceCents: true } },
} satisfies Prisma.OrderSelect;
```

```ts
// ❌ Returns passwordHash, oauthAccessToken, email, lastLoginIp ...
return Response.json(await db.user.findMany());

// ✅
return Response.json(await db.user.findMany({ select: publicUserSelect, take: 50 }));
```

- Every list has pagination with a fixed maximum (`take` ≤ 100), even if the client sends `limit=100000`.
- Error responses do not reveal whether accounts exist ("User does not exist" vs. "Wrong password" → one generic message).
- Server Components: pass only serialized, trimmed data to client components — props are visible in the HTML/RSC payload.

---

## F. Network and headers

### F1. Restrictive CORS allowlist — MUST

```ts
import cors from "cors";

const ALLOWED_ORIGINS = new Set(["https://example.com", "https://admin.example.com"]);

app.use(
  cors({
    origin(origin, callback) {
      // Requests without Origin (server-to-server, same-origin navigation) are not a CORS concern — authorization lives elsewhere.
      callback(null, !origin || ALLOWED_ORIGINS.has(origin));
    },
    credentials: true,
    methods: ["GET", "POST", "PATCH", "DELETE"],
    allowedHeaders: ["Content-Type"],
    maxAge: 600,
  }),
);
```

- **Forbidden:** `origin: "*"` with `credentials: true`, reflecting any `Origin`, a regex like `/example\.com/` (matches `evil-example.com`).
- If the API is called only by your own frontend from the same domain, do **not enable** CORS at all.

### F2. Security headers — MUST

This section owns every security header **except the Content Security Policy**, which is
defined once in `frontend-security` (section B: a nonce-based CSP for HTML pages).

| Header | Value |
|--------|-------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains` — add `preload` only deliberately |
| `X-Content-Type-Options` | `nosniff` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | disable what you don't use: `camera=(), microphone=(), geolocation=(), payment=()` |
| `Cross-Origin-Opener-Policy` | `same-origin` (check OAuth popups and payment windows) |
| `X-Powered-By` | removed |
| `Content-Security-Policy` | HTML pages: `frontend-security` B · JSON-only APIs: `default-src 'none'; frame-ancestors 'none'` |

Express API (Helmet):

```ts
import helmet from "helmet";

app.disable("x-powered-by");
app.use(
  helmet({
    // JSON API: nothing may load or frame its responses. HTML pages use the CSP from frontend-security.
    contentSecurityPolicy: { useDefaults: false, directives: { defaultSrc: ["'none'"], frameAncestors: ["'none'"] } },
    strictTransportSecurity: { maxAge: 63072000, includeSubDomains: true },
    referrerPolicy: { policy: "strict-origin-when-cross-origin" },
    crossOriginOpenerPolicy: { policy: "same-origin" },
  }),
);
app.use((_req, res, next) => {
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=()");
  next();
});
```

Next.js (`next.config.ts`):

```ts
const securityHeaders = [
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(), payment=()" },
  { key: "Cross-Origin-Opener-Policy", value: "same-origin" },
];

const nextConfig = {
  poweredByHeader: false,
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
// The CSP is set per request with a nonce in the proxy/middleware — frontend-security section B.
```

### F3. SSRF prevention — MUST
Wherever the server fetches a URL supplied by the user (link previews, avatar from URL,
webhook URLs, imports), validate the target and block internal addresses (including cloud
metadata `169.254.169.254`).

```ts
// lib/safe-fetch.ts
import "server-only";
import { lookup } from "node:dns/promises";
import ipaddr from "ipaddr.js";

const MAX_RESPONSE_BYTES = 2 * 1024 * 1024;

export async function assertPublicHttpsUrl(raw: string): Promise<URL> {
  const url = new URL(raw);
  if (url.protocol !== "https:") throw new HttpError(422, "Only https URLs are allowed");
  if (url.username || url.password) throw new HttpError(422, "Credentials in URL are not allowed");
  if (url.port && url.port !== "443") throw new HttpError(422, "Non-standard ports are not allowed");

  const addresses = await lookup(url.hostname, { all: true, verbatim: true });
  if (addresses.length === 0) throw new HttpError(422);
  for (const { address } of addresses) {
    const range = ipaddr.process(address).range(); // process() converts IPv4-mapped IPv6 to IPv4
    if (range !== "unicast") throw new HttpError(422, "Target address is not public");
  }
  return url;
}

export async function safeFetch(raw: string): Promise<ArrayBuffer> {
  const url = await assertPublicHttpsUrl(raw);
  const res = await fetch(url, { redirect: "error", signal: AbortSignal.timeout(5000) });
  const length = Number(res.headers.get("content-length") ?? "0");
  if (!res.ok || length > MAX_RESPONSE_BYTES) throw new HttpError(422);
  const body = await res.arrayBuffer();
  if (body.byteLength > MAX_RESPONSE_BYTES) throw new HttpError(422);
  return body;
}
```

- `redirect: "error"` — a redirect would bypass the target check. If a redirect is required, validate every hop again.
- The DNS check and the actual connection are two separate steps (DNS rebinding risk). For high-risk features, route outbound traffic through an egress proxy that blocks private ranges, or pin the verified IP in the HTTP agent.

---

## G. Production operation

### G1. Rate limiting — MUST
Limit per user **and** per IP. Minimum set:

| Endpoint | Example limit |
|----------|---------------|
| Sign-in, OAuth start and callback | 20 / 15 min / IP |
| Password reset, verification emails, one-time codes | 5 / hour / account and / IP |
| Creating records (orders, sign-up forms, contact forms) | 10 / hour / user or IP |
| Creating a ticket | 10 / hour / user |
| Comments and posts | 30 / 10 min / user |
| Upload | 20 / hour / user |

```ts
// Serverless (Vercel) — shared state via Redis
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const orderLimiter = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, "1 h"),
  prefix: "rl:order",
});

const { success, reset } = await orderLimiter.limit(`user:${user.id}`);
if (!success) {
  return Response.json(
    { error: "rate_limited" },
    { status: 429, headers: { "Retry-After": String(Math.max(1, Math.ceil((reset - Date.now()) / 1000))) } },
  );
}
```

```ts
// Express on your own server
import rateLimit from "express-rate-limit";

app.set("trust proxy", 1); // behind a reverse proxy, otherwise everyone shares the proxy's IP
app.use("/api/auth", rateLimit({ windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: "draft-7", legacyHeaders: false }));
```

An in-memory limiter **does not work** in serverless or with multiple instances.

### G2. Verifying cryptographic webhook signatures — MUST
The signature is verified over the **raw request body** (before JSON parsing) and before any
other logic. Header names, encodings (hex / base64) and what exactly is signed differ per
provider — follow its documentation, and enforce the timestamp tolerance if it sends one.

**HMAC-SHA256** (the most common scheme; the example uses the `sha256=<hex>` header format):

```ts
// lib/webhooks.ts
import { createHmac, timingSafeEqual } from "node:crypto";

export function verifyHmacSha256(rawBody: string, signatureHeader: string | null, secret: string) {
  if (!signatureHeader?.startsWith("sha256=")) return false;
  const expected = Buffer.from(`sha256=${createHmac("sha256", secret).update(rawBody).digest("hex")}`);
  const received = Buffer.from(signatureHeader);
  return expected.length === received.length && timingSafeEqual(expected, received);
}
```

```ts
// app/api/webhooks/provider/route.ts
export async function POST(req: Request) {
  const rawBody = await req.text();
  if (!verifyHmacSha256(rawBody, req.headers.get("x-signature-256"), env.WEBHOOK_SECRET)) {
    return new Response("invalid signature", { status: 401 });
  }
  const event = WebhookEventSchema.parse(JSON.parse(rawBody));
  // ... idempotent processing (see below)
  return new Response(null, { status: 200 });
}
```

**Stripe** (use the SDK — it checks the signature and the timestamp):

```ts
// app/api/stripe/webhook/route.ts
import Stripe from "stripe";
import { env } from "@/lib/env";

const stripe = new Stripe(env.STRIPE_SECRET_KEY);

export async function POST(req: Request) {
  const signature = req.headers.get("stripe-signature");
  const rawBody = await req.text();
  if (!signature) return new Response("missing signature", { status: 400 });

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(rawBody, signature, env.STRIPE_WEBHOOK_SECRET);
  } catch {
    return new Response("invalid signature", { status: 400 });
  }

  // Idempotency: providers deliver "at least once"
  const firstDelivery = await db.processedWebhook.createMany({
    data: [{ id: event.id, provider: "stripe" }],
    skipDuplicates: true,
  });
  if (firstDelivery.count === 0) return new Response(null, { status: 200 });

  // ... handle event.type
  return new Response(null, { status: 200 });
}
```

**Public-key signatures** (e.g. Ed25519, used by some chat platforms and payment providers):

```ts
// lib/webhooks.ts
import { createPublicKey, verify } from "node:crypto";

export function verifyEd25519(message: string, signatureHex: string, publicKeyHex: string) {
  if (!/^[0-9a-f]{128}$/i.test(signatureHex)) return false;
  const key = createPublicKey({
    key: { kty: "OKP", crv: "Ed25519", x: Buffer.from(publicKeyHex, "hex").toString("base64url") },
    format: "jwk",
  });
  return verify(null, Buffer.from(message), key, Buffer.from(signatureHex, "hex"));
}

// Typically the signed message is timestamp + raw body; reject timestamps older than ~5 minutes.
```

- In Express, use `express.raw({ type: "application/json" })` for the webhook route, not `express.json()`.
- Map identifiers from the webhook (e.g. `customer`) to users through your own DB; do not trust metadata without verification.
- Respond quickly (2xx) and do heavy work in a background job.

### G3. No stack traces or internal details in production — MUST

```ts
// Express — last middleware
import { randomUUID } from "node:crypto";
import type { NextFunction, Request, Response } from "express";

app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: err.message });
  }
  const requestId = randomUUID();
  logger.error({ err, requestId, method: req.method, path: req.path }, "unhandled_error");
  return res.status(500).json({ error: "internal_error", requestId });
});
```

- `NODE_ENV=production` in production (otherwise Express returns the stack trace in HTML).
- The client gets a generic message + `requestId`; details (stack, SQL error) go only to the server log.
- Logs **do not contain** cookies, the `Authorization` header, tokens, passwords or whole bodies with personal data (use redaction in the logger, e.g. `pino` `redact`).

### G4. Secrets and configuration — MUST

```ts
// lib/env.ts
import "server-only";
import { z } from "zod";

export const env = z
  .object({
    APP_ORIGIN: z.string().url(),
    DATABASE_URL: z.string().url(),
    OAUTH_AUTHORIZE_URL: z.string().url(),
    OAUTH_TOKEN_URL: z.string().url(),
    OAUTH_USERINFO_URL: z.string().url(),
    OAUTH_CLIENT_ID: z.string().min(1),
    OAUTH_CLIENT_SECRET: z.string().min(16),
    OAUTH_REDIRECT_URI: z.string().url(),
    WEBHOOK_SECRET: z.string().min(32),
    STRIPE_SECRET_KEY: z.string().startsWith("sk_"),
    STRIPE_WEBHOOK_SECRET: z.string().startsWith("whsec_"),
  })
  .parse(process.env); // the application does not start at all without a valid configuration
```

- `.env*` files are in `.gitignore`; only `.env.example` without values belongs in the repository.
- Nothing secret has the `NEXT_PUBLIC_` / `VITE_` / `PUBLIC_` prefix.
- Modules with secrets import `server-only`, so the bundler refuses to include them in the client.
- The toolkit's guard hook (`./install.sh --hooks`) blocks writing secrets into source files.

---

## Security Gate (before completion)

Do not declare backend work done until **all** items hold:

- [ ] No token is in `localStorage`/`sessionStorage`; the session cookie is `__Host-`, `HttpOnly`, `Secure`, `SameSite=Lax`.
- [ ] OAuth uses `state` (timing-safe compared) and PKCE; `redirect_uri` is a constant; accounts are linked by provider subject, emails only when verified.
- [ ] Passwords (if any) use Argon2id/bcrypt via a library; reset tokens are hashed, single-use and short-lived; no account enumeration.
- [ ] Every handler / server action starts with `requireUser()` or `requireRole()` (exceptions are explicitly public and documented).
- [ ] Every access to an object by ID — in the URL **or** in the body — checks ownership; someone else's record returns 404.
- [ ] Public IDs are UUIDs; new tables have RLS (if the DB is reachable outside the backend).
- [ ] Every input goes through a `.strict()` Zod schema with length limits; no `req.body` in `data:`; prices, status and owner come from the server.
- [ ] Uploads have a size limit, magic-byte check, re-encoding and a random name.
- [ ] No `*Unsafe` raw query with user input; sorting via an allowlist; no `where` with a possible `undefined`.
- [ ] Responses use explicit `select`/DTOs and pagination with a maximum.
- [ ] CORS is an allowlist or disabled; the F2 security headers are set; HTML pages have the CSP from `frontend-security`.
- [ ] Outbound requests to user-supplied URLs go through `safeFetch`.
- [ ] Sensitive endpoints have a rate limit with shared storage.
- [ ] Webhooks verify the signature over the raw body and are idempotent.
- [ ] Production errors do not return stack traces; logs contain no secrets.

## Output format (security report)

```markdown
## Security audit: <scope of the change>

| # | Severity | Category | CWE | Finding | File:line | Fix |
|---|----------|----------|-----|---------|-----------|-----|
| 1 | 🔴 Critical | IDOR | CWE-639 | GET /api/tickets/[id] does not filter by owner | app/api/tickets/[id]/route.ts:12 | `authorId: user.id` filter in the query, 404 |
| 2 | 🔴 Critical | Mass Assignment | CWE-915 | Order total is taken from the request body | app/api/orders/route.ts:20 | compute prices from the DB, explicit field mapping |
| 3 | 🟠 High | Auth | CWE-352 | OAuth callback does not verify `state` | app/api/auth/oauth/callback/route.ts:8 | state cookie + timingSafeEqual, add PKCE |
| 4 | 🟡 Medium | Rate limiting | CWE-770 | Password reset has no limit | app/api/auth/reset/route.ts:5 | 5/h per account and IP, shared store |

**Verified with no findings:** <list of sections>
**Out of scope / cannot verify:** <e.g. reverse proxy configuration>
```

Severity:
- 🔴 **Critical** — direct access to other users' data, account takeover, privilege escalation, payment manipulation, RCE, SQLi.
- 🟠 **High** — CSRF, missing signature verification, leaking tokens/personal data, SSRF.
- 🟡 **Medium** — missing rate limit, overly broad CORS, missing headers, stack trace leak.
- ⚪ **Low** — hardening and defense in depth.

## Behavior rules

- Never suggest "temporarily disabling" verification (CORS `*`, `verify: false`, skipping a signature) even for local development without an explicit warning and a `NODE_ENV` condition.
- If the user requests a dangerous pattern (token in `localStorage`), explain the risk in one sentence and implement the secure variant; implement the dangerous one only on an explicit repeated request, with a `// SECURITY:` comment in the code.
- Do not invent library APIs — when unsure, check the documentation of the current version.
- Always accompany security fixes with a test (unit or E2E via `webapp-testing`).
- Related skills: `auth-flows` (designing sign-in, recovery and 2FA flows), `frontend-security` (client side and dependencies), `api-design`, `database-design`, `gdpr-privacy` (personal data, retention, processors), `webapp-testing` (regression tests), `tech-stack-advisor` (choosing an auth library or provider).
