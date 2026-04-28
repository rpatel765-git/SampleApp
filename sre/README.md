# SRE Agent Configuration for Team Task Tracker

This directory contains the Azure SRE Agent deployment configuration for the Team Task Tracker application.

## Overview

The SRE Agent automates Site Reliability Engineering tasks for your application, including:
- **Incident Detection & Response**: Automatically identify and triage production incidents
- **Error Analysis**: Analyze error patterns and correlate with code changes
- **Performance Monitoring**: Track application health metrics and alert on anomalies
- **Runbook Automation**: Execute automated remediation workflows

## Prerequisites

Before deploying the SRE Agent, ensure you have:

- **Azure Subscription** with appropriate permissions
- **Azure CLI** (`az`) installed and authenticated
- **Azure Developer CLI** (`azd`) installed
  - Install: `brew install azure-dev-cli` (macOS) or see [official docs](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd)
- **GitHub Account** with access to your repository (for OAuth integration)
- **Bash** shell (macOS/Linux) or WSL on Windows

## Quick Start

### 1. Deploy Infrastructure

```bash
cd sre
azd up
```

This command will:
- Authenticate with Azure
- Provision the SRE Agent infrastructure in your Azure subscription
- Deploy required resources (App Service, Storage, Key Vault, etc.)
- Save deployment outputs to `.azure/` directory

### 2. Post-Provision Configuration

After `azd up` completes, run the configuration script:

```bash
bash scripts/post-provision.sh
```

This script will guide you through:
- Uploading sub-agent configurations
- Connecting your GitHub repository
- Uploading knowledge base documents
- Creating scheduled monitoring tasks

### 3. Verify Deployment

1. Navigate to the **SRE Agent Portal** (URL printed by `post-provision.sh`)
2. Confirm the agent is **Online**
3. Check **Health Status** tab for initial health check results
4. Review **Sub-agents** to verify `incident-handler` and `code-analyzer` are running

## Directory Structure

```
sre/
├── README.md                          # This file
├── azure.yaml                         # Azure Developer CLI configuration
├── scripts/
│   └── post-provision.sh              # Post-deployment configuration script
├── infra/                             # Infrastructure as Code (Bicep templates)
│   ├── main.bicep                     # Main infrastructure definition
│   ├── modules/                       # Reusable Bicep modules
│   └── parameters.json                # Infrastructure parameters
├── sre-config/                        # SRE Agent configuration
│   ├── agents/                        # Sub-agent configurations
│   │   ├── incident-handler.yaml      # Incident response automation
│   │   └── code-analyzer.yaml         # Code analysis and diagnostics
│   └── tasks/                         # Scheduled monitoring tasks
│       ├── health-check.yaml          # Runs every 30 minutes
│       ├── performance-audit.yaml     # Daily performance review
│       └── security-scan.yaml         # Weekly security audit
└── knowledge-base/                    # Knowledge base for agent
    ├── error-investigation-runbook.md # Common error patterns and fixes
    ├── app-architecture.md            # Application architecture overview
    └── deployment-guide.md            # Deployment and scaling procedures
```

## Configuration Files

### `azure.yaml`
The main Azure Developer CLI configuration file that defines:
- **Infra Provider**: Bicep for Infrastructure as Code
- **Pipeline**: GitHub for CI/CD integration
- **Hooks**: Post-provision script for automated setup

### `scripts/post-provision.sh`
Runs after infrastructure deployment to configure the SRE Agent with:
- Sub-agent definitions
- GitHub repository connection
- Knowledge base uploads
- Scheduled monitoring tasks

## Common Tasks

### Update Sub-Agent Configuration
1. Modify `sre-config/agents/incident-handler.yaml` or `sre-config/agents/code-analyzer.yaml`
2. Navigate to SRE Agent Portal → Sub-agents
3. Edit the sub-agent and re-upload the configuration
4. Agent will restart with new configuration

### Add New Knowledge Base Document
1. Create or modify `.md` file in `knowledge-base/`
2. Go to SRE Agent Portal → Knowledge Base
3. Upload the document
4. Agent will automatically index and use the new knowledge

### Schedule New Monitoring Task
1. Create new YAML file in `sre-config/tasks/`
2. Define the task schedule and actions
3. Upload via SRE Agent Portal → Scheduled Tasks

### View Agent Logs
```bash
# Tail logs from Azure Application Insights
az monitor app-insights query --app <app-insights-name> \
  --analytics-query "traces | order by timestamp desc | limit 100"
```

## Troubleshooting

### Agent Not Starting
- Check Azure portal for resource deployment errors
- Verify all required environment variables are set: `azd env list`
- Review Application Insights logs for startup errors

### GitHub Integration Failing
- Verify GitHub OAuth token is still valid
- Re-authorize GitHub connection in SRE Agent Portal → Integrations
- Check that repository permissions are granted

### Sub-Agents Not Running
- Confirm sub-agent configurations are valid YAML
- Check SRE Agent Portal → Sub-agents for error messages
- Review Application Insights logs for agent errors

## Documentation

For more information on Azure SRE Agent capabilities and configuration:
- [Azure SRE Agent Overview](https://learn.microsoft.com/en-us/azure/sre-agent/overview)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Bicep Template Reference](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/file)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Application Insights logs in Azure Portal
3. Consult the [Azure SRE Agent docs](https://learn.microsoft.com/en-us/azure/sre-agent/)
4. Contact Azure Support for infrastructure issues

## Next Steps

After successful deployment:
1. Configure monitoring alerts in Azure Portal
2. Set up GitHub workflow integration for automated diagnostics
3. Create custom sub-agents for application-specific logic
4. Schedule regular chaos engineering tests
