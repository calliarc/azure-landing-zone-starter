locals {
  spoke_subnets = merge([
    for spoke_key, spoke in var.spokes : {
      for subnet_name, prefix in spoke.subnets :
      "${spoke_key}/${subnet_name}" => {
        spoke  = spoke_key
        name   = subnet_name
        prefix = prefix
      }
    }
  ]...)
}

# ---------------------------------------------------------------------------
# Hub
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.prefix}-connectivity-${var.location}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.prefix}-hub-${var.location}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = var.hub_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "hub" {
  for_each = var.hub_subnets

  name                 = each.key
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "hub" {
  for_each = var.hub_subnets

  name                = "nsg-${var.prefix}-hub-${each.key}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "hub" {
  for_each = var.hub_subnets

  subnet_id                 = azurerm_subnet.hub[each.key].id
  network_security_group_id = azurerm_network_security_group.hub[each.key].id
}

resource "azurerm_subnet" "gateway" {
  count = var.gateway_subnet_prefix == null ? 0 : 1

  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.gateway_subnet_prefix]
}

# ---------------------------------------------------------------------------
# Optional Azure Firewall
# ---------------------------------------------------------------------------

resource "azurerm_subnet" "firewall" {
  count = var.enable_firewall ? 1 : 0

  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.firewall_subnet_prefix]
}

resource "azurerm_public_ip" "firewall" {
  count = var.enable_firewall ? 1 : 0

  name                = "pip-${var.prefix}-afw-${var.location}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}

resource "azurerm_firewall_policy" "this" {
  count = var.enable_firewall ? 1 : 0

  name                     = "afwp-${var.prefix}-${var.location}"
  location                 = azurerm_resource_group.hub.location
  resource_group_name      = azurerm_resource_group.hub.name
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Deny"
  tags                     = var.tags

  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall" "this" {
  count = var.enable_firewall ? 1 : 0

  name                = "afw-${var.prefix}-${var.location}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  firewall_policy_id  = azurerm_firewall_policy.this[0].id
  zones               = ["1", "2", "3"]
  tags                = var.tags

  ip_configuration {
    name                 = "ipconfig"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count = var.enable_firewall && var.log_analytics_workspace_id != null ? 1 : 0

  name                           = "diag-to-law"
  target_resource_id             = azurerm_firewall.this[0].id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "allLogs"
  }
}

# ---------------------------------------------------------------------------
# Spokes
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "spoke" {
  for_each = var.spokes

  name     = "rg-${var.prefix}-${each.key}-network-${var.location}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  for_each = var.spokes

  name                = "vnet-${var.prefix}-${each.key}-${var.location}"
  location            = azurerm_resource_group.spoke[each.key].location
  resource_group_name = azurerm_resource_group.spoke[each.key].name
  address_space       = each.value.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "spoke" {
  for_each = local.spoke_subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.spoke[each.value.spoke].name
  virtual_network_name = azurerm_virtual_network.spoke[each.value.spoke].name
  address_prefixes     = [each.value.prefix]
}

resource "azurerm_network_security_group" "spoke" {
  for_each = local.spoke_subnets

  name                = "nsg-${var.prefix}-${each.value.spoke}-${each.value.name}"
  location            = azurerm_resource_group.spoke[each.value.spoke].location
  resource_group_name = azurerm_resource_group.spoke[each.value.spoke].name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = local.spoke_subnets

  subnet_id                 = azurerm_subnet.spoke[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each = var.spokes

  name                         = "peer-hub-to-${each.key}"
  resource_group_name          = azurerm_resource_group.hub.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke[each.key].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each = var.spokes

  name                         = "peer-${each.key}-to-hub"
  resource_group_name          = azurerm_resource_group.spoke[each.key].name
  virtual_network_name         = azurerm_virtual_network.spoke[each.key].name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# Force spoke egress through the firewall when it is enabled.
resource "azurerm_route_table" "spoke" {
  for_each = { for k, v in var.spokes : k => v if var.enable_firewall }

  name                          = "rt-${var.prefix}-${each.key}-${var.location}"
  location                      = azurerm_resource_group.spoke[each.key].location
  resource_group_name           = azurerm_resource_group.spoke[each.key].name
  bgp_route_propagation_enabled = false
  tags                          = var.tags

  route {
    name                   = "default-via-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.this[0].ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "spoke" {
  for_each = { for k, v in local.spoke_subnets : k => v if var.enable_firewall }

  subnet_id      = azurerm_subnet.spoke[each.key].id
  route_table_id = azurerm_route_table.spoke[each.value.spoke].id
}
