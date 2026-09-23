// Monthly subscription budget with actual and forecast alerts.
targetScope = 'subscription'

param name string
param amount int

@description('First day of a month, yyyy-MM-dd.')
param startDate string

param contactEmails array

@description('Percent thresholds alerting on actual spend.')
param actualThresholds array = [
  50
  80
  100
]

@description('Percent thresholds alerting on forecasted spend.')
param forecastThresholds array = [
  100
]

var actualNotifications = [
  for t in actualThresholds: {
    key: 'actual_${t}'
    value: {
      enabled: true
      operator: 'GreaterThanOrEqualTo'
      threshold: t
      thresholdType: 'Actual'
      contactEmails: contactEmails
    }
  }
]

var forecastNotifications = [
  for t in forecastThresholds: {
    key: 'forecast_${t}'
    value: {
      enabled: true
      operator: 'GreaterThanOrEqualTo'
      threshold: t
      thresholdType: 'Forecasted'
      contactEmails: contactEmails
    }
  }
]

resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: name
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: toObject(concat(actualNotifications, forecastNotifications), n => n.key, n => n.value)
  }
}

output id string = budget.id
