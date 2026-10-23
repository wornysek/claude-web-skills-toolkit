---
name: webapp-testing
description: "Guide for generating and running Playwright E2E tests for a web application: form validation, error messages (422/429/500), redirect after submitting an application, double-submit protection, access by signed-out users and accessibility. Use whenever the user wants to test a form or flow, add E2E tests, verify a bug fix in the browser, or when you finish a form or application flow and need to verify that it actually works."
triggers:
  - "test the form / application / sign-up"
  - "write E2E tests / Playwright"
  - "verify validation / error messages / redirects"
  - "does submitting the application work?"
  - "regression test after a bug fix"
  - "write e2e tests / test the form"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  tool: "@playwright/test"
---

# Webapp Testing (Playwright E2E)

This skill defines **how Claude writes, runs and evaluates** end-to-end tests in
Playwright. A test you have not run does not exist — every generated test must be
run and its result reported.

## Process

1. **Read the implementation:** the form component, the Zod schema (the source of truth for validation rules and messages), the API route and the target page after submission.
2. **Build a test matrix** (see below) — what exactly is being verified and what the expected result is.
3. **Ensure the infrastructure:** Playwright installed, `playwright.config.ts`, authentication setup.
4. **Write the tests** following the rules in this file.
5. **Run them:** `npx playwright test <file> --project=chromium --reporter=list`.
6. **On failure**, analyze the error (error context, trace, screenshot) and decide: bug in the application → fix the application; bug in the test → fix the test. **Never** weaken an assertion just to make the test pass.
7. **Report:** number of tests, passed/failed, what was fixed, what remains open.

## Installation

```bash
npm init playwright@latest -- --quiet --browser=chromium --lang=ts --no-examples
npx playwright install --with-deps chromium
```

Or into an existing project:

```bash
npm install --save-dev @playwright/test
npx playwright install chromium
```

## Configuration

```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

const PORT = Number(process.env.PORT ?? 3000);
const baseURL = process.env.PLAYWRIGHT_BASE_URL ?? `http://localhost:${PORT}`;

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"], ["html", { open: "never" }]],
  use: {
    baseURL,
    locale: "en-US",
    timezoneId: "UTC",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
  projects: [
    { name: "setup", testMatch: /.*\.setup\.ts/ },
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"], storageState: "playwright/.auth/user.json" },
      dependencies: ["setup"],
    },
    {
      name: "mobile",
      use: { ...devices["Pixel 7"], storageState: "playwright/.auth/user.json" },
      dependencies: ["setup"],
    },
  ],
  webServer: {
    command: process.env.CI ? "npm run build && npm run start" : "npm run dev",
    url: baseURL,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: { NODE_ENV: process.env.CI ? "production" : "development", E2E_TEST_MODE: "1" },
  },
});
```

The `playwright/.auth/` folder contains session cookies — it **must** be in `.gitignore`.

## Authentication in tests (Discord OAuth)

E2E tests **must not** go through the real Discord OAuth (rate limits, 2FA, CAPTCHA, real
accounts). Use a test sign-in endpoint that exists **only** in test mode:

```ts
// app/api/test/login/route.ts — E2E only
import { createSession } from "@/lib/session";
import { upsertDiscordUser } from "@/lib/users";

export async function POST(req: Request) {
  if (process.env.E2E_TEST_MODE !== "1" || process.env.VERCEL_ENV === "production") {
    return new Response(null, { status: 404 });
  }
  const { role } = (await req.json()) as { role?: "user" | "reviewer" | "admin" };
  const user = await upsertDiscordUser({
    discordId: role === "admin" ? "100000000000000001" : "100000000000000002",
    username: `e2e-${role ?? "user"}`,
    avatar: null,
    role: role ?? "user",
  });
  await createSession(user.id);
  return new Response(null, { status: 204 });
}
```

```ts
// e2e/auth.setup.ts
import { test as setup, expect } from "@playwright/test";

const authFile = "playwright/.auth/user.json";

setup("sign in the test user", async ({ request }) => {
  const response = await request.post("/api/test/login", { data: { role: "user" } });
  expect(response.status()).toBe(204);
  await request.storageState({ path: authFile });
});
```

> Security: the endpoint returns 404 outside test mode, and `E2E_TEST_MODE` is **never**
> set in the production environment. Verify this in review (`backend-security-auditor`).

## Form test matrix

For every form, cover at least:

| # | Scenario | Expected result |
|---|----------|-----------------|
| 1 | Submitting an empty form | An error on every required field, `aria-invalid="true"`, focus on the first invalid field, no API request, URL unchanged |
| 2 | Invalid format / length | The specific message from the Zod schema on that field |
| 3 | Fixing an error | The message disappears after the fix and `blur`, `aria-invalid` is removed |
| 4 | Server error 500 | A generic understandable message (`role="alert"`), the form data is kept |
| 5 | Server validation error 422 | Server errors are shown on the corresponding fields |
| 6 | Rate limit 429 | A "Please try again later" message, the button is enabled again |
| 7 | Successful submission | Request with the expected body, status 201, redirect to the confirmation page, confirmation heading |
| 8 | Double submission | The button is `disabled` while submitting, exactly one request reaches the API |
| 9 | Signed-out user | Redirect to sign-in, the form is not shown |
| 10 | Keyboard | The form can be filled in and submitted using the keyboard only (Tab, Space, Enter) |

## Reference test: whitelist application

```ts
// e2e/whitelist-application.spec.ts
import { test, expect, type Page } from "@playwright/test";

