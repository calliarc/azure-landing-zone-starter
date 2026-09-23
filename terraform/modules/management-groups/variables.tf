variable "prefix" {
  description = "Short organisation prefix used for management group names and IDs (e.g. \"contoso\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,20}$", var.prefix))
    error_message = "prefix must be 2-20 characters of lowercase letters, digits or hyphens."
  }
}

variable "root_display_name" {
  description = "Display name of the top-level (intermediate root) management group."
  type        = string
}

variable "parent_management_group_id" {
  description = "Resource ID of the parent management group. Leave null to create directly under the tenant root group."
  type        = string
  default     = null
}

variable "subscription_placements" {
  description = "Map of subscription ID (GUID) to the key of the management group it should be moved into (platform, landingzones, sandbox or decommissioned)."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for mg in values(var.subscription_placements) : contains(["platform", "landingzones", "sandbox", "decommissioned"], mg)])
    error_message = "Each placement value must be one of: platform, landingzones, sandbox, decommissioned."
  }
}
