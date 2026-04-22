function "stripe_create_subscription" {
  description = "Create a recurring subscription for a customer and price"
  input {
    text customer { description = "Customer ID (cus_xxx) to create the subscription for" }
    json items { description = "Array of subscription items. E.g. [{price: 'price_xxx', quantity: 1}]" }
    text default_payment_method? { description = "PaymentMethod ID (pm_xxx) for invoice payments" }
    int trial_period_days? { description = "Number of trial days before first charge" }
    json metadata? { description = "Key-value pairs of additional data" }
    text payment_behavior?="default_incomplete" { description = "Behavior on first payment failure" }
    text description? { description = "Description displayed to the customer" }
  }
  stack {
    var $params {
      value = {
        customer: $input.customer,
        items: $input.items
      }
    }

    var.update $params { value = $params|set_ifnotempty:"default_payment_method":$input.default_payment_method }
    var.update $params { value = $params|set_ifnotempty:"trial_period_days":$input.trial_period_days }
    var.update $params { value = $params|set_ifnotempty:"metadata":$input.metadata }
    var.update $params { value = $params|set_ifnotempty:"payment_behavior":$input.payment_behavior }
    var.update $params { value = $params|set_ifnotempty:"description":$input.description }

    api.request {
      url = "https://api.stripe.com/v1/subscriptions"
      method = "POST"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY, "Content-Type: application/x-www-form-urlencoded"]
      params = $params
      mock = {
        "creates subscription successfully": { response: { status: 200, result: { id: "sub_1Nabc2DefGhi3", object: "subscription", customer: "cus_N1abc23def45", status: "active", current_period_start: 1677000000, current_period_end: 1679592000, items: { data: [{ id: "si_abc123", price: { id: "price_1Nabc", unit_amount: 2000, currency: "usd" } }] } } } }
      }
    } as $api_result

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "creates subscription successfully" {
    input = { customer: "cus_N1abc23def45", items: [{ price: "price_1Nabc", quantity: 1 }] }
    expect.to_equal ($response.id) { value = "sub_1Nabc2DefGhi3" }
    expect.to_equal ($response.status) { value = "active" }
    expect.to_equal ($response.customer) { value = "cus_N1abc23def45" }
  }
}