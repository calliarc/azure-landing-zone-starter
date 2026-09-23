// Hub virtual network, shared subnets and optional Azure Firewall.
param prefix string
param location string
param tags object
param addressSpace array
param subnets array
param firewallSubnetPrefix string
param gatewaySubnetPrefix string
param enableFirewall bool
param firewallSkuTier string
param logAnalyticsWorkspaceId string

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = [
  for s in subnets: {
    name: 'nsg-${prefix}-hub-${s.name}'
    location: location
    tags: tags
    properties: {}
  }
]

var sharedSubnets = [
  for (s, i) in subnets: {
    name: s.name
    properties: {
      addressPrefix: s.prefix
      networkSecurityGroup: {
        id: nsg[i].id
      }
    }
  }
]

var firewallSubnet = enableFirewall
  ? [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
    ]
  : []

var gatewaySubnet = empty(gatewaySubnetPrefix)
  ? []
  : [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaySubnetPrefix
        }
      }
    ]

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-${prefix}-hub-${location}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressSpace
    }
    subnets: concat(sharedSubnets, firewallSubnet, gatewaySubnet)
  }
}

resource firewallPip 'Microsoft.Network/publicIPAddresses@2024-01-01' = if (enableFirewall) {
  name: 'pip-${prefix}-afw-${location}'
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-01-01' = if (enableFirewall) {
  name: 'afwp-${prefix}-${location}'
  location: location
  tags: tags
  properties: {
    sku: {
      tier: firewallSkuTier
    }
    threatIntelMode: 'Deny'
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = if (enableFirewall) {
  name: 'afw-${prefix}-${location}'
  location: location
  tags: tags
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: firewallSkuTier
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: firewallPip.id
          }
        }
      }
    ]
  }
}

resource firewallDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableFirewall && !empty(logAnalyticsWorkspaceId)) {
  name: 'diag-to-law'
  scope: firewall
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output firewallPrivateIp string = enableFirewall ? firewall.properties.ipConfigurations[0].properties.privateIPAddress : ''
