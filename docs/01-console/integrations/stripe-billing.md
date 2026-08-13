# Stripe Billing Integration

This console now routes all purchase entry points through Stripe:

- `/prices`
- product detail pages
- `/panel/subscription`

The browser only needs public Stripe `price_id` values. Secret keys stay in `accounts.svc.plus`.

## Required Environment Variables

Set these in `console.svc.plus`:

```bash
NEXT_PUBLIC_STRIPE_PRICE_XSTREAM_PAYGO=price_xxx
NEXT_PUBLIC_STRIPE_PRICE_XSTREAM_SUBSCRIPTION=price_xxx
NEXT_PUBLIC_STRIPE_PRICE_XSCOPEHUB_PAYGO=price_xxx
NEXT_PUBLIC_STRIPE_PRICE_XSCOPEHUB_SUBSCRIPTION=price_xxx
NEXT_PUBLIC_STRIPE_PRICE_XCLOUDFLOW_PAYGO=price_xxx
NEXT_PUBLIC_STRIPE_PRICE_XCLOUDFLOW_SUBSCRIPTION=price_xxx
```

If a value is missing, the related purchase button stays visible but reports that Stripe pricing is not configured.

## Local Integration Checklist

1. Configure all `NEXT_PUBLIC_STRIPE_PRICE_*` values with Stripe test-mode `price_...` ids.
2. Start `accounts.svc.plus` with Stripe server-side settings.
3. Start this console with `yarn dev`.
4. Sign in with a normal user account.
5. Open `/prices` or `/panel/subscription` and start checkout.
6. Complete a Stripe test payment.
7. Confirm the browser returns to `/panel/subscription?checkout=success...`.
8. Confirm the subscription record appears in the subscription panel.
9. Open "Manage Stripe billing" and confirm the customer portal opens.

## Expected Flow

1. The console calls `/api/auth/stripe/checkout`.
2. The BFF proxies the request to `accounts.svc.plus` using the current account session.
3. `accounts.svc.plus` creates the Stripe Checkout Session.
4. Stripe redirects back to the console.
5. Stripe webhooks update the account service subscription record.
6. The console reads the final state from `/api/auth/subscriptions`.

## Notes

- The console does not store Stripe secret keys.
- Sensitive payment methods such as crypto QR flows are intentionally removed from the purchase UI.
- Use Stripe test mode first; do not validate this flow against live prices until webhook delivery is confirmed.
