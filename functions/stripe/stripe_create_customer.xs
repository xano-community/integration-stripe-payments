function "stripe_create_customer" {
  description = "Create a new Stripe customer with email and metadata"
  input {
    email email? { description = "Customer email address" }
    text name? { description = "Customer full name or business name" }
    text description? { description = "Internal description for the customer" }
    text phone? { description = "Customer phone number" }
    json metadata? { description = "Key-value pairs of additional data" }
    text payment_method? { description = "PaymentMethod ID to attach to this customer" }
  }
  stack {
    var $params { value = {} }
    var.update $params { value = $params|set_ifnotempty:"email":$input.email }
    var.update $params { value = $params|set_ifnotempty:"name":$input.name }
    var.update $params { value = $params|set_ifnotempty:"description":$input.description }
    var.update $params { value = $params|set_ifnotempty:"phone":$input.phone }
    var.update $params { value = $params|set_ifnotempty:"metadata":$input.metadata }
    var.update $params { value = $params|set_ifnotempty:"payment_method":$input.payment_method }

    api.request {
      url = "https://api.stripe.com/v1/customers"
      method = "POST"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY, "Content-Type: application/x-www-form-urlencoded"]
      params = $params
      mock = {
        "creates customer successfully": { response: { status: 200, result: { id: "cus_N1abc23def45", object: "customer", email: "jane@example.com", name: "Jane Doe", phone: null, metadata: {}, created: 1677000000 } } }
      }
    } as $api_result

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "creates customer successfully" {
    input = { email: "jane@example.com", name: "Jane Doe" }
    expect.to_equal ($response.id) { value = "cus_N1abc23def45" }
    expect.to_equal ($response.email) { value = "jane@example.com" }
  }
}