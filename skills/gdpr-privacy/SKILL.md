---
name: gdpr-privacy
description: "Privacy engineering for web apps under the EU GDPR and ePrivacy rules: data minimization and a data inventory, legal bases, cookie and tracking consent without dark patterns, third-party scripts and embeds, privacy notice contents, data subject rights (access/export, rectification, erasure, objection), retention and automatic deletion, processors and international transfers, PII in logs and error tracking, children's consent and breach readiness. Use whenever you build or change sign-up, forms that collect personal data, analytics, cookies or tracking, marketing emails, account deletion or export, logging, or third-party integrations, and when the user asks about GDPR, cookies, privacy policy or personal data."
triggers:
  - "GDPR / personal data / privacy"
  - "cookie banner / consent / analytics / tracking pixels"
  - "privacy policy / privacy notice"
  - "delete account / export my data / data retention"
  - "newsletter / marketing emails / consent checkbox"
  - "logging / Sentry / third-party scripts / embeds"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  references: "GDPR (EU) 2016/679, ePrivacy Directive 2002/58/EC, EDPB guidelines"
---

# GDPR & Privacy engineering

This skill makes the **technical** side of privacy correct by default: what you collect,
when scripts may run, how users exercise their rights and when data disappears.

> **Not legal advice.** The legal texts (privacy notice, terms, DPAs) and the choice of
> legal bases belong to the product owner and a lawyer or DPO. Claude implements the
> mechanics and flags open legal questions as `[LEGAL: …]` — it never writes a privacy
> notice that claims compliance it can't verify.

## Process

1. **Inventory the data** the change touches (section 1). New field, new table, new third party → new row.
2. **Minimize:** drop anything without a purpose for this feature (section 2).
3. **Gate non-essential processing behind consent** (sections 3–4).
4. **Implement the rights** that the data needs: export, correction, deletion (section 6).
5. **Set retention** and automatic deletion (section 7).
6. **Check processors, transfers and logs** (sections 8–9).
7. **Report** with the output format at the end, including open `[LEGAL: …]` questions.

---

## 1. Data inventory (record of processing)

Keep `docs/privacy/data-inventory.md` next to the code and update it in the same PR as the change:

| Data | Where | Purpose | Legal basis | Retention | Shared with | Location |
|------|-------|---------|-------------|-----------|-------------|----------|
| Email | `users.email` | sign-in, account emails | contract | account lifetime + 30 days | email provider | EU |
| IP address | access logs | security, abuse prevention | legitimate interest | 30 days | hosting provider | EU |
| Analytics events | analytics tool | product improvement | consent | 13 months | analytics provider | [LEGAL: confirm region] |
| Newsletter subscription | `subscriptions` | marketing emails | consent | until unsubscribed | email provider | EU |

## 2. Data minimization and privacy by default

- **Every field has a purpose.** If the feature works without it, don't collect it. Optional fields are really optional (not `required` in the schema).
- **Explain why** next to sensitive fields ("We use your phone number only for delivery updates").
- **Defaults are private:** marketing opt-ins unchecked, profiles not public, sharing off.
- **Special categories** (health, religion, political opinions, biometrics, sexual orientation) — avoid; if unavoidable, flag `[LEGAL: special category data]`.
- **Pseudonymize** where full identity isn't needed (analytics, internal statistics).
- **Don't put personal data in URLs** (query strings end up in logs, analytics and referrers).

## 3. Legal bases (for orientation)

| Basis | Typical use | Consequence in code |
|-------|-------------|---------------------|
| Contract | account, orders, delivering the service | no consent box needed for what the service requires |
| Legal obligation | invoices, tax records | retention set by law, can't be deleted on request |
| Legitimate interest | security logs, fraud prevention, basic product metrics | document the balancing test, offer objection |
| Consent | analytics and marketing cookies, newsletters, non-essential third parties | must be opt-in, granular, recorded, withdrawable |

Don't hide consent inside "I accept the terms". Accepting terms and consenting to marketing are separate checkboxes.

## 4. Cookies, tracking and third-party scripts

**Strictly necessary** (no consent needed): session cookie, CSRF token, load balancing,
the consent cookie itself, a shopping cart. **Everything else needs opt-in first:**
analytics, advertising and remarketing pixels, A/B testing tools, session replay, chat
widgets that track, embedded videos and maps that set cookies.

