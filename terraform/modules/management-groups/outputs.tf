output "root_id" {
  description = "Resource ID of the intermediate root management group."
  value       = azurerm_management_group.root.id
}

output "root_name" {
  description = "Name of the intermediate root management group."
  value       = azurerm_management_group.root.name
}

output "ids" {
  description = "Map of child management group key to resource ID."
  value       = { for k, mg in azurerm_management_group.child : k => mg.id }
}
