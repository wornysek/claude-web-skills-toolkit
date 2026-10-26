---
name: auth-flows
description: "Designing and implementing user-facing authentication flows: choosing methods (passkeys, email magic links and one-time codes, OAuth/social sign-in, passwords with 2FA, enterprise SSO), libraries vs. providers, sign-up and email verification, sign-in, magic links that survive email link scanners, one-time codes, passkey registration and conditional UI, TOTP 2FA with recovery codes, password reset, email change, account linking, session and device management, sign-out everywhere and account recovery. Use whenever you build or change sign-up, sign-in, password reset, 2FA, passkeys, magic links or account settings. Security rules for reviewing auth code (cookies, OAuth state/PKCE, hashing, rate limits) live in backend-security-auditor."
triggers:
  - "sign-up / sign-in / log in / register"
  - "passkeys / WebAuthn / magic link / one-time code"
  - "2FA / two-factor / TOTP / recovery codes"
  - "password reset / forgot password / change email"
  - "social login / SSO / account linking / devices and sessions"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Auth flows

Authentication is a product feature: it decides whether people can get in, stay in and
get back in when something goes wrong. This skill covers the **flows and their UX**. The
security rules every implementation must pass are in `backend-security-auditor`
(sections A1–A6) — apply both.

## Process

1. **Choose the methods** for the audience (section 1) and **a library or provider** (section 2).
2. **Design every flow**, including the unhappy paths: sign-up, sign-in, recovery, changes, sign-out (sections 3–9).
3. **Write the copy** with `ux-writing-en` / `ux-writing-cs` / `ux-writing-de`; build forms per `forms`.
4. **Review** with `backend-security-auditor`, **test** each flow end to end (`webapp-testing`).

---

## 1. Choosing methods

| Method | Good for | Watch out for |
|--------|----------|---------------|
| **Passkeys** (WebAuthn) | most consumer and SaaS apps; phishing-resistant, no passwords to leak | need a fallback and recovery; explain them in one sentence |
| **Email magic link / one-time code** | infrequent use, low-friction sign-up | depends on email deliverability (`transactional-email`); link scanners (section 4) |
| **OAuth / social sign-in** | audiences that already have the account (Google, GitHub, Microsoft, Apple…) | account linking by verified email only; provider outages |
| **Password + 2FA** | users or markets that expect passwords; offline use | resets, breaches, password policies — needs 2FA for anything valuable |
| **Enterprise SSO** (SAML / OIDC, SCIM) | B2B customers | per-organization setup, domain verification, just-in-time provisioning |

- Offer **two methods at most** on the first screen (e.g. passkey or email code, plus one social provider); more options slow people down (`ux-laws` Hick).
- Accounts with privileges (admins, staff, billing owners) **must** have a second factor or passkeys.

## 2. Library or provider

- **Library** (Auth.js, Better Auth, Arctic for OAuth, SimpleWebAuthn for passkeys): users live in your database, no per-user fees, you own the flows and their security.
- **Managed provider** (Clerk, Auth0, WorkOS, Supabase Auth, Firebase Auth…): faster to start, hosted UI, enterprise SSO, but vendor lock-in of user IDs and per-user pricing.
- **Never hand-roll** password hashing, token generation or WebAuthn verification. The decision is a one-way door — record it (`tech-stack-advisor`).

## 3. Sign-up and verification

- Ask for the minimum: email (or a passkey) — name and the rest later, in context.
- **Verify the email** before it is trusted (password resets, invoices, account linking). Decide whether unverified users can use the product in a limited way.
- The same response for "new email" and "already registered" ("Check your inbox to continue") — the existing user gets a sign-in link instead (no account enumeration).
- Terms acceptance and marketing consent are separate (`gdpr-privacy`).
- After sign-up: a clear next step, not an empty dashboard (`frontend-design-guide` empty states).

## 4. Magic links and one-time codes

Email security scanners open links before the user does. If the `GET` request signs the
user in or consumes the token, the scanner uses it up. **The link opens a confirmation
page; a `POST` consumes the token.**

```ts
// lib/magic-link.ts
import "server-only";
import { createHash, randomBytes } from "node:crypto";

const TTL_MINUTES = 15;
const hash = (token: string) => createHash("sha256").update(token).digest("hex");

export async function createMagicLink(email: string) {
  const token = randomBytes(32).toString("base64url");
  await db.magicLinkToken.create({
    data: { tokenHash: hash(token), email, expiresAt: new Date(Date.now() + TTL_MINUTES * 60_000) },
  });
  return `${env.APP_ORIGIN}/auth/verify?token=${token}`;
}

// Atomic: the token can be used exactly once, even with parallel requests
export async function consumeMagicLink(token: string): Promise<string | null> {
  const rows = await db.$queryRaw<{ email: string }[]>`
    DELETE FROM magic_link_tokens
    WHERE token_hash = ${hash(token)} AND expires_at > now()
    RETURNING email`;
  return rows[0]?.email ?? null;
}
```

```tsx
// app/auth/verify/page.tsx — GET shows a button, it doesn't sign in
export default async function VerifyPage({ searchParams }: { searchParams: Promise<{ token?: string }> }) {
  const { token } = await searchParams;
  return (
    <form action={verifyMagicLink}>
      <input type="hidden" name="token" value={token ?? ""} />
      <h1>Sign in to Acme</h1>
      <Button type="submit">Continue</Button>
    </form>
  );
}
```

- Tokens: random, stored hashed, single-use, 10–15 minutes; requesting a new one invalidates older ones.
- **One-time codes** (6 digits) as an alternative or fallback: same storage rules, max ~5 attempts per code, `autoComplete="one-time-code"`, paste allowed, code also in the email subject or preheader for mobile autofill.
- The confirmation screen says where the link was sent and offers "Use a code instead" and "Resend" (with a cooldown).

