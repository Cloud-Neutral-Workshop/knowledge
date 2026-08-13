# Stripe Billing

`accounts.svc.plus` is the server-side owner of Stripe billing.

It now provides:

- `POST /api/auth/stripe/checkout`
- `POST /api/auth/stripe/portal`
- `POST /api/billing/stripe/webhook`

## Required Environment Variables

Set these before starting the service:

```bash
STRIPE_SECRET_KEY=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
STRIPE_ALLOWED_PRICE_IDS=price_xstream_paygo,price_xstream_subscription
```

`STRIPE_ALLOWED_PRICE_IDS` is optional but recommended. When set, the checkout endpoint rejects any `price_id` that is not explicitly allowed.

## Local Test Mode Runbook

1. Start the account service with Stripe test-mode credentials.
2. Expose the service so Stripe webhooks can reach it, or use the Stripe CLI:

```bash
stripe listen --forward-to http://127.0.0.1:8080/api/billing/stripe/webhook
```

3. Copy the webhook secret printed by Stripe CLI into `STRIPE_WEBHOOK_SECRET`.
4. Restart `accounts.svc.plus`.
5. Start `console.svc.plus` with matching public `NEXT_PUBLIC_STRIPE_PRICE_*` values.
6. Sign in through the console and start a checkout flow.
7. Complete the payment with Stripe test card data.
8. Verify:
   - checkout redirects back to the console
   - webhook delivery succeeds
   - `GET /api/auth/subscriptions` contains a `provider = stripe` record
   - Stripe portal opens for the same user

## Webhook Notes

The webhook currently handles these events:

- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.paid`
- `invoice.payment_failed`

The webhook is the authoritative source for Stripe subscription status in the local `subscriptions` store.

## Operational Notes

- Keep Stripe secret values server-side only.
- Use test mode until the complete flow is verified end to end.
- If checkout succeeds but no subscription record appears, inspect webhook delivery first.
