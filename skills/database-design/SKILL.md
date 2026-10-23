---
name: database-design
description: "Relational database design and operations for web apps (PostgreSQL first; Prisma, Drizzle or SQL): modelling tables and relations, keys (UUID v4 vs. v7), data types for money, time and enums, constraints, multi-tenancy, indexes and EXPLAIN, N+1 queries, transactions and concurrency, safe zero-downtime migrations (expand and contract, concurrent indexes, lock timeouts), seed data and anonymized copies, connection pooling for serverless, and data retention. Use whenever you create or change a schema, a migration, an index or a slow query, add a table or relation, or the user asks about database structure or performance. For choosing the database engine use tech-stack-advisor; for backups use deploy-and-ops."
triggers:
  - "design the database / schema / tables / relations"
  - "migration / add column / rename / drop"
  - "slow query / index / EXPLAIN / N+1"
  - "Prisma schema / Drizzle schema / SQL"
  - "seed data / test data / multi-tenant"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Database design

The schema outlives the code that uses it. Constraints in the database protect data from
every bug in every service; indexes decide whether the app is fast at 10,000 rows and at
10,000,000. Migrations decide whether a release is boring or an outage.

## Process

1. **Model** the domain: entities, relations, ownership, lifecycle (section 1).
2. **Choose types and constraints** (sections 2–3).
3. **Index** for the real queries and check them with `EXPLAIN` (section 4).
4. **Write queries** without N+1 and with correct transactions (sections 5–6).
5. **Migrate safely** (section 7); keep **seeds** realistic and anonymous (section 8).
6. **Operate:** pooling, retention, monitoring (section 9).

---

## 1. Modelling

- **One table per entity**, named consistently (pick one: `invoices` or `invoice`; `snake_case` columns in SQL, mapped to `camelCase` in the ORM).
- **Every row has an owner** when users own data (`user_id`, `workspace_id`) — the basis for authorization and RLS (`backend-security-auditor` B1, B3).
- **Multi-tenancy:** a `workspace_id` / `tenant_id` on every tenant table, in every query and in composite indexes; RLS as a safety net.
- **Normalize** by default; **denormalize** deliberately for measured read performance (and document how the copy is kept in sync).
- **Lifecycle:** status columns with explicit allowed transitions; `created_at`, `updated_at` on every table; soft delete (`deleted_at`) only where restore is a real requirement — it complicates every query and unique constraint.
- **JSON columns** (`jsonb`) for truly flexible, schema-less data (settings blobs, provider payloads), not for core fields you filter or join on.

```prisma
model Invoice {
  id          String        @id @default(uuid()) @db.Uuid
  workspaceId String        @db.Uuid
  workspace   Workspace     @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  customerId  String        @db.Uuid
  customer    Customer      @relation(fields: [customerId], references: [id], onDelete: Restrict)
  number      String
  status      InvoiceStatus @default(DRAFT)
  totalCents  Int
  currency    String        @db.Char(3)
  dueDate     DateTime      @db.Date
  createdAt   DateTime      @default(now()) @db.Timestamptz
  updatedAt   DateTime      @updatedAt @db.Timestamptz
  lineItems   LineItem[]

  @@unique([workspaceId, number])
  @@index([workspaceId, status, dueDate])
  @@index([customerId])
}
```

## 2. Keys and types

| Data | Type | Why |
|------|------|-----|
| Primary key | `uuid` | no enumeration (`backend-security-auditor` B2); **v7** (time-ordered, `uuidv7()` built into PostgreSQL 18) indexes better, but reveals creation time — use **v4** where that matters |
| Money | `integer` / `bigint` minor units + `char(3)` currency, or `numeric(12,2)` | never `float` |
| Timestamps | `timestamptz` | stored in UTC, unambiguous |
| Dates without time | `date` | birthdays, due dates |
| Status | `text` + `CHECK`, or a native enum | adding enum values needs a migration; `CHECK` is easier to change |
| Email | `text` (+ `citext` or a lowercase unique index) | case-insensitive uniqueness |
| Booleans | `boolean NOT NULL DEFAULT false` | no three-state booleans by accident |

