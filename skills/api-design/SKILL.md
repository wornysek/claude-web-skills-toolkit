---
name: api-design
description: "Designing HTTP APIs that clients can rely on: when to use REST vs. server actions or RPC, resource naming and methods, status codes, a consistent error format (RFC 9457 Problem Details), cursor pagination, filtering and sorting, field conventions (IDs, dates, money), idempotency keys, ETags and optimistic concurrency, long-running operations, rate-limit headers, versioning and deprecation, OpenAPI as the contract, and outgoing webhooks (signing, retries, event design). Use whenever you create or change an API endpoint, a public or partner API, an SDK contract or outgoing webhooks. Security rules (auth, IDOR, validation, CORS) are in backend-security-auditor."
triggers:
  - "design an API / REST endpoint / public API"
  - "pagination / filtering / sorting"
  - "error format / status codes"
  - "API versioning / breaking change / deprecation"
  - "OpenAPI / API docs / SDK"
  - "send webhooks to customers / idempotency"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  references: "RFC 9110 (HTTP semantics), RFC 9457 (Problem Details), RFC 8594 (Sunset header)"
---

# API design

An API is a promise. Once a client depends on it, every change is either compatible or a
breaking change that someone pays for. Design for consistency first: the same naming,
errors, pagination and dates everywhere.

## Process

1. **Decide the API style** (section 1).
2. **Model resources and operations** (sections 2–3).
3. **Apply the shared conventions** — errors, pagination, fields (sections 4–6).
4. **Make writes safe** — idempotency, concurrency, long-running work (section 7).
5. **Describe it** in OpenAPI and plan its evolution (sections 8–9).
6. **Webhooks** if you notify others (section 10).

---

## 1. Which style

| Consumer | Style |
|----------|-------|
| Your own Next.js frontend only | Server Components + **server actions** — no public API needed |
| Your own frontends on several platforms (web, mobile) | **REST** (or a typed RPC like tRPC if all clients are TypeScript) |
| Partners, customers, public developers | **REST + OpenAPI**, versioned, documented, with webhooks |
| Highly relational reads from many clients | GraphQL — only if you can staff its complexity (caching, auth per field, query cost) |

Don't build a public REST API "just in case". Internal endpoints still follow the error and
validation rules below.

## 2. Resources and methods

- **Plural nouns**, lowercase, hyphenated: `/v1/invoices`, `/v1/invoices/{id}`, `/v1/invoices/{id}/line-items`. Nest at most one level.
- **Methods by meaning:** `GET` reads (safe, cacheable), `POST` creates or triggers, `PUT` replaces, `PATCH` partially updates, `DELETE` removes.
- **Actions that aren't CRUD** are sub-resources: `POST /v1/invoices/{id}/send`, `POST /v1/subscriptions/{id}/cancel`.
- **Never change state with `GET`.**
- Responses of single resources return the resource; lists return `{ "data": [...], "nextCursor": ... }`.

## 3. Status codes

| Code | Use |
|------|-----|
| 200 OK | read or update with a body |
| 201 Created | resource created (`Location` header with its URL) |
| 202 Accepted | long-running work started (section 7) |
| 204 No Content | success without a body (delete) |
| 400 Bad Request | malformed request (invalid JSON, wrong types) |
| 401 Unauthorized | missing or invalid authentication |
| 403 Forbidden | authenticated but not allowed (or 404 to hide existence) |
| 404 Not Found | doesn't exist or not visible to this caller |
| 409 Conflict | state conflict (duplicate, already cancelled) |
| 412 Precondition Failed | `If-Match` version mismatch |
| 422 Unprocessable Content | validation errors |
| 429 Too Many Requests | rate limited (`Retry-After`) |
| 500 / 503 | server error / temporarily unavailable (`Retry-After`) |

## 4. Errors — one format everywhere

Use **Problem Details** (`application/problem+json`):

