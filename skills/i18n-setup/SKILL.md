---
name: i18n-setup
description: "Technical internationalization (i18n) and localization setup for web apps — Next.js App Router with next-intl first, with equivalents for other stacks: locale routing and URL strategy, locale detection without forced redirects, message files and keys, ICU plurals and select, no string concatenation, date/number/currency formatting and time zones, a language switcher, localized metadata and hreflang, validation and API error messages, emails, RTL, type-safe keys, a CI check for missing translations, pseudo-localization and tests. Use whenever you add a second language, set up or change routing per locale, add translatable UI, build a language switcher, or the user asks about i18n, localization, translations, next-intl or multilingual sites."
triggers:
  - "add a second language / make the app multilingual"
  - "i18n / l10n / localization / translations"
  - "next-intl / react-i18next / vue-i18n / Paraglide"
  - "language switcher / /en and /cs routes / localized URLs"
  - "missing translations / message files / plural forms"
  - "date, number and currency formatting per locale"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# i18n setup — multilingual web apps

This skill covers the **infrastructure**: how locales reach the URL, where strings live,
how they are formatted and how missing translations are caught. **How the text itself is
written** belongs to the language skills — `ux-writing-en` / `ux-writing-cs` and
`deslop-en` / `deslop-cs`.

## Process

1. **Decide the basics** (section 1): locales, default locale, URL strategy, localized slugs or not.
2. **Set up routing and loading** of messages (sections 2–3).
3. **Move every user-facing string** into message files with ICU syntax (sections 4–5).
4. **Format** dates, numbers and currencies through `Intl` (section 6).
5. **Cover the edges:** switcher, metadata, validation and API errors, emails, RTL (sections 7–10).
6. **Add the safety net:** type-safe keys, CI key check, pseudo-locale, locale tests (section 11).

---

## 1. Decisions first

| Decision | Recommended default | Notes |
|----------|---------------------|-------|
| Locale codes | language only (`en`, `cs`, `de`) | add a region (`en-GB`, `pt-BR`) only when content really differs |
| URL strategy | path prefix `/en/…`, `/cs/…` | one URL per language — required for SEO and sharing |
| Default locale prefix | `always` or `as-needed` | `as-needed` keeps `/pricing` for the default locale |
| Localized slugs | only for marketing pages | `/en/pricing` ↔ `/cs/cenik`; app routes can share slugs |
| Locale detection | `Accept-Language` + remembered choice (cookie) | suggest, don't force; never redirect by IP |
| Source locale | one (usually `en`) | the reference for keys; other locales must match it |

- **Language ≠ region ≠ currency.** An English UI in Czechia still shows prices in CZK. Keep the user's language, region (formats) and currency as separate settings when the product needs it.
- Don't put the language only in a cookie or `localStorage` with one URL for all languages — search engines and shared links then see a random language.

## 2. Routing and loading (Next.js App Router + next-intl)

```
messages/
  en.json
  cs.json
src/
  i18n/
    routing.ts        # locales, default locale, pathnames
    navigation.ts     # locale-aware Link, redirect, useRouter, usePathname
    request.ts        # loads messages per request
  proxy.ts            # locale negotiation (middleware.ts in Next.js 15)
  app/
    [locale]/
      layout.tsx
      page.tsx
```

```ts
// src/i18n/routing.ts
import { defineRouting } from "next-intl/routing";

export const routing = defineRouting({
  locales: ["en", "cs", "de"],
  defaultLocale: "en",
  localePrefix: "as-needed",
  // Optional localized slugs for public pages:
  pathnames: {
    "/": "/",
    "/pricing": { en: "/pricing", cs: "/cenik", de: "/preise" },
  },
});
```

```ts
// src/i18n/navigation.ts
import { createNavigation } from "next-intl/navigation";
import { routing } from "./routing";

export const { Link, redirect, usePathname, useRouter, getPathname } = createNavigation(routing);
```

```ts
// src/i18n/request.ts
import { hasLocale } from "next-intl";
import { getRequestConfig } from "next-intl/server";
import { routing } from "./routing";

export default getRequestConfig(async ({ requestLocale }) => {
  const requested = await requestLocale;
  const locale = hasLocale(routing.locales, requested) ? requested : routing.defaultLocale;
  return {
    locale,
    messages: (await import(`../../messages/${locale}.json`)).default,
    timeZone: "UTC", // a fixed server time zone avoids hydration mismatches; see section 6
  };
});
```

```ts
// src/proxy.ts  (Next.js 15: src/middleware.ts with the same content)
import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";

export default createMiddleware(routing);

export const config = {
  // Everything except API routes, Next.js internals and files with an extension
  matcher: "/((?!api|trpc|_next|_vercel|.*\\..*).*)",
};
```

```ts
// next.config.ts
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin();

export default withNextIntl({});
```

