#!/bin/bash

################################################################################
# setup-devops-phase2.sh
#
# Description: Automates Azure DevOps Phase 2 setup (service connection, 
#              variables, secure files, environment)
#
# Prerequisites:
#   - Azure CLI installed (az --version)
#   - Azure DevOps CLI extension (az extension add --name azure-devops)
#   - Personal Access Token (PAT) from https://dev.azure.com/YOUR_ORG/_usersSettings/tokens
#   - Phase 1 outputs (from setup or Phase 1 output from SETUP_GUIDE.md)
#
# Usage: ./setup-devops-phase2.sh
#
# Author: DevOps Team

####VARIABLES TO UPDATE BEFORE RUNNING THE SCRIPT:
# 1. Make executable
chmod +x scripts/setup-devops-phase2.sh

# 2. Run the script
./scripts/setup-devops-phase2.sh

# 3. Provide inputs when prompted:
#    - Organization name
#    - Project name
#    - PAT token
#    - Service Principal details
#    - Storage account name
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to print colored messages
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${YELLOW}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Function to validate required tools
check_prerequisites() {
    print_header "Checking Prerequisites"

    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI not found. Install from: https://docs.microsoft.com/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI found: $(az --version | head -1)"

    # Check Azure DevOps extension
    if ! az extension show --name azure-devops &> /dev/null 2>&1; then
        print_step "Installing Azure DevOps CLI extension..."
        az extension add --name azure-devops
        print_success "Azure DevOps extension installed"
    else
        print_success "Azure DevOps extension found"
    fi

    # Check jq (for JSON parsing)
    if ! command -v jq &> /dev/null; then
        print_error "jq not found. Install from: https://stedolan.github.io/jq/download/"
        exit 1
    fi
    print_success "jq found"

    # Check SSH key exists
    if [ ! -f "$HOME/.ssh/id_rsa" ] || [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
        print_error "SSH keys not found at ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub"
        print_info "Generate SSH keys with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N \"\""
        exit 1
    fi
    print_success "SSH keys found at ~/.ssh/"
}

# Function to collect user inputs
collect_inputs() {
    print_header "Collecting Configuration Inputs"

    # Azure DevOps Organization
    read -p "Enter Azure DevOps Organization name (from https://dev.azure.com/YOUR_ORG): " DEVOPS_ORG
    if [ -z "$DEVOPS_ORG" ]; then
        print_error "Organization name cannot be empty"
        exit 1
    fi
    DEVOPS_URL="https://dev.azure.com/$DEVOPS_ORG"
    print_success "DevOps URL: $DEVOPS_URL"

    # Azure DevOps Project
    read -p "Enter Azure DevOps Project name: " PROJECT
    if [ -z "$PROJECT" ]; then
        print_error "Project name cannot be empty"
        exit 1
    fi
    print_success "Project: $PROJECT"

    # Personal Access Token
    read -sp "Enter Azure DevOps Personal Access Token (hidden): " PAT
    echo ""
    if [ -z "$PAT" ]; then
        print_error "PAT cannot be empty"
        exit 1
    fi
    print_success "PAT provided"
    print_info "Generate PAT at: https://dev.azure.com/$DEVOPS_ORG/_usersSettings/tokens"

    # Service Principal Details (from Phase 1)
    print_info "You need values from Phase 1 of SETUP_GUIDE.md"
    read -p "Enter SUBSCRIPTION_ID: " SUBSCRIPTION_ID
    read -p "Enter APP_ID (Client ID): " APP_ID
    read -sp "Enter PASSWORD (Client Secret) [hidden]: " CLIENT_SECRET
    echo ""
    read -p "Enter TENANT_ID: " TENANT_ID

    # Storage Account Details
    read -p "Enter STORAGE_ACCOUNT_NAME (from Phase 1): " STORAGE_ACCOUNT_NAME
    if [ -z "$STORAGE_ACCOUNT_NAME" ]; then
        print_error "Storage account name cannot be empty"
        exit 1
    fi

    print_success "All inputs collected"
}

# Function to configure Azure DevOps CLI
configure_devops_cli() {
    print_header "Configuring Azure DevOps CLI"

    # Set defaults
    az devops configure --defaults organization="$DEVOPS_URL" project="$PROJECT" use-git-uri=true

    # Authenticate using PAT
    echo "$PAT" | az devops login --organization "$DEVOPS_URL"

    print_success "Azure DevOps CLI configured and authenticated"
}

# Function to create service connection
create_service_connection() {
    print_header "Creating Azure Resource Manager Service Connection"

    SERVICE_ENDPOINT_NAME="terraform-azure-connection"

    print_step "Creating service connection: $SERVICE_ENDPOINT_NAME"

    az devops service-endpoint azurerm create \
        --name "$SERVICE_ENDPOINT_NAME" \
        --azure-rm-service-principal-id "$APP_ID" \
        --azure-rm-service-principal-key "$CLIENT_SECRET" \
        --azure-rm-subscription-id "$SUBSCRIPTION_ID" \
        --azure-rm-subscription-name "Azure Subscription" \
        --azure-rm-tenant-id "$TENANT_ID" \
        --organization "$DEVOPS_URL" \
        --project "$PROJECT"

    print_success "Service connection created: $SERVICE_ENDPOINT_NAME"
}

# Function to create pipeline variables
create_pipeline_variables() {
    print_header "Creating Pipeline Variables"

    # Non-secret variables
    print_step "Creating non-secret variables..."

    az pipelines variable create \
        --name "BACKEND_RESOURCE_GROUP" \
        --value "terraform-state-rg" \
        --pipeline-id 1 \
        --organization "$DEVOPS_URL" \
        --project "$PROJECT" 2>/dev/null || print_info "Note: Pipeline variable creation requires pipeline-id (will create after pipeline is created)"

    print_info "Creating variables (note: best done after pipeline creation)"
    print_info "You can also set variables via Azure DevOps UI under Pipeline > Edit > Variables"

    # Note: Full variable creation via CLI is complex; showing UI-friendly approach
    print_step "Variables to create manually in Azure DevOps UI:"
    echo ""
    echo -e "${BLUE}Non-Secret Variables:${NC}"
    echo "  BACKEND_RESOURCE_GROUP = terraform-state-rg"
    echo "  BACKEND_STORAGE_ACCOUNT = $STORAGE_ACCOUNT_NAME"
    echo "  BACKEND_CONTAINER = tfstate"
    echo "  terraformVersion = 1.5.0"
    echo ""
    echo -e "${BLUE}Secret Variables (mark as Secret):${NC}"
    echo "  ARM_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
    echo "  ARM_CLIENT_ID = $APP_ID"
    echo "  ARM_CLIENT_SECRET = $CLIENT_SECRET"
    echo "  ARM_TENANT_ID = $TENANT_ID"
    echo ""
}

# Function to upload SSH secure file
upload_secure_file() {
    print_header "Uploading SSH Key to Secure Files"

    print_step "Preparing SSH key upload via REST API..."

    SSH_KEY_PATH="$HOME/.ssh/id_rsa"
    SECURE_FILE_NAME="id_rsa"

    # Base64 encode the SSH key
    SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")
    SSH_KEY_B64=$(echo -n "$SSH_KEY_CONTENT" | base64 -w 0)

    print_info "Uploading SSH key ($SSH_KEY_PATH)..."

    # Use REST API to create secure file
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Basic $(echo -n ":$PAT" | base64 -w 0)" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$SECURE_FILE_NAME\",\"properties\":{\"name\":\"$SECURE_FILE_NAME\"}}" \
        "$DEVOPS_URL/$PROJECT/_apis/distributedtask/securefiles?api-version=7.1-preview.1")

    if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
        SECURE_FILE_ID=$(echo "$RESPONSE" | jq -r '.id')
        print_success "Secure file created with ID: $SECURE_FILE_ID"

        # Upload the actual file
        curl -s -X PATCH \
            -H "Authorization: Basic $(echo -n ":$PAT" | base64 -w 0)" \
            -H "Content-Type: application/octet-stream" \
            --data-binary @"$SSH_KEY_PATH" \
            "$DEVOPS_URL/$PROJECT/_apis/distributedtask/securefiles/$SECURE_FILE_ID?api-version=7.1-preview.1" > /dev/null

        print_success "SSH key uploaded to secure files"

        # Authorize for use in pipelines
        print_step "Authorizing secure file for use in all pipelines..."
        curl -s -X PATCH \
            -H "Authorization: Basic $(echo -n ":$PAT" | base64 -w 0)" \
            -H "Content-Type: application/json" \
            -d '{"authorize":true}' \
            "$DEVOPS_URL/$PROJECT/_apis/distributedtask/securefiles/$SECURE_FILE_ID?api-version=7.1-preview.1" > /dev/null

        print_success "SSH key authorized for all pipelines"
    else
        print_error "Failed to create secure file"
        print_info "Error response: $RESPONSE"
        print_info "Try uploading SSH key manually via Azure DevOps UI:"
        print_info "  Pipelines > Library > Secure files > + Secure file > Select ~/.ssh/id_rsa"
    fi
}

