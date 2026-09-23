// Example parameters - all IDs and emails are placeholders.
using 'main.bicep'

param prefix = 'contoso'
param organizationName = 'Contoso'
param platformSubscriptionId = '00000000-0000-0000-0000-000000000000'
param location = 'westeurope'
param allowedLocations = [
  'westeurope'
  'northeurope'
]

param tags = {
  CostCenter: 'IT-0000'
  Environment: 'platform'
  Owner: 'cloud-team@example.com'
  ManagedBy: 'bicep'
}

param requiredTags = [
  'CostCenter'
  'Environment'
  'Owner'
]

param subscriptionPlacements = [
  {
    subscriptionId: '00000000-0000-0000-0000-000000000000'
    managementGroup: 'platform'
  }
]

// Start audit-only, review compliance, then set to true.
param policyEnforcement = false
param assignSecurityBenchmark = true

param enableFirewall = false
param firewallSkuTier = 'Standard'

param spokes = [
  {
    name: 'prod'
    addressSpace: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-app'
        prefix: '10.1.0.0/24'
      }
      {
        name: 'snet-data'
        prefix: '10.1.1.0/24'
      }
    ]
  }
  {
    name: 'dev'
    addressSpace: [
      '10.2.0.0/16'
    ]
    subnets: [
      {
        name: 'snet-app'
        prefix: '10.2.0.0/24'
      }
    ]
  }
]

param logRetentionInDays = 90
param logDailyQuotaGb = 5

param securityContactEmail = 'security@example.com'

param budgetAmount = 500
param budgetContactEmails = [
  'finance@example.com'
  'cloud-team@example.com'
]
