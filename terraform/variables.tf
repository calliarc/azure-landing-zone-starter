variable "subscription_id" {
  description = "Subscription ID (GUID) for the platform subscription that hosts hub networking and logging. Null uses ARM_SUBSCRIPTION_ID."
  type        = string
  default     = null
}

variable "prefix" {
  description = "Short organisation prefix (lowercase, 2-10 chars) used in every resource name."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.prefix))
    error_message = "prefix must be 2-10 lowercase letters or digits."
  }
}

variable "organization_name" {
  description = "Human-readable organisation name, used for the root management group display name."
  type        = string
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "westeurope"
}

variable "allowed_locations" {
  description = "Regions permitted by policy. Should include var.location."
  type        = list(string)
  default     = ["westeurope", "northeurope"]
}

variable "tags" {
  description = "Cost-allocation tags applied to every resource. Keys should cover var.required_tags."
  type        = map(string)
}

variable "required_tags" {
  description = "Tag names enforced by policy on resource groups (and inherited by resources)."
  type        = list(string)
  default     = ["CostCenter", "Environment", "Owner"]
}

variable "parent_management_group_id" {
  description = "Parent management group resource ID. Null places the hierarchy under the tenant root group."
  type        = string
  default     = null
}

variable "subscription_placements" {
  description = "Map of subscription ID to management group key (platform, landingzones, sandbox, decommissioned)."
  type        = map(string)
  default     = {}
}

variable "policy_enforcement" {
  description = "false assigns every policy in DoNotEnforce (audit-only) mode."
  type        = bool
  default     = true
}

variable "assign_security_benchmark" {
  description = "Assign the Microsoft cloud security benchmark initiative."
  type        = bool
  default     = true
}

variable "hub_address_space" {
  description = "Hub virtual network address space."
  type        = list(string)
  default     = ["10.0.0.0/22"]
}

variable "hub_subnets" {
  description = "Hub shared-services subnets (name => prefix)."
  type        = map(string)
  default = {
    "snet-shared" = "10.0.1.0/24"
  }
}

variable "firewall_subnet_prefix" {
  description = "AzureFirewallSubnet prefix (/26)."
  type        = string
  default     = "10.0.0.0/26"
}

variable "gateway_subnet_prefix" {
  description = "GatewaySubnet prefix reserved for a future VPN gateway. Null to skip."
  type        = string
  default     = "10.0.0.64/27"
}

variable "enable_firewall" {
  description = "Deploy Azure Firewall in the hub (adds significant monthly cost)."
  type        = bool
  default     = false
}

variable "firewall_sku_tier" {
  description = "Azure Firewall tier: Standard or Premium."
  type        = string
  default     = "Standard"
}

variable "spokes" {
  description = "Spoke virtual networks keyed by short name."
  type = map(object({
    address_space = list(string)
    subnets       = map(string)
  }))
  default = {}
}

variable "log_retention_in_days" {
  description = "Log Analytics retention in days."
  type        = number
  default     = 90
}

variable "log_daily_quota_gb" {
  description = "Log Analytics daily cap in GB (-1 = unlimited)."
  type        = number
  default     = -1
}

variable "defender_plans" {
  description = "Defender for Cloud plan tiers keyed by resource type (Free or Standard)."
  type        = map(string)
  default = {
    CloudPosture    = "Free"
    VirtualMachines = "Free"
    StorageAccounts = "Free"
    KeyVaults       = "Free"
    Arm             = "Free"
  }
}

variable "security_contact_email" {
  description = "Email for Defender for Cloud alerts."
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget for the platform subscription in billing currency."
  type        = number
  default     = 500
}

variable "budget_contact_emails" {
  description = "Recipients of budget alerts."
  type        = list(string)
}

variable "budget_start_date" {
  description = "Budget start date (first of month, RFC3339). Null uses the current month."
  type        = string
  default     = null
}
