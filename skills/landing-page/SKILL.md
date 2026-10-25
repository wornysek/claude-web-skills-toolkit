---
name: landing-page
description: "Planning and building landing pages and marketing pages that convert: one goal per page, page structure by visitor intent (hero, proof, problem and solution, benefits, how it works, pricing, objections and FAQ, final call to action), above-the-fold rules, trust and proof without fabrication, lead capture, measuring conversions with consent, UTM handling, and A/B testing done right (hypothesis, primary metric, sample size, no peeking, no flicker, consent). Use whenever you create or redesign a landing page, home page, product or feature page, pricing page or campaign page, or the user asks about conversion rate or A/B tests. For the copy use ux-writing-en / ux-writing-cs; for visual design use frontend-design-guide; for animations use magic-animations."
triggers:
  - "landing page / home page / campaign page"
  - "product page / feature page / pricing page"
  - "conversion rate / CRO / more sign-ups"
  - "A/B test / split test / experiment"
  - "hero section / call to action / social proof"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Landing pages

A landing page has one job: move a specific visitor to one action. Everything on it either
helps that action or competes with it. This skill covers the **structure, measurement and
experiments**; the words come from `ux-writing-*`, the look from `frontend-design-guide`.

## Process

1. **Define the page:** audience, where they come from (ad, search, email, social), the one primary action and its success metric.
2. **Outline the sections** by what this visitor needs to believe before acting (section 2).
3. **Write the copy** (`ux-writing-en` / `ux-writing-cs`, then `deslop-*`) and design it: a pattern and components per section from `component-registries`, tokens from `frontend-design-guide`, primitives from `shadcn-ui`, motion rules from `magic-animations`, the design loop from `impeccable-workflow`.
4. **Build it fast and accessible** (`web-performance`, `a11y-auditor`), with metadata (`seo-metadata`).
5. **Measure** the primary conversion with consent (section 5); **experiment** only with a hypothesis (section 6).

---

## 1. One goal

- **One primary call to action** per page ("Start free trial", "Book a demo", "Buy now"), repeated at natural decision points; secondary actions are visually quieter (`ux-laws` Hick, Von Restorff).
- **Message match:** the headline continues the promise of the ad, email or search result that brought the visitor.
- Campaign pages may drop the full navigation to remove distractions; keep the logo link and the footer with legal links.

## 2. Structure

Not every page needs every section — pick by how much convincing the visitor needs. How each section looks (pattern, components) is chosen with `component-registries`.

| # | Section | Purpose | Notes |
|---|---------|---------|-------|
| 1 | **Hero** | what it is, for whom, the main outcome, the CTA | headline ≤ 10 words, subheadline ≤ 25, a real product visual |
| 2 | **Proof bar** | "others like me use it" | real customer logos (with permission), real numbers |
| 3 | **Problem → solution** | show you understand the visitor's situation | concrete, in their words |
| 4 | **Benefits** | outcomes, not feature names | 3–6, each with a short explanation and visual |
| 5 | **How it works** | reduce perceived effort | 3 steps, honest about setup time |
| 6 | **Detail / features** | for evaluators who need specifics | screenshots, comparisons, integrations |
| 7 | **Testimonials / case studies** | trust | name, role, company, photo — with permission |
| 8 | **Pricing** (or a link) | remove the biggest unknown | clear plans, what's included, VAT handling (`ecommerce`) |
| 9 | **FAQ / objections** | answer the reasons people don't act | from real sales and support questions |
| 10 | **Final CTA** | the decision point at the end | repeat the primary action with a reassurance line |
| 11 | **Footer** | trust and legal | contact, legal pages, accessibility statement |

**Above the fold** (first screen on a common mobile and desktop size): headline, subheadline, primary CTA and a hint of the product. Not everything — but enough to know what this is.

## 3. Trust and proof — real only

- **Never invent** testimonials, logos, user counts, ratings, "as seen in" badges or urgency ("only 2 left", countdown timers that reset). It is deceptive and in the EU often illegal (unfair commercial practices).
- Use `[TODO: real metric]` placeholders until real data exists (`ux-writing-*`).
- Security and compliance badges only for certifications you actually hold.
- Show the people and the company behind the product: contact, address, team — especially for paid products.

