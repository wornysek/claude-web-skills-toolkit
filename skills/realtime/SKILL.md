---
name: realtime
description: "Realtime features in web apps: choosing between polling, Server-Sent Events, WebSockets, WebRTC and managed realtime services, hosting constraints of serverless, authenticating connections and authorizing every channel, validating and rate-limiting messages, cross-site WebSocket hijacking, scaling with a pub/sub backplane, presence and typing indicators, reconnection with backoff and resume, ordering and idempotency, optimistic updates with useOptimistic, live dashboards, collaborative editing with CRDTs, and realtime UX and accessibility. Use whenever you build chat, notifications, live updates, presence, collaborative editing, live dashboards or multiplayer features. For choosing a hosting platform use tech-stack-advisor."
triggers:
  - "chat / live notifications / live updates"
  - "WebSocket / Server-Sent Events / SSE / polling"
  - "presence / who is online / typing indicator"
  - "collaborative editing / multiplayer / live cursors"
  - "optimistic updates / useOptimistic"
  - "live dashboard / streaming data"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
---

# Realtime

Realtime features feel simple in a demo and get hard in production: connections drop,
messages arrive twice or out of order, users switch devices, and every channel is a new
place to leak data. Choose the simplest transport that meets the latency the product
actually needs.

## Process

1. **Define the need:** who sends, who receives, acceptable delay (seconds? sub-second?), volume, what happens when offline.
2. **Choose the transport and hosting** (section 1).
3. **Secure** connections, channels and messages (section 2).
4. **Make delivery reliable** — reconnects, resume, ordering, idempotency (section 3).
5. **Build the UI:** optimistic updates, presence, connection status (sections 4–6).
6. **Scale and observe** (section 7).

---

## 1. Transport

| Need | Transport |
|------|-----------|
| Updates within ~10–60 s (status pages, dashboards that refresh) | **polling** with `If-None-Match` / ETag — simplest, cacheable |
| Server → client streams (notifications, progress, AI tokens, live feeds) | **Server-Sent Events** — plain HTTP, automatic reconnect, `Last-Event-ID` resume |
| Two-way, low latency (chat, multiplayer, live cursors) | **WebSockets** |
| Peer-to-peer audio, video, screen sharing | **WebRTC** (with a signaling server and TURN servers) |
| Any of the above without running infrastructure | a **managed realtime service** (pub/sub, presence, history) |

**Hosting:** classic serverless functions can't hold long-lived WebSocket connections and
limit how long an SSE stream may stay open. Use a long-running server (container, VM), a
platform with durable connections, or a managed service (`tech-stack-advisor`,
`deploy-and-ops`).

**SSE in a route handler:**

```ts
// app/api/notifications/stream/route.ts
export async function GET(req: Request) {
  const user = await requireUser();
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    start(controller) {
      const send = (event: string, data: unknown, id?: string) =>
        controller.enqueue(encoder.encode(`${id ? `id: ${id}\n` : ""}event: ${event}\ndata: ${JSON.stringify(data)}\n\n`));

      const unsubscribe = notifications.subscribe(user.id, (message) => send("notification", message, message.id));
      const keepAlive = setInterval(() => controller.enqueue(encoder.encode(": keep-alive\n\n")), 25_000);

      req.signal.addEventListener("abort", () => {
        clearInterval(keepAlive);
        unsubscribe();
        controller.close();
      });
    },
  });

  return new Response(stream, {
    headers: { "Content-Type": "text/event-stream", "Cache-Control": "no-cache, no-transform", Connection: "keep-alive" },
  });
}
```

## 2. Security

- **Authenticate the connection:** cookies for same-origin connections, or a **short-lived, single-use ticket** fetched over an authenticated request — not a long-lived token in the URL (URLs end up in logs).
- **Check the `Origin`** on the WebSocket handshake against an allowlist — browsers send cookies with cross-site WebSocket connections (cross-site WebSocket hijacking).
- **Authorize every channel subscription** on the server: may this user join `workspace:123` or `ticket:456`? A channel name from the client is untrusted input — this is IDOR again (`backend-security-auditor` B1).
- **Re-check permissions** when they change (user removed from a workspace → close or unsubscribe their connections).
- **Validate every incoming message** with a schema (type, size, fields) and **rate-limit** messages per connection and per user.
- Treat messages from other users as user-generated content in the UI (escaping, moderation, `frontend-security`).
- Close idle connections; cap connections per user.

## 3. Reliable delivery

- **Reconnect** automatically with exponential backoff and jitter (e.g. 1 s, 2 s, 4 s … up to 30 s); stop after the user signs out.
- **Resume:** every message has an ID or a sequence number; after reconnecting, the client asks for everything after the last one it saw (`Last-Event-ID` for SSE, a `since` cursor for WebSockets), or refetches the current state.
- **At-least-once delivery** is the realistic guarantee: handle messages **idempotently** by ID.
- **Ordering:** don't assume it across reconnects or servers — order by server timestamp or sequence per channel.
- **The database is the source of truth.** The realtime layer notifies; on doubt, refetch.
- Back pressure: drop or coalesce updates for slow clients (send "the latest state" instead of every intermediate change).

