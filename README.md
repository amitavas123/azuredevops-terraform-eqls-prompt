# Azure Terraform Linux VM Provisioning Project

A production-ready Terraform project to provision an Azure Linux VM with secure SSH access, complete Azure DevOps CI/CD pipeline, and health checks.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start (Local Development)](#quick-start-local-development)
- [Azure DevOps Setup](#azure-devops-setup)
- [Running the Pipeline](#running-the-pipeline)
- [Outputs & SSH Access](#outputs--ssh-access)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## 🎯 Project Overview

This project deploys:
- **Azure Resource Group**: Organizational container for all resources
- **Virtual Network (VNet)**: 10.0.0.0/16 with two subnets
  - **App Subnet** (10.0.1.0/24): For application servers
  - **Management Subnet** (10.0.2.0/24): For management/jump hosts
- **Network Security Group (NSG)**: 
  - SSH access from configurable admin IP
  - Optional HTTP/HTTPS access
  - All outbound traffic allowed
- **Linux VM** (Ubuntu 22.04 LTS):
  - Attached to management subnet
  - Public IP for SSH access
  - SSH key-only authentication (no passwords)
  - Standard_B2s by default (customizable)
- **Nginx Web Server**: Installed and running on the VM

## 📦 Prerequisites

### Local Development
- **Terraform**: v1.5+ ([Install](https://www.terraform.io/downloads.html))
- **Azure CLI**: ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **SSH Keys**: Generate SSH key pair if you don't have one:
  ```bash
  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
  ```
- **Git**: For version control

### Azure DevOps
- **Azure DevOps Organization**: ([Create one free](https://dev.azure.com))
- **Azure Storage Account**: For Terraform remote state
  - Create: `Storage account > Blob service > Container` named `tfstate`
  - Get: Access keys or SAS token
- **Azure Service Connection**: In Azure DevOps project settings
- **Secure Files**: SSH private key uploaded to secure files library

### Azure Subscription
- Active Azure subscription with permissions to create resources
- Service Principal or credentials for CI/CD authentication

## 📁 Project Structure

```
.
├── terraform/
│   ├── main.tf                 # Main configuration, calls modules
│   ├── variables.tf            # Input variables with validation
│   ├── outputs.tf              # Output values (IPs, names, SSH command)
│   ├── versions.tf             # Provider and version requirements
│   ├── providers.tf            # Provider configuration
│   ├── modules/
│   │   ├── network/            # Network module (VNet, Subnets, NSG)
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── compute/            # Compute module (VM, NIC, Public IP)
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── env/
│       └── dev/
│           └── dev.tfvars      # Development environment values
├── pipelines/
│   ├── azure-pipelines.yml     # Main pipeline definition
│   └── templates/
│       ├── terraform-steps.yml # Terraform validate/plan/apply steps
│       └── vm-health-check.yml # Post-deployment health checks
├── scripts/
│   └── check_processes.sh      # Script to verify running processes
├── .gitignore
└── README.md                   # This file
```

## 🚀 Quick Start (Local Development)

### Step 1: Clone and Setup
```bash
git clone <your-repo-url>
cd azuredevops-terraform-eqls-prompt
```

### Step 2: Configure Azure CLI
```bash
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
```

### Step 3: Update dev.tfvars
Edit `terraform/env/dev/dev.tfvars`:
```hcl
subscription_id  = "YOUR_AZURE_SUBSCRIPTION_ID"
project_prefix   = "myapp"              # Change to your prefix
admin_source_ip  = "YOUR_IP/32"         # IMPORTANT: Set to your IP for SSH access
public_key_path  = "~/.ssh/id_rsa.pub"  # Path to your SSH public key
```

### Step 4: Initialize Terraform
```bash
cd terraform
terraform init
```

### Step 5: Validate Configuration
```bash
terraform fmt -recursive .
terraform validate
```

### Step 6: Plan Deployment
```bash
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"
```

### Step 7: Apply Configuration
```bash
terraform apply \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"
```

### Step 8: Get Outputs
```bash
terraform output vm_public_ip
terraform output ssh_command
```

### Step 9: SSH into VM
```bash
# Using the output SSH command (replace <path-to-private-key>)
ssh -i ~/.ssh/id_rsa azureuser@<VM_PUBLIC_IP>

# Or use the terraform output directly
terraform output -raw ssh_command | sed 's|<path-to-private-key>|'~/.ssh/id_rsa'|'
```

## 🔧 Azure DevOps Setup

### Step 1: Create Azure Storage for Terraform State

```bash
# Create storage account
STORAGE_ACCOUNT_NAME="tfstate$(date +%s)"
RESOURCE_GROUP="terraform-state-rg"

az group create -n $RESOURCE_GROUP -l eastus

az storage account create \
  -n $STORAGE_ACCOUNT_NAME \
  -g $RESOURCE_GROUP \
  --sku Standard_LRS

# Create blob container
az storage container create \
  --account-name $STORAGE_ACCOUNT_NAME \
  --name tfstate

# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  -g $RESOURCE_GROUP \
  -n $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Storage Key: $STORAGE_KEY"
```

### Step 2: Create Azure Service Principal

```bash
az ad sp create-for-rbac \
  --name terraform-sp \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Output will include: appId, password, tenant
```

### Step 3: Create Service Connection in Azure DevOps

1. Go to **Project Settings > Service connections**
2. Create **Azure Resource Manager** connection
3. Choose **Service Principal (manual)**
4. Fill in credentials from Step 2
5. Name it: `terraform-azure-connection`

### Step 4: Upload SSH Public Key as Secure File

In Azure DevOps:
1. Go to **Pipelines > Library > Secure files**
2. Click **+ Secure file**
3. Upload your SSH **private key** (id_rsa)
4. Name it: `id_rsa`

⚠️ **IMPORTANT**: Never upload SSH keys to version control. Use Azure DevOps Secure Files.

### Step 5: Create Pipeline Variables

In Azure DevOps, create these variables in **Pipelines > Edit pipeline > Variables**:

| Variable | Value | Secret |
|----------|-------|--------|
| `BACKEND_RESOURCE_GROUP` | terraform-state-rg | ❌ |
| `BACKEND_STORAGE_ACCOUNT` | tfstate... | ❌ |
| `BACKEND_CONTAINER` | tfstate | ❌ |
| `ARM_SUBSCRIPTION_ID` | YOUR_SUB_ID | ✅ |
| `ARM_CLIENT_ID` | Service Principal App ID | ✅ |
| `ARM_CLIENT_SECRET` | Service Principal Password | ✅ |
| `ARM_TENANT_ID` | Your Tenant ID | ✅ |

### Step 6: Update Pipeline File

Update `pipelines/azure-pipelines.yml`:
- Update `trigger` and `pr` branches as needed
- Verify `terraformVersion` matches your version
- Ensure `environment` matches your Azure DevOps environment name

### Step 7: Create Azure DevOps Environment

1. Go to **Pipelines > Environments**
2. Create environment: `Azure-dev`
3. (Optional) Add approvals for production safety

### Step 8: Push to Repository

```bash
git add .
git commit -m "Initial Terraform and pipeline setup"
git push origin main
```

## 🏃 Running the Pipeline

The Azure DevOps pipeline runs automatically on pushes to `main` and `develop` branches.

### Manual Pipeline Run

1. Go to **Pipelines > All pipelines**
2. Select your pipeline
3. Click **Run pipeline**

### Pipeline Stages

1. **Validate**: Checks Terraform syntax and formatting
2. **Plan**: Shows what changes will be made
3. **Apply**: Creates Azure resources
4. **VMHealthCheck**: 
   - Installs Nginx
   - Verifies service is running
   - Checks port connectivity
   - Confirms SSH access

## 📤 Outputs & SSH Access

After successful Terraform apply, you'll see:

```
vm_public_ip = "40.71.x.x"
vm_admin_username = "azureuser"
ssh_command = "ssh -i <path-to-private-key> azureuser@40.71.x.x"
```

### Connect to VM

```bash
# Via SSH
ssh -i ~/.ssh/id_rsa azureuser@40.71.x.x

# Or use the terraform output
ssh -i ~/.ssh/id_rsa $(terraform output -raw vm_admin_username)@$(terraform output -raw vm_public_ip)
```

## 🔐 Security Best Practices

### SSH Key Management
- ✅ Use SSH key-only authentication (passwords disabled)
- ✅ Store private keys in secure locations (never in Git)
- ✅ Use Azure DevOps Secure Files for CI/CD
- ⚠️ Change `admin_source_ip` from 0.0.0.0/0 to your IP for production

### Network Security
- ✅ SSH (22) access restricted to configurable source IP
- ✅ HTTP/HTTPS optional via variables
- ✅ All rules follow principle of least privilege
- ✅ Consider using Azure Bastion for jumphost access

### Terraform State
- ✅ Remote state stored in Azure Storage Account
- ✅ Storage account has firewall rules (configure as needed)
- ✅ Enable storage account encryption
- ✅ Use managed identities or service principals (not shared keys)

### DevOps Practices
- ✅ Pipeline validates before applying
- ✅ Requires manual approval (configure in environment settings)
- ✅ All variables use secure storage
- ✅ SSH keys via secure files (not in environment variables)

## 🐛 Troubleshooting

### Issue: "Error: Invalid location"
**Solution**: Check available Azure regions:
```bash
az account list-locations --query "[].name" -o tsv
```
Update `dev.tfvars` with a valid location.

### Issue: SSH key permission denied
**Solution**: Fix SSH key permissions:
```bash
chmod 600 ~/.ssh/id_rsa
ssh-keyscan -H <VM_IP> >> ~/.ssh/known_hosts
```

### Issue: Admin source IP blocked
**Solution**: Find your IP and update `dev.tfvars`:
```bash
curl https://ifconfig.me
# Update admin_source_ip with YOUR_IP/32
```

### Issue: "ResourceGroupNotFound"
**Solution**: Ensure Terraform can access Azure:
```bash
az login
az account set --subscription YOUR_SUBSCRIPTION_ID
terraform init
```

### Issue: Pipeline authentication fails
**Solution**: Verify Azure DevOps service connection:
1. Go to Project Settings > Service connections
2. Test the connection
3. Verify Service Principal credentials
4. Check subscription ID matches

### Issue: Remote state initialization fails
**Solution**: Verify storage account:
```bash
az storage account show -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP
az storage container list --account-name $STORAGE_ACCOUNT_NAME
```

### Issue: VM health check fails
**Solution**: SSH to VM and check Nginx:
```bash
ssh -i ~/.ssh/id_rsa azureuser@<VM_IP>
sudo systemctl status nginx
sudo systemctl restart nginx
```

## 📝 Local Testing Without Azure

To validate Terraform without applying:

```bash
cd terraform

# Initialize (uses local backend)
terraform init -backend=false

# Format check
terraform fmt -check -recursive .

# Validate syntax
terraform validate

# Plan with test values
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=00000000-0000-0000-0000-000000000000" \
  -var="public_key_path=~/.ssh/id_rsa.pub" \
  -out=/dev/null
```

## 🔄 Cleanup

To destroy all resources and remove state:

```bash
cd terraform

terraform destroy \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  -auto-approve
```

## 📚 Additional Resources

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure DevOps YAML Pipeline Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [Azure Virtual Networks Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/)
- [Azure Linux VM Best Practices](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/overview)

## 📞 Support & Contributing

For issues or improvements:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Terraform logs: `TF_LOG=DEBUG terraform plan`
3. Check pipeline logs in Azure DevOps
4. Consult Azure documentation

## 📄 License

[Specify your license]

---

**Last Updated**: 2024  
**Terraform Version**: 1.5+  
**Azure Provider Version**: ~3.0