```tsx
// src/app/[locale]/layout.tsx
import { NextIntlClientProvider, hasLocale } from "next-intl";
import { setRequestLocale } from "next-intl/server";
import { notFound } from "next/navigation";
import { routing } from "@/i18n/routing";

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!hasLocale(routing.locales, locale)) notFound();
  setRequestLocale(locale); // enables static rendering

  return (
    <html lang={locale} dir={locale === "ar" || locale === "he" ? "rtl" : "ltr"}>
      <body>
        <NextIntlClientProvider>{children}</NextIntlClientProvider>
      </body>
    </html>
  );
}
```

- Every page and layout under `[locale]` that should render statically calls `setRequestLocale(locale)`.
- Use the `Link`, `redirect` and `useRouter` from `@/i18n/navigation`, never the ones from `next/link` / `next/navigation`, so links keep the locale and localized slugs.
- API routes and webhooks stay outside `[locale]` and outside the proxy matcher.

## 3. Using translations

```tsx
// Server Component
import { getTranslations, setRequestLocale } from "next-intl/server";

export default async function PricingPage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  setRequestLocale(locale);
  const t = await getTranslations("Pricing");
  return <h1>{t("title")}</h1>;
}
```

```tsx
// Client Component
"use client";
import { useTranslations } from "next-intl";

export function ProjectCounter({ count }: { count: number }) {
  const t = useTranslations("Projects");
  return <p>{t("count", { count })}</p>;
}
```

```tsx
// Rich text: markup stays in the component, words stay in the message
t.rich("terms", {
  link: (chunks) => <Link href="/terms">{chunks}</Link>,
});
// en.json: "terms": "By continuing you agree to the <link>terms of service</link>."
```

- In large apps, don't send every message to the client: pass a subset to `NextIntlClientProvider` (`messages={pick(messages, ["Projects", "Common"])}`) or keep translations in Server Components.

## 4. Message files and keys

```json
// messages/en.json
{
  "Common": {
    "save": "Save changes",
    "cancel": "Cancel"
  },
  "Projects": {
    "title": "Projects",
    "count": "{count, plural, =0 {No projects} one {# project} other {# projects}}",
    "deleteConfirm": "Delete {name}? Its {tasks, plural, one {# task} other {# tasks}} will be deleted too."
  }
}
```

```json
// messages/cs.json
{
  "Common": {
    "save": "Uložit změny",
    "cancel": "Zrušit"
  },
  "Projects": {
    "title": "Projekty",
    "count": "{count, plural, =0 {Žádné projekty} one {# projekt} few {# projekty} many {# projektu} other {# projektů}}",
    "deleteConfirm": "Smazat projekt {name}? Smažeme i {tasks, plural, one {# úkol} few {# úkoly} many {# úkolu} other {# úkolů}} v něm."
  }
}
```

- **Namespaces by feature or screen** (`Projects`, `Billing`, `Common`), keys by meaning (`deleteConfirm`), never the English sentence as the key.
- **No hard-coded user-facing strings** in components, including `aria-label`, `alt`, `title`, placeholders, toasts and error messages. Optionally enforce it with `eslint-plugin-i18next` (`no-literal-string`).
- **Named placeholders** (`{name}`, `{count}`), never positional ones.
- **One message per sentence.** Never assemble a sentence from several keys or concatenate translated parts.
- **Context for translators:** keep a short description for ambiguous keys (a `_description` sibling or the TMS comment field) — "Save" as a verb or a noun?

## 5. ICU MessageFormat

- **Plurals** use the target language's categories from `Intl.PluralRules`: English has `one` / `other`, Czech `one` / `few` / `many` / `other`, Arabic six. Put the whole phrase — including verbs that agree with the number — into each branch. Czech details: `ux-writing-cs`.
- **Select** for grammatical variants:

  ```
  {role, select, admin {Admin} member {Member} other {Guest}}
  ```

- **Exact matches** (`=0`) for special cases like "No projects".
- **Escape** literal braces and apostrophes according to ICU rules (`'{'`), and validate messages in CI (section 11).

## 6. Dates, numbers, currencies and time zones

```tsx
"use client";
import { useFormatter, useNow } from "next-intl";

export function InvoiceMeta({ issuedAt, amount }: { issuedAt: Date; amount: number }) {
  const format = useFormatter();
  const now = useNow({ updateInterval: 60_000 });
  return (
    <p>
      {format.number(amount, { style: "currency", currency: "EUR" })} ·{" "}
      {format.dateTime(issuedAt, { dateStyle: "medium" })} ·{" "}
      {format.relativeTime(issuedAt, now)}
    </p>
  );
}
```

