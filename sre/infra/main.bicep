// ---------------------------------------------------------------------------
// Main deployment – subscription-scoped
// Deploys the SRE Agent infrastructure for the Team Task Tracker application.
// ---------------------------------------------------------------------------
targetScope = 'subscription'

// ── Parameters ──────────────────────────────────────────────────────────────

@minLength(1)
@maxLength(20)
@description('Environment name used for resource naming (e.g. dev, staging, prod).')
param environmentName string

@allowed([
  'swedencentral'
  'eastus2'
  'australiaeast'
])
@description('Azure region for all SRE resources.')
param location string

@description('Name of the existing resource group that contains the application resources.')
param appResourceGroup string

@description('Name of the backend Container App to monitor.')
param backendContainerAppName string

// ── Variables ───────────────────────────────────────────────────────────────

var sreResourceGroupName = 'rg-sre-${environmentName}'

var tags = {
  application: 'team-task-tracker'
  purpose: 'sre-monitoring'
  environment: environmentName
}

// ── Resource Group ──────────────────────────────────────────────────────────

resource sreResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: sreResourceGroupName
  location: location
  tags: tags
}

// Reference the existing app resource group (no deployment – just a lookup)
resource appRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: appResourceGroup
}

// ── Modules ─────────────────────────────────────────────────────────────────

module sreResources 'resources.bicep' = {
  name: 'sre-resources-${environmentName}'
  scope: sreResourceGroup
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appResourceGroupName: appResourceGroup
    backendContainerAppName: backendContainerAppName
  }
}

module subscriptionRbac 'modules/subscription-rbac.bicep' = {
  name: 'sre-subscription-rbac-${environmentName}'
  params: {
    managedIdentityPrincipalId: sreResources.outputs.identityPrincipalId
    environmentName: environmentName
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────

@description('Name of the SRE resource group.')
output resourceGroupName string = sreResourceGroup.name

@description('Azure region of the deployment.')
output location string = location

@description('Name of the deployed SRE Agent.')
output agentName string = sreResources.outputs.agentName

@description('Endpoint URL of the SRE Agent.')
output agentEndpoint string = sreResources.outputs.agentEndpoint

@description('Azure Portal URL for the SRE Agent.')
output portalUrl string = sreResources.outputs.portalUrl
