---
name: superpowers-debugging
description: "Enforces a deterministic debugging process (based on the superpowers plugin from Anthropic's official marketplace): reproduce the bug on a minimal test input, isolate the cause in the logs and stack trace, verify the hypothesis, and make a clean fix at the root cause without unnecessary try-catch wrappers, retry loops or error suppression. Use whenever you work on a bug, failing test, exception, unexpected behavior, regression, production error, or when a previous fix attempt did not work."
triggers:
  - "bug / error / doesn't work / crashes"
  - "failing test / flaky test"
  - "exception / stack trace / error in the log"
  - "regression / it used to work"
  - "fix this"
  - "the previous fix didn't work"
metadata:
  type: official-plugin
  plugin: "superpowers@claude-plugins-official"
  author: "Jesse Vincent (obra) and contributors"
  distribution: "Anthropic — official marketplace claude-plugins-official"
  source: "https://github.com/obra/superpowers"
  license: MIT
  wrapper-license: "MIT (claude-web-skills-toolkit)"
---

# Superpowers Debugging — a deterministic process

| | |
|---|---|
| **Plugin** | `superpowers@claude-plugins-official` |
| **Distribution** | Anthropic — official marketplace [`claude-plugins-official`](https://github.com/anthropics/claude-plugins-official) |
| **Plugin author** | Jesse Vincent ([obra/superpowers](https://github.com/obra/superpowers)) and contributors |
| **License** | MIT (superpowers) · this wrapper skill: MIT |
| **Type** | Official Claude Code plugin (a set of skills + a hook) |

## Installation

In Claude Code:

```text
/plugin install superpowers@claude-plugins-official
```

From the shell (same effect, usable in scripts):

```bash
claude plugin install superpowers@claude-plugins-official
```

Alternatively from the author's marketplace:

```text
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

Installation via the toolkit (together with the `frontend-design` plugin):

```bash
./install.sh --plugins
```

After installing, restart Claude Code; check the available skills with `/skills`
(e.g. `superpowers:systematic-debugging`, `superpowers:test-driven-development`,
`superpowers:verification-before-completion`).

## Configuration

To give the whole team the plugin automatically, add this to the project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "claude-code-plugins": {
      "source": {
        "source": "github",
        "repo": "anthropics/claude-code"
      }
    }
  },
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "frontend-design@claude-code-plugins": true
  }
}
```

Claude Code then offers team members to install the listed plugins when they open the project.

## Relationship to the plugin

The superpowers plugin contains a general `systematic-debugging` skill. This wrapper builds
on it and **tightens** it for the toolkit's web projects: it enforces a minimal reproduction
as a test, concrete rules for TypeScript/React/Node.js and a ban on wrapping errors.
If the plugin is installed, use both together; if not, this file applies on its own.

## The iron rule

> **No fix without a reproduction and without a found root cause.**
> A fix that "will probably help" is guessing. Guessing is forbidden.

## Process — 6 steps

### 1. Reproduce on a minimal input
- Establish the exact steps, input, environment, and expected vs. actual behavior.
- Shrink the input as long as the bug still occurs: the smallest payload, the shortest sequence of steps, a single component.
- Write the reproduction as a **failing test** (unit/integration, for UI an E2E test via `webapp-testing`):

```ts
// lib/__tests__/application-status.test.ts
import { describe, expect, it } from "vitest";
import { canEditApplication } from "@/lib/applications";

describe("canEditApplication", () => {
  it("the owner must not edit an application that has already been reviewed", () => {
    const application = { applicantId: "u1", status: "approved" as const };
    expect(canEditApplication(application, { id: "u1", role: "user" })).toBe(false);
  });
});
```

- Run the test and **verify that it fails for the right reason** (the same error as in the report). A test that fails for a different reason reproduces nothing.
- If the bug cannot be reproduced, **do not fix it** — collect data (logs, exact versions, input) and return to step 1.

### 2. Isolate the cause in the logs and stack trace
- Read the **whole** error message and stack trace, not just the first line. Find the first frame in your own code.
- Trace the data upstream: where did the wrong value first appear? Keep going back from there until you find where it originates.
- Add **targeted, temporary** logging at component boundaries (function input/output, request/response, SQL query):

```ts
console.debug("[DEBUG:apply-status]", { applicationId, status: application.status, role: user.role });
```

- For regressions, use `git bisect` with the test from step 1:

```bash
git bisect start
git bisect bad HEAD
git bisect good v1.4.0
git bisect run npx vitest run lib/__tests__/application-status.test.ts
git bisect reset
```

- Compare with a working example in the code (a similar endpoint/component that works) and list **all** differences.

### 3. Formulate and verify one hypothesis
- Write it down explicitly: *"The bug occurs because `X`, which causes `Y`; I will verify it by `Z`."*
- Test **one variable at a time**. No combined changes "just to be safe".
- Hypothesis disproved → revert the change, formulate a new one. Do not stack fixes on top of each other.

### 4. Make a clean fix at the root cause
- Fix the place **where the bug originates**, not the place where it shows up.
- The fix is minimal and readable; no extra refactoring in the same step.
- The test from step 1 must now pass.

**Forbidden "fixes" (masking symptoms):**

| ❌ Forbidden | Why |
|-------------|-----|
| `try { … } catch {}` or `catch (e) { console.log(e) }` around failing code | The bug doesn't go away, you just stop seeing it |
| Blanket `?.` and `?? []` wherever `undefined` crashes | Hides why the value is missing; the bug moves elsewhere |
| `as any`, `@ts-ignore`, `@ts-expect-error` without an explanation | Turns off the check that may be reporting the bug |
| Retry loops and `setTimeout`/longer timeouts for an "occasional" error | Masks a race condition |
| Deleting, skipping (`.skip`) or weakening a failing test | Destroys the evidence of the bug |
| `suppressHydrationWarning`, `eslint-disable` without understanding the cause | Suppresses diagnostics |
| Returning a default value on a DB/API error as if nothing happened | Silent data loss and inconsistency |

**Example:**

```ts
// ❌ Masking: the error disappears from the log, the user gets an empty list and nobody knows why
export async function getOpenTickets(userId: string) {
  try {
    return await db.ticket.findMany({ where: { authorId: userId, status: "open" } });
  } catch {
    return [];
  }
}

// ✅ Root cause: the DB enum is "OPEN" (uppercase), the query sent "open".
//    The fix is at the source and type-enforced; DB errors still propagate to the error handler.
import { TicketStatus } from "@prisma/client";

export async function getOpenTickets(userId: string) {
  return db.ticket.findMany({ where: { authorId: userId, status: TicketStatus.OPEN } });
}
```

**When `try/catch` is right:** at system boundaries where you **handle the error specifically** —
parsing untrusted input, verifying a webhook signature, calling an external service with a
fallback that is part of the requirements. Always catch a specific type, log the context, and
either return a defined error response or rethrow the error (`throw new Error("…", { cause })`).

### 5. Verify
- The test from step 1 passes; the **entire** test suite passes (`npm test`, `npx playwright test`).
- Types and lint are clean (`npx tsc --noEmit`, `npm run lint`).
- For UI bugs: verify in the browser via `chrome-devtools` (zero new console errors).
- Remove the temporary `[DEBUG:*]` logs: `grep -rn "\[DEBUG:" src app lib`.
- Only now may you say "fixed" — with evidence (test output), not with an assumption.

### 6. Report

```markdown
## Fix: <short name of the bug>

**Reproduction:** lib/__tests__/application-status.test.ts — "the owner must not edit a reviewed application" (failed: expected false, received true)
**Root cause:** `canEditApplication` checked only ownership, not the `pending` status (lib/applications.ts:18)
**Fix:** added the `application.status === "pending"` condition; the `updateApplication` server action uses the same function
**Verification:** vitest 48/48 ✅ · playwright 12/12 ✅ · tsc ✅ · lint ✅
**Risk / impact:** applications in the `needs_info` state now also cannot be edited — confirmed against the requirements
```

## The three-attempts rule

If **three** consecutive fixes did not work (each one reveals a new problem elsewhere), stop
fixing. The problem is probably in the design (shared mutable state, a wrong responsibility
boundary, a flawed data model). Summarize the findings, propose a structural change, and leave
the decision to the user.

## Related skills

- `webapp-testing` — reproducing UI bugs as a Playwright test.
- `chrome-devtools` — collecting runtime evidence (console, network) from the browser.
- `backend-security-auditor` — if the cause is missing authorization or validation, fix it according to its rules.
