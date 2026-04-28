// ---------------------------------------------------------------------------
// Subscription RBAC – assigns Reader and Log Analytics Reader roles
// to the SRE managed identity at subscription scope.
// ---------------------------------------------------------------------------
targetScope = 'subscription'

// ── Parameters ──────────────────────────────────────────────────────────────

@description('Principal ID of the SRE managed identity.')
param managedIdentityPrincipalId string

@description('Environment name (used to generate deterministic GUIDs).')
param environmentName string

// ── Variables ───────────────────────────────────────────────────────────────

// Built-in role definition IDs
var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var logAnalyticsReaderRoleId = '73c42c96-874c-492b-b04d-ab87d138a893'

// ── Role Assignments ────────────────────────────────────────────────────────

// Reader role – provides read access to all subscription resources
resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, managedIdentityPrincipalId, readerRoleId, environmentName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'SRE Agent Reader access on subscription (${environmentName})'
  }
}

// Log Analytics Reader – provides read access to Log Analytics workspaces
resource logAnalyticsReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, managedIdentityPrincipalId, logAnalyticsReaderRoleId, environmentName)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logAnalyticsReaderRoleId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    description: 'SRE Agent Log Analytics Reader access on subscription (${environmentName})'
  }
}
