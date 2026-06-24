#!/bin/bash

# Prerequisites: Install Azure CLI extensions
az extension add --name azure-devops

# Set variables
DEVOPS_ORG="https://dev.azure.com/YOUR_ORG"
PROJECT="YOUR_PROJECT"
SERVICE_ENDPOINT_NAME="terraform-azure-connection"
SUBSCRIPTION_ID="ba4d7370-8df0-4392-b5b9-d99d93e39cd7"
CLIENT_ID="YOUR_APP_ID"
CLIENT_SECRET="YOUR_PASSWORD"
TENANT_ID="YOUR_TENANT_ID"

# Authenticate
az devops configure --defaults organization=$DEVOPS_ORG project=$PROJECT

# Create service connection
az devops service-endpoint azurerm create \
  --azure-rm-service-principal-id "$CLIENT_ID" \
  --azure-rm-service-principal-key "$CLIENT_SECRET" \
  --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
  --azure-rm-subscription-name "Azure Subscription" \
  --azure-rm-tenant-id "$TENANT_ID" \
  --name "$SERVICE_ENDPOINT_NAME"

# Add pipeline variables
az pipelines variable create --name BACKEND_RESOURCE_GROUP --value terraform-state-rg
az pipelines variable create --name BACKEND_STORAGE_ACCOUNT --value tfstate123456
az pipelines variable create --name BACKEND_CONTAINER --value tfstate
az pipelines variable create --name terraformVersion --value 1.5.0

# Secret variables
az pipelines variable create --name ARM_SUBSCRIPTION_ID --value "$SUBSCRIPTION_ID" --secret
az pipelines variable create --name ARM_CLIENT_ID --value "$CLIENT_ID" --secret
az pipelines variable create --name ARM_CLIENT_SECRET --value "$CLIENT_SECRET" --secret
az pipelines variable create --name ARM_TENANT_ID --value "$TENANT_ID" --secret

echo "✓ Azure DevOps setup automated!"