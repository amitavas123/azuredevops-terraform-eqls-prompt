# Local Development Guide

This guide helps you develop and test Terraform configurations locally before committing to the repository and running through Azure DevOps.

## Prerequisites

### Required Tools
```bash
# Check versions
terraform version          # Should be 1.5+
az version                 # Azure CLI
ssh-keygen --version      # SSH utilities
git --version             # Version control
```

### SSH Key Setup (if not already done)
```bash
# Generate SSH key pair (if needed)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Verify keys exist
ls -la ~/.ssh/id_rsa*
```

### Azure Authentication
```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription YOUR_SUBSCRIPTION_ID

# Verify authentication
az account show
```

## Development Workflow

### Step 1: Local Testing (No Remote State)

For rapid iteration without affecting Azure resources:

```bash
cd terraform

# Initialize with local backend (no remote state)
terraform init -backend=false

# Format check
terraform fmt -check -recursive .

# Validate syntax
terraform validate
```

Output should show no errors.

### Step 2: Plan with Test Values

Test the plan without creating resources:

```bash
# Get a test subscription ID (can be fake for plan-only)
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  -var="public_key_path=~/.ssh/id_rsa.pub" \
  -var="admin_source_ip=$(curl -s https://ifconfig.me)/32" \
  -out=tfplan-test \
  -no-color

# View the plan
terraform show tfplan-test

# Count resources that will be created
terraform show tfplan-test | grep -c "# azurerm_"
```

### Step 3: Set Up Remote Backend (Local)

To test remote state locally:

```bash
# Copy your dev.tfvars for local testing
cp terraform/env/dev/dev.tfvars terraform/env/local.tfvars

# Edit terraform/versions.tf to configure local backend for testing
# (Skip this step if not testing state management)

cd terraform
terraform init

# Now using remote state
```

### Step 4: Create Development Environment

Full local deployment to Azure (test environment):

```bash
# Update variables for your environment
cat > terraform/env/dev/dev.tfvars << 'EOF'
subscription_id  = "$(az account show --query id -o tsv)"
project_prefix   = "devtest"
environment      = "dev"
location         = "East US"
admin_source_ip  = "YOUR_IP/32"              # Get from: curl https://ifconfig.me
enable_http      = true
vnet_cidr        = "10.0.0.0/16"
app_subnet_cidr  = "10.0.1.0/24"
mgmt_subnet_cidr = "10.0.2.0/24"
vm_admin_username = "azureuser"
vm_size          = "Standard_B1s"            # Use smaller size for testing
vm_image_publisher = "Canonical"
vm_image_offer     = "0001-com-ubuntu-server-jammy"
vm_image_sku       = "22_04-lts-gen2"
vm_image_version   = "latest"
public_key_path  = "~/.ssh/id_rsa.pub"
ssh_key_name     = "vm-ssh-key-dev"
tags = {
  terraform   = "true"
  environment = "dev"
  testing     = "true"
}
EOF

# Initialize Terraform
terraform init -backend=false

# Plan deployment
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)" \
  -out=tfplan

# Review plan
terraform show tfplan | head -50

# Apply if satisfied
terraform apply tfplan
```

### Step 5: Test Outputs

```bash
# Get all outputs
terraform output

# Get specific outputs
VM_IP=$(terraform output -raw vm_public_ip)
VM_USER=$(terraform output -raw vm_admin_username)

echo "SSH Command:"
echo "ssh -i ~/.ssh/id_rsa $VM_USER@$VM_IP"

# SSH into the VM
ssh -i ~/.ssh/id_rsa $VM_USER@$VM_IP

# From inside VM, test what pipeline will verify
sudo systemctl status nginx
sudo systemctl is-active nginx
pgrep nginx
```

## Common Development Tasks

### Modifying Variables

When testing variable changes:

```bash
# Update dev.tfvars
vim terraform/env/dev/dev.tfvars

# Plan to see what changes
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"

# Apply changes if needed
terraform apply -auto-approve
```

### Modifying Resources

When modifying Terraform code:

```bash
# Format all files
terraform fmt -recursive .

# Validate syntax
terraform validate

# Plan changes
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"

# Apply if approved
terraform apply -auto-approve
```

### Testing Module Changes

When modifying modules:

```bash
# Validate each module independently
terraform validate -json
terraform validate

# Re-initialize if module sources changed
terraform init -upgrade

# Plan to see module changes
terraform plan
```

### Checking Resource State

```bash
# List all resources in state
terraform state list

# Show specific resource
terraform state show azurerm_linux_virtual_machine.main

# Show resource JSON
terraform state show -json azurerm_resource_group.main | jq .

# Count resources
terraform state list | wc -l
```

### Destroying Test Resources

```bash
# Destroy all resources (careful!)
terraform destroy -auto-approve \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"

# Destroy specific resource
terraform destroy -target=azurerm_linux_virtual_machine.main \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"
```

## Debugging

### Enable Terraform Debug Logging

