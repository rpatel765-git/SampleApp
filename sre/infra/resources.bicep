// ---------------------------------------------------------------------------
// SRE Resources – resource-group-scoped composition module
// Wires together identity, SRE Agent, and alert rules.
// ---------------------------------------------------------------------------

// ── Parameters ──────────────────────────────────────────────────────────────

@description('Environment name for resource naming.')
param environmentName string

@description('Azure region for all resources.')
param location string

@description('Tags applied to every resource.')
param tags object

@description('Name of the existing app resource group (for alert rule scoping).')
param appResourceGroupName string

@description('Name of the backend Container App to monitor.')
param backendContainerAppName string

// ── Modules ─────────────────────────────────────────────────────────────────

module identity 'modules/identity.bicep' = {
  name: 'sre-identity-${environmentName}'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
  }
}

module sreAgent 'modules/sre-agent.bicep' = {
  name: 'sre-agent-${environmentName}'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    managedIdentityId: identity.outputs.identityId
    managedIdentityPrincipalId: identity.outputs.identityPrincipalId
  }
}

module alertRules 'modules/alert-rules.bicep' = {
  name: 'sre-alert-rules-${environmentName}'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appResourceGroupName: appResourceGroupName
    backendContainerAppName: backendContainerAppName
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────

@description('Principal ID of the SRE managed identity.')
output identityPrincipalId string = identity.outputs.identityPrincipalId

@description('Name of the deployed SRE Agent.')
output agentName string = sreAgent.outputs.agentName

@description('Endpoint URL of the SRE Agent.')
output agentEndpoint string = sreAgent.outputs.agentEndpoint

@description('Azure Portal URL for the SRE Agent.')
output portalUrl string = sreAgent.outputs.portalUrl
