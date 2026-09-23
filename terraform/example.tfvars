# Example values - copy to terraform.tfvars (git-ignored) and edit.
# All IDs and emails below are placeholders.

# subscription_id = "00000000-0000-0000-0000-000000000000" # or export ARM_SUBSCRIPTION_ID

prefix            = "contoso"
organization_name = "Contoso"
location          = "westeurope"
allowed_locations = ["westeurope", "northeurope"]

tags = {
  CostCenter  = "IT-0000"
  Environment = "platform"
  Owner       = "cloud-team@example.com"
  ManagedBy   = "terraform"
}

required_tags = ["CostCenter", "Environment", "Owner"]

# Move subscriptions into the new hierarchy (subscription GUID => management group key).
subscription_placements = {
  # "00000000-0000-0000-0000-000000000000" = "platform"
  # "11111111-1111-1111-1111-111111111111" = "landingzones"
}

# Start with audit-only to review impact, then flip to true.
policy_enforcement        = false
assign_security_benchmark = true

hub_address_space      = ["10.0.0.0/22"]
hub_subnets            = { "snet-shared" = "10.0.1.0/24" }
firewall_subnet_prefix = "10.0.0.0/26"
gateway_subnet_prefix  = "10.0.0.64/27"

enable_firewall   = false
firewall_sku_tier = "Standard"

spokes = {
  prod = {
    address_space = ["10.1.0.0/16"]
    subnets = {
      "snet-app"  = "10.1.0.0/24"
      "snet-data" = "10.1.1.0/24"
    }
  }
  dev = {
    address_space = ["10.2.0.0/16"]
    subnets = {
      "snet-app" = "10.2.0.0/24"
    }
  }
}

log_retention_in_days = 90
log_daily_quota_gb    = 5

defender_plans = {
  CloudPosture    = "Free"
  VirtualMachines = "Free"
  StorageAccounts = "Free"
  KeyVaults       = "Free"
  Arm             = "Free"
}

security_contact_email = "security@example.com"

budget_amount         = 500
budget_contact_emails = ["finance@example.com", "cloud-team@example.com"]
