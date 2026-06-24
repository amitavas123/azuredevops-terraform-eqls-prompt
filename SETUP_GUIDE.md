# Azure DevOps Pipeline Configuration Guide

This document provides step-by-step instructions to set up and run the Terraform pipeline in Azure DevOps.

## Prerequisites Checklist

- [ ] Azure Subscription (active and accessible)
- [ ] Azure DevOps Organization
- [ ] Azure CLI installed locally
- [ ] Terraform CLI installed locally
- [ ] SSH key pair generated (`~/.ssh/id_rsa` and `~/.ssh/id_rsa.pub`)
- [ ] Git repository (GitHub, Azure Repos, etc.)
- [ ] Project admin permissions in Azure DevOps

## Step-by-Step Setup

### Phase 1: Azure Infrastructure Setup (Run These Commands Locally)

#### 1.1 Set Variables
```bash
# Set your Azure subscription ID
SUBSCRIPTION_ID="YOUR_AZURE_SUBSCRIPTION_ID"
--> $env:SUBSCRIPTION_ID = "ba4d7370-8df0-4392-b5b9-d99d93e39cd7"
--> $env:LOCATION="australiaeast"

echo "SUBSCRIPTION_ID: $env:SUBSCRIPTION_ID"
echo "LOCATION: $env:LOCATION"


$env:STORAGE_ACCOUNT_NAME="tfstate$(date +%s)"
--> $env:STORAGE_ACCOUNT_NAME="amstfstate$(date +%s)"
--> $env:RESOURCE_GROUP="terraform-state-eqls-prompt-rg"   XXX at this stage

echo "STORAGE_ACCOUNT_NAME: $env:STORAGE_ACCOUNT_NAME"
echo "Resource Group: $env:RESOURCE_GROUP"


# Set these in the commands below

```

#### 1.2 Authenticate to Azure
```bash
az login
az account set --subscription $SUBSCRIPTION_ID
az account set --subscription ba4d7370-8df0-4392-b5b9-d99d93e39cd7
```

#### 1.3 Create Resource Group for Terraform State
```bash
az group create \
  --name $env:RESOURCE_GROUP \
  --location $env:LOCATION
```

#### 1.4 Create Storage Account
```bash
az storage account create \
  --name $env:STORAGE_ACCOUNT_NAME \
  --resource-group $env:RESOURCE_GROUP \
  --location $env:LOCATION \
  --sku Standard_LRS \
  --kind StorageV2 \
  --https-only true \
  --encryption-services blob
```

#### 1.5 Create Storage Container
```bash
az storage container create \
  --account-name $env:STORAGE_ACCOUNT_NAME \
  --name tfstate \
  --auth-mode login
```

#### 1.6 Get Storage Account Key
```bash
$env:STORAGE_KEY=$(az storage account keys list \
  --resource-group $env:RESOURCE_GROUP \
  --account-name $env:STORAGE_ACCOUNT_NAME \
  --query '[0].value' --output tsv)

echo "Storage Account Key: $env:STORAGE_KEY"
# Save this! You'll need it for Azure DevOps variables
```

#### 1.7 Create Service Principal for Terraform
```bash
$env:SERVICE_PRINCIPAL=$(az ad sp create-for-rbac \
  --name terraform-sp-$(date +%s) \
  --role Contributor \
  --scopes /subscriptions/$env:SUBSCRIPTION_ID \
  --output json)

# Extract values
##APP_ID=$(echo $env:SERVICE_PRINCIPAL | jq -r '.appId')
##PASSWORD=$(echo $env:SERVICE_PRINCIPAL | jq -r '.password')
##TENANT_ID=$(echo $env:SERVICE_PRINCIPAL | jq -r '.tenant')

$sp = $env:SERVICE_PRINCIPAL | ConvertFrom-Json
$APP_ID = $sp.appId
echo "APP_ID=$APP_ID"

$sp = $env:SERVICE_PRINCIPAL | ConvertFrom-Json
$PASSWORD = $sp.password
echo "PASSWORD=$PASSWORD"

$sp = $env:SERVICE_PRINCIPAL | ConvertFrom-Json
$TENANT = $sp.tenant
echo "TENANT=$TENANT"


echo "============================================"
echo "Service Principal Details:"
echo "============================================"
echo "APP_ID (Client ID): $APP_ID"
echo "PASSWORD (Client Secret): $PASSWORD"
echo "TENANT_ID: $TENANT_ID"
echo "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "============================================"
# Save all of these! You'll need them for Azure DevOps
```

