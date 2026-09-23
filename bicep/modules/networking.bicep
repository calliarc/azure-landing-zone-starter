// Hub-and-spoke networking with optional Azure Firewall.
targetScope = 'subscription'

param prefix string
param location string
param tags object
param hubAddressSpace array
param hubSubnets array
param firewallSubnetPrefix string
param gatewaySubnetPrefix string
param enableFirewall bool
param firewallSkuTier string
param spokes array
param logAnalyticsWorkspaceId string

resource hubRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${prefix}-connectivity-${location}'
  location: location
  tags: tags
}

resource spokeRg 'Microsoft.Resources/resourceGroups@2024-03-01' = [
  for spoke in spokes: {
    name: 'rg-${prefix}-${spoke.name}-network-${location}'
    location: location
    tags: tags
  }
]

module hub 'hub.bicep' = {
  name: 'alz-hub'
  scope: hubRg
  params: {
    prefix: prefix
    location: location
    tags: tags
    addressSpace: hubAddressSpace
    subnets: hubSubnets
    firewallSubnetPrefix: firewallSubnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    enableFirewall: enableFirewall
    firewallSkuTier: firewallSkuTier
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
  }
}

module spoke 'spoke.bicep' = [
  for (s, i) in spokes: {
    name: 'alz-spoke-${s.name}'
    scope: spokeRg[i]
    params: {
      prefix: prefix
      name: s.name
      location: location
      tags: tags
      addressSpace: s.addressSpace
      subnets: s.subnets
      hubVnetId: hub.outputs.vnetId
      firewallPrivateIp: hub.outputs.firewallPrivateIp
    }
  }
]

module hubPeering 'hub-peering.bicep' = [
  for (s, i) in spokes: {
    name: 'alz-hub-peering-${s.name}'
    scope: hubRg
    params: {
      hubVnetName: hub.outputs.vnetName
      spokeName: s.name
      spokeVnetId: spoke[i].outputs.vnetId
    }
  }
]

output hubVnetId string = hub.outputs.vnetId
output firewallPrivateIp string = hub.outputs.firewallPrivateIp
