---
name: ux-laws
description: "Audits and designs UI according to 20 UX laws (Hick, Fitts, Jakob, Miller, Doherty, Gestalt, Peak-End, Tesler, Postel and more). Use whenever you design, generate or review a page, form, navigation, onboarding, dashboard or any UI component, and when the user asks for a UX review or for better usability, conversion or accessibility."
triggers:
  - "design a UI / page / screen"
  - "UX review / UX audit"
  - "improve usability / conversion"
  - "form, sign-up, onboarding, checkout, booking"
  - "navigation, menu, dashboard, landing page"
  - "why don't users finish ..."
  - "review my UI / improve UX / usability"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  inspired-by: "Laws of UX — Jon Yablonski (lawsofux.com)"
---

# UX Laws — 20 usability laws as hard rules

This skill turns psychological UX principles into **verifiable checks**. They are not
"for inspiration" recommendations — every UI you generate or modify must pass all
relevant *Implementation Checks*. If you deliberately break a check, you must say so
explicitly in your response and justify it.

## When to use this skill

- When **generating** a new page, component or flow (apply the rules while designing).
- When **reviewing** existing UI (go through the checks and list the findings).
- When **refactoring** forms, navigation and onboarding.
- Whenever the user is dealing with low conversion, abandoned forms or complaints about confusion.

## Process

1. **Identify the context:** What is the primary goal of the screen? Who is the user? Which device (mobile/desktop)?
2. **Pick the relevant laws:** Form → Hick, Miller, Postel, Tesler, Recognition, Goal-Gradient, Feedback.
   Navigation → Jakob, Hick, Serial Position, Fitts. Landing page → Aesthetic-Usability, Visual Hierarchy, Von Restorff, Occam.
3. **Go through the Implementation Checks** of each selected law against the actual code (JSX/HTML/CSS/Tailwind classes).
4. **Fix the findings** directly in the code, not just in a comment.
5. **Output a report** in the format given at the end of this file.

---

## 1. Aesthetic-Usability Effect

**Principle:** Users perceive an aesthetically polished interface as easier to use and
tolerate minor flaws in it. Aesthetics, however, does **not fix** poor usability —
it only masks it during testing.

**Implementation Check:**
- [ ] Consistent spacing scale (Tailwind 4px step: `1, 2, 3, 4, 6, 8, 12, 16`), no random values like `mt-[13px]`.
- [ ] At most 2 font families (text + display/mono), one type scale.
- [ ] Visual quality is not judged "by eye" but by a task: can the user complete the primary action without help?
- [ ] Grid alignment — all elements in a section share the same left guide.

**Anti-pattern:** A beautiful form that wipes all filled-in fields after an error.

---

## 2. Hick's Law

**Principle:** Decision time grows with the number and complexity of choices. Reduce the
choices to what is actually needed at the given step.

**Implementation Check:**
- [ ] The screen has **exactly one** primary action (`variant="default"`), the others are secondary (`outline`, `ghost`, `link`).
- [ ] The main navigation has at most 5–7 top-level items; the rest goes under "More" or into secondary navigation.
- [ ] A `<select>` with more than ~10 options is replaced by a searchable combobox (shadcn `Command` + `Popover`).
- [ ] The recommended choice is preselected or visually highlighted (e.g. "Recommended" on a pricing plan).
- [ ] Complex decisions are split into steps (wizard) instead of one screen with 20 toggles.

**Anti-pattern:** A dashboard with 4 equally prominent buttons "Save", "Publish", "Export", "Share".

---

## 3. Fitts's Law

**Principle:** The time needed to hit a target depends on its size and distance.
Important and frequent targets must be large and close to where the attention/cursor/thumb is.

**Implementation Check:**
- [ ] Touch targets are at least **44×44 px** (`min-h-11 min-w-11`); the absolute minimum per WCAG 2.5.8 is 24×24 px.
- [ ] There is at least 8 px (`gap-2`) between adjacent clickable elements to prevent misclicks.
- [ ] On mobile, the primary CTA is within thumb reach (lower half of the screen, or a sticky bottom bar).
- [ ] The whole row/card is clickable, not just a small link text inside it.
- [ ] `<label>` is connected to its input (`htmlFor`/`id`), so clicking the label focuses the field and enlarges the target area of a checkbox.
- [ ] Destructive actions (Delete) are **not** right next to frequent actions (Save) — distance protects against mistakes.

**Anti-pattern:** A 16×16 px icon button with no padding for closing a modal.

---

## 4. Jakob's Law

**Principle:** Users spend most of their time on other sites and expect yours to work
the same way. Use established conventions; innovate in content, not in basic controls.

