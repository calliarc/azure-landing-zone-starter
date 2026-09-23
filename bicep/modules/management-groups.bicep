// SMB management group hierarchy. Deployed from a management-group-scoped
// deployment; management groups themselves are tenant-level resources.
targetScope = 'managementGroup'

@description('Prefix used as the intermediate root management group name.')
param prefix string

@description('Display name of the intermediate root management group.')
param rootDisplayName string

@description('Resource ID of the parent management group.')
param parentManagementGroupId string

@description('Subscriptions to move: [{ subscriptionId, managementGroup }].')
param subscriptionPlacements array = []

var children = [
  {
    key: 'platform'
    displayName: 'Platform'
  }
  {
    key: 'landingzones'
    displayName: 'Landing Zones'
  }
  {
    key: 'sandbox'
    displayName: 'Sandbox'
  }
  {
    key: 'decommissioned'
    displayName: 'Decommissioned'
  }
]

resource root 'Microsoft.Management/managementGroups@2023-04-01' = {
  scope: tenant()
  name: prefix
  properties: {
    displayName: rootDisplayName
    details: {
      parent: {
        id: parentManagementGroupId
      }
    }
  }
}

resource child 'Microsoft.Management/managementGroups@2023-04-01' = [
  for c in children: {
    scope: tenant()
    name: '${prefix}-${c.key}'
    properties: {
      displayName: c.displayName
      details: {
        parent: {
          id: root.id
        }
      }
    }
  }
]

resource placement 'Microsoft.Management/managementGroups/subscriptions@2023-04-01' = [
  for p in subscriptionPlacements: {
    scope: tenant()
    name: '${prefix}-${p.managementGroup}/${p.subscriptionId}'
    dependsOn: [
      child
    ]
  }
]

output rootId string = root.id
output rootName string = root.name
