---
name: a11y-auditor
description: "Accessibility audit and implementation rules for websites and web apps against WCAG 2.2 level AA and the European Accessibility Act (EAA): semantic HTML and landmarks, keyboard access and visible focus, ARIA patterns, screen reader announcements, forms and error messages, color and contrast, motion, zoom and reflow, target size, media, testing with tools and screen readers, and an accessibility statement. Use whenever you build or review pages, components, forms, dialogs, menus or custom widgets, or when the user asks about accessibility, a11y, WCAG, EAA, screen readers or keyboard navigation. For usability psychology use ux-laws; for visual style use frontend-design-guide."
triggers:
  - "accessibility / a11y / WCAG / EAA"
  - "screen reader / keyboard navigation / focus"
  - "is this component accessible?"
  - "dialog / menu / tabs / combobox / custom widget"
  - "accessibility statement / accessibility audit"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  references: "WCAG 2.2, WAI-ARIA Authoring Practices Guide, EN 301 549, Directive (EU) 2019/882"
---

# Accessibility auditor (WCAG 2.2 AA)

Accessible means usable with a keyboard, a screen reader, zoom, voice control, high
contrast and reduced motion — by people with permanent, temporary or situational
limitations. The target is **WCAG 2.2 level AA**. Automated tools find only a part of the
problems; the rest needs a keyboard and a screen reader.

**Legal context (not legal advice):** the European Accessibility Act (Directive (EU)
2019/882) applies since **28 June 2025** to many products and services sold in the EU —
including e-commerce, banking, e-books, transport ticketing and communication services.
Microenterprises providing services are exempt. The harmonized standard EN 301 549 refers
to WCAG. Public sector websites fall under the Web Accessibility Directive. Flag the
applicability as `[LEGAL: …]` when it is unclear.

## Process

1. **Automated scan** of the changed pages (axe via Playwright, see Testing) — fix everything it finds.
2. **Keyboard pass:** go through the whole flow with Tab, Shift+Tab, Enter, Space, Escape and arrow keys.
3. **Screen reader smoke test** of the key flow (sections 4–6).
4. **Zoom, reflow and contrast:** 200 % and 400 % zoom, 320 px width, forced colors, reduced motion.
5. **Fix** in the code, then **report** with WCAG success criteria (output format at the end).

---

## 1. Semantics and structure

- **Native elements first:** `<button>` for actions, `<a href>` for navigation, `<input>`, `<select>`, `<dialog>`, `<details>`. A `div` with `onClick` is never a button.
- **Landmarks:** one `<header>`, `<nav>` (with `aria-label` if there are several), `<main>`, `<footer>`; `<aside>` for complementary content.
- **Headings:** one `<h1>`, then `h2`–`h6` without skipping levels; headings describe the section.
- **Language:** `<html lang="…">`; parts in another language get their own `lang`.
- **Page titles:** unique and descriptive per page (`Invoices · Acme`) — `seo-metadata`.
- **Skip link** as the first focusable element:

```tsx
<a
  href="#main"
  className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-background focus:px-4 focus:py-2 focus:ring-2 focus:ring-ring"
>
  Skip to content
</a>
{/* … */}
<main id="main" tabIndex={-1}>…</main>
```

## 2. Keyboard and focus

- Everything interactive is reachable and operable by keyboard (SC 2.1.1) and there are no keyboard traps (2.1.2).
- **Focus order** follows the visual order (2.4.3). Never use a positive `tabIndex`.
- **Visible focus** on every interactive element (2.4.7): `focus-visible:ring-[3px] focus-visible:ring-ring`. Never `outline: none` without a replacement.
- **Focus not obscured** by sticky headers, cookie banners or chat widgets (2.4.11): add `scroll-padding-top` equal to the sticky header height.
- **Dialogs:** focus moves into the dialog, is trapped there, Escape closes it and focus returns to the trigger. Use the registry component (`shadcn-ui`) instead of building your own.
- **Route changes in SPAs:** the new page is announced. Next.js has a built-in route announcer; in custom routers move focus to the new `<h1>` or announce the title.
- **Single-key shortcuts** can be turned off or remapped (2.1.4).

## 3. ARIA — only where HTML is not enough

The first rule of ARIA: if a native element has the semantics, use it. Custom widgets
(combobox, tabs, tree, menu) follow the WAI-ARIA Authoring Practices patterns — prefer a
tested library component.

| ❌ Mistake | ✅ Fix |
|-----------|-------|
| `<div onClick>` / `<span role="button">` without key handling | `<button type="button">` |
| `aria-label` on a `div` or `span` without a role | visible text, or a real interactive element |
| `aria-hidden="true"` on something focusable | remove it from the tab order or don't hide it |
| `role="menu"` for site navigation | `<nav>` with a list of links; `menu` is for application menus |
| Redundant roles (`<button role="button">`, `<nav role="navigation">`) | delete the role |
| `aria-live` on a container that re-renders completely | a dedicated, persistent live region |