**Implementation Check:**
- [ ] The logo is top left and links to the home page.
- [ ] Search uses a magnifier icon (`Search` from Lucide) and responds to Enter.
- [ ] Account/profile top right, cart top right, sign-out in the profile menu.
- [ ] Links look like links (color + underline or a clear hover), buttons look like buttons.
- [ ] Native behavior is preserved: scrolling, browser back, Ctrl/Cmd+click to open in a new tab (use `<a href>`/`<Link>`, not `onClick` with `router.push` on a `<div>`).
- [ ] A form submits with the Enter key, a modal closes with the Escape key.

**Anti-pattern:** A custom scrollbar, a "hamburger" menu on desktop with 3 items, navigation hidden behind an unlabeled icon.

---

## 5. Miller's Law

**Principle:** Working memory holds roughly 7 (±2) items. This is not a limit on the number
of menu items, but a reason to **group (chunk)** information into meaningful units.

**Implementation Check:**
- [ ] Long forms are split into sections (`<fieldset>` + `<legend>`) of 3–7 fields.
- [ ] Long strings are formatted into groups: phone `+420 777 123 456`, IBAN in groups of 4 characters, codes `ABCD-1234`.
- [ ] The user does not have to remember anything between steps — a summary of previous steps is visible.
- [ ] Tables with many columns show the most important columns by default and allow adding more.

**Anti-pattern:** 25 sign-up fields in a single unstructured column.

---

## 6. Doherty Threshold — < 400 ms

**Principle:** Productivity and the feeling of smoothness rise dramatically when the system
responds within **400 ms**. Every interaction must give visual feedback immediately; if the
result takes longer, the progress must be visible.

**Implementation Check:**
- [ ] Every click/press gives visual feedback within 100 ms (`active:` state, ripple, button text change).
- [ ] Operations longer than 400 ms show a loading state (spinner in the button, content skeleton, progress bar).
- [ ] The skeleton appears only after a ~150–200 ms delay so that fast responses don't flicker.
- [ ] Optimistic UI for cheap and reversible actions (like, toggle, moving a card) with rollback on error.
- [ ] Core Web Vitals: **INP < 200 ms**, LCP < 2.5 s, CLS < 0.1 (verify with Lighthouse or the Chrome DevTools MCP).
- [ ] Heavy computation off the main thread (Web Worker) and debounced search (200–300 ms).

**Anti-pattern:** A "Submit" button that does nothing visible for 2 seconds, so the user clicks again.

---

## 7. Law of Proximity

**Principle:** Elements close to each other are perceived as related. Distance is the
strongest tool for expressing structure — stronger than lines and borders.

**Implementation Check:**
- [ ] The spacing **inside** a group is smaller than the spacing **between** groups (e.g. `space-y-2` inside, `space-y-8` between sections).
- [ ] A label is closer to its input than to the previous field (`gap-1.5` label→input, `gap-6` between fields).
- [ ] An error message sits directly below the field it belongs to, not in a summary at the top (a summary may exist in addition).
- [ ] The form's action buttons are at the end of the form, not in the opposite corner of the page.

**Anti-pattern:** Uniform `gap-4` spacing everywhere — the page looks like one undivided block.

---

## 8. Law of Similarity

**Principle:** Visually similar elements are perceived as functionally the same. Same
function = same look; different function = different look.

**Implementation Check:**
- [ ] All links in text share the same style; nothing that is not clickable looks like a link.
- [ ] States (e.g. ticket "Open", "Pending", "Closed") have consistent color coding across the whole application.
- [ ] Button variants are used according to their semantics (`destructive` only for destructive actions).
- [ ] Icons come from one set (Lucide), with the same stroke width and size within a context.

**Anti-pattern:** Bold blue text used for both headings and links.

---

## 9. Law of Common Region

**Principle:** Elements inside a clearly bounded area are perceived as a group. A border,
background or card creates a stronger bond than proximity alone.

**Implementation Check:**
- [ ] Logically related content (ticket card, forum post, settings section) sits in a `Card` or an area with a distinct background.
- [ ] Do not nest cards in cards in cards — at most 2 levels of boundaries.
- [ ] Areas have enough inner padding (`p-4` to `p-6`) so the content does not "stick" to the edge.
- [ ] The danger zone (account deletion) is in a separate, visually distinct area.

**Anti-pattern:** Every paragraph in its own box with a shadow — the boundaries lose their meaning.

---

## 10. Visual Hierarchy

**Principle:** Size, color, contrast, weight and position determine the order in which the
user reads information. The most important element must be the most prominent.

