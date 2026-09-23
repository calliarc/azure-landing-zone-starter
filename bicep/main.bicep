// Azure Landing Zone Starter - Bicep entry point.
//
// Deploy at the scope of the PARENT management group (usually the tenant root
// group, whose ID equals the tenant ID):
//
//   az deployment mg create \
//     --management-group-id <parent-mg-id> \
//     --location westeurope \
//     --template-file bicep/main.bicep \
//     --parameters bicep/main.bicepparam

targetScope = 'managementGroup'

@description('Short organisation prefix (lowercase, 2-10 chars) used in every resource name.')
@minLength(2)
@maxLength(10)
param prefix string

@description('Human-readable organisation name, used for the root management group display name.')
param organizationName string

@description('Subscription ID (GUID) of the platform subscription that hosts hub networking, logging and the budget.')
param platformSubscriptionId string

@description('Primary Azure region.')
param location string = 'westeurope'

@description('Regions permitted by policy.')
param allowedLocations array = [
  'westeurope'
  'northeurope'
]

@description('Cost-allocation tags applied to every resource.')
param tags object

@description('Tag names enforced by policy on resource groups (and inherited by resources).')
param requiredTags array = [
  'CostCenter'
  'Environment'
  'Owner'
]

@description('Subscriptions to place into the hierarchy: [{ subscriptionId: GUID, managementGroup: platform|landingzones|sandbox|decommissioned }].')
param subscriptionPlacements array = []

@description('false assigns every policy in DoNotEnforce (audit-only) mode.')
param policyEnforcement bool = true

@description('Assign the Microsoft cloud security benchmark initiative.')
param assignSecurityBenchmark bool = true

@description('Hub virtual network address space.')
param hubAddressSpace array = [
  '10.0.0.0/22'
]

@description('Hub shared-services subnets: [{ name, prefix }].')
param hubSubnets array = [
  {
    name: 'snet-shared'
    prefix: '10.0.1.0/24'
  }
]

@description('AzureFirewallSubnet prefix (/26).')
param firewallSubnetPrefix string = '10.0.0.0/26'

@description('GatewaySubnet prefix reserved for a future VPN gateway. Empty string to skip.')
param gatewaySubnetPrefix string = '10.0.0.64/27'

@description('Deploy Azure Firewall in the hub (adds significant monthly cost).')
param enableFirewall bool = false

@description('Azure Firewall tier.')
@allowed([
  'Standard'
  'Premium'
])
param firewallSkuTier string = 'Standard'

@description('Spoke virtual networks: [{ name, addressSpace: [], subnets: [{ name, prefix }] }].')
param spokes array = []

@description('Log Analytics retention in days.')
@minValue(30)
@maxValue(730)
param logRetentionInDays int = 90

@description('Log Analytics daily cap in GB (-1 = unlimited).')
param logDailyQuotaGb int = -1

@description('Defender for Cloud plan tiers keyed by plan name (Free or Standard).')
param defenderPlans object = {
  CloudPosture: 'Free'
  VirtualMachines: 'Free'
  StorageAccounts: 'Free'
  KeyVaults: 'Free'
  Arm: 'Free'
}

@description('Email for Defender for Cloud alerts.')
param securityContactEmail string

@description('Monthly budget for the platform subscription in billing currency.')
param budgetAmount int = 500

@description('Recipients of budget alerts.')
param budgetContactEmails array

@description('Budget start date (first of month, yyyy-MM-dd). Defaults to the current month.')
param budgetStartDate string = utcNow('yyyy-MM-01')

// ---------------------------------------------------------------------------

module managementGroups 'modules/management-groups.bicep' = {
  name: 'alz-management-groups'
  params: {
    prefix: prefix
    rootDisplayName: organizationName
    parentManagementGroupId: managementGroup().id
    subscriptionPlacements: subscriptionPlacements
  }
}

module policy 'modules/policy.bicep' = {
  name: 'alz-policy'
  scope: managementGroup(prefix)
  dependsOn: [
    managementGroups
  ]
  params: {
    location: location
    allowedLocations: allowedLocations
    requiredTags: requiredTags
    enforcementMode: policyEnforcement ? 'Default' : 'DoNotEnforce'
    assignSecurityBenchmark: assignSecurityBenchmark
  }
}

module logging 'modules/logging.bicep' = {
  name: 'alz-logging'
  scope: subscription(platformSubscriptionId)
  params: {
    prefix: prefix
    location: location
    tags: tags
    retentionInDays: logRetentionInDays
    dailyQuotaGb: logDailyQuotaGb
    defenderPlans: defenderPlans
    securityContactEmail: securityContactEmail
  }
}

module networking 'modules/networking.bicep' = {
  name: 'alz-networking'
  scope: subscription(platformSubscriptionId)
  params: {
    prefix: prefix
    location: location
    tags: tags
    hubAddressSpace: hubAddressSpace
    hubSubnets: hubSubnets
    firewallSubnetPrefix: firewallSubnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    enableFirewall: enableFirewall
    firewallSkuTier: firewallSkuTier
    spokes: spokes
    logAnalyticsWorkspaceId: logging.outputs.workspaceId
  }
}

module budget 'modules/budget.bicep' = {
  name: 'alz-budget'
  scope: subscription(platformSubscriptionId)
  params: {
    name: 'budget-${prefix}-platform-monthly'
    amount: budgetAmount
    startDate: budgetStartDate
    contactEmails: budgetContactEmails
  }
}

output managementGroupRootId string = managementGroups.outputs.rootId
output logAnalyticsWorkspaceId string = logging.outputs.workspaceId
output hubVnetId string = networking.outputs.hubVnetId
output firewallPrivateIp string = networking.outputs.firewallPrivateIp