### Phase 2: Azure DevOps Project Setup

#### 2.1 Create/Access Azure DevOps Project
1. Go to https://dev.azure.com
2. Create a new project or use existing one
3. Note the project name and URL

#### 2.2 Create Service Connection
1. Go to **Project Settings** (⚙️ icon bottom left)
2. Select **Service connections** (under Pipelines)
3. Click **Create service connection**
4. Choose **Azure Resource Manager**
5. Select **Service Principal (manual)**
6. Fill in the form:
   - **Subscription ID**: `SUBSCRIPTION_ID` from Phase 1
   - **Subscription Name**: Any name (e.g., "Azure Production")
   - **Service Principal ID**: `APP_ID` from Phase 1
   - **Service Principal Key**: `PASSWORD` from Phase 1
   - **Tenant ID**: `TENANT_ID` from Phase 1
7. Click **Save**
8. Name it: `terraform-azure-connection-eqls`

#### 2.3 Upload SSH Secure File
1. Go to **Pipelines** → **Library** → **Secure files** (top navigation)
2. Click **+ Secure file**
3. Browse and select your **SSH PRIVATE KEY** (`~/.ssh/id_rsa`) []
3. Browse and select your **SSH PRIVATE KEY** (`~/.ssh/id_rsa` In Windows: C:\Users\Amitava\.ssh) [Check in Powershell by: Get-ChildItem $env:USERPROFILE\.ssh]
4. Click **Upload**
5. Authorize for use in all pipelines (click the file and authorize)

⚠️ **SECURITY**: Never commit or share the private key!

#### 2.4 Create Pipeline Variables
1. Go to **Pipelines** → **Edit pipeline** (or create new)
2. Click **Variables** button (top right)
3. Add these variables:

**Non-Secret Variables:**
| Name | Value | Secret |
|------|-------|--------|
| `BACKEND_RESOURCE_GROUP` | `terraform-state-rg` | ❌ |
| `BACKEND_STORAGE_ACCOUNT` | (Your storage account name) | ❌ |
| `BACKEND_CONTAINER` | `tfstate` | ❌ |
| `terraformVersion` | `1.5.0` | ❌ |

**Secret Variables (lock icon):**
| Name | Value | Secret |
|------|-------|--------|
| `ARM_SUBSCRIPTION_ID` | (From Phase 1) | ✅ |
| `ARM_CLIENT_ID` | `APP_ID` (From Phase 1) | ✅ |
| `ARM_CLIENT_SECRET` | `PASSWORD` (From Phase 1) | ✅ |
| `ARM_TENANT_ID` | `TENANT_ID` (From Phase 1) | ✅ |

#### 2.5 Create Environment for Approvals (Optional but Recommended)
1. Go to **Pipelines** → **Environments**
2. Click **Create environment**
3. Name: `Azure-dev`
4. (Optional) Add approvers:
   - Click the environment
   - Click **Approvals and checks** (top right)
   - Add **Approvals** check
   - Select approvers

### Phase 3: Repository Setup

#### 3.1 Clone/Update Repository
```bash
git clone <your-repo-url>
cd azuredevops-terraform-eqls-prompt
```

#### 3.2 Create Pipeline in Azure DevOps
1. Go to **Pipelines** → **Pipelines**
2. Click **New pipeline**
3. Select **Azure Repos Git** (or your source)
4. Select your repository
5. Choose **Existing Azure Pipelines YAML file**
6. Select: `pipelines/azure-pipelines.yml`
7. Click **Continue**
8. Click **Save** (or **Save and run**)

#### 3.3 Configure dev.tfvars
Update `terraform/env/dev/dev.tfvars`:
```hcl
subscription_id  = "YOUR_AZURE_SUBSCRIPTION_ID"
project_prefix   = "myapp"              # Use your prefix
environment      = "dev"
location         = "East US"            # Or your preferred location
admin_source_ip  = "YOUR_IP/32"         # CRITICAL: Your actual IP
enable_http      = true
public_key_path  = "~/.ssh/id_rsa.pub"
```

Get your IP:
```bash
# From Mac/Linux:
curl -s https://ifconfig.me
# Or use: dig +short myip.opendns.com @resolver1.opendns.com

# From Windows:
(Invoke-RestMethod -Uri "https://ifconfig.me").Trim()
```

#### 3.4 Push to Repository
```bash
git add .
git commit -m "Add Terraform and Azure DevOps pipeline"
git push origin main
```

## Running the Pipeline

### Automatic Trigger
The pipeline runs automatically on:
- Push to `main` branch
- Push to `develop` branch
- Pull requests to `main`

