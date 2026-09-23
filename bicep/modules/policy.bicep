// Baseline built-in Azure Policy assignments at management group scope.
targetScope = 'managementGroup'

@description('Region for the managed identity used by Modify assignments.')
param location string

@description('Regions permitted for resources and resource groups.')
param allowedLocations array

@description('Tag names required on resource groups and inherited by resources.')
param requiredTags array

@description('Default or DoNotEnforce.')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'Default'

@description('Assign the Microsoft cloud security benchmark initiative.')
param assignSecurityBenchmark bool = true

// Built-in definition GUIDs (stable across all tenants).
var builtin = {
  allowedLocations: 'e56962a6-4747-49cd-b67b-bf8b01975c4c' // Allowed locations
  allowedLocationsRg: 'e765b5de-1225-4ba3-bd56-1ac6695af988' // Allowed locations for resource groups
  requireTagRg: '96670d01-0a4d-4649-9c89-2d3abc0a5025' // Require a tag on resource groups
  inheritTagRg: 'ea3f2387-9b95-492a-a190-fcdc54f7b070' // Inherit a tag from the resource group if missing
}

var secureDefaults = [
  {
    name: 'sec-storage-https'
    displayName: 'Secure transfer to storage accounts should be enabled'
    id: '404c3081-a854-4457-ae30-26a93ef643f9'
  }
  {
    name: 'sec-storage-public'
    displayName: 'Storage account public access should be disallowed'
    id: '4fa4b6c0-31ca-4c0d-b10d-24b96f62a751'
  }
  {
    name: 'sec-app-https'
    displayName: 'App Service apps should only be accessible over HTTPS'
    id: 'a4af4a39-4135-47fb-b175-47fbdf85311d'
  }
  {
    name: 'sec-kv-softdelete'
    displayName: 'Key vaults should have soft delete enabled'
    id: '1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d'
  }
  {
    name: 'sec-vm-mdisks'
    displayName: 'Audit VMs that do not use managed disks'
    id: '06a78e20-9358-41c9-923c-fb736d382a4d'
  }
]

var mcsbInitiativeId = '1f3afdf9-d0c9-4c3d-847f-89da613e70a8'

// Contributor - declared by the built-in "Inherit a tag" Modify policy.
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations'
  properties: {
    displayName: 'Allowed locations'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtin.allowedLocations)
    enforcementMode: enforcementMode
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    nonComplianceMessages: [
      {
        message: 'Resources must be deployed to an approved region: ${join(allowedLocations, ', ')}.'
      }
    ]
  }
}

resource allowedLocationsRgAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'allowed-locations-rg'
  properties: {
    displayName: 'Allowed locations for resource groups'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtin.allowedLocationsRg)
    enforcementMode: enforcementMode
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

resource requireTagRg 'Microsoft.Authorization/policyAssignments@2024-04-01' = [
  for tag in requiredTags: {
    name: take('req-rg-tag-${toLower(tag)}', 24)
    properties: {
      displayName: 'Require tag \'${tag}\' on resource groups'
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtin.requireTagRg)
      enforcementMode: enforcementMode
      parameters: {
        tagName: {
          value: tag
        }
      }
      nonComplianceMessages: [
        {
          message: 'Resource groups must carry the \'${tag}\' tag for cost allocation.'
        }
      ]
    }
  }
]

resource inheritTag 'Microsoft.Authorization/policyAssignments@2024-04-01' = [
  for tag in requiredTags: {
    name: take('inh-tag-${toLower(tag)}', 24)
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: 'Inherit tag \'${tag}\' from resource group'
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', builtin.inheritTagRg)
      enforcementMode: enforcementMode
      parameters: {
        tagName: {
          value: tag
        }
      }
    }
  }
]

resource inheritTagRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (tag, i) in requiredTags: {
    name: guid(managementGroup().id, 'inherit-tag', tag)
    properties: {
      roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
      principalId: inheritTag[i].identity.principalId
      principalType: 'ServicePrincipal'
    }
  }
]

resource secureDefaultAssignments 'Microsoft.Authorization/policyAssignments@2024-04-01' = [
  for p in secureDefaults: {
    name: p.name
    properties: {
      displayName: p.displayName
      policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', p.id)
      enforcementMode: enforcementMode
    }
  }
]

resource mcsb 'Microsoft.Authorization/policyAssignments@2024-04-01' = if (assignSecurityBenchmark) {
  name: 'mcsb-audit'
  properties: {
    displayName: 'Microsoft cloud security benchmark'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policySetDefinitions', mcsbInitiativeId)
    enforcementMode: enforcementMode
  }
}
