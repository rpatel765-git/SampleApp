#!/usr/bin/env bash
set -euo pipefail

# Post-provision script for Azure SRE Agent
# This script configures the SRE Agent after infrastructure deployment

echo "=== SRE Agent Post-Provision Configuration ==="

# Read outputs from azd
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP 2>/dev/null || echo "")
SRE_AGENT_NAME=$(azd env get-value SRE_AGENT_NAME 2>/dev/null || echo "")
AGENT_PORTAL_URL=$(azd env get-value AGENT_PORTAL_URL 2>/dev/null || echo "https://sre.azure.com")

if [ -z "$RESOURCE_GROUP" ] || [ -z "$SRE_AGENT_NAME" ]; then
  echo "ERROR: Missing required azd environment values."
  echo "  Run 'azd up' first to deploy the SRE Agent infrastructure."
  exit 1
fi

echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "SRE Agent:      $SRE_AGENT_NAME"
echo ""

# Step 1: Upload subagent configurations
echo "--- Step 1: Uploading subagent configurations ---"
echo "Navigate to $AGENT_PORTAL_URL"
echo "1. Select your agent: $SRE_AGENT_NAME"
echo "2. Go to 'Sub-agents' tab"
echo "3. Create sub-agent 'incident-handler' with config from sre-config/agents/incident-handler.yaml"
echo "4. Create sub-agent 'code-analyzer' with config from sre-config/agents/code-analyzer.yaml"
echo ""

# Step 2: Connect GitHub repository
echo "--- Step 2: Connect GitHub Repository ---"
echo "1. In the SRE Agent portal, go to 'Integrations'"
echo "2. Click 'Connect GitHub Repository'"
echo "3. Authorize via OAuth and select your repository"
echo "4. The agent will use this connection for source code analysis"
echo ""

# Step 3: Upload knowledge base documents
echo "--- Step 3: Upload Knowledge Base ---"
echo "1. Go to 'Knowledge Base' tab"
echo "2. Upload knowledge-base/error-investigation-runbook.md"
echo "3. Upload knowledge-base/app-architecture.md"
echo ""

# Step 4: Create scheduled tasks
echo "--- Step 4: Create Scheduled Tasks ---"
echo "1. Go to 'Scheduled Tasks' tab"
echo "2. Create tasks from sre-config/tasks/*.yaml"
echo ""

echo "=== Configuration Complete ==="
echo "SRE Agent Portal: $AGENT_PORTAL_URL"
echo ""
echo "Next steps:"
echo "  - Verify the agent is monitoring your application"
echo "  - Trigger a test incident to validate the pipeline"
echo "  - Review the first health check results (runs every 30 min)"
