#!/usr/bin/env bash
# Provision Azure resources required by .github/workflows/ci-cd.yml
# Usage:
#   chmod +x scripts/provision-azure.sh
#   ./scripts/provision-azure.sh <subscription-id>
#
# Creates:
#   - Resource group: team-task-tracker-rg
#   - App Service plan (Linux, B1)
#   - Web App: team-task-tracker (Node 20)
#   - Deployment slot: staging
#   - Service principal scoped to the RG (prints AZURE_CREDENTIALS JSON)

set -euo pipefail

SUBSCRIPTION_ID="${1:-}"
LOCATION="${LOCATION:-eastus}"
RG="${RG:-team-task-tracker-rg}"
PLAN="${PLAN:-team-task-tracker-plan}"
APP="${APP:-team-task-tracker}"
SP_NAME="${SP_NAME:-sp-sampleapp-cicd}"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "Usage: $0 <subscription-id>"
  echo "Hint: az account list --query '[].{name:name,id:id}' -o table"
  exit 1
fi

echo "==> Setting subscription"
az account set --subscription "$SUBSCRIPTION_ID"

echo "==> Creating resource group $RG in $LOCATION"
az group create --name "$RG" --location "$LOCATION" -o none

echo "==> Creating App Service plan $PLAN (Linux, B1)"
az appservice plan create \
  --name "$PLAN" \
  --resource-group "$RG" \
  --is-linux \
  --sku B1 -o none

echo "==> Creating Web App $APP (Node 20)"
az webapp create \
  --name "$APP" \
  --resource-group "$RG" \
  --plan "$PLAN" \
  --runtime "NODE:20-lts" -o none

echo "==> Creating staging deployment slot"
az webapp deployment slot create \
  --name "$APP" \
  --resource-group "$RG" \
  --slot staging -o none

echo "==> Configuring app settings (production)"
az webapp config appsettings set \
  --name "$APP" \
  --resource-group "$RG" \
  --settings NODE_ENV=production WEBSITE_NODE_DEFAULT_VERSION=~20 \
  -o none

echo "==> Configuring app settings (staging slot)"
az webapp config appsettings set \
  --name "$APP" \
  --resource-group "$RG" \
  --slot staging \
  --settings NODE_ENV=staging WEBSITE_NODE_DEFAULT_VERSION=~20 \
  -o none

echo "==> Creating service principal (scoped to $RG)"
SP_JSON=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG" \
  --sdk-auth)

echo ""
echo "============================================================"
echo " Done. Production URL:  https://$APP.azurewebsites.net"
echo " Staging URL:           https://$APP-staging.azurewebsites.net"
echo "============================================================"
echo ""
echo "Add this JSON as repository secret AZURE_CREDENTIALS:"
echo "  Settings → Secrets and variables → Actions → New repository secret"
echo "  Name: AZURE_CREDENTIALS"
echo ""
echo "$SP_JSON"
echo ""
echo "Then create environments 'staging' and 'production':"
echo "  Settings → Environments → New environment"
echo "  (Add required reviewers on 'production' for manual approval gate.)"