```bash
# Set debug logging
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/terraform.log

# Run terraform commands
terraform plan

# View logs
tail -f /tmp/terraform.log
```

### Validate Azure Resources

```bash
# List all resources in resource group
az resource list --resource-group myapp-dev-rg

# Get specific VM details
az vm show --resource-group myapp-dev-rg --name myapp-dev-vm

# Check network interfaces
az network nic list --resource-group myapp-dev-rg

# Check NSG rules
az network nsg rule list --resource-group myapp-dev-rg \
  --nsg-name myapp-dev-nsg
```

### SSH Connection Debugging

```bash
# Verbose SSH output
ssh -vvv -i ~/.ssh/id_rsa azureuser@<VM_IP>

# Check SSH key permissions
ls -la ~/.ssh/id_rsa
# Should show: -rw------- (600)

# Fix key permissions if needed
chmod 600 ~/.ssh/id_rsa

# Check if key is in ssh-agent
ssh-add ~/.ssh/id_rsa

# Test SSH connectivity
nc -zv <VM_IP> 22

# Add host to known_hosts
ssh-keyscan -H <VM_IP> >> ~/.ssh/known_hosts
```

### Azure CLI Debugging

```bash
# Enable debug output
az configure --defaults group=myapp-dev-rg

# Get detailed error information
az resource show \
  --resource-group myapp-dev-rg \
  --name myapp-dev-vm \
  --resource-type "Microsoft.Compute/virtualMachines"

# Check service principal permissions
PRINCIPAL_ID=$(az ad sp show --id <APP_ID> --query objectId -o tsv)
az role assignment list --assignee $PRINCIPAL_ID
```

## Best Practices for Local Development

### 1. Use Feature Branches
```bash
git checkout -b feature/add-ssl-certificate
# Make changes
git push origin feature/add-ssl-certificate
# Create Pull Request in Azure DevOps
```

### 2. Test Before Commit
```bash
# Format code
terraform fmt -recursive terraform/

# Validate
terraform validate

# Plan
terraform plan -out=tfplan

# Commit only if plan looks good
git add terraform/
git commit -m "Add new network rules"
```

### 3. Use Consistent Naming
- Follow the `${project_prefix}-${environment}-${resource_type}` pattern
- Use descriptive names
- Keep names under 24 characters (Azure limit)

### 4. Document Changes
```bash
git commit -m "Brief summary

- Detailed change 1
- Detailed change 2
- Links to related issues/PRs
"
```

### 5. Use .terraform for Isolation
```bash
# Each environment has its own .terraform directory
terraform workspace new dev
terraform workspace new prod

# List workspaces
terraform workspace list

# Switch workspace
terraform workspace select dev
```

## Integration with IDE

### VS Code

#### Recommended Extensions
1. **HashiCorp Terraform** (official)
   - Syntax highlighting
   - Formatting
   - Validation
   
2. **Azure Terraform**
   - Azure resource browsing
   - State management

#### Settings (`.vscode/settings.json`)
```json
{
  "terraform.format.onSave": true,
  "[hcl]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true
  }
}
```

### IntelliJ / WebStorm

1. Install HCL plugin
2. Enable Terraform language support
3. Configure formatter: Settings → Languages & Frameworks → HCL → Formatter

## Git Workflow

### Pre-commit Hook (Optional)

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash

echo "Running terraform fmt..."
terraform fmt -check -recursive terraform/

if [ $? -ne 0 ]; then
    echo "❌ Terraform files not formatted. Run: terraform fmt -recursive terraform/"
    exit 1
fi

echo "Running terraform validate..."
terraform validate

if [ $? -ne 0 ]; then
    echo "❌ Terraform validation failed"
    exit 1
fi

echo "✓ All checks passed"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Performance Tips

### Large Infrastructure
```bash
# Speed up terraform init
terraform init -upgrade=false

# Parallelize operations (use cautiously)
terraform apply -parallelism=10
```

### Workspace Management
```bash
# Use separate workspaces for different environments
terraform workspace new staging
terraform workspace select staging

# Apply only to current workspace
terraform apply -var-file="env/staging.tfvars"
```

## Troubleshooting Local Issues

### Issue: "resource already exists"
```bash
# Remove from state without deleting from Azure
terraform state rm azurerm_resource_group.main

# Or import existing resource
terraform import azurerm_resource_group.main /subscriptions/{sub}/resourceGroups/myapp-dev-rg
```

### Issue: "state lock"
```bash
# View lock info
terraform state list | grep lock

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

### Issue: Module not found
```bash
# Reinstall modules
terraform get -update

# Or
rm -rf .terraform/modules/
terraform init
```

## Clean Up

```bash
# Remove local terraform files
rm -rf terraform/.terraform
rm terraform/.terraform.lock.hcl

# Remove plan files
rm terraform/*.tfplan

# Reset to tracked state only
git clean -fd terraform/
```

---

**Tip**: Always run `terraform plan` before `terraform apply` to review changes!

**Remember**: What you test locally will run through the CI/CD pipeline, so local validation saves time and prevents production issues.
