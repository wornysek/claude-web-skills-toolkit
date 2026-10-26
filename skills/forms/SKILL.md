---
name: forms
description: "Building web forms end to end: one Zod schema for client and server, React 19 server actions with useActionState (progressive enhancement) or react-hook-form for rich client forms, field types, autocomplete and input modes, inline and summary errors, keeping values after errors, double-submit protection, multi-step forms and drafts, spam protection (honeypot, timing, Turnstile/CAPTCHA alternatives), and file uploads with presigned URLs. Use whenever you create or change a form — contact, sign-up, checkout, settings, search, multi-step wizard or upload. For the wording of labels and errors use ux-writing-en / ux-writing-cs; for tests use webapp-testing; for server-side security rules use backend-security-auditor."
triggers:
  - "create a form / contact form / settings form / wizard"
  - "form validation / error messages / Zod / react-hook-form"
  - "server action / useActionState / progressive enhancement"
  - "spam protection / honeypot / CAPTCHA / Turnstile"
  - "file upload / drag and drop / presigned URL"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Forms

Forms are where users give you something — and where most of the frustration happens.
A good form asks for little, accepts reasonable input, explains errors next to the field,
never loses what the user typed and can't be submitted twice.

## Process

1. **Decide the fields** with the product goal: drop everything that isn't needed now (`ux-laws` — Occam, Miller; `gdpr-privacy` — minimization).
2. **Write one schema** (section 1) — the source of truth for types, rules and messages.
3. **Pick the form approach** (section 2): server action with `useActionState`, or react-hook-form for rich client-side forms.
4. **Build the fields** from the registry (`shadcn-ui`: `field`, `input`, `select`, `checkbox`…) with correct types and `autocomplete` (section 3).
5. **Handle errors, pending state and spam** (sections 4–6), uploads if needed (section 8).
6. **Test** with the form matrix in `webapp-testing`.

---

## 1. One schema for client and server

```ts
// lib/schemas/contact.ts
import { z } from "zod";

export const ContactSchema = z.object({
  name: z.string().trim().min(1, "Enter your name.").max(100),
  email: z.string().trim().toLowerCase().email("Enter an email address like name@example.com."),
  company: z.string().trim().max(120).optional(),
  message: z.string().trim().min(20, "Write at least 20 characters.").max(2000),
});

export type ContactInput = z.infer<typeof ContactSchema>;
```