### Manual Trigger
1. Go to **Pipelines** → **All pipelines**
2. Select your pipeline
3. Click **Run pipeline**
4. Select branch and click **Run**

### Monitoring Pipeline Execution
1. Go to **Pipelines** → **All pipelines**
2. Click your pipeline run
3. Watch progress through stages:
   - **Validate**: Checks syntax and formatting
   - **Plan**: Shows what will be created
   - **Apply**: Creates resources in Azure
   - **VMHealthCheck**: Verifies VM is working

## Post-Pipeline: Access Your VM

### 1. Get VM Details
From pipeline output or manually:
```bash
cd terraform
terraform output vm_public_ip
terraform output vm_admin_username
```

### 2. SSH into VM
```bash
ssh -i ~/.ssh/id_rsa azureuser@<VM_PUBLIC_IP>
```

### 3. Verify Services
```bash
# Check nginx
sudo systemctl status nginx

# Check port 22 (SSH)
sudo netstat -tlnp | grep ssh

# Or from your local machine
ssh -i ~/.ssh/id_rsa azureuser@<VM_PUBLIC_IP> "sudo systemctl status nginx"
```

## Troubleshooting

### Pipeline Fails at "Terraform Init"
**Error**: Authentication failure or storage account not found

**Solution**:
1. Verify `BACKEND_STORAGE_ACCOUNT` variable is correct
2. Check Service Principal has `Contributor` role:
   ```bash
   az role assignment list --assignee $APP_ID
   ```
3. Test locally:
   ```bash
   export ARM_SUBSCRIPTION_ID="YOUR_ID"
   export ARM_CLIENT_ID="YOUR_APP_ID"
   export ARM_CLIENT_SECRET="YOUR_PASSWORD"
   export ARM_TENANT_ID="YOUR_TENANT"
   
   cd terraform
   terraform init -backend-config="..."
   ```

### Pipeline Fails at SSH Key Download
**Error**: Secure file not found

**Solution**:
1. Verify SSH key is uploaded to Secure Files:
   - **Pipelines** → **Library** → **Secure files**
   - File should be named: `id_rsa`
2. Authorize for pipeline use:
   - Click the file
   - Click "Authorize for use in all pipelines"

### Pipeline Fails at "Terraform Apply"
**Error**: Resource already exists or quota exceeded

**Solution**:
1. Check Azure portal for existing resources
2. Verify subscription has quota for VM size:
   ```bash
   az compute vm-image list --location eastus --query "[].name"
   ```
3. Check error logs in pipeline output

### VM Health Check Fails
**Error**: Cannot connect to VM or service not running

**Solution**:
1. Wait 2-3 minutes for VM to fully start
2. Verify NSG rules allow SSH from pipeline agent:
   - Azure portal → VM → Networking → Network security group rules
3. SSH manually to diagnose:
   ```bash
   ssh -v -i ~/.ssh/id_rsa azureuser@<VM_PUBLIC_IP>
   ```

### "AdminSourceIp" Validation Error
**Error**: Invalid CIDR block format

**Solution**:
Update `admin_source_ip` to valid CIDR:
- Correct: `"203.0.113.0/32"` (single IP)
- Correct: `"10.0.0.0/8"` (range)
- Incorrect: `"203.0.113.0"` (missing /32)

## Cleanup

### Destroy Resources
```bash
# Option 1: Via Pipeline
# Edit pipeline YAML to add destroy stage

# Option 2: Manual
cd terraform
terraform destroy \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$SUBSCRIPTION_ID" \
  -auto-approve
```

### Delete Azure DevOps Resources
1. Delete pipeline from **Pipelines** → **All pipelines**
2. Delete service connection from **Project Settings**
3. Delete secure files from **Pipelines** → **Library** → **Secure files**

### Delete Azure Infrastructure
```bash
# Delete state storage
az group delete --name terraform-state-rg

# Delete service principal
az ad sp delete --id $APP_ID
```

## Security Checklist

- [ ] SSH keys stored securely (not in Git)
- [ ] Service Principal credentials stored as secrets
- [ ] Storage account has encryption enabled
- [ ] `admin_source_ip` set to your IP (not 0.0.0.0/0 for production)
- [ ] NSG rules follow least privilege principle
- [ ] Pipeline approvals configured for production
- [ ] Terraform state locked (if using Terraform Enterprise)
- [ ] Regular secret rotation implemented

## Additional Resources

- [Azure DevOps YAML Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/security/compass/compass)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)

---

**Last Updated**: 2024