Consent banner rules:
- **"Reject all" is as easy and as visible as "Accept all"** — same level, same prominence, first layer.
- **No pre-ticked categories**, no "by continuing to browse you agree", no cookie walls blocking the content.
- **Granular** categories (e.g. analytics, marketing), each explained in one sentence.
- **Withdrawal is as easy as consent:** a permanent "Cookie settings" link in the footer.
- **Record the consent:** choices, timestamp, banner/policy version (needed to demonstrate consent).
- **Nothing non-essential loads before consent** — not "loaded but paused".

```tsx
// components/consent-scripts.tsx
"use client";

import Script from "next/script";
import { useConsent } from "@/lib/consent"; // reads the stored choices, updates on change

export function ConsentScripts() {
  const consent = useConsent();
  return (
    <>
      {consent.analytics ? (
        <Script src="https://analytics.example.com/script.js" strategy="afterInteractive" data-domain="example.com" />
      ) : null}
      {consent.marketing ? <Script id="marketing-pixel" strategy="afterInteractive" src="/scripts/pixel.js" /> : null}
    </>
  );
}
```

```ts
// lib/consent.ts — stored choices (a first-party, strictly necessary cookie)
export type ConsentChoices = {
  version: string;        // bump when categories or the policy change → ask again
  decidedAt: string;      // ISO timestamp
  analytics: boolean;
  marketing: boolean;
};
```

Third parties that leak data without any cookie banner involvement:
- **Fonts from a third-party CDN** send the visitor's IP to that provider — self-host fonts (`next/font` does this automatically).
- **Embeds** (video, maps, social posts): click-to-load placeholders; use privacy-enhanced embed domains where they exist.
- **"Cookieless" analytics** reduce risk but are not automatically exempt everywhere — record the assessment in the inventory.

## 5. Privacy notice — what the code must support

The text is legal work, but the product must provide the facts and links (GDPR Art. 13/14):

- [ ] Controller identity and contact; DPO contact if there is one.
- [ ] Purposes and legal bases (from the inventory); legitimate interests named.
- [ ] Recipients and processors; transfers outside the EEA and their safeguards (e.g. adequacy decision, Standard Contractual Clauses).
- [ ] Retention periods (from section 7).
- [ ] The user's rights and **how to use them in the product** (links to export, delete, settings).
- [ ] Right to withdraw consent and to complain to a supervisory authority.
- [ ] Whether providing data is required and what happens if not; any automated decision-making.
- [ ] Linked from the footer, the sign-up form and every form collecting personal data. Versioned.

## 6. Data subject rights — implement them in the product

Respond **without undue delay and within one month** (extendable in complex cases).
Self-service in the product is the cheapest way to comply.

| Right | Implementation |
|-------|----------------|
| Access + portability | "Download my data" → machine-readable JSON (or CSV) of everything tied to the account |
| Rectification | editable profile and settings |
| Erasure | "Delete account" → delete or anonymize, cascade to related data and processors |
| Restriction / objection | opt-outs for marketing and profiling; objection to legitimate-interest processing |
| Withdraw consent | cookie settings, unsubscribe links, notification settings |

Rules:
- **Re-authenticate** before export or deletion (fresh sign-in or confirmation code).
- Export and deletion run as **background jobs** with a status and an email when done; exports are delivered through a short-lived authenticated download, never as a public link.
- **Deletion means** removing personal data from the primary database, search indexes, caches and file storage, and telling processors (email provider, CRM). **Backups** expire on their normal cycle — document the window.
- **Keep what the law requires** (invoices, tax records) and anonymize the rest of the record.
- Content other people rely on (forum posts, comments) can be **anonymized** ("Deleted user") instead of removed — decide and document.

```ts
// app/api/account/route.ts — account deletion (simplified)
export async function DELETE(req: Request) {
  const user = await requireRecentAuth(req); // re-authenticated within the last few minutes
  await db.$transaction(async (tx) => {
    await tx.session.deleteMany({ where: { userId: user.id } });
    await tx.comment.updateMany({ where: { authorId: user.id }, data: { authorId: null, authorLabel: "Deleted user" } });
    await tx.invoice.updateMany({ where: { userId: user.id }, data: { customerEmail: null } }); // invoices kept by law
    await tx.user.delete({ where: { id: user.id } });
  });
  await jobs.enqueue("erase-user-from-processors", { userId: user.id }); // email provider, CRM, analytics
  await audit.log("account.deleted", { userId: user.id });                // store the ID only, no personal data
  return new Response(null, { status: 204 });
}
```

## 7. Retention and automatic deletion

Every data type in the inventory has a retention period and a **job that enforces it**.
"We delete it eventually" is not a retention policy.

