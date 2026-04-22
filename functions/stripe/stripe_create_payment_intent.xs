function "stripe_create_payment_intent" {
  description = "Create a payment intent for a given amount and currency"
  input {
    int amount { description = "Amount in smallest currency unit (e.g. cents). Must be positive" }
    text currency { description = "Three-letter ISO currency code in lowercase (e.g. usd, eur)" }
    text customer? { description = "Stripe Customer ID (cus_xxx) to associate with this payment" }
    text payment_method? { description = "PaymentMethod ID to attach" }
    bool confirm? { description = "If true, confirms the intent immediately" }
    text description? { description = "Arbitrary string for internal use" }
    json metadata? { description = "Key-value pairs of additional data" }
    email receipt_email? { description = "Email to send payment receipt to" }
    text capture_method? { description = "When to capture: automatic (default), automatic_async, or manual" }
    text setup_future_usage? { description = "Save payment method for future: on_session or off_session" }
  }
  stack {
    var $params {
      value = {
        amount: $input.amount,
        currency: $input.currency,
        "automatic_payment_methods[enabled]": "true"
      }
    }
    var.update $params { value = $params|set_ifnotempty:"customer":$input.customer }
    var.update $params { value = $params|set_ifnotempty:"payment_method":$input.payment_method }
    conditional {
      if ($input.confirm == true) {
        var.update $params { value = $params|set:"confirm":"true" }
      }
    }
    var.update $params { value = $params|set_ifnotempty:"description":$input.description }
    var.update $params { value = $params|set_ifnotempty:"metadata":$input.metadata }
    var.update $params { value = $params|set_ifnotempty:"receipt_email":$input.receipt_email }
    var.update $params { value = $params|set_ifnotempty:"capture_method":$input.capture_method }
    var.update $params { value = $params|set_ifnotempty:"setup_future_usage":$input.setup_future_usage }

    api.request {
      url = "https://api.stripe.com/v1/payment_intents"
      method = "POST"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY, "Content-Type: application/x-www-form-urlencoded"]
      params = $params
      mock = {
        "creates payment intent successfully": { response: { status: 200, result: { id: "pi_3Nab1cDef2gHi3j", object: "payment_intent", amount: 5000, currency: "usd", status: "requires_payment_method", client_secret: "pi_3Nab1cDef2gHi3j_secret_xyz", created: 1677000000 } } }
      }
    } as $api_result

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "creates payment intent successfully" {
    input = { amount: 5000, currency: "usd" }
    expect.to_equal ($response.id) { value = "pi_3Nab1cDef2gHi3j" }
    expect.to_equal ($response.amount) { value = 5000 }
    expect.to_equal ($response.currency) { value = "usd" }
  }
}