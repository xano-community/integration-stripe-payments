function "stripe_retrieve_customer" {
  description = "Get customer details by Stripe customer ID"
  input {
    text customer_id { description = "Stripe Customer ID (cus_xxx) to retrieve" }
  }
  stack {
    api.request {
      url = "https://api.stripe.com/v1/customers/" ~ $input.customer_id
      method = "GET"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY]
      mock = {
        "retrieves customer successfully": { response: { status: 200, result: { id: "cus_N1abc23def45", object: "customer", email: "jane@example.com", name: "Jane Doe", phone: "+15551234567", metadata: {}, created: 1677000000 } } }
      }
    } as $api_result

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "retrieves customer successfully" {
    input = { customer_id: "cus_N1abc23def45" }
    expect.to_equal ($response.id) { value = "cus_N1abc23def45" }
    expect.to_equal ($response.email) { value = "jane@example.com" }
    expect.to_equal ($response.name) { value = "Jane Doe" }
  }
}