- The **server always validates again** — client validation is UX only (`backend-security-auditor` C1).
- Normalize before validating (trim, lowercase emails, strip spaces from phone numbers — Postel's law in `ux-laws`).
- Messages say how to fix the problem (`ux-writing-en` / `ux-writing-cs` / `ux-writing-de` / `ux-writing-uk`); with i18n they are translation keys (`i18n-setup`).

## 2. Choosing the approach

| Situation | Approach |
|-----------|----------|
| Most forms: contact, sign-up, settings, checkout steps | **Server action + `useActionState`** — works without JavaScript, simple, one round trip |
| Rich client behavior: dependent fields, live previews, field arrays, instant validation on every change | **react-hook-form + `zodResolver`**, submitting to a server action or API |
| Search and filters | a `GET` form that updates the URL (shareable, back button works) |

**Server action with progressive enhancement:**

```ts
// app/contact/actions.ts
"use server";

import { redirect } from "next/navigation";
import { ContactSchema } from "@/lib/schemas/contact";
import { isLikelySpam } from "@/lib/spam";

export type ContactState = {
  errors?: Partial<Record<"name" | "email" | "company" | "message" | "form", string[]>>;
  values?: Record<string, string>;
};

export async function sendContact(_prev: ContactState, formData: FormData): Promise<ContactState> {
  const values = Object.fromEntries(
    ["name", "email", "company", "message"].map((key) => [key, String(formData.get(key) ?? "")]),
  );

  if (await isLikelySpam(formData)) redirect("/contact/thanks"); // don't tell bots they were caught

  const parsed = ContactSchema.safeParse(values);
  if (!parsed.success) return { errors: parsed.error.flatten().fieldErrors, values };

  await contactRequests.create(parsed.data); // explicit fields only, rate-limited (backend-security-auditor)
  redirect("/contact/thanks");
}
```

```tsx
// app/contact/contact-form.tsx
"use client";

import { useActionState } from "react";
import { sendContact, type ContactState } from "./actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

export function ContactForm() {
  const [state, formAction, isPending] = useActionState<ContactState, FormData>(sendContact, {});
  const error = (field: keyof NonNullable<ContactState["errors"]>) => state.errors?.[field]?.[0];

  return (
    <form action={formAction} className="space-y-6" noValidate>
      <div className="space-y-1.5">
        <Label htmlFor="name">Name</Label>
        <Input
          id="name"
          name="name"
          autoComplete="name"
          required
          defaultValue={state.values?.name}
          aria-invalid={error("name") ? true : undefined}
          aria-describedby={error("name") ? "name-error" : undefined}
        />
        {error("name") ? <p id="name-error" className="text-sm text-destructive">{error("name")}</p> : null}
      </div>

      {/* email (type="email", autoComplete="email", inputMode="email"), company, message — same pattern */}

      {/* Honeypot: invisible to people, attractive to bots */}
      <div aria-hidden="true" className="absolute -left-[9999px]">
        <label htmlFor="website">Website</label>
        <input id="website" name="website" tabIndex={-1} autoComplete="off" />
      </div>

      <Button type="submit" disabled={isPending} aria-busy={isPending}>
        {isPending ? "Sending…" : "Send message"}
      </Button>
    </form>
  );
}
```

- `noValidate` turns off the browser's bubbles once JavaScript runs; native attributes (`required`, `type`, `maxLength`) still document intent and help without JS.
- With react-hook-form keep the same schema (`zodResolver(ContactSchema)`), validate `onBlur` then `onChange` after the first submit (`mode: "onTouched"`), and still parse on the server.

## 3. Fields

| Data | Input | Attributes |
|------|-------|------------|
| Name | `text` | `autoComplete="name"` (or `given-name` / `family-name`) |
| Email | `email` | `autoComplete="email"`, `inputMode="email"`, `spellCheck={false}` |
| Phone | `tel` | `autoComplete="tel"`, accept spaces and `+` |
| Address | `text` | `street-address`, `address-line1`, `postal-code`, `address-level2` (city), `country` |
| New password | `password` | `autoComplete="new-password"`, show/hide toggle, paste allowed |
| Current password | `password` | `autoComplete="current-password"` |
| One-time code | `text` | `autoComplete="one-time-code"`, `inputMode="numeric"`, `pattern="[0-9]*"` |
| Amount / quantity | `text` + `inputMode="decimal"` / `number` | avoid `type="number"` for codes, card numbers and IDs |
| Date | native `date`, or a date picker from the registry | always allow typing; store ISO 8601 |
| Search | `search` | `enterKeyHint="search"` |

- Visible labels always; hints under the label before errors happen; `(optional)` on optional fields.
- Group related fields with `<fieldset>` + `<legend>` (radio groups, addresses).
- Use `<select>` / combobox for long known lists, radios for 2–5 options, a checkbox for a single yes/no.
- Font size ≥ 16 px on inputs so iOS doesn't zoom on focus (`pwa-mobile`).

## 4. Errors

- **Inline error** under each invalid field, linked via `aria-describedby`, with `aria-invalid="true"`.
- **After submit:** move focus to the first invalid field — or, for long forms, to an error summary at the top with links to each field.
- **Keep every value** the user typed (server actions return `values`; never reset the form on error). Passwords may be cleared.
- **Server errors** that belong to a field (`email already registered`, `coupon expired`) are shown at that field; general errors in a `role="alert"` region near the submit button.
- **Timing:** validate on blur and on submit; after the first submit, re-validate on change so errors disappear as soon as they are fixed.
- Accessibility rules: `a11y-auditor` section 5.

## 5. Submitting

- The submit button is disabled with a progress label while pending (`isPending`) — no double submissions.
- The server is idempotent for side effects that must not happen twice (payments, orders): an idempotency key per form instance (`api-design`).
- After success: redirect to a result page (POST → redirect → GET), so reload doesn't resubmit, and confirm what happened (`ux-laws` Peak-End).
- Long forms autosave a draft (local draft per user, or a server-side draft); leaving with unsaved changes asks for confirmation.

## 6. Spam and abuse

Layer cheap defenses before adding friction for people:

1. **Rate limits** per IP and per account (`backend-security-auditor` G1).
2. **Honeypot field** (section 2) — bots fill it, people don't see it.
3. **Timing check** — a signed timestamp in a hidden field; submissions faster than a few seconds are suspicious.
4. **Content checks** — links in fields that shouldn't have links, known spam patterns.
5. **Invisible challenge** (e.g. Cloudflare Turnstile) only if spam continues — verify the token on the server:

```ts
// lib/spam.ts
export async function verifyTurnstile(token: string | null, remoteIp?: string) {
  if (!token) return false;
  const res = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body: new URLSearchParams({ secret: process.env.TURNSTILE_SECRET_KEY!, response: token, ...(remoteIp ? { remoteip: remoteIp } : {}) }),
    signal: AbortSignal.timeout(5000),
  });
  const data = (await res.json()) as { success: boolean };
  return data.success === true;
}
```

- Puzzle CAPTCHAs are a last resort: they fail accessibility (`a11y-auditor` 3.3.8) and conversion.
- Challenge scripts are third parties — CSP and consent rules apply (`frontend-security`, `gdpr-privacy`).

## 7. Multi-step forms

- Show the steps and progress ("Step 2 of 3") and allow going back without losing data (`ux-laws` Goal-Gradient).
- Validate each step with its slice of the schema (`ContactSchema.pick({...})`) and the whole schema on final submit.
- Keep the state in the URL (step) and in a draft (values), so refresh and back button work.
- Summarize everything before the final submit, with "Edit" links to each step.

## 8. File uploads

- Show accepted types and the maximum size **before** the user picks a file (`accept` attribute plus text).
- Drag and drop **and** a regular button (keyboard and touch).
- Show the file name, size, a progress bar and a way to remove or replace it; allow retry on failure.
- Large files upload **directly to object storage** with a short-lived presigned URL; the server issues the URL after checking permissions and limits, then validates the stored file (magic bytes, size, re-encoding) before using it (`backend-security-auditor` C3).
- Never trust the client's MIME type or file name.

## Checklist

- [ ] Only necessary fields; one shared schema; the server validates again.
- [ ] Correct input types, `autocomplete`, `inputMode`; visible labels and hints.
- [ ] Inline errors linked to fields, focus to the first error, values kept after errors.
- [ ] Submit disabled while pending; side effects idempotent; POST → redirect → GET.
- [ ] Works without JavaScript where feasible (server actions).
- [ ] Spam: rate limit, honeypot, timing; challenge only if needed, verified on the server.
- [ ] Multi-step: progress, back without data loss, summary.
- [ ] Uploads: limits shown up front, progress, direct-to-storage with server-side validation.
- [ ] Covered by the `webapp-testing` form matrix and an axe scan.

## Output format

```markdown
## Form review: app/contact

| # | Finding | File:line | Fix |
|---|---------|-----------|-----|
| 1 | Form resets after a server error | contact-form.tsx:40 | return `values` from the action, use `defaultValue` |
| 2 | Email input is `type="text"` without `autoComplete` | contact-form.tsx:22 | `type="email" autoComplete="email" inputMode="email"` |
| 3 | No spam protection, 300 bot messages/day | actions.ts:12 | honeypot + timing + rate limit |
```

## Related skills

- `ux-writing-en` / `ux-writing-cs` / `ux-writing-de` / `ux-writing-uk` (labels, hints, errors), `ux-laws` (Hick, Miller, Postel, Feedback), `a11y-auditor` (form accessibility), `shadcn-ui` (field components), `backend-security-auditor` (validation, mass assignment, uploads), `webapp-testing` (form matrix), `auth-flows` (sign-in and sign-up forms).