## 4. Names, labels and images

- Every interactive element has an **accessible name** that contains its visible label (2.5.3).
- **Icon-only buttons:** `aria-label="Close"` or `<span className="sr-only">Close</span>`; the icon gets `aria-hidden="true"`.
- **Images:** `alt` describes the purpose ("Chart: revenue grew 12 % in Q3"); decorative images get `alt=""`; images of text are avoided (1.4.5).
- **SVG:** decorative → `aria-hidden="true"`; meaningful → `role="img"` with `aria-label` or `<title>`.
- **Link purpose** is clear from the text or its context (2.4.4) — no "click here", no repeated "Read more" without context (`aria-label` or visually hidden text).

## 5. Forms

- Every field has a visible `<label>` connected by `htmlFor`/`id` (1.3.1, 3.3.2). Placeholders are not labels.
- **Required fields** are marked in the label and with `required` / `aria-required`.
- **Autocomplete** attributes for personal data (`name`, `email`, `tel`, `street-address`, `postal-code`, `cc-number`, `new-password`, `one-time-code`) — SC 1.3.5.
- **Errors** (3.3.1, 3.3.3): text next to the field connected by `aria-describedby`, `aria-invalid="true"`, focus moves to the first invalid field or to an error summary with links to the fields. Color alone never signals an error.
- **Redundant entry** (3.3.7): don't ask for the same information twice in one process (offer "same as billing address").
- **Accessible authentication** (3.3.8): no cognitive tests to sign in; allow paste and password managers; offer passkeys, email links or codes instead of puzzles. CAPTCHAs need an accessible alternative.
- Details for building forms: `forms`.

## 6. Dynamic content and status messages

- **Status messages** (4.1.3) are announced without moving focus: `role="status"` (polite) for success and progress, `role="alert"` for errors. The live region exists in the DOM before the message is inserted.
- **Loading:** `aria-busy="true"` on the region that loads; skeletons are hidden from screen readers or labelled once ("Loading invoices").
- **Toasts** don't disappear before they can be read; important ones stay until dismissed (2.2.1).
- **Infinite scroll** offers a "Load more" button and keeps the footer reachable.
- **Streaming text** (AI responses, live logs) is announced in chunks or at the end, not word by word.

## 7. Color and contrast

The contrast thresholds below are the toolkit's single source; other skills refer to them.

- Text **4.5 : 1**, large text (≥ 24 px, or ≥ 18.66 px bold) **3 : 1** (1.4.3).
- UI components, focus indicators and meaningful graphics **3 : 1** against adjacent colors (1.4.11).
- Never color alone (1.4.1) — add text, icons or patterns (status badges, form errors, chart series).
- Check both themes and the **forced colors** mode (Windows high contrast): use `@media (forced-colors: active)` to keep borders and focus visible; don't rely on background images for meaning.

## 8. Motion and media

- Respect `prefers-reduced-motion` (`motion-safe:` / `motion-reduce:`); parallax and auto-animations turn off.
- Nothing flashes more than 3 times per second (2.3.1).
- Moving content longer than 5 seconds can be paused (2.2.2) — carousels, marquees, background videos.
- **Video:** captions (1.2.2), audio description or a text alternative for important visual information (1.2.5); **audio:** a transcript. No autoplay with sound.

## 9. Zoom, reflow and text spacing

- Text resizes to **200 %** without loss of content (1.4.4); never `maximum-scale=1` or `user-scalable=no`.
- **Reflow** at 320 CSS px width (= 400 % zoom on 1280 px) without horizontal scrolling, except data tables and maps (1.4.10).
- **Text spacing** overrides (line height 1.5, paragraph spacing 2×, letter spacing 0.12 em, word spacing 0.16 em) don't cut off text (1.4.12) — avoid fixed heights on text containers.
- Content on hover or focus (tooltips) is dismissible with Escape, hoverable and persistent (1.4.13).

## 10. Pointer and touch

- **Target size:** at least **24 × 24 CSS px** or enough spacing around smaller targets (SC 2.5.8, AA); **44 × 44 px recommended** for primary controls on touch devices (SC 2.5.5, AAA). Other skills refer to these numbers.
- **Dragging** (sortable lists, sliders, maps) has a single-pointer alternative — buttons or inputs (2.5.7).
- Multi-finger and path gestures have simple alternatives (2.5.1); actions fire on release, not on press (2.5.2).

## 11. Tables, charts and complex content