## 3. Constraints

- `NOT NULL` by default; nullable only when "unknown" is a real state.
- `UNIQUE` for business rules (`(workspace_id, number)`, one active subscription per customer via a partial unique index).
- **Foreign keys always**, with a deliberate `ON DELETE` (`CASCADE` for owned children, `RESTRICT` for references that must not disappear, `SET NULL` for optional links).
- `CHECK` constraints for invariants: `total_cents >= 0`, `ends_at > starts_at`.
- The application validates too (friendly errors), but the database is the last line of defense.

```sql
-- One active subscription per customer
CREATE UNIQUE INDEX one_active_subscription
  ON subscriptions (customer_id)
  WHERE status IN ('trialing', 'active');
```

## 4. Indexes

- **Foreign keys are not indexed automatically** in PostgreSQL — index the columns you join and filter on.
- **Composite indexes** follow the query: equality columns first, then the range or sort column (`(workspace_id, status, due_date)`).
- **Partial indexes** for hot subsets (`WHERE deleted_at IS NULL`, `WHERE status = 'pending'`).
- Every new query on a large table gets an `EXPLAIN (ANALYZE, BUFFERS)` check — look for sequential scans on big tables and row estimates that are far off.
- Watch `pg_stat_statements` for the slowest and most frequent queries; don't add indexes nobody uses (they slow down writes).
- Full-text search: a `tsvector` column with a GIN index before reaching for a search engine.

## 5. Queries and N+1

```ts
// ❌ N+1: one query for invoices, then one per invoice for the customer
const invoices = await db.invoice.findMany({ where: { workspaceId } });
for (const invoice of invoices) {
  invoice.customer = await db.customer.findUnique({ where: { id: invoice.customerId } });
}

// ✅ One query with a join, only the needed columns, limited
const invoices = await db.invoice.findMany({
  where: { workspaceId },
  select: { id: true, number: true, totalCents: true, customer: { select: { id: true, name: true } } },
  orderBy: { createdAt: "desc" },
  take: 50,
});
```

- Select only the columns you need (`api-design`, `backend-security-auditor` E1).
- Every list is limited and paginated.
- Turn on query logging in development to spot N+1 patterns; in GraphQL-style resolvers use a batching loader.
- Aggregations happen in the database (`COUNT`, `SUM`, `GROUP BY`), not by loading rows into the app.

## 6. Transactions and concurrency

- Multi-step writes that must succeed together run in **one transaction**; keep transactions short (no HTTP calls inside).
- **Race conditions** (stock, seats, balances): use an atomic update with a condition, or row locks.

```sql
-- Reserve stock atomically: succeeds only if enough is left
UPDATE products SET stock = stock - $2
WHERE id = $1 AND stock >= $2
RETURNING stock;
```

- **Optimistic locking** for user edits: a `version` column, `UPDATE … WHERE id = $1 AND version = $2`; zero updated rows means someone else changed it (`api-design` ETag/412).
- Unique constraints + idempotency keys prevent duplicates better than "check, then insert".
- Background jobs that process rows concurrently use `SELECT … FOR UPDATE SKIP LOCKED`.

## 7. Migrations without downtime

Code and schema change at different moments: during a deploy the **old code runs against
the new schema**. Every migration must work with both.

**Expand and contract** (e.g. renaming `name` to `full_name`):
1. **Expand:** add `full_name` (nullable); deploy code that writes both columns.
2. **Backfill** in batches (`UPDATE … WHERE id IN (…)` with a few thousand rows per batch).
3. **Switch reads** to `full_name`; add `NOT NULL` once every row is filled.
4. **Contract:** stop writing `name`; in a later release drop it.

Dangerous operations on large or busy tables:

