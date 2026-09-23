# SMB-sized management group hierarchy:
#
#   Tenant Root Group
#   └── <prefix>                (intermediate root, policies assigned here)
#       ├── <prefix>-platform       (connectivity, management, identity)
#       ├── <prefix>-landingzones   (workload subscriptions)
#       ├── <prefix>-sandbox        (experimentation, relaxed guardrails)
#       └── <prefix>-decommissioned (subscriptions pending cancellation)

locals {
  children = {
    platform       = "Platform"
    landingzones   = "Landing Zones"
    sandbox        = "Sandbox"
    decommissioned = "Decommissioned"
  }
}

resource "azurerm_management_group" "root" {
  name                       = var.prefix
  display_name               = var.root_display_name
  parent_management_group_id = var.parent_management_group_id
}

resource "azurerm_management_group" "child" {
  for_each = local.children

  name                       = "${var.prefix}-${each.key}"
  display_name               = each.value
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group_subscription_association" "this" {
  for_each = var.subscription_placements

  management_group_id = azurerm_management_group.child[each.value].id
  subscription_id     = "/subscriptions/${each.key}"
}
