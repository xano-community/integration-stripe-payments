function "stripe_list_invoices" {
  description = "List invoices for a customer with pagination"
  input {
    text customer? { description = "Filter by Customer ID (cus_xxx)" }
    text status? { description = "Filter by status: draft, open, paid, uncollectible, or void" }
    int limit?=10 { description = "Number of invoices to return (1-100, default 10)" }
    text starting_after? { description = "Cursor for pagination - pass last invoice ID from previous page" }
  }
  stack {
    var $params { value = {} }
    var.update $params { value = $params|set_ifnotempty:"customer":$input.customer }
    var.update $params { value = $params|set_ifnotempty:"status":$input.status }
    var.update $params { value = $params|set_ifnotempty:"limit":$input.limit }
    var.update $params { value = $params|set_ifnotempty:"starting_after":$input.starting_after }

    api.request {
      url = "https://api.stripe.com/v1/invoices"
      method = "GET"
      headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY]
      params = $params
      mock = {
        "lists invoices successfully": { response: { status: 200, result: { object: "list", has_more: false, data: [{ id: "in_1Nabc2DefGhi3", object: "invoice", customer: "cus_N1abc23def45", amount_due: 5000, currency: "usd", status: "paid" }] } } }
      }
    } as $api_result

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "lists invoices successfully" {
    input = { customer: "cus_N1abc23def45" }
    expect.to_equal ($response.object) { value = "list" }
    expect.to_be_false ($response.has_more)
    expect.to_not_be_null ($response.data)
  }
}