const APPLY_URL = "/whitelist/apply";
const API_PATTERN = "**/api/applications";

async function fillValidApplication(page: Page) {
  await page.getByLabel("In-game name").fill("Steve_123");
  await page.getByLabel("Age").fill("21");
  await page.getByLabel("Time zone").fill("Europe/Prague");
  await page
    .getByLabel("Why do you want to join?")
    .fill("I have been playing on community servers for five years and I am looking for a long-term roleplay community.");
  await page.getByLabel("I agree to the server rules").check();
}

const submitButton = (page: Page) => page.getByRole("button", { name: "Submit application" });

test.describe("Whitelist application", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(APPLY_URL);
    await expect(page.getByRole("heading", { level: 1, name: "Whitelist application" })).toBeVisible();
  });

  test("empty submission shows errors on required fields and sends no request", async ({ page }) => {
    let apiCalls = 0;
    await page.route(API_PATTERN, (route) => {
      apiCalls += 1;
      return route.continue();
    });

    await submitButton(page).click();

    const name = page.getByLabel("In-game name");
    await expect(name).toHaveAttribute("aria-invalid", "true");
    await expect(name).toBeFocused();
    await expect(page.getByText("3–16 characters: letters, digits, underscore")).toBeVisible();
    await expect(page.getByLabel("Why do you want to join?")).toHaveAttribute("aria-invalid", "true");
    await expect(page.getByLabel("I agree to the server rules")).toHaveAttribute("aria-invalid", "true");
    await expect(page).toHaveURL(new RegExp(`${APPLY_URL}$`));
    expect(apiCalls).toBe(0);
  });

  test("invalid name and short motivation show specific messages", async ({ page }) => {
    await fillValidApplication(page);
    await page.getByLabel("In-game name").fill("ab");
    await page.getByLabel("Why do you want to join?").fill("I want to play.");
    await submitButton(page).click();

    await expect(page.getByText("3–16 characters: letters, digits, underscore")).toBeVisible();
    await expect(page.getByText(/at least 50 characters/i)).toBeVisible();
  });

  test("fixing a field removes the error message", async ({ page }) => {
    await submitButton(page).click();
    const name = page.getByLabel("In-game name");
    await expect(name).toHaveAttribute("aria-invalid", "true");

    await name.fill("Steve_123");
    await name.blur();

    await expect(name).not.toHaveAttribute("aria-invalid", "true");
    await expect(page.getByText("3–16 characters: letters, digits, underscore")).toBeHidden();
  });

  test("server error 500 shows a message and keeps the filled-in data", async ({ page }) => {
    await page.route(API_PATTERN, (route) =>
      route.fulfill({ status: 500, json: { error: "internal_error", requestId: "e2e-req-1" } }),
    );
    await fillValidApplication(page);
    await submitButton(page).click();

    await expect(page.getByRole("alert")).toContainText(/something went wrong/i);
    await expect(page.getByRole("alert")).not.toContainText(/stack|exception|prisma|sql/i);
    await expect(page.getByLabel("In-game name")).toHaveValue("Steve_123");
    await expect(submitButton(page)).toBeEnabled();
  });

  test("server validation error 422 is shown on the field", async ({ page }) => {
    await page.route(API_PATTERN, (route) =>
      route.fulfill({
        status: 422,
        json: { error: "validation_error", issues: { inGameName: ["This name already has an active application"] } },
      }),
    );
    await fillValidApplication(page);
    await submitButton(page).click();

    await expect(page.getByText("This name already has an active application")).toBeVisible();
    await expect(page.getByLabel("In-game name")).toHaveAttribute("aria-invalid", "true");
  });

  test("rate limit 429 shows an understandable message", async ({ page }) => {
    await page.route(API_PATTERN, (route) =>
      route.fulfill({ status: 429, headers: { "Retry-After": "3600" }, json: { error: "rate_limited" } }),
    );
    await fillValidApplication(page);
    await submitButton(page).click();

    await expect(page.getByRole("alert")).toContainText(/try again later/i);
    await expect(submitButton(page)).toBeEnabled();
  });

  test("successful submission sends the right data and redirects to the application status", async ({ page }) => {
    await fillValidApplication(page);

    const requestPromise = page.waitForRequest((r) => r.url().includes("/api/applications") && r.method() === "POST");
    const responsePromise = page.waitForResponse((r) => r.url().includes("/api/applications") && r.request().method() === "POST");
    await submitButton(page).click();

    const request = await requestPromise;
    expect(request.postDataJSON()).toMatchObject({
      inGameName: "Steve_123",
      age: 21,
      rulesAccepted: true,
    });
    expect(request.postDataJSON()).not.toHaveProperty("status");
    expect(request.postDataJSON()).not.toHaveProperty("role");

    const response = await responsePromise;
    expect(response.status()).toBe(201);

    await expect(page).toHaveURL(/\/whitelist\/status$/);
    await expect(page.getByRole("heading", { name: "Application submitted" })).toBeVisible();
    await expect(page.getByText(/get back to you/i)).toBeVisible();
  });

  test("double click submits the application only once", async ({ page }) => {
    let apiCalls = 0;
    await page.route(API_PATTERN, async (route) => {
      apiCalls += 1;
      await new Promise((resolve) => setTimeout(resolve, 600));
      await route.fulfill({ status: 201, json: { id: "00000000-0000-4000-8000-000000000001" } });
    });
    await fillValidApplication(page);

    await submitButton(page).dblclick();
    await expect(page.getByRole("button", { name: /submitting/i })).toBeDisabled();
    await expect(page).toHaveURL(/\/whitelist\/status$/);
    expect(apiCalls).toBe(1);
  });

  test("the form can be filled in and submitted with the keyboard only", async ({ page }) => {
    await page.route(API_PATTERN, (route) => route.fulfill({ status: 201, json: { id: "00000000-0000-4000-8000-000000000002" } }));

    await page.getByLabel("In-game name").focus();
    await page.keyboard.type("Steve_123");
    await page.keyboard.press("Tab");
    await page.keyboard.type("21");
    await page.keyboard.press("Tab");
    await page.keyboard.type("Europe/Prague");
    await page.keyboard.press("Tab");
    await page.keyboard.type("I have been playing on community servers for five years and I am looking for a long-term roleplay community.");
    await page.keyboard.press("Tab");
    await page.keyboard.press("Space");
    await page.keyboard.press("Enter");

    await expect(page).toHaveURL(/\/whitelist\/status$/);
  });
});

