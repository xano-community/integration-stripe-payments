function "stripe_create_checkout_session" {
  description = "Create a Stripe Checkout session for hosted payment page"
  input {
    text mode { description = "Session mode: payment, subscription, or setup" }
    json line_items { description = "Array of items with price and quantity. E.g. [{price: 'price_xxx', quantity: 1}]" }
    text success_url { description = "URL to redirect after successful payment" }
    text cancel_url? { description = "URL to redirect if customer cancels" }
    text customer? { description = "Existing Customer ID (cus_xxx) to prefill and associate" }
    email customer_email? { description = "Prefill customer email. Cannot use with customer param" }
    json metadata? { description = "Key-value pairs of additional data" }
    bool allow_promotion_codes? { description = "Enable promo code entry at checkout" }
    text client_reference_id? { description = "Unique reference for reconciliation" }
    int trial_period_days? { description = "Trial days before first charge (subscription mode only)" }
  }
  stack {
    var $params {
      value = {
        mode: $input.mode,
        success_url: $input.success_url,
        line_items: $input.line_items
      }
    }

    var.update $params { value = $params|set_ifnotempty:"cancel_url":$input.cancel_url }
    var.update $params { value = $params|set_ifnotempty:"customer":$input.customer }
    var.update $params { value = $params|set_ifnotempty:"customer_email":$input.customer_email }
    var.update $params { value = $params|set_ifnotempty:"metadata":$input.metadata }
    conditional {
      if ($input.allow_promotion_codes == true) {
        var.update $params { value = $params|set:"allow_promotion_codes":"true" }
      }
    }
    var.update $params { value = $params|set_ifnotempty:"client_reference_id":$input.client_reference_id }
    var.update $params { value = $params|set_ifnotempty:"subscription_data[trial_period_days]":$input.trial_period_days }

    api.request {
      url = "https://api.stripe.com/v1/checkout/sessions"
      method = "POST"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY, "Content-Type: application/x-www-form-urlencoded"]
      params = $params
      mock = {
        "creates checkout session successfully": { response: { status: 200, result: { id: "cs_test_a1b2c3d4e5", object: "checkout.session", url: "https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5", mode: "payment", status: "open", success_url: "https://example.com/success", cancel_url: "https://example.com/cancel", created: 1677000000 } } }
      }
    } as $api_result

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "creates checkout session successfully" {
    input = { mode: "payment", line_items: [{ price: "price_1Nabc", quantity: 1 }], success_url: "https://example.com/success" }
    expect.to_not_be_null ($response.id)
    expect.to_not_be_null ($response.url)
    expect.to_equal ($response.status) { value = "open" }
  }
}