- **Never hard-code formats** (`MM/DD/YYYY`, `1,234.56`, `$`). Use `Intl.DateTimeFormat`, `Intl.NumberFormat`, `Intl.RelativeTimeFormat`, `Intl.ListFormat` (or the library's formatter).
- **Currency comes from the data or the market**, not from the UI language.
- **Store timestamps in UTC**, format in the user's time zone. Server-rendered dates use a fixed `timeZone` (avoids hydration mismatches); show the user's local time on the client or store a time zone preference.
- **Sorting** user-visible lists with `Intl.Collator(locale)`, not the default string sort.
- **Units** with `Intl.NumberFormat(locale, { style: "unit", unit: "megabyte" })`.

## 7. Language switcher

```tsx
"use client";
import { useLocale, useTranslations } from "next-intl";
import { usePathname, useRouter } from "@/i18n/navigation";
import { routing } from "@/i18n/routing";

// Language names in their own language — users look for "Deutsch", not "German"
const LANGUAGE_NAMES: Record<string, string> = { en: "English", cs: "Čeština", de: "Deutsch" };

export function LanguageSwitcher() {
  const t = useTranslations("Common");
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();

  return (
    <select
      aria-label={t("language")}
      value={locale}
      onChange={(event) => router.replace(pathname, { locale: event.target.value })}
    >
      {routing.locales.map((code) => (
        <option key={code} value={code} lang={code}>
          {LANGUAGE_NAMES[code]}
        </option>
      ))}
    </select>
  );
}
```

- In a real project build it from the registry (`shadcn-ui`: `select` or `dropdown-menu`).
- **No flags** — flags are countries, not languages (Spanish, English, Portuguese span many countries).
- The switcher keeps the current page; with localized slugs and dynamic segments pass `{ pathname, params }` to `router.replace`.
- The chosen language is remembered (next-intl sets the `NEXT_LOCALE` cookie) and wins over `Accept-Language` next time.

## 8. Metadata and SEO per locale

```tsx
// src/app/[locale]/pricing/page.tsx
import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { getPathname } from "@/i18n/navigation";
import { routing } from "@/i18n/routing";

export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "Pricing.meta" });
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, getPathname({ locale: l, href: "/pricing" })]),
  );
  return {
    title: t("title"),
    description: t("description"),
    alternates: {
      canonical: getPathname({ locale, href: "/pricing" }),
      languages: { ...languages, "x-default": getPathname({ locale: routing.defaultLocale, href: "/pricing" }) },
    },
  };
}
```

- `<html lang>` matches the page language. `hreflang`, `x-default`, canonicals and the multilingual sitemap follow `seo-metadata` section 6 — the code above only computes the localized URLs.
- OG images and social texts are localized too.

## 9. Validation, API errors and server messages

- **APIs return codes, the UI translates them.** An API responds `{ "error": "project_name_taken" }`; the client shows `t("errors.project_name_taken")`. Don't send English sentences from the server to a Czech UI.
- **Validation messages are translation keys.** Define schema messages as keys (`"validation.nameTooShort"`) and translate where they are shown, or set a localized error map for the validation library per request.
- **Server-rendered errors** (`not-found.tsx`, `error.tsx`, global error pages) are inside `[locale]` or read the locale explicitly.

## 10. Beyond the UI

- **Emails, push notifications, SMS, PDFs, invoices** are rendered in the **recipient's** stored locale, not the locale of whoever triggered them. Store `locale` on the user.
- **User-generated content** is not translated automatically; mark its language (`lang` attribute) when known.
- **RTL languages** (Arabic, Hebrew): `dir="rtl"` on `<html>`, and use logical CSS properties everywhere — Tailwind `ms-*` / `me-*`, `ps-*` / `pe-*`, `start-*` / `end-*`, `text-start` instead of `ml-*`, `pl-*`, `left-*`, `text-left`. Mirror directional icons (arrows), not logos.
- **Images with text** need a version per locale — better: no text in images.
- **Search** and **sorting** in the database use a collation that fits the language.

## 11. Safety net

**Type-safe keys (next-intl):**

```ts
// global.d.ts
import type { routing } from "@/i18n/routing";
import type messages from "./messages/en.json";

declare module "next-intl" {
  interface AppConfig {
    Locale: (typeof routing.locales)[number];
    Messages: typeof messages;
  }
}
```

**Missing and extra keys in CI** (no dependencies):

```js
// scripts/check-messages.mjs — run with: node scripts/check-messages.mjs
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const DIR = "messages";
const SOURCE = "en.json";

const flatten = (object, prefix = "") =>
  Object.entries(object).flatMap(([key, value]) =>
    value && typeof value === "object" ? flatten(value, `${prefix}${key}.`) : [`${prefix}${key}`],
  );
const keysOf = (file) => new Set(flatten(JSON.parse(readFileSync(join(DIR, file), "utf8"))));

const source = keysOf(SOURCE);
let failed = false;

for (const file of readdirSync(DIR).filter((name) => name.endsWith(".json") && name !== SOURCE)) {
  const keys = keysOf(file);
  const missing = [...source].filter((key) => !keys.has(key));
  const extra = [...keys].filter((key) => !source.has(key));
  if (missing.length > 0 || extra.length > 0) {
    failed = true;
    console.error(`${file}: ${missing.length} missing, ${extra.length} extra`);
    for (const key of missing) console.error(`  - missing ${key}`);
    for (const key of extra) console.error(`  + extra   ${key}`);
  }
}

process.exit(failed ? 1 : 0);
```

```json
// package.json
{ "scripts": { "i18n:check": "node scripts/check-messages.mjs" } }
```

**Missing translations at runtime:** in development, fail loudly; in production, fall back to the default locale and report it (next-intl `onError` and `getMessageFallback` in `request.ts`). Never show raw keys like `Projects.count` to users.

**Pseudo-localization:** generate a test locale with longer, accented strings (`"Save changes"` → `"[Šåvé çhåñĝéš ·····]"`) to find hard-coded text and layouts that break with 30–40 % longer strings.

**Tests per locale** (Playwright, see `webapp-testing`):

```ts
import { test, expect } from "@playwright/test";

for (const locale of ["en", "cs", "de"]) {
  test(`pricing page renders in ${locale}`, async ({ page }) => {
    await page.goto(locale === "en" ? "/pricing" : `/${locale}/pricing`);
    await expect(page.locator("html")).toHaveAttribute("lang", locale);
    // No untranslated keys leaked into the page
    await expect(page.getByText(/^[A-Z][A-Za-z]+\.[a-zA-Z.]+$/)).toHaveCount(0);
  });
}
```

---

## Other stacks

| Stack | Library | Notes |
|-------|---------|-------|
| React (SPA, Vite) | `react-i18next` + `i18next-icu` | lazy-load namespaces with `i18next-http-backend`; locale in the URL via the router |
| Next.js Pages Router | `next-intl` (Pages Router mode) or built-in `i18n` config | the built-in `i18n` key exists only in the Pages Router |
| Vue / Nuxt | `vue-i18n` / `@nuxtjs/i18n` | Nuxt module handles prefixes, hreflang and detection |
| SvelteKit | Paraglide JS | compiled, tree-shaken messages |
| Astro | built-in `i18n` routing | `astro:i18n` helpers for localized URLs |
| Remix / React Router | `remix-i18next` | detection on the server, locale in the URL |

The rules in sections 1 and 4–11 apply to all of them.

## Checklist

- [ ] Locales, default locale and URL strategy are decided and documented; one URL per language.
- [ ] Locale detection suggests and remembers; no forced redirects by IP.
- [ ] No hard-coded user-facing strings (including `aria-label`, `alt`, toasts, errors).
- [ ] Messages use ICU with named placeholders; plurals have every category the language needs; no concatenation.
- [ ] Dates, numbers, currencies and sorting go through `Intl` / the library formatter; timestamps stored in UTC.
- [ ] The language switcher shows native language names, keeps the current page and has no flags.
- [ ] `<html lang>` (and `dir`) are set; metadata and OG images are per locale; hreflang and the sitemap follow `seo-metadata`.
- [ ] APIs return error codes; validation messages are translated in the UI.
- [ ] Emails and notifications use the recipient's stored locale.
- [ ] Logical CSS properties are used (RTL-ready).
- [ ] Type-safe keys, `i18n:check` in CI and tests per locale are in place.

## Output format

```markdown
## i18n review: src/app

| # | Area | Finding | File:line | Fix |
|---|------|---------|-----------|-----|
| 1 | Hard-coded string | "Delete project" in a button | components/project-menu.tsx:41 | `t("Projects.delete")` in en/cs/de |
| 2 | Plurals | `count === 1 ? "task" : "tasks"` | components/task-count.tsx:8 | ICU plural with all Czech categories |
| 3 | Formatting | `toLocaleDateString("en-US")` hard-coded | lib/format.ts:12 | `format.dateTime(date, { dateStyle: "medium" })` |
| 4 | Keys | cs.json: 3 missing, 1 extra | messages/cs.json | run `npm run i18n:check`, translate with `ux-writing-cs` |

**Locales:** en (source), cs, de · **URL strategy:** as-needed prefix, localized slugs for marketing pages
```

## Related skills

- `ux-writing-en` / `ux-writing-cs` — how to write the strings in each language; `deslop-en` / `deslop-cs` — the editing pass.
- `seo-metadata` — hreflang, canonical URLs and localized metadata in depth.
- `webapp-testing` — Playwright tests per locale.
- `shadcn-ui` — the switcher built from registry components.
- `gdpr-privacy` — consent and privacy texts must exist in every supported language.
