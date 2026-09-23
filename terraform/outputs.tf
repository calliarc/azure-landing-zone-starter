output "management_group_root_id" {
  description = "Resource ID of the intermediate root management group."
  value       = module.management_groups.root_id
}

output "management_group_ids" {
  description = "Child management group IDs."
  value       = module.management_groups.ids
}

output "log_analytics_workspace_id" {
  description = "Central Log Analytics workspace ID."
  value       = module.logging.workspace_id
}

output "hub_vnet_id" {
  description = "Hub virtual network ID."
  value       = module.networking.hub_vnet_id
}

output "spoke_vnet_ids" {
  description = "Spoke virtual network IDs."
  value       = module.networking.spoke_vnet_ids
}

output "firewall_private_ip" {
  description = "Azure Firewall private IP (null when disabled)."
  value       = module.networking.firewall_private_ip
}

output "policy_assignment_ids" {
  description = "Baseline policy assignment IDs."
  value       = module.policy.assignment_ids
}
