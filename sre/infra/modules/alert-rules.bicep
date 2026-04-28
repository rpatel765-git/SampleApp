// ---------------------------------------------------------------------------
// Alert Rules – Azure Monitor metric alerts for the backend Container App
// Three alerts: HTTP 5xx spikes, container restarts, high response time.
// ---------------------------------------------------------------------------

// ── Parameters ──────────────────────────────────────────────────────────────

@description('Environment name for resource naming.')
param environmentName string

@description('Azure region for alert resources.')
param location string

@description('Tags applied to every resource.')
param tags object

@description('Name of the resource group containing the app resources.')
param appResourceGroupName string

@description('Name of the backend Container App to monitor.')
param backendContainerAppName string

// ── Variables ───────────────────────────────────────────────────────────────

// Reference the backend Container App in the app resource group
var backendContainerAppId = resourceId(appResourceGroupName, 'Microsoft.App/containerApps', backendContainerAppName)

var actionGroupName = 'ag-sre-${environmentName}'

// ── Action Group ────────────────────────────────────────────────────────────

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'sre-${environmentName}'
    enabled: true
  }
}

// ── Alert: HTTP 5xx Spike ───────────────────────────────────────────────────

resource http5xxAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-http-5xx-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Fires when HTTP 5xx responses exceed threshold on the backend Container App.'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    scopes: [
      backendContainerAppId
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'http5xx'
          metricName: 'Requests'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Total'
          dimensions: [
            {
              name: 'statusCodeCategory'
              operator: 'Include'
              values: [
                '5xx'
              ]
            }
          ]
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ── Alert: Container Restarts ───────────────────────────────────────────────

resource containerRestartAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-container-restarts-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Fires when any container restart is detected on the backend Container App.'
    severity: 1
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    scopes: [
      backendContainerAppId
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'restarts'
          metricName: 'RestartCount'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// ── Alert: High Response Time ───────────────────────────────────────────────

resource highResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-high-response-time-${environmentName}'
  location: 'global'
  tags: tags
  properties: {
    description: 'Fires when average response time exceeds 3000ms on the backend Container App.'
    severity: 3
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    scopes: [
      backendContainerAppId
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'responseTime'
          metricName: 'ResponseTime'
          metricNamespace: 'Microsoft.App/containerApps'
          operator: 'GreaterThan'
          threshold: 3000
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
