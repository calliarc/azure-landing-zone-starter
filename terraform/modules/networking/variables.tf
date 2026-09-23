variable "prefix" {
  description = "Naming prefix for all networking resources."
  type        = string
}

variable "location" {
  description = "Azure region for the hub and spokes."
  type        = string
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "hub_address_space" {
  description = "Address space of the hub virtual network."
  type        = list(string)
  default     = ["10.0.0.0/22"]
}

variable "hub_subnets" {
  description = "Hub subnets. Reserved names (AzureFirewallSubnet, GatewaySubnet) are handled automatically; list shared-services subnets here."
  type        = map(string)
  default = {
    "snet-shared" = "10.0.1.0/24"
  }
}

variable "firewall_subnet_prefix" {
  description = "Address prefix for AzureFirewallSubnet (/26 or larger). Only used when enable_firewall = true."
  type        = string
  default     = "10.0.0.0/26"
}

variable "gateway_subnet_prefix" {
  description = "Address prefix for GatewaySubnet (reserved for a future VPN/ExpressRoute gateway). Set to null to skip."
  type        = string
  default     = "10.0.0.64/27"
}

variable "enable_firewall" {
  description = "Deploy Azure Firewall in the hub and route spoke egress through it."
  type        = bool
  default     = false
}

variable "firewall_sku_tier" {
  description = "Azure Firewall SKU tier."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "firewall_sku_tier must be Standard or Premium."
  }
}

variable "spokes" {
  description = "Spoke virtual networks keyed by short name. Each spoke gets its own resource group, NSG per subnet and peering to the hub."
  type = map(object({
    address_space = list(string)
    subnets       = map(string)
  }))
  default = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for firewall diagnostics. Null disables diagnostics."
  type        = string
  default     = null
}