## 4. Optimistic updates

```tsx
"use client";
import { useOptimistic, useTransition } from "react";

type Message = { id: string; body: string; pending?: boolean };

export function Thread({ messages, sendMessage }: { messages: Message[]; sendMessage: (body: string) => Promise<void> }) {
  const [optimisticMessages, addOptimistic] = useOptimistic(messages, (state, body: string) => [
    ...state,
    { id: `temp-${crypto.randomUUID()}`, body, pending: true },
  ]);
  const [, startTransition] = useTransition();

  function onSend(body: string) {
    startTransition(async () => {
      addOptimistic(body);
      await sendMessage(body); // on error the optimistic message disappears; show a retry
    });
  }

  return (
    <ul aria-live="polite">
      {optimisticMessages.map((message) => (
        <li key={message.id} className={message.pending ? "opacity-60" : undefined}>{message.body}</li>
      ))}
    </ul>
  );
}
```

- Use temporary IDs, replace them with server IDs when the confirmation (or the realtime echo) arrives, and **deduplicate** the echo of your own message.
- On failure: mark the item as failed with "Retry" and "Delete" — never silently drop what the user typed.
- Only for cheap, reversible actions (`ux-laws` Doherty); payments and destructive actions wait for the server.

## 5. Presence, typing and live dashboards

- **Presence** with heartbeats and a TTL (e.g. a heartbeat every 20 s, offline after 60 s without one); tabs and devices of one user count once.
- **Typing indicators** are throttled (send at most every few seconds) and expire automatically.
- **Live dashboards:** aggregate on the server and push snapshots at a fixed rate (e.g. every 2–5 s) instead of every database change; pause updates when the tab is hidden (`visibilitychange`).

## 6. Collaborative editing

- Use **CRDTs** (e.g. Yjs, Automerge) or a managed collaboration service rather than inventing merge logic; operational transforms are hard to get right.
- Persist document state on the server (snapshots + updates), authorize per document, and keep an undo history per user.
- Show collaborators (avatars, cursors) and handle offline edits merging back.

## 7. Scaling and observability

- With more than one server instance, use a **pub/sub backplane** (e.g. Redis, Postgres `LISTEN/NOTIFY` for small loads, or the managed service) so a message reaches clients connected to any instance.
- Sticky sessions or connection-aware load balancing for WebSockets; graceful shutdown that tells clients to reconnect elsewhere.
- Limits: message size, messages per second, connections per user and per instance.
- Metrics: open connections, connects/disconnects per minute, message rate, delivery latency, errors per channel (`deploy-and-ops`).

## 8. UX and accessibility

- A small, calm **connection status** ("Reconnecting…", "Offline — changes will sync") — not a blocking modal.
- New content in a long feed: a "3 new messages" pill instead of jumping the scroll position while the user reads.
- Screen readers: announce new messages politely (`aria-live="polite"`), but not every update of a busy feed or dashboard — offer a summary or a setting (`a11y-auditor`).
- Respect `prefers-reduced-motion` for live animations (counters, cursors).

## Checklist

- [ ] The transport matches the needed latency; hosting supports it (no long-lived sockets on plain serverless).
- [ ] Connections authenticated with cookies or short-lived tickets; WebSocket `Origin` checked.
- [ ] Every channel subscription authorized on the server and re-checked on permission changes.
- [ ] Messages validated, size-limited and rate-limited.
- [ ] Reconnect with backoff and jitter; resume from the last ID or refetch; idempotent handling.
- [ ] Optimistic updates with temp IDs, deduplication and visible failure + retry.
- [ ] Presence with heartbeats and TTL; typing throttled; dashboards push snapshots and pause when hidden.
- [ ] Pub/sub backplane for multiple instances; limits and metrics in place.
- [ ] Calm connection status; no scroll jumps; polite announcements.

## Output format

```markdown
## Realtime review: support chat

| # | Area | Finding | Fix |
|---|------|---------|-----|
| 1 | Security | Client can subscribe to any `ticket:<id>` channel | authorize subscription against ticket ownership/staff role |
| 2 | Security | WebSocket handshake doesn't check Origin | allowlist check, reject others |
| 3 | Reliability | Messages lost after reconnect | sequence numbers + `since` resume |
| 4 | UX | Own messages appear twice (optimistic + echo) | dedupe by client message ID |
```

## Related skills

- `backend-security-auditor` (auth, IDOR, rate limits), `frontend-security` (rendering messages), `api-design` (idempotency, ETags for polling), `database-design` (source of truth, LISTEN/NOTIFY), `deploy-and-ops` (hosting, scaling, metrics), `ux-laws` (Doherty, Feedback Loops), `a11y-auditor` (live regions), `ai-features` (streaming responses).
