// Spoke virtual network with an NSG per subnet, peering to the hub and an
// optional default route through Azure Firewall.
param prefix string
param name string
param location string
param tags object
param addressSpace array

@description('Subnets: [{ name, prefix }].')
param subnets array

param hubVnetId string

@description('Firewall private IP. Empty string means no forced tunnelling.')
param firewallPrivateIp string = ''

var useFirewall = !empty(firewallPrivateIp)

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-01-01' = [
  for s in subnets: {
    name: 'nsg-${prefix}-${name}-${s.name}'
    location: location
    tags: tags
    properties: {}
  }
]

resource routeTable 'Microsoft.Network/routeTables@2024-01-01' = if (useFirewall) {
  name: 'rt-${prefix}-${name}-${location}'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'default-via-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-${prefix}-${name}-${location}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressSpace
    }
    subnets: [
      for (s, i) in subnets: {
        name: s.name
        properties: union(
          {
            addressPrefix: s.prefix
            networkSecurityGroup: {
              id: nsg[i].id
            }
          },
          useFirewall
            ? {
                routeTable: {
                  id: routeTable.id
                }
              }
            : {}
        )
      }
    ]
  }
}

resource toHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-01-01' = {
  parent: vnet
  name: 'peer-${name}-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
}

output vnetId string = vnet.id
