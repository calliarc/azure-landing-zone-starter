output "hub_resource_group_name" {
  description = "Name of the connectivity (hub) resource group."
  value       = azurerm_resource_group.hub.name
}

output "hub_vnet_id" {
  description = "Resource ID of the hub virtual network."
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_ids" {
  description = "Map of spoke key to virtual network resource ID."
  value       = { for k, v in azurerm_virtual_network.spoke : k => v.id }
}

output "firewall_private_ip" {
  description = "Private IP of Azure Firewall (null when disabled)."
  value       = var.enable_firewall ? azurerm_firewall.this[0].ip_configuration[0].private_ip_address : null
}