- Data tables use `<table>`, `<th scope="col|row">` and a `<caption>`; never tables for layout.
- Charts have a text summary and an accessible data table or download.
- Maps and embeds have a text alternative for the essential information (address, directions).
- PDFs offered for download need to be tagged and accessible, or have an HTML equivalent.

## 12. Consistency and help

- Navigation and repeated components appear in the same order and are named consistently (3.2.3, 3.2.4).
- Help mechanisms (contact, chat, FAQ link) are in the same place on every page (3.2.6).
- No unexpected context changes on focus or input (3.2.1, 3.2.2) — submitting happens with an explicit button.

---

## Testing

```ts
// e2e/a11y.spec.ts — automated scan of key pages (see webapp-testing)
import AxeBuilder from "@axe-core/playwright";
import { expect, test } from "@playwright/test";

for (const path of ["/", "/pricing", "/signup", "/dashboard"]) {
  test(`no WCAG A/AA violations on ${path}`, async ({ page }) => {
    await page.goto(path);
    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
      .analyze();
    expect(results.violations).toEqual([]);
  });
}
```

- **Lint:** `eslint-plugin-jsx-a11y` (or the framework's equivalent) in CI.
- **Keyboard script** for every key flow: reach, operate and leave every control; focus always visible; logical order; Escape closes overlays.
- **Screen readers:** NVDA + Firefox or Chrome (Windows), VoiceOver + Safari (macOS, iOS), TalkBack + Chrome (Android). Check: page title and headings list, landmarks, form labels and errors, dialogs, status messages.
- **Zoom and reflow:** 200 %, 400 %, 320 px width; text spacing bookmarklet; forced colors; `prefers-reduced-motion`.
- **Runtime checks** with the `chrome-devtools` skill (accessibility tree via `take_snapshot`).

## Accessibility statement

Publish it at a stable URL (e.g. `/accessibility`) and link it from the footer:

```markdown
# Accessibility statement

We want everyone to be able to use <product>. We aim to meet WCAG 2.2 level AA.

## Conformance status
<Fully / partially / not> conformant with WCAG 2.2 AA. Last reviewed: <date>, by <method: self-assessment / external audit>.

## Known limitations
- <Feature>: <what doesn't work> — <workaround> — <planned fix and date>

## Feedback and contact
If something doesn't work for you, contact us at <email / form>. We reply within <n> working days.

## Enforcement
If you are not satisfied with our response, you can contact <the national enforcement body>.
```

## Checklist

- [ ] Native elements and landmarks; one `<h1>`, ordered headings; `lang` set; skip link.
- [ ] Every flow works with the keyboard alone; focus visible and never hidden behind sticky elements.
- [ ] Dialogs trap and return focus; route changes are announced.
- [ ] Every control has an accessible name containing its visible label; icons and images handled.
- [ ] Forms: labels, `autocomplete`, errors linked with `aria-describedby`, no cognitive tests at sign-in.
- [ ] Status messages via `role="status"` / `role="alert"`.
- [ ] Contrast 4.5 : 1 / 3 : 1 in both themes; nothing conveyed by color alone; forced colors checked.
- [ ] Reduced motion respected; nothing flashes; long motion pausable; media captioned.
- [ ] 200 % zoom and 320 px reflow without loss; no zoom blocking.
- [ ] Targets ≥ 24 px; dragging has an alternative.
- [ ] axe scan passes in CI; screen reader smoke test done; accessibility statement up to date.

## Output format

```markdown
## Accessibility audit: /signup

| # | Severity | WCAG | Finding | File:line | Fix |
|---|----------|------|---------|-----------|-----|
| 1 | 🔴 Blocker | 2.1.1 Keyboard | Plan picker is a `div` with `onClick` | components/plan-picker.tsx:18 | radio group (`RadioGroup` from the registry) |
| 2 | 🟠 Major | 3.3.1 Error identification | Errors only shown in red, not linked to fields | app/signup/form.tsx:52 | text + `aria-describedby` + `aria-invalid` |
| 3 | 🟡 Minor | 2.4.11 Focus not obscured | Sticky header covers focused fields | app/layout.tsx:9 | `scroll-padding-top: 4rem` |

**Automated:** axe 0 violations after fixes · **Manual:** keyboard ✅, NVDA + Chrome ✅, VoiceOver iOS ⚠️ (item 4 open)
```

Severity: 🔴 **Blocker** — a task can't be completed with assistive technology · 🟠 **Major** — very hard or confusing · 🟡 **Minor** — inconvenient.

## Related skills

- `ux-laws` (Fitts, Feedback Loops), `frontend-design-guide` (contrast tokens, focus styles), `shadcn-ui` (accessible primitives), `forms`, `webapp-testing` (axe in Playwright), `chrome-devtools` (accessibility tree).
