# Stripe Integration for Xano

Accept payments, manage customers and subscriptions, and handle checkout flows directly from your Xano backend.

This integration also provisions 1 database table (see `tables/`).

## Functions

| Function | Description |
| --- | --- |
| `stripe_create_customer` | Creates a new customer record in Stripe with email and optional metadata. |
| `stripe_create_payment_intent` | Creates a payment intent for a specified amount and currency. |
| `stripe_create_checkout_session` | Creates a hosted Stripe Checkout session with a redirect URL. |
| `stripe_retrieve_customer` | Retrieves a Stripe customer record by its ID. |
| `stripe_list_invoices` | Lists invoices with optional customer filtering and pagination. |
| `stripe_create_subscription` | Creates a recurring subscription for a customer and price. |
| `stripe_cancel_subscription` | Cancels a subscription immediately or at the end of the billing period. |
| `stripe_verify_webhook` | Verifies a Stripe webhook signature and parses the event payload. |

## Install

### Option A — Ask Claude Code

With the [Xano MCP](https://github.com/xano-labs/mcp-server) enabled in Claude Code, paste this into Claude:

> Install the integration at https://github.com/xano-community/integration-stripe-payments into my Xano workspace.

Claude will clone the repo and push the functions and tables to your workspace.

### Option B — Use the Xano CLI

1. Install and authenticate the [Xano CLI](https://docs.xano.com/cli):
   ```sh
   npm install -g @xano/cli
   xano auth
   ```

2. Clone and push this integration:
   ```sh
   git clone https://github.com/xano-community/integration-stripe-payments.git
   cd integration-stripe-payments
   xano workspace:push . -w <your-workspace-id>
   ```

   Replace `<your-workspace-id>` with the ID from `xano workspace:list`.

## Configure Credentials

1. Create a Stripe account at https://dashboard.stripe.com/register
2. Navigate to Developers > API keys in the Stripe Dashboard
3. Copy your Secret Key (starts with sk_)
4. Navigate to Developers > Webhooks and create an endpoint to get your signing secret (starts with whsec_)
5. In Xano, set the environment variable STRIPE_API_KEY to your Secret Key
6. Set the environment variable STRIPE_SIGNING_SECRET to your webhook signing secret

Environment variables used by this integration:

- `STRIPE_API_KEY`
- `STRIPE_SIGNING_SECRET`

See `.env.example` for a template.

## Usage

Call any function from another function, task, or API endpoint using `function.run`:

```xs
function.run "stripe_create_customer" {
  input = {
    // See function signature for required parameters
  }
} as $result
```

## Function Reference

### `stripe_create_customer`

Creates a new Stripe customer object that can be used for recurring billing and payment tracking. Accepts an email address and optional metadata key-value pairs for your own reference. Returns the full customer object including the Stripe customer ID, which you can store for future charges and subscriptions.

### `stripe_create_payment_intent`

Initiates a new payment by creating a PaymentIntent object in Stripe. Specify the amount in the smallest currency unit (e.g., cents for USD) and a three-letter currency code. Optionally attach the payment to an existing customer. Returns a client secret that your frontend uses to confirm the payment.

### `stripe_create_checkout_session`

Generates a Stripe-hosted checkout page for collecting payment details. Configure line items, success and cancel redirect URLs, and optional customer references. Ideal for one-time purchases or subscription signups where you want Stripe to handle the entire payment UI. Returns a session URL to redirect your user to.

### `stripe_retrieve_customer`

Fetches the full customer object from Stripe using a customer ID. Returns all stored information including email, metadata, default payment method, and subscription status. Useful for syncing customer data back to your Xano database or displaying account details.

### `stripe_list_invoices`

Retrieves a paginated list of invoices from your Stripe account. Filter by customer ID to see a specific user's billing history, or list all invoices across your account. Supports cursor-based pagination with a configurable limit. Returns invoice details including amount, status, and line items.

### `stripe_create_subscription`

Sets up a recurring billing subscription by linking a Stripe customer to a price ID. The customer must have a valid payment method on file. Supports trial periods and metadata for tracking. Returns the full subscription object including the current billing period and status.

### `stripe_cancel_subscription`

Cancels an active Stripe subscription by its ID. Choose to cancel immediately for an instant stop, or set it to cancel at the end of the current billing period so the customer retains access until their paid time expires. Returns the updated subscription object reflecting the cancellation status.

### `stripe_verify_webhook`

Validates incoming webhook requests from Stripe by checking the signature header against your webhook secret. Ensures the event was genuinely sent by Stripe and has not been tampered with. Parses the request body into a structured event object containing the event type and associated data. Essential for securely processing payment confirmations, subscription changes, and other Stripe events.

## License

MIT — see [LICENSE](./LICENSE).