## 5. Passkeys

- **Registration** after sign-in or at sign-up: server generates options (challenge, user ID, relying party ID = your domain), the browser creates the credential, the server verifies and stores **credential ID, public key, sign counter, transports and a user-given name**.
- **Sign-in:** offer passkeys through autofill ("conditional UI") on the email field — `autoComplete="username webauthn"` — plus an explicit "Sign in with a passkey" button.
- Allow **several passkeys** per account (phone, laptop, security key), show them in settings with names and last-used dates, and let users remove them.
- Keep a **fallback** (email code) and a **recovery path** (section 8); never lock out a user who lost their only device.
- Use a maintained library (e.g. SimpleWebAuthn: `generateRegistrationOptions` / `verifyRegistrationResponse`, `generateAuthenticationOptions` / `verifyAuthenticationResponse`) and check its current API.

## 6. Passwords and 2FA

- Password rules per `backend-security-auditor` A4 (Argon2id, length over composition, paste and managers allowed, breached-password check).
- **TOTP 2FA setup:** show a QR code and the secret as text, require a valid code before enabling, then show **recovery codes once**.
- **Recovery codes:** 8–10 random codes, stored hashed, each usable once, regenerable (which invalidates the old set).

```ts
// lib/recovery-codes.ts
import { createHash, randomBytes } from "node:crypto";

export function generateRecoveryCodes(count = 10) {
  const codes = Array.from({ length: count }, () => {
    const raw = randomBytes(5).toString("hex"); // 10 hex characters
    return `${raw.slice(0, 5)}-${raw.slice(5)}`;
  });
  const hashes = codes.map((code) => createHash("sha256").update(code).digest("hex"));
  return { codes, hashes }; // show `codes` once, store only `hashes`
}
```

- "Remember this device" for 2FA is a signed, expiring cookie tied to the user, revocable in settings.
- Passkeys count as a second factor or replace password + TOTP entirely.

## 7. Password reset and email change

**Reset:**
1. "Forgot password?" → email field → always "If an account exists, we sent a link".
2. The link (token rules: `backend-security-auditor` A4) opens a page to set a new password.
3. After the change: other sessions are revoked (A4) and the user gets a notification email ("Your password was changed — if it wasn't you, …").

**Email change:**
1. Confirm the **new** address with a link or code before switching.
2. Notify the **old** address with a way to revert for a limited time.
3. Re-authenticate before the change (recent sign-in or a fresh code).

## 8. Account recovery

- Plan for: lost device with the only passkey, lost authenticator app, lost access to the email account.
- Self-service recovery uses something the attacker is unlikely to have: recovery codes, a second passkey, a verified phone *as a recovery option only*.
- Manual recovery by support follows a written process with identity verification and a **cooling-off period** (e.g. 24–72 hours with notifications to all known contacts) — support staff are the easiest target for social engineering.

## 9. Sessions, devices and sign-out

- **Settings → Security** lists active sessions (device, browser, approximate location, last active) and passkeys; each can be revoked.
- "Sign out of all other devices" — after password changes this happens automatically.
- Sensitive actions (changing email, password, 2FA, deleting the account, payouts) require **re-authentication** if the last sign-in is older than a few minutes.
- Session lifetime: sliding expiry for normal use, absolute maximum (e.g. 30 days); shorter for admin areas.
- Notify users by email about new sign-ins from unknown devices and about security changes.

## 10. OAuth and account linking

- Implementation and security rules: `backend-security-auditor` A3 (state, PKCE, provider subject as the identity).
- **Linking:** a user signed in with email can add Google; an existing account is merged only when the provider's email is **verified** — otherwise ask the user to sign in with the original method first.
- Show connected providers in settings; never let the user remove the last sign-in method.
- Handle provider errors and cancellations with a clear message and a way back.

## Checklist

- [ ] Methods chosen for the audience; at most two on the first screen; privileged accounts have 2FA or passkeys.
- [ ] Library or provider chosen and recorded; no hand-rolled crypto.
- [ ] Sign-up asks the minimum; email verified before it is trusted; no account enumeration.
- [ ] Magic links confirmed by POST, single-use, short-lived; codes limited in attempts.
- [ ] Passkeys: several per account, managed in settings, with fallback and recovery.
- [ ] 2FA with recovery codes shown once and stored hashed.
- [ ] Reset revokes other sessions and notifies; email change confirmed on the new and notified on the old address.
- [ ] Recovery process written down, with a cooling-off period for manual recovery.
- [ ] Sessions listed and revocable; re-authentication for sensitive actions; security notifications.
- [ ] Reviewed against `backend-security-auditor` A1–A6; every flow covered by E2E tests.

## Output format

```markdown
## Auth flow review

| # | Flow | Finding | Fix |
|---|------|---------|-----|
| 1 | Magic link | GET /auth/verify signs in — email scanners consume links | confirmation page + POST |
| 2 | Password reset | Other sessions stay active after reset | revoke sessions + notification email |
| 3 | 2FA | Recovery codes stored in plain text | store SHA-256 hashes, show codes once |
| 4 | Account linking | Google account merged by unverified email | merge only if `email_verified`, else ask to sign in first |
```

## Related skills

- `backend-security-auditor` (A1–A6), `forms` (sign-in and sign-up forms), `transactional-email` (verification, reset and notification emails), `ux-writing-en` / `ux-writing-cs` / `ux-writing-de` (auth copy), `a11y-auditor` (accessible authentication 3.3.8), `gdpr-privacy` (consent, account deletion), `tech-stack-advisor` (library vs. provider).
