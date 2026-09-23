variable "name" {
  description = "Budget name."
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID (GUID) the budget applies to."
  type        = string
}

variable "amount" {
  description = "Monthly budget amount in the billing currency."
  type        = number
}

variable "start_date" {
  description = "Budget start date (first day of a month, RFC3339, e.g. 2026-01-01T00:00:00Z). Null uses the first day of the current month."
  type        = string
  default     = null
}

variable "contact_emails" {
  description = "Email addresses notified when thresholds are reached."
  type        = list(string)
}

variable "actual_thresholds" {
  description = "Percent-of-budget thresholds that alert on actual spend."
  type        = list(number)
  default     = [50, 80, 100]
}

variable "forecast_thresholds" {
  description = "Percent-of-budget thresholds that alert on forecasted spend."
  type        = list(number)
  default     = [100]
}

variable "filter_tag" {
  description = "Optional tag filter (e.g. { name = \"CostCenter\", values = [\"1234\"] }) to scope the budget to cost-allocation tags."
  type = object({
    name   = string
    values = list(string)
  })
  default = null
}
