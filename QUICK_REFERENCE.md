# Quick Reference Guide

Fast lookup for common commands and configurations.

## 🚀 Quick Start Commands

### Initialize Terraform Locally
```bash
cd terraform
terraform init -backend=false
terraform validate
```

### Plan & Apply Locally
```bash
terraform plan -var-file="env/dev/dev.tfvars" -var="subscription_id=$(az account show --query id -o tsv)"
terraform apply -var-file="env/dev/dev.tfvars" -var="subscription_id=$(az account show --query id -o tsv)"
```

### Get VM IP and SSH
```bash
VM_IP=$(terraform output -raw vm_public_ip)
ssh -i ~/.ssh/id_rsa azureuser@$VM_IP
```

### Destroy Everything
```bash
terraform destroy -auto-approve -var-file="env/dev/dev.tfvars" -var="subscription_id=$(az account show --query id -o tsv)"
```

## 📋 Azure CLI Essentials

### Get Your IP (for admin_source_ip)
```bash
# macOS/Linux
curl https://ifconfig.me

# Windows PowerShell
(Invoke-RestMethod -Uri "https://ifconfig.me").Trim()
```

### List Azure Resources
```bash
# All resources in resource group
az resource list --resource-group myapp-dev-rg

# VMs only
az vm list --resource-group myapp-dev-rg --output table

# Network interfaces
az network nic list --resource-group myapp-dev-rg
```

### Delete Resources
```bash
# Delete entire resource group
az group delete --name myapp-dev-rg

# Delete specific VM
az vm delete --resource-group myapp-dev-rg --name myapp-dev-vm
```

## 🔑 SSH Key Management

### Generate Keys (if needed)
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