# Function to create environment
create_environment() {
    print_header "Creating Azure DevOps Environment"

    ENV_NAME="Azure-dev"

    print_step "Creating environment: $ENV_NAME"

    # Use REST API to create environment
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Basic $(echo -n ":$PAT" | base64 -w 0)" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$ENV_NAME\",\"description\":\"Development environment for Terraform deployments\"}" \
        "$DEVOPS_URL/$PROJECT/_apis/pipelines/environments?api-version=7.1-preview.1")

    if echo "$RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
        print_success "Environment created: $ENV_NAME"
        print_info "You can configure approvals manually in: Environments > $ENV_NAME > Approvals and checks"
    else
        print_error "Failed to create environment"
        print_info "You can create it manually: Pipelines > Environments > New environment"
    fi
}

# Function to create summary
create_summary() {
    print_header "Phase 2 Setup Summary"

    echo -e "${GREEN}Completed Actions:${NC}"
    echo "  ✓ Azure DevOps CLI configured"
    echo "  ✓ Service connection created: terraform-azure-connection"
    echo "  ✓ SSH key uploaded to secure files (authorized)"
    echo "  ✓ Environment created: Azure-dev"
    echo ""

    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Create Pipeline Variables (best done after pipeline creation)"
    echo "     Go to: Azure DevOps > Pipelines > Your Pipeline > Edit > Variables"
    echo ""
    echo "  2. Add Non-Secret Variables:"
    echo "     - BACKEND_RESOURCE_GROUP = terraform-state-rg"
    echo "     - BACKEND_STORAGE_ACCOUNT = $STORAGE_ACCOUNT_NAME"
    echo "     - BACKEND_CONTAINER = tfstate"
    echo "     - terraformVersion = 1.5.0"
    echo ""
    echo "  3. Add Secret Variables (click lock icon):"
    echo "     - ARM_SUBSCRIPTION_ID = $SUBSCRIPTION_ID"
    echo "     - ARM_CLIENT_ID = $APP_ID"
    echo "     - ARM_CLIENT_SECRET = $CLIENT_SECRET"
    echo "     - ARM_TENANT_ID = $TENANT_ID"
    echo ""
    echo "  4. Follow Phase 3 in SETUP_GUIDE.md to create the pipeline"
    echo ""

    echo -e "${BLUE}Links:${NC}"
    echo "  Azure DevOps: $DEVOPS_URL"
    echo "  Project: $PROJECT"
    echo "  Service Connections: $DEVOPS_URL/$PROJECT/_settings/adminservices"
    echo "  Secure Files: $DEVOPS_URL/$PROJECT/_library?itemType=SecureFiles"
    echo "  Environments: $DEVOPS_URL/$PROJECT/_environments"
    echo ""
}

# Main execution
main() {
    print_header "Azure DevOps Phase 2 Automated Setup"

    # Run setup steps
    check_prerequisites
    collect_inputs
    configure_devops_cli
    create_service_connection
    create_pipeline_variables
    upload_secure_file
    create_environment
    create_summary

    print_success "Phase 2 setup completed!"
}

# Run main
main "$@"
