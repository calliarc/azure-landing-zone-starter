// Central Log Analytics workspace, Activity Log export and Defender for Cloud.
targetScope = 'subscription'

param prefix string
param location string
param tags object
param retentionInDays int = 90
param dailyQuotaGb int = -1

@description('Defender plan tiers keyed by plan name (Free or Standard).')
param defenderPlans object

param securityContactEmail string

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${prefix}-management-${location}'
  location: location
  tags: tags
}

module workspace 'log-analytics.bicep' = {
  name: 'alz-log-analytics'
  scope: rg
  params: {
    name: 'log-${prefix}-${location}'
    location: location
    tags: tags
    retentionInDays: retentionInDays
    dailyQuotaGb: dailyQuotaGb
  }
}

resource activityLog 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'activity-log-to-law'
  properties: {
    workspaceId: workspace.outputs.id
    logs: [
      for category in [
        'Administrative'
        'Security'
        'ServiceHealth'
        'Alert'
        'Recommendation'
        'Policy'
        'Autoscale'
        'ResourceHealth'
      ]: {
        category: category
        enabled: true
      }
    ]
  }
}

@batchSize(1)
resource pricing 'Microsoft.Security/pricings@2024-01-01' = [
  for plan in items(defenderPlans): {
    name: plan.key
    properties: {
      pricingTier: plan.value
    }
  }
]

resource workspaceSetting 'Microsoft.Security/workspaceSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    workspaceId: workspace.outputs.id
    scope: subscription().id
  }
}

resource securityContact 'Microsoft.Security/securityContacts@2020-01-01-preview' = {
  name: 'default'
  properties: {
    emails: securityContactEmail
    alertNotifications: {
      state: 'On'
      minimalSeverity: 'Medium'
    }
    notificationsByRole: {
      state: 'On'
      roles: [
        'Owner'
      ]
    }
  }
}

output resourceGroupName string = rg.name
output workspaceId string = workspace.outputs.id