## 4. Lead capture

- Ask for the minimum (often just email); every extra field costs conversions (`forms`).
- Say what happens next ("We'll email you the guide", "A specialist replies within one working day" — if true).
- Marketing consent is a separate, unchecked option (`gdpr-privacy`); the form is protected against spam (`forms` section 6).
- The thank-you page continues the journey (next step, resource, calendar link), and is `noindex`.

## 5. Measuring

- Define the **primary conversion event** (e.g. `signup_completed`) and a few supporting events (`cta_clicked`, `pricing_viewed`); track them consistently across pages.
- **Consent first:** analytics and ad pixels load only after opt-in (`gdpr-privacy`); prefer privacy-friendly analytics; server-side conversion tracking still needs a legal basis.
- **UTM parameters** are read on landing, stored with the session or lead (first-touch and last-touch), and stripped from canonical URLs (`seo-metadata`).
- Watch speed: every 100 ms of LCP on landing pages matters (`web-performance`).

## 6. A/B testing

- **Start with a hypothesis:** "Showing the price on the hero will increase trial starts for visitors from search, because pricing is the top question in support." One change per test where possible.
- **One primary metric** decided before the test (e.g. trial starts per visitor), plus guardrail metrics (refunds, support tickets).
- **Sample size before starting:** estimate it from the baseline conversion rate and the smallest effect worth detecting; low-traffic pages can't detect small effects — make bigger changes or don't test.
- **Run full weeks** (weekday/weekend differences) and **don't stop when it looks good** (peeking inflates false positives) — or use a method designed for continuous monitoring (sequential testing).
- **No flicker:** assign the variant on the server or at the edge (cookie) and render the right variant directly, instead of swapping content in the browser.
- **Consent:** experiment cookies and identifiers usually need consent in the EU; without consent, show the default variant `[LEGAL: check]`.
- Document every test (hypothesis, dates, traffic, result, decision) so learnings survive.

## 7. Technical quality

- Meets the landing-page LCP target and budgets in `web-performance`; hero image prioritized; no heavy third-party scripts above the fold.
- Accessible: headings in order, contrast, keyboard, reduced motion for animated sections (`a11y-auditor`).
- Metadata and social image per page (`seo-metadata`); campaign variants that shouldn't rank are `noindex`.
- Responsive and touch-friendly CTAs (`pwa-mobile`).

## Checklist

- [ ] Audience, source, one primary action and its metric are written down.
- [ ] The headline matches the promise that brought the visitor.
- [ ] Sections chosen by intent; the first screen says what it is, for whom, and how to start.
- [ ] Proof is real and permitted; no fake urgency.
- [ ] Lead forms minimal, consent separate, spam-protected, thank-you page with a next step.
- [ ] Conversion events tracked after consent; UTMs stored; canonical URLs clean.
- [ ] Experiments with a hypothesis, primary metric, sample size, full weeks, server-side assignment.
- [ ] Fast, accessible and with correct metadata.

## Output format

```markdown
## Landing page review: /campaign/freelancers

**Goal:** trial starts from paid social · **Current conversion:** 1.8 % · **Target:** 2.5 %

| # | Section | Finding | Change | Expected effect |
|---|---------|---------|--------|-----------------|
| 1 | Hero | Headline "The future of invoicing" doesn't match the ad ("Get paid 2× faster") | reuse the ad's promise, add product screenshot | higher message match |
| 2 | Proof | "10,000+ happy users" without a source | real count from the DB or remove `[TODO: real metric]` | trust, compliance |
| 3 | Form | 6 fields for a trial | email only, rest during onboarding | fewer drop-offs |
| 4 | Tracking | Pixel fires before consent | load after opt-in | compliance |
```

## Related skills

- `ux-writing-en` / `ux-writing-cs`, `deslop-*` (copy), `frontend-design-guide`, `shadcn-ui`, `magic-animations` (design), `ux-laws` (Hick, Von Restorff, Serial Position), `forms` (lead capture), `gdpr-privacy` (consent for analytics and experiments), `seo-metadata`, `web-performance`, `a11y-auditor`, `ecommerce` (pricing and legal).
