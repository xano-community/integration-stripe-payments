function "stripe_verify_webhook" {
  description = "Verify Stripe webhook signature and parse event payload"
  input {
    text payload { description = "Raw request body from the webhook POST" }
    text signature_header { description = "Value of the Stripe-Signature HTTP header" }
    int tolerance?=300 { description = "Max age of event in seconds (default 300)" }
  }
  stack {
    var $timestamp { value = "" }
    var $signature { value = "" }

    var $parts { value = $input.signature_header|split:"," }
    foreach ($parts) {
      each as $part {
        var $trimmed { value = $part|trim }
        conditional {
          if ($trimmed|starts_with:"t=") {
            var.update $timestamp { value = $trimmed|replace:"t=":"" }
          }
        }
        conditional {
          if ($trimmed|starts_with:"v1=") {
            var.update $signature { value = $trimmed|replace:"v1=":"" }
          }
        }
      }
    }

    precondition ($timestamp != "") {
      error_type = "inputerror"
      error = "Invalid Stripe-Signature header: missing timestamp"
    }

    precondition ($signature != "") {
      error_type = "inputerror"
      error = "Invalid Stripe-Signature header: missing v1 signature"
    }

    var $now {
      value = "now"|to_seconds
      mock = {
        "parses valid webhook event": 9999999999
      }
    }
    var $age { value = $now - ($timestamp|to_int) }

    precondition ($age <= $input.tolerance) {
      error_type = "standard"
      error = "Webhook timestamp too old. Age: " ~ $age ~ " seconds, tolerance: " ~ $input.tolerance ~ " seconds"
    }

    precondition ($age >= 0) {
      error_type = "standard"
      error = "Webhook timestamp is in the future"
    }

    var $signed_payload { value = $timestamp ~ "." ~ $input.payload }
    var $expected_signature {
      value = $signed_payload|hmac_sha256:$env.STRIPE_SIGNING_SECRET
      mock = {
        "parses valid webhook event": "placeholder"
      }
    }

    precondition ($expected_signature == $signature) {
      error_type = "accessdenied"
      error = "Webhook signature verification failed"
    }

    var $result { value = $input.payload|json_decode }
  }
  response = $result

  test "parses valid webhook event" {
    input = { payload: "{\"id\":\"evt_1Nabc\",\"type\":\"payment_intent.succeeded\",\"data\":{\"object\":{\"id\":\"pi_abc123\"}}}", signature_header: "t=9999999999,v1=placeholder", tolerance: 99999999 }
    expect.to_not_be_null ($response.id)
  }
}