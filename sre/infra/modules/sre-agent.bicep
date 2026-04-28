// ---------------------------------------------------------------------------
// SRE Agent – core Azure SRE Agent resource
// Provisions the agent with system + user-assigned identity, knowledge graph
// configuration, and review-mode action settings.
// ---------------------------------------------------------------------------

// ── Parameters ──────────────────────────────────────────────────────────────

@description('Environment name for resource naming.')
param environmentName string

@description('Azure region for the SRE Agent.')
param location string

@description('Tags applied to the resource.')
param tags object

@description('Resource ID of the user-assigned managed identity.')
param managedIdentityId string

@description('Principal ID of the user-assigned managed identity (for RBAC).')
param managedIdentityPrincipalId string

// ── Variables ───────────────────────────────────────────────────────────────

var agentName = 'sre-agent-${environmentName}'

// SRE Agent Administrator role definition ID
var sreAgentAdminRoleId = 'e79298df-d852-4c6d-84f9-5d13249d1e55'

// ── SRE Agent ───────────────────────────────────────────────────────────────

resource sreAgent 'Microsoft.App/agents@2025-05-01-preview' = {
  name: agentName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    knowledgeGraphConfiguration: {
      managedResources: true
    }
    actionConfiguration: {
      mode: 'review'
      accessLevel: 'Low'
    }
    mcpServers: []
  }
}

// ── RBAC – SRE Agent Administrator ─────────────────────────────────────────

resource sreAgentAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sreAgent.id, managedIdentityPrincipalId, sreAgentAdminRoleId)
  scope: sreAgent
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', sreAgentAdminRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ── Outputs ─────────────────────────────────────────────────────────────────

@description('Name of the deployed SRE Agent.')
output agentName string = sreAgent.name

@description('Endpoint URL of the SRE Agent.')
output agentEndpoint string = 'https://${sreAgent.name}.${location}.agents.containerapp.io'

@description('Azure Portal URL for the SRE Agent.')
output portalUrl string = 'https://portal.azure.com/#resource${sreAgent.id}'
