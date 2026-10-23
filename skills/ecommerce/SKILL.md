---
name: ecommerce
description: "E-commerce and paid products: platform vs. custom build, catalog and variants, prices and money, carts (guest, merge, server-side pricing), checkout with Stripe (Checkout or Payment Element, SCA/3-D Secure, webhooks as the source of truth, idempotency), order state machine, subscriptions and billing portal, refunds, EU VAT (OSS, reverse charge, prices incl. VAT), invoices, EU consumer law for online shops (pre-contractual information, order button wording, 14-day withdrawal and the withdrawal function, legal guarantee, price reductions and reviews), required legal pages, product SEO and fraud. Use whenever you build or change a shop, cart, checkout, pricing page, subscription billing, refunds or order emails. Not legal or tax advice."
triggers:
  - "e-shop / online store / cart / checkout"
  - "Stripe / payments / subscriptions / billing portal"
  - "VAT / taxes / invoices"
  - "terms and conditions / returns / withdrawal / legal pages for a shop"
  - "product page / pricing page / coupons / refunds"
metadata:
  author: claude-web-skills-toolkit
  license: MIT
  version: "1.0.0"
  references: "Directive 2011/83/EU (Consumer Rights), Directive (EU) 2019/2161 (Omnibus), Directive (EU) 2023/2673, Directive (EU) 2019/771, EU VAT e-commerce package"
---

# E-commerce

Selling online combines the hardest parts of web development: money, inventory, taxes,
consumer law and fraud. Most of it is solved — by platforms and payment providers. Build
only what makes the shop different.

> **Not legal or tax advice.** Rules differ by country, product type and business size.
> Mark open questions as `[LEGAL: …]` / `[TAX: …]` for the owner and their advisers.

## Process

1. **Platform or custom** (section 1) — record the decision (`tech-stack-advisor`).
2. **Catalog, prices, cart** (sections 2–3).
3. **Checkout and payments** with webhooks as the source of truth (sections 4–5).
4. **Orders, refunds, subscriptions** (sections 6–7).
5. **Taxes and invoices** (section 8), **consumer law and legal pages** (section 9).
6. **Product SEO, emails, fraud, testing** (sections 10–12).

---

## 1. Platform or custom

| Situation | Recommendation |
|-----------|----------------|
| Physical goods, standard checkout, small team | a hosted commerce platform (themes, payments, taxes, shipping built in) |
| Custom storefront, standard back office | **headless**: the platform's back office + your frontend |
| Digital products / SaaS subscriptions | a payment provider's hosted checkout and billing (e.g. Stripe Checkout + Billing), or a **merchant of record** that also handles global VAT |
| Truly custom flows (marketplace, configurators, B2B pricing) | custom build on a payment provider — budget for the parts below |

## 2. Catalog and money

- **Products → variants (SKUs)** with their own price, stock and attributes (size, color).
- **Money as integers in minor units with a currency** (`database-design`); never floats; rounding rules defined once.
- **Prices are versioned:** an order stores the price it was sold at; changing the catalog never changes past orders.
- **Inventory** is reserved atomically at checkout and released on expiry or cancellation (`database-design` section 6).
- Show availability honestly ("2 left", "ships in 3–5 days") from real data.

## 3. Cart

- The cart lives **on the server** (a cart ID in a cookie); guests can shop without an account; the cart merges into the account on sign-in.
- **Prices, discounts, shipping and taxes are recalculated on the server** on every change and at checkout — the client never sends prices (`backend-security-auditor` C2).
- Coupons are validated server-side (validity, usage limits per user, combinability) and rate-limited against guessing.
- Cart changes give immediate feedback (`ux-laws` Feedback Loops, optimistic UI with rollback — `realtime`).

## 4. Checkout

- **Guest checkout** by default; account creation optional after payment.
- **Few steps, clear total:** the full price including taxes, shipping and fees is visible **before** the order button.
- Address forms with `autocomplete` and country-aware fields (`forms`).
- Use the payment provider's **hosted checkout or embedded elements** — card data never touches your servers (keeps PCI scope minimal).
- **Strong Customer Authentication (3-D Secure)** in the EU is handled by the provider's payment flow — don't build around it.