### Fix Permissions
```bash
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Add to SSH Agent
```bash
ssh-add ~/.ssh/id_rsa
ssh-add -l    # List added keys
```

## 📁 Important File Locations

| File | Purpose |
|------|---------|
| `terraform/main.tf` | Root configuration |
| `terraform/variables.tf` | Input variables |
| `terraform/outputs.tf` | Output values |
| `terraform/env/dev/dev.tfvars` | Dev environment variables |
| `terraform/modules/network/main.tf` | Network resources (VNet, NSG, etc.) |
| `terraform/modules/compute/main.tf` | VM resources |
| `pipelines/azure-pipelines.yml` | Main CI/CD pipeline |
| `pipelines/templates/terraform-steps.yml` | Terraform pipeline steps |
| `pipelines/templates/vm-health-check.yml` | Post-deploy health checks |

## 🔐 Azure DevOps Variables to Set

**Non-Secret:**
- `BACKEND_RESOURCE_GROUP` → `terraform-state-rg`
- `BACKEND_STORAGE_ACCOUNT` → Your storage account name
- `BACKEND_CONTAINER` → `tfstate`
- `terraformVersion` → `1.5.0`

**Secret:**
- `ARM_SUBSCRIPTION_ID` → Your subscription ID
- `ARM_CLIENT_ID` → Service Principal App ID
- `ARM_CLIENT_SECRET` → Service Principal password
- `ARM_TENANT_ID` → Azure tenant ID

## 🎯 Key Variable Overrides

Most important variables to customize in `dev.tfvars`:

```hcl
project_prefix = "yourprefix"       # Used in all resource names
admin_source_ip = "YOUR_IP/32"      # CRITICAL: Set to your IP
location = "East US"                # Azure region
vm_size = "Standard_B2s"            # VM type
enable_http = true                  # HTTP/HTTPS access
```

## 🔍 Terraform State Inspection

### View State
```bash
terraform state list              # All resources
terraform state show <resource>   # Specific resource
terraform state show -json | jq   # JSON output
```

### Modify State (Careful!)
```bash
terraform state rm <resource>     # Remove from state
terraform state mv <old> <new>    # Rename
terraform import <type>.<name> <id>  # Import existing resource
```

## 🐛 Troubleshooting Checklist

| Problem | Command |
|---------|---------|
| Format errors | `terraform fmt -recursive terraform/` |
| Validation errors | `terraform validate` |
| SSH connection fails | `ssh -vvv -i ~/.ssh/id_rsa azureuser@IP` |
| Storage account not found | Verify `BACKEND_STORAGE_ACCOUNT` variable |
| Authentication fails | `az login && az account show` |
| VM not ready | Wait 2-3 minutes after apply |
| Port not accessible | Check NSG rules in Azure portal |

## 📊 Monitoring

### Watch Pipeline
Azure DevOps → Pipelines → Your pipeline → View run

### Check VM Health
```bash
ssh -i ~/.ssh/id_rsa azureuser@<IP>
sudo systemctl status nginx
ps aux | grep nginx
```

### View Azure Costs (Estimate)
```bash
az costmanagement forecast --time-period fromDate=2024-01-01 toDate=2024-01-31
```

## 🔄 Common Workflows

### Add/Modify Network Rule
1. Edit `terraform/modules/network/main.tf`
2. Add NSG rule resource
3. Run `terraform plan` to review
4. Run `terraform apply`

### Change VM Size
1. Update `vm_size` in `dev.tfvars`
2. Run `terraform plan`
3. Apply: `terraform apply` (VM will be recreated)

### Update VM Configuration
1. SSH into VM
2. Make changes
3. Test thoroughly
4. Document in code/comments

### Deploy to New Environment
1. Create `terraform/env/staging/staging.tfvars`
2. Update `project_prefix = "myapp-staging"`
3. Create new pipeline or modify trigger
4. Test in staging before production

## 📞 Getting Help

### Terraform Documentation
```bash
terraform -help
terraform <command> -help
```

### Check Terraform Logs
```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=/tmp/tf.log
terraform apply
cat /tmp/tf.log
```

### Azure CLI Help
```bash
az <service> <operation> -h
az resource show -h
```

### Common Errors

**Error**: "resource already exists"
```bash
# Check what Terraform thinks exists
terraform state list
# If not in state, import it
terraform import azurerm_resource_group.main /subscriptions/{sub}/resourceGroups/myapp-dev-rg
```

**Error**: "invalid or expired token"
```bash
# Re-authenticate
az login
terraform init -reconfigure
```

**Error**: "resource group not found"
```bash
# Verify resource group exists
az group list --query "[].name" | grep myapp-dev-rg
# Or create via Azure CLI
az group create -n myapp-dev-rg -l eastus
```

## 📝 Pre-Push Checklist

- [ ] Ran `terraform fmt -recursive .`
- [ ] Ran `terraform validate`
- [ ] Ran `terraform plan` with test values
- [ ] Reviewed plan output for unexpected changes
- [ ] Updated `.tfvars` file with real values
- [ ] Verified SSH public key path is correct
- [ ] Set correct `admin_source_ip`
- [ ] Committed changes to feature branch
- [ ] Created pull request for review
- [ ] Verified no secrets in commit

## 🚨 Emergency Commands

### Force Destroy Everything
```bash
terraform destroy -auto-approve -parallelism=30
az group delete --name myapp-dev-rg --yes
```

### Reset Local State
```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Force Unlock State
```bash
terraform force-unlock <LOCK_ID>
```

## 💡 Pro Tips

1. **Always plan before apply**: `terraform plan -out=tfplan` then `terraform apply tfplan`

2. **Use workspaces for environments**: 
   ```bash
   terraform workspace new staging
   terraform workspace select staging
   ```

3. **Save plans for audit**:
   ```bash
   terraform show -json tfplan > tfplan.json
   ```

4. **Test formatting before commit**:
   ```bash
   terraform fmt -check -recursive terraform/
   ```

5. **Keep sensitive data out of code**: Use variables and Azure KeyVault

6. **Document all changes**: 
   ```bash
   git commit -m "Description of changes and reasoning"
   ```

7. **Review state regularly**:
   ```bash
   terraform state list | wc -l  # Count resources
   ```

---

**More Help**: See `README.md`, `SETUP_GUIDE.md`, or `LOCAL_DEVELOPMENT.md`
