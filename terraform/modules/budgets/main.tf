locals {
  start_date = coalesce(var.start_date, formatdate("YYYY-MM-01'T'00:00:00Z", timestamp()))

  notifications = concat(
    [for t in var.actual_thresholds : { threshold = t, type = "Actual" }],
    [for t in var.forecast_thresholds : { threshold = t, type = "Forecasted" }],
  )
}

resource "azurerm_consumption_budget_subscription" "this" {
  name            = var.name
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.amount
  time_grain      = "Monthly"

  time_period {
    start_date = local.start_date
  }

  dynamic "filter" {
    for_each = var.filter_tag == null ? [] : [var.filter_tag]
    content {
      tag {
        name   = filter.value.name
        values = filter.value.values
      }
    }
  }

  dynamic "notification" {
    for_each = local.notifications
    content {
      enabled        = true
      threshold      = notification.value.threshold
      threshold_type = notification.value.type
      operator       = "GreaterThanOrEqualTo"
      contact_emails = var.contact_emails
    }
  }

  lifecycle {
    # timestamp() changes on every run; the start date is only relevant at creation.
    ignore_changes = [time_period]
  }
}