```json
{
  "type": "https://example.com/problems/validation-error",
  "title": "Your request has invalid fields.",
  "status": 422,
  "detail": "2 fields are invalid.",
  "instance": "/v1/invoices",
  "requestId": "req_7f3a9c",
  "errors": [
    { "field": "dueDate", "code": "date_in_past", "message": "Due date must be today or later." },
    { "field": "lineItems[0].quantity", "code": "too_small", "message": "Quantity must be at least 1." }
  ]
}
```

```ts
// lib/problem.ts
export function problem(status: number, type: string, title: string, extra: Record<string, unknown> = {}) {
  return Response.json(
    { type: `https://example.com/problems/${type}`, title, status, ...extra },
    { status, headers: { "Content-Type": "application/problem+json" } },
  );
}
```

- **Machine-readable `code`s** are stable; human `message`s may change and be translated (`i18n-setup`).
- No stack traces, SQL or internal names in errors (`backend-security-auditor` G3); a `requestId` links to the logs.
- The same error shape for validation, auth, rate limits and server errors.

## 5. Lists: pagination, filtering, sorting

**Cursor pagination** is stable under inserts and fast on large tables:

```ts
// app/api/v1/invoices/route.ts
const PageQuery = z.object({
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  status: z.enum(["draft", "sent", "paid", "overdue"]).optional(),
  sort: z.enum(["createdAt", "-createdAt", "dueDate", "-dueDate"]).default("-createdAt"),
});

