output "resource_group_name" {
  description = "Name of the management resource group."
  value       = azurerm_resource_group.management.name
}

output "workspace_id" {
  description = "Resource ID of the central Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}