```ts
// app/api/checkout/route.ts — create a hosted checkout session for an existing pending order
import Stripe from "stripe";
import { env } from "@/lib/env";

const stripe = new Stripe(env.STRIPE_SECRET_KEY);

export async function POST(req: Request) {
  const user = await requireUser();
  const { orderId } = IdBodySchema.parse(await req.json());
  const order = await db.order.findFirst({
    where: { id: orderId, customerId: user.id, status: "pending" },
    select: { id: true, items: { select: { stripePriceId: true, quantity: true } } },
  });
  if (!order) throw new HttpError(404);

  const session = await stripe.checkout.sessions.create(
    {
      mode: "payment",
      line_items: order.items.map((item) => ({ price: item.stripePriceId, quantity: item.quantity })),
      client_reference_id: order.id,
      metadata: { orderId: order.id },
      customer_email: user.email,
      automatic_tax: { enabled: true },
      success_url: `${env.APP_ORIGIN}/orders/${order.id}?checkout=success`,
      cancel_url: `${env.APP_ORIGIN}/cart`,
    },
    { idempotencyKey: `checkout-${order.id}` },
  );

  return Response.json({ url: session.url });
}
```

## 5. Webhooks are the source of truth

- **Never fulfill on the success redirect** — the user may close the tab, the redirect can be faked. Fulfill when the **verified webhook** arrives (`backend-security-auditor` G2).
- Handle the events of your flow, e.g. `checkout.session.completed` (check `payment_status`), `checkout.session.async_payment_succeeded` / `…_failed` for delayed methods, `charge.refunded`, `invoice.paid` / `invoice.payment_failed` for subscriptions.
- **Idempotent processing** by event ID; out-of-order events are expected.
- The success page shows the order status from your database ("Payment confirmed" or "Waiting for payment confirmation").

## 6. Orders and refunds

| Status | Next states | Triggered by |
|--------|-------------|--------------|
| `pending` | `paid`, `cancelled`, `expired` | checkout started |
| `paid` | `fulfilled`, `refunded`, `partially_refunded` | payment webhook |
| `fulfilled` | `shipped` | warehouse / digital delivery |
| `shipped` | `delivered`, `returned` | carrier |
| `cancelled` / `expired` / `refunded` | — | final |

- Allowed transitions are enforced in one place (a function or a DB constraint), not scattered.
- Every transition is logged (who, when, why) — support needs the history.
- **Refunds** go through the payment provider; the order updates from the refund webhook; restock if the goods come back.
- Customers see their orders, invoices and statuses in their account; guests get a signed link by email.

## 7. Subscriptions

- Use the provider's billing (plans, trials, proration, invoices, dunning, tax) and its **customer portal** for card changes and cancellation.
- Access is granted from **your database**, updated by webhooks (`active`, `past_due`, `canceled`) — not by asking the provider on every request.
- **Cancellation is as easy as sign-up** (consumer protection rules in several countries; a one-click online cancellation path is the safe default).
- Communicate before renewals and price changes; show the next charge date and amount in the account.

## 8. Taxes and invoices (EU)

- **B2C prices are shown including VAT** in the EU.
- Cross-border B2C sales to other EU countries: once EU-wide distance sales exceed **€10,000 per year**, VAT of the **customer's country** applies, typically declared through the **One-Stop Shop (OSS)** `[TAX: confirm registration]`.
- **B2B within the EU:** validate the customer's VAT ID (VIES) and apply reverse charge where it applies; store the validation result.
- Digital services to consumers are taxed in the consumer's country from the first euro.
- Use the payment provider's tax calculation or a **merchant of record** instead of maintaining tax tables yourself.
- **Invoices:** sequential numbering without gaps, the legally required fields for your country, issued in the right currency and language, stored for the legal retention period (often 10 years) `[TAX: local requirements]`.

## 9. EU consumer law and legal pages

For contracts concluded online with consumers in the EU `[LEGAL: verify per country]`:

- **Pre-contractual information** before the order: seller identity and contact, main characteristics, total price incl. taxes and delivery, payment and delivery terms, withdrawal right, legal guarantee, contract duration and cancellation for subscriptions.
- **Order button** states the obligation to pay — e.g. "Order with obligation to pay" / "Buy now", never just "Continue".
- **Right of withdrawal: 14 days** for distance contracts (from delivery for goods), with a model withdrawal form; exceptions exist (e.g. personalized goods, sealed hygiene goods, digital content after an express request and acknowledgement).
- **Withdrawal function:** an online "withdraw from contract" function is required for contracts concluded via online interfaces (from 19 June 2026 under Directive (EU) 2023/2673) — make it easy to find in the account and footer.
- **Legal guarantee:** at least 2 years for goods sold to consumers; don't present it as a paid extra.
- **Price reductions** show the lowest price of the previous 30 days next to the discount.
- **Reviews:** say whether and how you verify that reviews come from real buyers; never fake or buy reviews.
- **Confirmation** of the contract on a durable medium (the order confirmation email with the terms attached or linked as a PDF).
- **Accessibility:** e-commerce services fall under the European Accessibility Act (`a11y-auditor`).

**Legal pages** (linked from the footer and the checkout): terms and conditions, privacy notice (`gdpr-privacy`), cookie settings, withdrawal information + form + online withdrawal function, shipping and returns, complaints and guarantee, company details (imprint where required), accessibility statement. The EU online dispute resolution (ODR) platform was closed in 2025 — remove old ODR links `[LEGAL: national ADR information may still be required]`.

## 10. Product pages and SEO

- Real photos with zoom, all variants visible, price, availability, delivery estimate, returns summary near the buy button.
- **Structured data:** `Product` with `Offer` (price, currency, availability) and real `AggregateRating` only (`seo-metadata`).
- Variant URLs or parameters canonicalized; out-of-stock pages stay (with alternatives) instead of 404s.
- Fast product pages: LCP image priority, no heavy third-party scripts (`web-performance`).

## 11. Emails and notifications

Order confirmation (with the contract information), payment received, shipped (tracking), delivered, refund issued, subscription renewal reminder, payment failed — essential emails via `transactional-email`, localized, with the order link.

## 12. Fraud and testing

- The provider's fraud screening, velocity limits on checkout attempts and coupon use, address and email checks for risky orders; manual review queue for high-value orders.
- Test with the provider's **test mode and test cards** (including 3-D Secure and declined cards) in previews; never live keys outside production (`deploy-and-ops`).
- E2E: add to cart → checkout (mocked or test mode) → webhook → order paid → confirmation email (`webapp-testing`).

## Checklist

- [ ] Platform vs. custom decided and recorded.
- [ ] Money in minor units; prices versioned; stock reserved atomically.
- [ ] Server-side cart with recalculated prices, discounts, shipping and taxes; coupons validated and rate-limited.
- [ ] Hosted checkout or provider elements; total shown before the order button; SCA via the provider.
- [ ] Fulfillment only from verified, idempotent webhooks; success page reads the DB status.
- [ ] Order state machine enforced and logged; refunds via provider + webhook.
- [ ] Subscriptions from DB state; portal; cancellation as easy as sign-up.
- [ ] VAT handling decided (provider tax, MoR, OSS); invoices compliant and stored.
- [ ] Consumer law: pre-contractual info, order button wording, withdrawal right and function, guarantee, 30-day price rule, review transparency, confirmation email.
- [ ] Legal pages linked from footer and checkout; accessibility statement.
- [ ] Product structured data real; test mode and E2E for the full purchase flow.

## Output format

```markdown
## E-commerce review: checkout

| # | Area | Finding | Fix |
|---|------|---------|-----|
| 1 | Payments | Order marked paid on the success redirect | fulfill from verified `checkout.session.completed` webhook |
| 2 | Cart | Price sent from the client | recalculate on the server from the catalog |
| 3 | Consumer law | Order button says "Continue" | "Order with obligation to pay" `[LEGAL: wording per country]` |
| 4 | Tax | Prices shown without VAT to consumers | show incl. VAT; provider tax calculation |
```

## Related skills

- `backend-security-auditor` (server-side prices, webhooks, IDOR), `database-design` (money, stock, state), `forms` (checkout forms), `transactional-email` (order emails), `gdpr-privacy` (privacy notice, consent), `a11y-auditor` (EAA), `seo-metadata` (product structured data), `web-performance`, `tech-stack-advisor` (platform choice).
