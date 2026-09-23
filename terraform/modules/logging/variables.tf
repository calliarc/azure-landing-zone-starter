variable "prefix" {
  description = "Naming prefix."
  type        = string
}

variable "location" {
  description = "Region for the management resource group and workspace."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "subscription_id" {
  description = "Subscription ID (GUID) whose Activity Log and Defender plans are configured."
  type        = string
}

variable "retention_in_days" {
  description = "Log Analytics retention in days (30-730)."
  type        = number
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB to protect against runaway cost. -1 means unlimited."
  type        = number
  default     = -1
}

variable "defender_plans" {
  description = "Defender for Cloud plans keyed by resource type, value is the tier (Free or Standard). Standard plans incur cost."
  type        = map(string)
  default = {
    CloudPosture    = "Free"
    VirtualMachines = "Free"
    StorageAccounts = "Free"
    KeyVaults       = "Free"
    Arm             = "Free"
  }

  validation {
    condition     = alltrue([for t in values(var.defender_plans) : contains(["Free", "Standard"], t)])
    error_message = "Defender plan tiers must be Free or Standard."
  }
}

variable "security_contact_email" {
  description = "Email address that receives Defender for Cloud security alerts."
  type        = string
}