| Data | Example retention | Job |
|------|-------------------|-----|
| Unverified sign-ups | 30 days | daily cleanup |
| Inactive accounts | 2 years → warning email → deletion | monthly |
| Access and security logs | 30–90 days | log provider retention setting |
| Password reset / email tokens | 1 hour | expire on read + daily cleanup |
| Analytics events | 13–26 months | provider setting |
| Invoices | as required by local law | archive, no deletion |

```sql
-- Daily job (pg_cron, a scheduled function or a cron route)
DELETE FROM users WHERE email_verified_at IS NULL AND created_at < now() - interval '30 days';
DELETE FROM password_reset_tokens WHERE expires_at < now();
```

## 8. Processors and international transfers

- Every third party that touches personal data (hosting, database, email, analytics, error tracking, support chat, payments) is a **processor** → a signed **DPA** and an entry in the inventory.
- Prefer **EU regions** for databases, storage and logs; set the region explicitly.
- Transfers outside the EEA need a legal mechanism (adequacy decision such as the EU–US Data Privacy Framework for certified companies, or SCCs) → `[LEGAL: transfer mechanism for <provider>]`.
- Maintain a public **sub-processor list** if you are a processor for your own customers (B2B).

## 9. Logs, monitoring and error tracking

- **Don't log personal data** you don't need: no emails, names, request bodies, tokens or full IP addresses in application logs. Log IDs instead.
- **Error tracking:** turn off default PII collection and scrub before sending:

```ts
// sentry.server.config.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  sendDefaultPii: false,
  beforeSend(event) {
    if (event.request) {
      delete event.request.cookies;
      delete event.request.data;
      if (event.request.headers) delete event.request.headers.authorization;
    }
    if (event.user) event.user = { id: event.user.id }; // keep only the internal ID
    return event;
  },
});
```

- **Session replay** tools mask all inputs and text by default; enable only with consent.
- **IP addresses:** truncate or hash for statistics; keep full IPs only in short-lived security logs.

## 10. Children, marketing and breaches

- **Children:** for services offered directly to children, consent requires a parent below the national age limit (13–16 depending on the member state, e.g. 15 in Czechia, 16 in Germany). Ask for age only if the service needs it → `[LEGAL: age limit and verification]`.
- **Marketing emails:** separate opt-in (double opt-in recommended), a working one-click unsubscribe in every email, and no marketing to people who only made an account.
- **Breach readiness:** a personal data breach must be reported to the supervisory authority within **72 hours** of becoming aware of it, and to affected users when the risk is high. Keep a short runbook (who decides, who notifies, where the access logs are) and make sure logs can answer "what was accessed, by whom, when".
- **Security of processing** (encryption, access control, audit logs) is part of GDPR — apply `backend-security-auditor`.

---

## Checklist

- [ ] The data inventory is updated for every new field, table and third party.
- [ ] No field without a purpose; optional fields are optional; defaults are private.
- [ ] No non-essential cookie, pixel, font CDN or embed loads before opt-in.
- [ ] "Reject all" is as visible as "Accept all"; consent is granular, recorded and withdrawable from the footer.
- [ ] Terms acceptance and marketing consent are separate.
- [ ] Users can export their data (JSON) and delete their account in the product, after re-authentication.
- [ ] Deletion cascades to related data, caches, files and processors; legally required records are kept anonymized.
- [ ] Every data type has a retention period and a job that enforces it.
- [ ] Every processor has a DPA; regions are set; transfers have a mechanism.
- [ ] Logs and error tracking contain no unnecessary personal data.
- [ ] Open legal questions are listed as `[LEGAL: …]` for the product owner.

## Output format

```markdown
## Privacy review: sign-up and analytics

| # | Area | Finding | File:line | Fix |
|---|------|---------|-----------|-----|
| 1 | Consent | Analytics script loads before the banner choice | app/layout.tsx:18 | render via `ConsentScripts` only when `consent.analytics` |
| 2 | Minimization | Phone number is required but never used | lib/schemas/signup.ts:9 | remove the field |
| 3 | Rights | No account deletion in settings | app/settings/page.tsx | add "Delete account" with re-auth + background erasure |
| 4 | Logs | Request bodies with emails logged on errors | lib/logger.ts:22 | log user ID only, redact body |

**Inventory updated:** yes · **Open legal questions:** [LEGAL: transfer mechanism for the analytics provider]
```

## Related skills

- `backend-security-auditor` — security of processing, auth, access control, secrets.
- `ux-writing-en` / `ux-writing-cs` — clear consent texts, banner copy and form explanations (no dark patterns in wording either).
- `ux-laws` — Hick and Von Restorff: "Reject" must not be visually hidden behind a highlighted "Accept".
- `seo-metadata` — noindex for account, export and settings pages.
