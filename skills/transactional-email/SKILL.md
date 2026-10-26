---
name: transactional-email
description: "Transactional and notification email for web apps: choosing a provider, React Email templates with plain-text versions, sending from background jobs with retries, deliverability (SPF, DKIM, DMARC, alignment, separate sending subdomains, bulk-sender requirements, one-click unsubscribe), bounces and complaints, notification preferences, localized emails in the recipient's language, accessible and dark-mode-friendly design, security of links and content, and testing without sending real email. Use whenever you add or change an email (verification, magic link, password reset, receipts, notifications, digests), set up an email provider or DNS for email, or emails land in spam. For the wording use ux-writing-en / ux-writing-cs; for marketing consent use gdpr-privacy."
triggers:
  - "send an email / email template / React Email"
  - "verification / password reset / receipt / notification email"
  - "emails go to spam / SPF / DKIM / DMARC"
  - "unsubscribe / notification preferences"
  - "email provider / Resend / Postmark / SES"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Transactional email

Transactional emails are part of the product: sign-in links, password resets, receipts
and notifications. If they arrive late, land in spam or look broken, users can't sign in
or think they didn't pay.

## Process

1. **List the emails** the product sends, their trigger, recipient language and whether they are essential or optional (notification preferences).
2. **Set up the domain** — sending subdomain, SPF, DKIM, DMARC (section 1).
3. **Build templates** with React Email (or the provider's templates), HTML + plain text (sections 3–4).
4. **Send from a job** with retries and logging (section 2).
5. **Handle bounces and complaints**, offer preferences and unsubscribe (section 5).
6. **Test** locally without real recipients (section 7).

---

## 1. Domain and deliverability

| Record | Example (placeholders) | Purpose |
|--------|------------------------|---------|
| SPF | `mail.example.com TXT "v=spf1 include:<provider-spf> ~all"` | which servers may send for the domain |
| DKIM | `<selector>._domainkey.mail.example.com CNAME <provider-dkim-target>` | signs each message |
| DMARC | `_dmarc.example.com TXT "v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com"` | policy + reports; tighten to `quarantine` / `reject` once reports are clean |
| Return path | `bounces.mail.example.com CNAME <provider-target>` | bounce handling and SPF alignment |

- Send from a **subdomain** (`mail.example.com`) and keep **transactional and marketing streams separate** (different subdomains or provider streams) — a marketing complaint spike must not block password resets.
- The `From` domain **aligns** with the DKIM (and ideally SPF) domain — required for DMARC to pass.
- Only one SPF record per name, at most 10 DNS lookups.
- Large mailbox providers require authentication (SPF, DKIM, DMARC), low spam complaint rates and **one-click unsubscribe** (`List-Unsubscribe` + `List-Unsubscribe-Post`) for bulk and marketing mail.
- Warm up new domains and IPs gradually; monitor provider dashboards and postmaster tools.
- A real `Reply-To` that someone reads, or a clear "replies are not monitored" note with a support link.

## 2. Sending

```tsx
// lib/email/send.tsx
import "server-only";
import { render } from "@react-email/render";
import { Resend } from "resend";
import PasswordResetEmail from "@/emails/password-reset";
import { env } from "@/lib/env";

const resend = new Resend(env.RESEND_API_KEY);

export async function sendPasswordResetEmail(to: { email: string; name: string; locale: string }, resetUrl: string) {
  const element = <PasswordResetEmail name={to.name} resetUrl={resetUrl} locale={to.locale} />;
  const { error } = await resend.emails.send({
    from: "Acme <notifications@mail.example.com>",
    to: to.email,
    subject: to.locale === "cs" ? "Obnovení hesla" : "Reset your password",
    react: element,
    text: await render(element, { plainText: true }),
  });
  if (error) throw new Error(`Email provider rejected the message: ${error.name}`);
}
```

- **Send from a background job** (`deploy-and-ops`), not inside the request: retries with backoff on provider errors, the user doesn't wait, a provider outage doesn't break sign-up.
- **Idempotent:** a job key per email event (`password-reset:<tokenId>`) so retries don't send duplicates.
- Log the provider message ID and the event, **not** the content or full addresses beyond what you need (`gdpr-privacy`).
- Rate-limit user-triggered emails (resend link, invite) per user and per recipient (`backend-security-auditor` G1).
- Any provider works the same way (Postmark, Amazon SES, SendGrid, Mailgun…); check the SDK's current API.

## 3. Templates

```tsx
// emails/password-reset.tsx
import { Body, Button, Container, Head, Heading, Html, Preview, Text } from "@react-email/components";

export default function PasswordResetEmail({ name, resetUrl, locale = "en" }: { name: string; resetUrl: string; locale?: string }) {
  return (
    <Html lang={locale}>
      <Head />
      <Preview>Reset your password. The link works for 1 hour.</Preview>
      <Body style={{ backgroundColor: "#ffffff", color: "#111111", fontFamily: "system-ui, -apple-system, Segoe UI, sans-serif" }}>
        <Container style={{ maxWidth: 560, padding: "24px" }}>
          <Heading as="h1" style={{ fontSize: 22, lineHeight: 1.3 }}>Reset your password</Heading>
          <Text style={{ fontSize: 16, lineHeight: 1.5 }}>
            Hi {name}, we received a request to reset the password for your Acme account. The link works for 1 hour.
          </Text>
          <Button href={resetUrl} style={{ backgroundColor: "#111111", color: "#ffffff", padding: "12px 20px", borderRadius: 6, fontSize: 16 }}>
            Reset password
          </Button>
          <Text style={{ fontSize: 14, color: "#555555" }}>
            If you didn't ask for this, you can ignore this email. Your password stays the same.
          </Text>
        </Container>
      </Body>
    </Html>
  );
}
```

- **One purpose and one primary action** per email; the subject states the result or the action ("Your payment was received", "Confirm your email").
- **Preview text** (preheader) adds information instead of repeating the subject.
- **Plain-text version** always (accessibility, spam filters, some clients).
- **Localized** in the recipient's stored language, with dates and amounts formatted for that locale (`i18n-setup`); copy by `ux-writing-en` / `ux-writing-cs` / `ux-writing-de`, then `deslop-*`.
- Brand from the design tokens, but email-safe: inline styles, system fonts or web fonts with fallbacks, max width ~600 px, no layout depending on CSS that email clients drop.

## 4. Accessibility, dark mode and links

- `lang` on `<html>`, real headings, text at least 14–16 px, contrast per `a11y-auditor`, meaningful `alt` text; the email still makes sense with images blocked.
- **Dark mode:** avoid transparent PNG logos that disappear on dark backgrounds; test in clients that invert colors.
- Buttons are links with descriptive text, plus the full URL as text for clients that break buttons.
- **Absolute HTTPS links** to your own domain; no link shorteners; tracking redirects only through your own domain (and only with consent where required).

## 5. Bounces, complaints, preferences

- Subscribe to provider **webhooks** for bounces, complaints and deliveries; verify their signatures (`backend-security-auditor` G2).
- **Hard bounces and complaints** go on a suppression list — never send to those addresses again automatically; show users "We couldn't deliver email to this address" in settings.
- **Essential emails** (security, receipts, password reset) can't be turned off; **optional notifications** (comments, digests, product news) have per-type preferences and an unsubscribe link that works without signing in (signed, expiring token).
- Marketing email needs opt-in consent and lives in the marketing stream (`gdpr-privacy`).

## 6. Security of email content

- **No secrets in email:** no passwords, no long-lived tokens; sign-in and reset links are single-use and short-lived (`auth-flows`).
- Don't put personal data that isn't needed into emails (they are stored forever in inboxes).
- Escape all user-provided content in templates (React Email does it; raw HTML templates must too) — a user's display name must not inject links or HTML.
- Security-relevant events (password changed, new sign-in, email changed) notify the user with a way to react.

## 7. Testing

- **Preview templates** locally (`email dev` from React Email) with realistic data: long names, long amounts, other languages.
- In development and previews send to a **local mail catcher** (e.g. Mailpit) or the provider's test mode — never to real addresses.
- E2E tests mock the email provider or read the catcher's API to follow links (`webapp-testing`).
- Check rendering in the main clients (Gmail web and mobile, Apple Mail, Outlook) and run a spam/authentication test before launch.

## Checklist

- [ ] Sending subdomain with SPF, DKIM, DMARC (aligned); transactional and marketing streams separate.
- [ ] Templates with one primary action, preheader, plain-text version, localized, accessible.
- [ ] Sending from background jobs, idempotent, rate-limited, logged by message ID without content.
- [ ] Bounce and complaint webhooks verified; suppression list honored.
- [ ] Optional notifications have preferences and a working unsubscribe; essential ones are clearly essential.
- [ ] No secrets or unnecessary personal data in emails; user content escaped.
- [ ] Previews and tests never send to real recipients.

## Output format

```markdown
## Email review

| # | Email / area | Finding | Fix |
|---|--------------|---------|-----|
| 1 | DNS | DMARC missing, From domain not aligned with DKIM | add DMARC `p=none`, DKIM for `mail.example.com` |
| 2 | Password reset | Sent inside the request; provider timeout fails the whole request | background job with retries |
| 3 | Comment notifications | No unsubscribe, no preferences | per-type preferences + signed unsubscribe link |
| 4 | All templates | No plain-text version | `render(…, { plainText: true })` |
```

## Related skills

- `auth-flows` (verification, magic links, reset, security notifications), `ux-writing-en` / `ux-writing-cs` / `ux-writing-de` (copy), `i18n-setup` (recipient locale), `gdpr-privacy` (consent, retention), `deploy-and-ops` (DNS, jobs, monitoring), `backend-security-auditor` (webhook signatures, rate limits).