**Implementation Check:**
- [ ] Every page has exactly one `<h1>`; headings go in order without skipping levels (h1 → h2 → h3).
- [ ] The type scale has clear steps (e.g. 14 / 16 / 20 / 24 / 32 / 48 px); no two levels are nearly the same.
- [ ] "Squint test": when the screen is blurred, the primary heading and the primary CTA are still visible.
- [ ] Secondary information (metadata, date, author) is muted (`text-muted-foreground`, `text-sm`).
- [ ] F/Z reading pattern: key content top left, the CTA at the end of the reading path.

**Anti-pattern:** Everything bold, everything large, everything colorful — nothing stands out.

---

## 11. Progressive Disclosure

**Principle:** Show only what most users need first. Reveal advanced options only on
request. This reduces cognitive load without limiting experts.

**Implementation Check:**
- [ ] Advanced settings are in an `Accordion`/`Collapsible` ("Advanced options"), closed by default.
- [ ] Disclosure depth is at most 2 levels — users will not find anything deeper.
- [ ] Conditional fields appear only after the relevant choice (e.g. "Other" → text field).
- [ ] Onboarding explains features in the context of first use, not with 10 slides upfront.
- [ ] Hidden content is still reachable by keyboard and screen reader (`aria-expanded`, `aria-controls`).

**Anti-pattern:** A settings form that immediately shows options only admins ever need.

---

## 12. Recognition over Recall

**Principle:** Recognizing an option is much easier than recalling it from memory. Show
options, history and context instead of demanding them from the user.

**Implementation Check:**
- [ ] Every field has a **visible label** — a placeholder never replaces a label (it disappears once typing starts).
- [ ] Search offers suggestions, recent searches and autocomplete.
- [ ] Breadcrumb navigation (`Breadcrumb`) on pages deeper than 2 levels.
- [ ] The active navigation item is visually marked (`aria-current="page"`).
- [ ] Icons without labels only for universally known symbols (close, search); others have text or a tooltip.
- [ ] Forms show examples of the correct format ("e.g. acme-studio") as a hint below the field.

**Anti-pattern:** "Enter the category ID" instead of choosing from a list of categories.

---

## 13. Von Restorff Effect (Isolation Effect)

**Principle:** From a group of similar items, people remember best the one that stands out.
Use this for the most important thing — and only for that.

**Implementation Check:**
- [ ] **Only one** element on the screen is visually isolated (primary CTA, recommended plan).
- [ ] The distinction does not rely on color alone (WCAG 1.4.1) — add shape, icon, size, text ("Recommended").
- [ ] Notification badges are used sparingly; when they are everywhere, they stop working.
- [ ] Animation/pulsing only on truly critical elements and with respect to `prefers-reduced-motion`.

**Anti-pattern:** Five "highlighted" banners on one page.

---

## 14. Peak-End Rule

**Principle:** People judge an experience mainly by its most intense moment and by its end,
not by the average. Design the peaks and the ending of a flow deliberately.

**Implementation Check:**
- [ ] A successful completion (placing an order, creating a ticket) is followed by a **well-crafted confirmation screen**: what happened, what comes next, when, a link to the status.
- [ ] Error states are humane: they explain the problem and what to do about it, and never lose the user's data.
- [ ] The most frustrating step of the flow (waiting, payment, upload) is identified and gets extra care (progress, reassurance).
- [ ] The end of the flow offers a meaningful next step, not a dead end.

**Anti-pattern:** After placing an order, the form is simply cleared without any confirmation.

---

## 15. Goal-Gradient Effect

**Principle:** Motivation to finish a task grows as the user approaches the goal. Show
progress and give the feeling that "part of the way is already behind them".

**Implementation Check:**
- [ ] A multi-step form has a "Step 2 of 3" indicator or a progress bar with `aria-valuenow`.
- [ ] The number of steps is known upfront and does not grow along the way.
- [ ] Already completed parts count towards progress (e.g. a profile prefilled from the sign-in provider = step 1 done).
- [ ] Work in progress is saved (draft), so coming back does not start from zero.

**Anti-pattern:** A wizard with no indication of length — the user does not know whether they are near the end or at the beginning.

---

## 16. Serial Position Effect

**Principle:** People best remember the first and last items of a list (primacy and recency).
The most important choices belong at the beginning and the end.

**Implementation Check:**
- [ ] In navigation, the most important item is first and the second most important is last (e.g. "Home" … "Account").
- [ ] In a mobile bottom bar (max. 5 items), key destinations are at the edges.
- [ ] In lists of benefits/features, the strongest argument is first and the second strongest is last.
- [ ] Less important items are in the middle, never the key action.

**Anti-pattern:** "Pricing" as the fourth of eight navigation items.

---

## 17. Tesler's Law (Law of Conservation of Complexity)

