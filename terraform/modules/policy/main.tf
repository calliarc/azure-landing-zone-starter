# Baseline Azure Policy assignments. All definitions are built-in and are
# referenced by their stable GUID name; the data sources fail at plan time if
# a definition is ever removed from Azure.

locals {
  builtin = {
    allowed_locations       = "e56962a6-4747-49cd-b67b-bf8b01975c4c" # Allowed locations
    allowed_locations_rg    = "e765b5de-1225-4ba3-bd56-1ac6695af988" # Allowed locations for resource groups
    require_tag_rg          = "96670d01-0a4d-4649-9c89-2d3abc0a5025" # Require a tag on resource groups
    inherit_tag_rg          = "ea3f2387-9b95-492a-a190-fcdc54f7b070" # Inherit a tag from the resource group if missing
    storage_secure_transfer = "404c3081-a854-4457-ae30-26a93ef643f9" # Secure transfer to storage accounts should be enabled
    storage_no_public_blob  = "4fa4b6c0-31ca-4c0d-b10d-24b96f62a751" # Storage account public access should be disallowed
    appservice_https_only   = "a4af4a39-4135-47fb-b175-47fbdf85311d" # App Service apps should only be accessible over HTTPS
    keyvault_soft_delete    = "1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d" # Key vaults should have soft delete enabled
    vm_managed_disks        = "06a78e20-9358-41c9-923c-fb736d382a4d" # Audit VMs that do not use managed disks
  }

  # Secure-default policies that only take an optional "effect" parameter.
  # Map of assignment name => key in local.builtin.
  secure_defaults = {
    "sec-storage-https"  = "storage_secure_transfer"
    "sec-storage-public" = "storage_no_public_blob"
    "sec-app-https"      = "appservice_https_only"
    "sec-kv-softdelete"  = "keyvault_soft_delete"
    "sec-vm-mdisks"      = "vm_managed_disks"
  }

  microsoft_cloud_security_benchmark = "1f3afdf9-d0c9-4c3d-847f-89da613e70a8"
}

data "azurerm_policy_definition" "builtin" {
  for_each = local.builtin
  name     = each.value
}

data "azurerm_policy_set_definition" "mcsb" {
  count = var.assign_security_benchmark ? 1 : 0
  name  = local.microsoft_cloud_security_benchmark
}

# --- Allowed regions ---------------------------------------------------------

resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  display_name         = "Allowed locations"
  management_group_id  = var.management_group_id
  policy_definition_id = data.azurerm_policy_definition.builtin["allowed_locations"].id
  enforce              = var.enforcement_mode

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })

  non_compliance_message {
    content = "Resources must be deployed to an approved region: ${join(", ", var.allowed_locations)}."
  }
}

resource "azurerm_management_group_policy_assignment" "allowed_locations_rg" {
  name                 = "allowed-locations-rg"
  display_name         = "Allowed locations for resource groups"
  management_group_id  = var.management_group_id
  policy_definition_id = data.azurerm_policy_definition.builtin["allowed_locations_rg"].id
  enforce              = var.enforcement_mode

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# --- Required cost-allocation tags ------------------------------------------

resource "azurerm_management_group_policy_assignment" "require_tag_rg" {
  for_each = toset(var.required_tags)

  name                 = substr("req-rg-tag-${lower(each.value)}", 0, 24)
  display_name         = "Require tag '${each.value}' on resource groups"
  management_group_id  = var.management_group_id
  policy_definition_id = data.azurerm_policy_definition.builtin["require_tag_rg"].id
  enforce              = var.enforcement_mode

  parameters = jsonencode({
    tagName = { value = each.value }
  })

  non_compliance_message {
    content = "Resource groups must carry the '${each.value}' tag for cost allocation."
  }
}

resource "azurerm_management_group_policy_assignment" "inherit_tag" {
  for_each = toset(var.required_tags)

  name                 = substr("inh-tag-${lower(each.value)}", 0, 24)
  display_name         = "Inherit tag '${each.value}' from resource group"
  management_group_id  = var.management_group_id
  policy_definition_id = data.azurerm_policy_definition.builtin["inherit_tag_rg"].id
  enforce              = var.enforcement_mode
  location             = var.location

  parameters = jsonencode({
    tagName = { value = each.value }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "inherit_tag" {
  for_each = azurerm_management_group_policy_assignment.inherit_tag

  # Contributor is the role declared by the built-in Modify policy for remediation.
  scope                = var.management_group_id
  role_definition_name = "Contributor"
  principal_id         = each.value.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# --- Secure defaults ---------------------------------------------------------

resource "azurerm_management_group_policy_assignment" "secure_defaults" {
  for_each = local.secure_defaults

  name                 = each.key
  display_name         = data.azurerm_policy_definition.builtin[each.value].display_name
  management_group_id  = var.management_group_id
  policy_definition_id = data.azurerm_policy_definition.builtin[each.value].id
  enforce              = var.enforcement_mode
}

resource "azurerm_management_group_policy_assignment" "mcsb" {
  count = var.assign_security_benchmark ? 1 : 0

  name                 = "mcsb-audit"
  display_name         = "Microsoft cloud security benchmark"
  management_group_id  = var.management_group_id
  policy_definition_id = data.azurerm_policy_set_definition.mcsb[0].id
  enforce              = var.enforcement_mode
}
