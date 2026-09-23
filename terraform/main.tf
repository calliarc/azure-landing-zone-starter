data "azurerm_client_config" "current" {}

locals {
  subscription_id = coalesce(var.subscription_id, data.azurerm_client_config.current.subscription_id)
}

module "management_groups" {
  source = "./modules/management-groups"

  prefix                     = var.prefix
  root_display_name          = var.organization_name
  parent_management_group_id = var.parent_management_group_id
  subscription_placements    = var.subscription_placements
}

module "policy" {
  source = "./modules/policy"

  management_group_id       = module.management_groups.root_id
  location                  = var.location
  allowed_locations         = var.allowed_locations
  required_tags             = var.required_tags
  enforcement_mode          = var.policy_enforcement
  assign_security_benchmark = var.assign_security_benchmark
}

module "logging" {
  source = "./modules/logging"

  prefix                 = var.prefix
  location               = var.location
  tags                   = var.tags
  subscription_id        = local.subscription_id
  retention_in_days      = var.log_retention_in_days
  daily_quota_gb         = var.log_daily_quota_gb
  defender_plans         = var.defender_plans
  security_contact_email = var.security_contact_email
}

module "networking" {
  source = "./modules/networking"

  prefix                     = var.prefix
  location                   = var.location
  tags                       = var.tags
  hub_address_space          = var.hub_address_space
  hub_subnets                = var.hub_subnets
  firewall_subnet_prefix     = var.firewall_subnet_prefix
  gateway_subnet_prefix      = var.gateway_subnet_prefix
  enable_firewall            = var.enable_firewall
  firewall_sku_tier          = var.firewall_sku_tier
  spokes                     = var.spokes
  log_analytics_workspace_id = module.logging.workspace_id
}

module "budget" {
  source = "./modules/budgets"

  name            = "budget-${var.prefix}-platform-monthly"
  subscription_id = local.subscription_id
  amount          = var.budget_amount
  start_date      = var.budget_start_date
  contact_emails  = var.budget_contact_emails
}
