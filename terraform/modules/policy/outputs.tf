output "assignment_ids" {
  description = "IDs of all baseline policy assignments."
  value = concat(
    [
      azurerm_management_group_policy_assignment.allowed_locations.id,
      azurerm_management_group_policy_assignment.allowed_locations_rg.id,
    ],
    [for a in azurerm_management_group_policy_assignment.require_tag_rg : a.id],
    [for a in azurerm_management_group_policy_assignment.inherit_tag : a.id],
    [for a in azurerm_management_group_policy_assignment.secure_defaults : a.id],
    [for a in azurerm_management_group_policy_assignment.mcsb : a.id],
  )
}