| Operation | Problem | Safer |
|-----------|---------|-------|
| `CREATE INDEX` | blocks writes | `CREATE INDEX CONCURRENTLY` (outside a transaction) |
| Adding `NOT NULL` to an existing column | full table scan under lock | add `CHECK (col IS NOT NULL) NOT VALID`, `VALIDATE CONSTRAINT`, then `SET NOT NULL` |
| Adding a foreign key | validates all rows under lock | `ADD CONSTRAINT … NOT VALID`, then `VALIDATE CONSTRAINT` |
| Changing a column type | rewrites the table | new column + backfill + switch |
| Renaming or dropping a column | breaks the running code | expand and contract |

```sql
SET lock_timeout = '5s';           -- fail fast instead of queueing behind long transactions
CREATE INDEX CONCURRENTLY IF NOT EXISTS invoices_customer_id_idx ON invoices (customer_id);
```

- Migrations are **reviewed SQL** (look at what the ORM generated), committed, and never edited after they ran anywhere.
- They run as a separate deploy step before the code that needs them (`deploy-and-ops`).
- Destructive migrations run after a fresh backup and with a tested rollback plan.

## 8. Seeds and test data

- **Seed scripts** are deterministic and idempotent (`upsert`), create realistic volumes for performance testing and cover edge cases (long names, many line items, other currencies, Czech or other diacritics).
- Use generated fake data — **never copies of production personal data** in development or previews. If staging needs production-like data, anonymize it irreversibly (`gdpr-privacy`).
- E2E tests create their own data and clean it up, or run against a fresh database.

## 9. Operations

- **Connection pooling** in serverless and multi-instance setups (PgBouncer, the provider's pooler); the app uses the pooled URL, migrations the direct URL.
- Set statement timeouts for web requests (`statement_timeout`) so one slow query can't exhaust the pool.
- **Retention:** every table with personal or growing data has a retention rule and a cleanup job (`gdpr-privacy`); partition or archive very large time-series tables.
- **Backups, point-in-time recovery and restore drills:** `deploy-and-ops`.
- Monitor connections, slow queries, table and index bloat, replication lag.

## Checklist

- [ ] Every user-owned table has an owner column; tenant tables have `workspace_id` in queries and indexes.
- [ ] UUID keys (v4 or v7 deliberately); money in minor units or numeric; `timestamptz`.
- [ ] `NOT NULL`, `UNIQUE`, foreign keys with deliberate `ON DELETE`, `CHECK` for invariants.
- [ ] Indexes on foreign keys and real query patterns; `EXPLAIN` checked for new queries on big tables.
- [ ] No N+1; selects limited to needed columns; lists paginated.
- [ ] Concurrent writes atomic or locked; optimistic locking for user edits.
- [ ] Migrations backward compatible (expand and contract), concurrent indexes, lock timeouts, reviewed SQL.
- [ ] Seeds deterministic and fake; no production personal data outside production.
- [ ] Pooling, statement timeouts, retention jobs and backups in place.

## Output format

```markdown
## Database review: invoices module

| # | Finding | File | Fix |
|---|---------|------|-----|
| 1 | `invoices.customer_id` has no index; customer page does a seq scan on 3M rows | schema.prisma:41 | `@@index([customerId])`, created CONCURRENTLY |
| 2 | Migration renames `name` → `full_name` in one step | migrations/20261023_rename.sql | expand and contract over two releases |
| 3 | Totals stored as `Float` | schema.prisma:18 | `Int` cents + currency |
| 4 | N+1 when listing invoices with customers | app/invoices/page.tsx:12 | `select` with relation |
```

## Related skills

- `tech-stack-advisor` (database engine, ORM), `backend-security-auditor` (RLS, parameterized queries, undefined filters), `api-design` (pagination, idempotency, concurrency), `deploy-and-ops` (migrations in CI/CD, backups), `gdpr-privacy` (retention, anonymization), `web-performance` (slow TTFB from slow queries).