export async function GET(req: Request) {
  const user = await requireUser();
  const query = PageQuery.parse(Object.fromEntries(new URL(req.url).searchParams));
  const [field, direction] = query.sort.startsWith("-") ? [query.sort.slice(1), "desc"] : [query.sort, "asc"];

  const rows = await db.invoice.findMany({
    where: { workspaceId: user.workspaceId, ...(query.status ? { status: query.status } : {}) },
    orderBy: [{ [field]: direction }, { id: direction }],
    take: query.limit + 1,
    ...(query.cursor ? { cursor: { id: query.cursor }, skip: 1 } : {}),
    select: invoiceListSelect,
  });

  const hasMore = rows.length > query.limit;
  const data = hasMore ? rows.slice(0, query.limit) : rows;
  return Response.json({ data, nextCursor: hasMore ? data[data.length - 1].id : null });
}
```

- A hard maximum for `limit`; a stable tie-breaker (`id`) in every sort.
- Filters and sort fields come from an **allowlist** (as above), never passed through to the query.
- Offset pagination (`page=3`) only for small, admin-style lists where users jump to a page.
- Don't return total counts on huge tables unless needed — they are expensive.

## 6. Field conventions

- **Naming:** one style everywhere (`camelCase` for JSON from a JS stack); booleans as `isPaid` / `hasAttachments`.
- **IDs:** strings (UUIDs or prefixed IDs like `inv_…`), never numbers that clients might do math on.
- **Dates:** ISO 8601 in UTC (`2026-10-23T14:30:00Z`); dates without time as `2026-10-23`.
- **Money:** integer minor units + ISO currency: `{ "amount": 129050, "currency": "CZK" }` — never floats.
- **Enums:** lowercase strings; clients must tolerate new values.
- **Nulls:** document whether a field can be `null` or omitted; don't use both for the same meaning.
- **Expansion:** related objects by ID by default; `?expand=customer` for embedding.

## 7. Safe writes

**Idempotency keys** for `POST` requests that create things or move money:

```ts
// Client sends: Idempotency-Key: 5f0c8a1e-…  (a new UUID per user action, reused on retries)
export async function POST(req: Request) {
  const user = await requireUser();
  const key = req.headers.get("idempotency-key");
  if (!key || !/^[A-Za-z0-9-]{16,64}$/.test(key)) return problem(400, "idempotency-key-required", "Send an Idempotency-Key header.");

  const previous = await db.idempotencyRecord.findUnique({ where: { userId_key: { userId: user.id, key } } });
  if (previous) return new Response(previous.responseBody, { status: previous.status, headers: { "Content-Type": "application/json" } });

  const created = await createInvoice(user, await req.json());
  const body = JSON.stringify(created);
  await db.idempotencyRecord.create({ data: { userId: user.id, key, status: 201, responseBody: body } }); // keep ~24 h
  return new Response(body, { status: 201, headers: { "Content-Type": "application/json", Location: `/v1/invoices/${created.id}` } });
}
```

- In production, insert the idempotency record first (unique constraint) to block concurrent duplicates, then fill in the response.
- **Optimistic concurrency:** responses include `ETag` (a version); updates send `If-Match`; a mismatch returns 412 so clients don't overwrite each other's changes.
- **Long-running work** (exports, imports, video processing): `202 Accepted` with a status resource (`/v1/exports/{id}` → `pending | done | failed`, a download URL when done) and an optional webhook.
- **Bulk operations** report per-item results instead of failing everything for one bad item.

## 8. Contract and documentation

- **OpenAPI 3.1** is the contract; generate it from the same schemas used for validation (code-first with Zod-based generators, or spec-first with generated types) so docs can't drift.
- Every endpoint documents: auth, parameters, request and response schemas, error codes, rate limits, an example.
- Publish rate limits and send headers: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset` (or the platform's equivalent) and `Retry-After` on 429.
- Provide a sandbox / test mode with test keys for partners.

## 9. Versioning and evolution

- **Additive changes are compatible:** new endpoints, new optional fields, new enum values (documented as possible).
- **Breaking changes** (removing or renaming fields, changing types or meanings, new required inputs) need a new version: `/v2/...` in the path (simple, visible) or a version header.
- **Deprecation:** announce with dates, send `Deprecation` and `Sunset` headers on old endpoints, log who still calls them, and contact those clients before removal.
- Never change the meaning of an existing field silently.

## 10. Outgoing webhooks

- **Events** are past-tense facts with a type and version: `invoice.paid`, `subscription.cancelled`; payload contains an event `id`, `type`, `createdAt` and the object (or its ID).
- **Signing:** HMAC-SHA256 over `timestamp.body`, sent as `Webhook-Signature: t=<unix>,v1=<hex>`; document verification code for receivers; support **secret rotation** (two valid secrets during rotation).
- **Delivery:** at-least-once with retries and exponential backoff (e.g. over 24–72 hours); receivers must be idempotent by event `id`; respect `410 Gone` as unsubscribe.
- **Safety:** customer-supplied webhook URLs go through SSRF protection (`backend-security-auditor` F3); timeouts of a few seconds; no redirects followed.
- **Operability:** a delivery log per endpoint, manual "resend", automatic disabling after repeated failures with a notification.

## Checklist

- [ ] The API style fits its consumers; no public API without a consumer.
- [ ] Plural resources, correct methods, no state change on GET, correct status codes.
- [ ] One Problem Details error format with stable codes and a request ID.
- [ ] Cursor pagination with a max limit; filters and sorts from allowlists.
- [ ] IDs as strings, ISO 8601 UTC dates, money in minor units with currency.
- [ ] Idempotency keys for creating and payment requests; ETag / If-Match for updates; 202 for long work.
- [ ] OpenAPI generated from the validation schemas; rate limits documented and sent as headers.
- [ ] Versioning and deprecation policy written down.
- [ ] Webhooks signed, retried, idempotent, with delivery logs and SSRF protection.

## Output format

```markdown
## API review: /v1/invoices

| # | Finding | Fix |
|---|---------|-----|
| 1 | Errors are `{ "message": "..." }` on some routes, plain text on others | Problem Details everywhere via `problem()` |
| 2 | `?page=` offset pagination on a 4M-row table | cursor pagination with `limit` ≤ 100 |
| 3 | `amount` returned as float (129.5) | `{ amount: 12950, currency: "EUR" }` |
| 4 | Retried POST creates duplicate invoices | `Idempotency-Key` header with stored responses |
```

## Related skills

- `backend-security-auditor` (auth, IDOR, validation, CORS, rate limiting, webhook verification), `database-design` (indexes for pagination and filters), `i18n-setup` (translated error messages), `deploy-and-ops` (monitoring and alerts per endpoint).
