// ---------------------------------------------------------------------------
// Managed Identity – user-assigned identity for the SRE Agent
// ---------------------------------------------------------------------------

// ── Parameters ──────────────────────────────────────────────────────────────

@description('Environment name for resource naming.')
param environmentName string

@description('Azure region for the managed identity.')
param location string

@description('Tags applied to the resource.')
param tags object

// ── Managed Identity ────────────────────────────────────────────────────────

resource sreIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-sre-agent-${environmentName}'
  location: location
  tags: tags
}

// ── Outputs ─────────────────────────────────────────────────────────────────

@description('Resource ID of the managed identity.')
output identityId string = sreIdentity.id

@description('Principal ID of the managed identity (for RBAC assignments).')
output identityPrincipalId string = sreIdentity.properties.principalId
