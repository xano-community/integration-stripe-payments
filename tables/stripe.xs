table "stripe_data" {
  auth = false
  schema {
    int id
    int user_id { table = "user", description = "Reference to local user" }
    text stripe_customer_id? { description = "Stripe Customer ID (cus_xxx)" }
    text event_id? { description = "Stripe webhook event ID (evt_xxx) for idempotency" }
    text event_type? { description = "Stripe event type (e.g. payment_intent.succeeded)" }
    json event_data? { description = "Full event payload from webhook" }
    timestamp created_at?=now
  }
  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "user_id"}]}
    {type: "btree|unique", field: [{name: "stripe_customer_id"}]}
    {type: "btree|unique", field: [{name: "event_id"}]}
  ]
}