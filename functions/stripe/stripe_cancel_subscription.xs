function "stripe_cancel_subscription" {
  description = "Cancel an active subscription immediately or at period end"
  input {
    text subscription_id { description = "Subscription ID (sub_xxx) to cancel" }
    bool at_period_end?=false { description = "If true, cancel at end of billing period. If false, cancel immediately" }
    text cancellation_comment? { description = "Additional comments about the cancellation" }
    text cancellation_feedback? { description = "Reason: customer_service, low_quality, missing_features, other, switched_service, too_complex, too_expensive, unused" }
  }
  stack {
    var $params { value = {} }
    var.update $params { value = $params|set_ifnotempty:"cancellation_details[comment]":$input.cancellation_comment }
    var.update $params { value = $params|set_ifnotempty:"cancellation_details[feedback]":$input.cancellation_feedback }

    conditional {
      if ($input.at_period_end == true) {
        var.update $params { value = $params|set:"cancel_at_period_end":"true" }

        api.request {
          url = "https://api.stripe.com/v1/subscriptions/" ~ $input.subscription_id
          method = "POST"
          headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY, "Content-Type: application/x-www-form-urlencoded"]
          params = $params
          mock = {
            "cancels subscription at period end": { response: { status: 200, result: { id: "sub_1Nabc2DefGhi3", object: "subscription", status: "active", cancel_at_period_end: true, canceled_at: 1677000000, current_period_end: 1679592000 } } }
          }
        } as $api_result
      }
      else {
        api.request {
          url = "https://api.stripe.com/v1/subscriptions/" ~ $input.subscription_id
          method = "DELETE"
          headers = ["Authorization: Bearer " ~ $env.STRIPE_API_KEY, "Content-Type: application/x-www-form-urlencoded"]
          params = $params
          mock = {
            "cancels subscription at period end": { response: { status: 200, result: { id: "sub_1Nabc2DefGhi3", object: "subscription", status: "active", cancel_at_period_end: true, canceled_at: 1677000000, current_period_end: 1679592000 } } }
          }
        } as $api_result
      }
    }

    precondition ($api_result.response.status == 200) {
      error_type = "standard"
      error = "Stripe API error: " ~ ($api_result.response.result|json_encode)
    }

    var $result { value = $api_result.response.result }
  }
  response = $result

  test "cancels subscription at period end" {
    input = { subscription_id: "sub_1Nabc2DefGhi3", at_period_end: true }
    expect.to_equal ($response.id) { value = "sub_1Nabc2DefGhi3" }
    expect.to_be_true ($response.cancel_at_period_end)
  }
}