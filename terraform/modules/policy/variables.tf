variable "management_group_id" {
  description = "Resource ID of the management group the baseline policies are assigned to."
  type        = string
}

variable "location" {
  description = "Region for the managed identity used by Modify/DeployIfNotExists assignments."
  type        = string
}

variable "allowed_locations" {
  description = "Azure regions where resources and resource groups may be created."
  type        = list(string)
}

variable "required_tags" {
  description = "Tag names that must be present on every resource group. Resources inherit missing values from their resource group."
  type        = list(string)
  default     = ["CostCenter", "Environment", "Owner"]
}

variable "enforcement_mode" {
  description = "Set to false to assign all policies in DoNotEnforce (audit-only) mode for a dry run."
  type        = bool
  default     = true
}

variable "assign_security_benchmark" {
  description = "Assign the Microsoft cloud security benchmark initiative (audit) to the management group."
  type        = bool
  default     = true
}