**Principle:** Every system has a certain amount of irreducible complexity. The only
question is who carries it — the user or the system. Move it to the system.

**Implementation Check:**
- [ ] Sensible defaults (time zone from the browser, language from `Accept-Language`, country from locale).
- [ ] Data the system already knows (name, avatar and email from the OAuth sign-in) is prefilled and not requested again.
- [ ] Automatic input formatting (spaces in a phone number, uppercase in a code) instead of error messages.
- [ ] The system validates and explains; it does not throw an error without context.

**Anti-pattern:** The user has to type their email again, even though they just signed in with Google.

---

## 18. Postel's Law (Robustness Principle)

**Principle:** "Be liberal in what you accept and conservative in what you send."
Accept input in various reasonable formats, normalize it, and keep the output strict.

**Implementation Check:**
- [ ] Inputs are normalized before validation: `trim()`, lowercase email, spaces removed from phone/IBAN.
- [ ] A phone field accepts `+420777123456`, `777 123 456` and `777-123-456`.
- [ ] A date field accepts the local format (e.g. `10/23/2026` or `23. 10. 2026`) or offers a date picker; it is stored internally as ISO 8601.
- [ ] Pasting into fields works — no `onPaste` blocking on email or password.
- [ ] Liberal input **does not mean weak validation**: after normalization, a strict Zod schema applies on the server.

**Anti-pattern:** "Invalid phone number" because the user typed a space.

---

## 19. Occam's Razor

**Principle:** Of two solutions that meet the goal, choose the simpler one. Every element
must justify its place; whatever does not support the goal of the screen, remove it.

**Implementation Check:**
- [ ] Every element on the screen answers the question "Which user goal does it support?" — otherwise it goes.
- [ ] A form contains only the fields necessary for the given step (data minimization — from the GDPR perspective too).
- [ ] No decorative elements that compete with content (unnecessary illustrations, carousel, autoplay video).
- [ ] Components are not oversized: a tooltip on a tooltip, a modal in a modal = wrong.

**Anti-pattern:** "Fax" and "Middle name" fields in a newsletter sign-up.

---

## 20. Feedback Loops

**Principle:** Every user action must get a visible, understandable and timely response
from the system. Without feedback, the user does not know whether the action happened and repeats it.

**Implementation Check:**
- [ ] Interactive elements have all states: `hover`, `focus-visible`, `active`, `disabled`, `loading`.
- [ ] Success and failure of an asynchronous action are announced (toast via `sonner`, inline message) and made accessible to screen readers (`role="status"` / `aria-live="polite"`, errors `role="alert"`).
- [ ] Field validation runs on `blur` and after the first submit, not on every keystroke from the start.
- [ ] Destructive actions have a confirmation (`AlertDialog`) or an "Undo" option (undo toast).
- [ ] While submitting, the button is `disabled` + `aria-busy="true"` so double submission cannot happen.
- [ ] System status is visible: saved/unsaved, online/offline, number of unread items.

**Anti-pattern:** A silent `catch {}` — the action fails and the user never finds out.

---

## Output format (UX report)

When reviewing, list the findings sorted by severity:

```markdown
## UX audit: <screen name / file>

| # | Severity | Law | Finding | File:line | Fix |
|---|----------|-----|---------|-----------|-----|
| 1 | 🔴 Critical | Feedback Loops | Submit button has no loading state, double submission happens | app/signup/form.tsx:84 | `disabled={isPending}` + spinner |
| 2 | 🟠 High | Fitts | 16×16 px close icon | components/modal.tsx:22 | `size="icon"` (40×40) + `aria-label` |
| 3 | 🟡 Medium | Proximity | Same spacing inside and between sections | app/signup/form.tsx:30 | `space-y-2` inside, `space-y-8` between |

**Passed:** Hick, Jakob, Miller, Postel, ...
**Deliberate exceptions:** <law> — <justification>
```

Severity:
- 🔴 **Critical** — blocks task completion, causes data loss or violates accessibility (WCAG A/AA).
- 🟠 **High** — significantly slows down or confuses most users.
- 🟡 **Medium** — worsens the experience, but the task can be completed.
- ⚪ **Low** — cosmetic improvement.

## Behavior rules

- Never deliver UI without checking laws 3 (Fitts), 6 (Doherty), 10 (Visual Hierarchy) and 20 (Feedback Loops) — they apply to every screen.
- Fix the findings in the code; a report without a fix is only half the job.
- If a rule conflicts with the user's request (e.g. they explicitly want 3 primary buttons), fulfill the request and point out the conflict in one sentence.
- Combine with `frontend-design-guide` (visual quality), `vercel-web-guidelines` (automated audit) and `a11y-auditor` (WCAG conformance).