test.describe("Application — signed-out user", () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test("is redirected to sign-in", async ({ page }) => {
    await page.goto(APPLY_URL);
    await expect(page).toHaveURL(/\/login(\?|$)/);
    await expect(page.getByRole("button", { name: /sign in with discord/i })).toBeVisible();
  });
});
```

> Adapt the label names, messages and URLs in the reference test to the actual
> implementation — read them from the component and the Zod schema, do not invent them.

## Optional: automated accessibility check

```bash
npm install --save-dev @axe-core/playwright
```

```ts
import AxeBuilder from "@axe-core/playwright";

test("the form has no WCAG A/AA violations", async ({ page }) => {
  await page.goto("/whitelist/apply");
  const results = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa"]).analyze();
  expect(results.violations).toEqual([]);
});
```

## Rules for writing tests

- **Locators by role and accessible name:** `getByRole`, `getByLabel`, `getByText`, `getByPlaceholder` (in this order). `data-testid` only as a last resort. **Forbidden:** CSS classes, XPath, `nth-child`.
- **Web-first assertions** (`await expect(locator).toBeVisible()`) that wait on their own. **Forbidden:** `page.waitForTimeout()`, manual `sleep`.
- **Forbidden:** `click({ force: true })` — it masks real problems (an overlaid element, a disabled state).
- Every test is **isolated** — it does not depend on the order or on data from another test.
- External services (Discord, Stripe, email) are **mocked** via `page.route()`; tests never send real payments or messages.
- No real credentials in test code; test secrets go in `.env.test` (gitignored).
- One test = one behavior; the test name describes the expected result.
- Tests also verify **negative** conditions: the `role`/`status` fields were not sent to the API (mass assignment), the error message does not contain a stack trace.

## Running and debugging

```bash
npx playwright test                                   # all tests
npx playwright test e2e/whitelist-application.spec.ts # one file
npx playwright test -g "double click"                 # by name
npx playwright test --project=chromium --reporter=list
npx playwright test --headed                          # visible browser
npx playwright test --ui                              # interactive mode
npx playwright test --repeat-each=5                   # detect flaky tests
npx playwright show-report                            # HTML report
npx playwright show-trace test-results/<test>/trace.zip
```

On failure:
1. Read the error message and the `error-context.md` / page snapshot in `test-results/`.
2. Run the test again with `--trace on` and go through the trace (network, console, DOM over time).
3. Decide where the bug is (application vs. test) and fix the **cause**.
4. Verify stability: `--repeat-each=5` must pass.
5. For runtime errors in the console use the `chrome-devtools` skill, for the debugging process `superpowers-debugging`.

## Output format

```markdown
## E2E results: e2e/whitelist-application.spec.ts

- Ran: 10 tests (chromium) · ✅ 9 passed · ❌ 1 failed
- ❌ "double click submits the application only once" — 2 requests reached the API.
  - Cause: the button is disabled only after `fetch` returns, not on submit (app/whitelist/apply/form.tsx:58).
  - Fix: `useTransition` + `disabled={isPending}`; after the fix 10/10 ✅, `--repeat-each=5` ✅.
```
