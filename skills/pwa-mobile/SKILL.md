---
name: pwa-mobile
description: "Mobile web and Progressive Web Apps: responsive layouts beyond breakpoints (container queries, fluid type, dynamic viewport units, safe areas), touch input and gestures with alternatives, mobile keyboards and inputs, hover-free interaction, the web app manifest and icons, service workers with caching strategies and an offline fallback, safe updates, offline data and sync, web push notifications with permission done right, installability on Android and iOS, and app-store packaging options. Use whenever you make a site work well on phones and tablets, add a manifest, offline support, installability or push notifications, or the user asks about PWA, mobile UX or touch. For page speed on mobile use web-performance; for a native app decision use tech-stack-advisor."
triggers:
  - "mobile version / responsive / works badly on phone"
  - "PWA / installable / add to home screen / manifest"
  - "offline mode / service worker / caching"
  - "push notifications / web push"
  - "touch / swipe / gestures / mobile keyboard"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Mobile web & PWA

Most visits come from phones: small screens, touch, interrupted attention, flaky
networks and browser toolbars that appear and disappear. A good mobile experience is
designed for that first; a PWA adds installability, offline use and notifications on top.

## Process

1. **Responsive layout and touch** for every page (sections 1–3).
2. **Manifest and icons** if the app should be installable (section 4).
3. **Service worker** for offline fallback and caching (section 5), offline data if needed (section 6).
4. **Push notifications** only with a clear user benefit (section 7).
5. **Test on real devices** (section 9).

---

## 1. Responsive layout

- **Mobile-first CSS:** base styles for small screens, `sm:` / `md:` / `lg:` add complexity; breakpoints follow the content, not device names.
- **Container queries** (`@container`) for components that live in different column widths (cards in a sidebar vs. main area).
- **Fluid type and spacing** with `clamp()` for headings: `font-size: clamp(2rem, 1.5rem + 2.5vw, 3.5rem)`.
- **Viewport units:** `100dvh` (dynamic) or `100svh` (small) instead of `100vh`, which ignores the mobile browser toolbar and cuts off content.
- **Safe areas** on devices with notches and home indicators:

```css
/* with <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"> */
.bottom-bar {
  padding-bottom: max(1rem, env(safe-area-inset-bottom));
}
```

- No horizontal scrolling at 320–360 px; tables scroll inside their own container; long words break (`overflow-wrap: anywhere` for URLs and codes).
- Sticky elements (headers, bottom bars, cookie banners) together take at most ~25 % of the viewport.

## 2. Touch and pointer

- Touch targets ≥ 44 × 44 px with spacing (`ux-laws` Fitts, `a11y-auditor` 2.5.8).
- **No hover-only interactions:** menus, tooltips and previews also open on tap and focus; use `@media (hover: hover)` for hover-only decoration.
- **Gestures have visible alternatives:** swipe-to-delete also has a delete button; carousels have buttons (`a11y-auditor` 2.5.1, 2.5.7).
- `touch-action` and `overscroll-behavior: contain` for custom scrolling areas, maps and drawers (prevents accidental pull-to-refresh and page scroll).
- Feedback on press within 100 ms (`active:` styles) — taps without feedback get repeated.
- Bottom-of-screen placement for primary mobile actions (thumb zone); destructive actions away from them.

## 3. Mobile inputs and keyboards

- The right keyboard: `type="email"`, `type="tel"`, `inputMode="numeric" | "decimal" | "search"`, `enterKeyHint="next" | "send" | "search"` (`forms`).
- **Input font size ≥ 16 px** — smaller sizes make iOS Safari zoom in on focus.
- `autocomplete` everywhere for autofill (addresses, one-time codes, passwords).
- The focused field stays visible above the on-screen keyboard; fixed bottom bars don't cover inputs.
- Native date, time and select pickers usually beat custom ones on mobile.

## 4. Manifest and installability

```ts
// app/manifest.ts
import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Acme Invoices",
    short_name: "Acme",
    description: "Send invoices and track payments.",
    start_url: "/?source=pwa",
    scope: "/",
    display: "standalone",
    background_color: "#ffffff",
    theme_color: "#0f1411",
    icons: [
      { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" },
      { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png" },
      { src: "/icons/icon-maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
    ],
  };
}
```

- Icons: 192 and 512 px, a **maskable** version with safe padding, an Apple touch icon (`apple-icon.png` / 180 px).
- `theme_color` matches the design tokens in light and dark mode (`<meta name="theme-color" media="(prefers-color-scheme: dark)">`).
- An install prompt appears **after** the user got value (e.g. after the third visit or a completed task), never on first load. On iOS, explain "Share → Add to Home Screen".
- Installed apps open without browser UI: the app needs its own back navigation and visible sign-out.

## 5. Service worker and caching

- **Strategies:** network-first for HTML pages (fresh content, cached fallback), stale-while-revalidate for static assets and images, cache-first only for fingerprinted files.
- **Never cache personalized API responses** in a shared cache, and clear user data caches on sign-out (shared devices).
- **Offline fallback page** for navigations when the network is down:

```js
// public/sw.js — minimal offline fallback
const CACHE = "offline-v1";

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.add("/offline")));
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key)))),
  );
});

self.addEventListener("fetch", (event) => {
  if (event.request.mode !== "navigate") return;
  event.respondWith(fetch(event.request).catch(() => caches.match("/offline")));
});
```

- For full caching use a maintained service-worker library (e.g. Serwist for Next.js, Workbox) instead of hand-written routing.
- **Updates:** a new service worker waits; show "A new version is available — Reload" instead of reloading under the user's hands; version caches and delete old ones on activate.
- Serve `sw.js` with `Cache-Control: no-cache` so updates are found.

## 6. Offline data

- Decide per feature: read-only offline (cached content), queued writes (send when back online), or full offline editing (needs conflict resolution).
- Store offline data in **IndexedDB** (via a small wrapper), not `localStorage`; encrypt or avoid sensitive data on shared devices (`frontend-security`).
- **Queued writes** carry an idempotency key so retries don't duplicate (`api-design`); show their status ("Will sync when online").
- Background sync is not available in every browser — always retry on the next app start or when the `online` event fires.
- Show connection status clearly but calmly (a small banner, not a modal).

## 7. Web push notifications

- **Ask for permission only after a user action** that shows the benefit ("Notify me when the invoice is paid") — never on page load. A denied permission is hard to undo.
- Notification preferences per type in settings; easy unsubscribe; quiet hours where it matters.
- **VAPID keys** on the server; store subscriptions per user and device; remove expired subscriptions (`410 Gone`).

```ts
// lib/push.ts — server
import webpush from "web-push";
import { env } from "@/lib/env";

webpush.setVapidDetails("mailto:ops@example.com", env.VAPID_PUBLIC_KEY, env.VAPID_PRIVATE_KEY);

export async function sendPush(subscription: webpush.PushSubscription, payload: { title: string; body: string; url: string }) {
  await webpush.sendNotification(subscription, JSON.stringify(payload), { TTL: 60 * 60 });
}
```

```ts
// client — after the user clicks "Notify me"
const registration = await navigator.serviceWorker.ready;
const subscription = await registration.pushManager.subscribe({
  userVisibleOnly: true,
  applicationServerKey: process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY,
});
await fetch("/api/push/subscriptions", { method: "POST", body: JSON.stringify(subscription) });
```

- Payloads contain no sensitive data (they may appear on lock screens); the click opens the relevant page.
- On iOS, web push works only for installed web apps (Home Screen).
- Push is a communication channel: consent, preferences and data retention per `gdpr-privacy`.

## 8. App stores

- Android: a PWA can be published to Google Play as a Trusted Web Activity.
- iOS App Store: requires a native wrapper (e.g. Capacitor) and must offer more than a website.
- If you need deep native features or store presence as a product requirement, decide with `tech-stack-advisor` (PWA vs. wrapper vs. native/Expo).

## 9. Testing

- Real devices: at least one recent iPhone (Safari) and one mid-range Android (Chrome); browser emulation is not enough for keyboards, safe areas and performance.
- Throttled network and offline mode in DevTools; installed mode (standalone) as well as browser tabs.
- Rotate the device, enlarge text (accessibility settings), switch dark mode.
- Playwright mobile projects for flows (`webapp-testing`); Lighthouse PWA and performance checks (`web-performance`).

## Checklist

- [ ] Mobile-first layout; container queries where components move; `dvh`/`svh`; safe areas; no horizontal scroll at 320 px.
- [ ] Touch targets ≥ 44 px; no hover-only interactions; gestures have alternatives; press feedback.
- [ ] Correct input types and `inputMode`; input font ≥ 16 px; fields visible above the keyboard.
- [ ] Manifest with maskable icons and theme colors; install prompt after value, not on load.
- [ ] Service worker with sensible strategies, offline fallback, controlled updates; no personalized data in shared caches.
- [ ] Offline writes queued with idempotency keys and visible status.
- [ ] Push permission asked in context; preferences; no sensitive payloads; expired subscriptions removed.
- [ ] Tested on real iOS and Android devices, offline and installed.

## Output format

```markdown
## Mobile review: dashboard

| # | Finding | File:line | Fix |
|---|---------|-----------|-----|
| 1 | `h-screen` hides the bottom bar behind Safari's toolbar | app/(app)/layout.tsx:12 | `h-dvh` + safe-area padding |
| 2 | Row actions only appear on hover | components/invoice-row.tsx:40 | always-visible menu button on touch devices |
| 3 | Push permission requested on first load | app/layout.tsx:25 | ask after "Notify me" click |
| 4 | Inputs 14 px, iOS zooms on focus | components/ui/input.tsx | `text-base` on mobile |
```

## Related skills

- `web-performance` (mobile speed), `a11y-auditor` (targets, gestures, zoom), `ux-laws` (Fitts, Doherty), `forms` (mobile inputs), `frontend-security` (offline data), `api-design` (idempotent queued writes), `gdpr-privacy` (push consent), `tech-stack-advisor` (PWA vs. native).
