# 📚 Documentation Index

Welcome to the Azure Terraform Linux VM provisioning project! This index helps you navigate all documentation.

## 🎯 Where to Start

| Your Situation | Read This First |
|---|---|
| **New to the project** | Start with [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) |
| **Want to deploy locally** | Go to [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md) |
| **Setting up Azure DevOps** | Follow [SETUP_GUIDE.md](SETUP_GUIDE.md) |
| **Need quick command lookup** | Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) |
| **Comprehensive guide** | Read [README.md](README.md) |

---

## 📖 Full Documentation

### Getting Started
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** ⭐ **START HERE**
  - What was created
  - Architecture overview
  - Quick overview of all 5 guides
  - Next steps

- **[README.md](README.md)** - Complete Reference
  - Project overview
  - Prerequisites
  - Project structure explained
  - Quick start (local)
  - Azure DevOps setup
  - Running the pipeline
  - Outputs and SSH access
  - Troubleshooting
  - Security best practices
  - Cleanup

### Setup & Configuration
- **[SETUP_GUIDE.md](SETUP_GUIDE.md)** - Azure DevOps Configuration
  - Prerequisites checklist
  - Phase 1: Azure infrastructure setup (commands)
  - Phase 2: Azure DevOps project setup
  - Phase 3: Repository setup
  - Running the pipeline
  - Post-pipeline VM access
  - Detailed troubleshooting
  - Security checklist

- **[LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md)** - Local Development
  - Prerequisites
  - 5-step development workflow
  - Common development tasks
  - Debugging techniques
  - Best practices
  - IDE integration
  - Git workflow
  - Performance tips
  - Troubleshooting

### Quick Reference
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command Lookup
  - Quick start commands
  - Azure CLI essentials
  - SSH key management
  - File locations table
  - DevOps variables table
  - Common workflows
  - Troubleshooting checklist
  - Emergency commands
  - Pro tips

---

## 🏗️ Infrastructure Files

### Terraform Root Configuration
Located in `/terraform`:
- `versions.tf` - Provider requirements and remote backend
- `providers.tf` - Azure provider configuration
- `variables.tf` - All input variables (with validation)
- `main.tf` - Main configuration (resource group + modules)
- `outputs.tf` - Output values (VM IP, SSH command, etc.)

### Network Module
Located in `/terraform/modules/network`:
- `main.tf` - Virtual Network, Subnets, NSG with 6 security rules
- `variables.tf` - Module input variables
- `outputs.tf` - Module output values

**Creates**:
- Virtual Network: 10.0.0.0/16
- App Subnet: 10.0.1.0/24
- Management Subnet: 10.0.2.0/24
- NSG with rules for SSH, HTTP, HTTPS

### Compute Module
Located in `/terraform/modules/compute`:
- `main.tf` - Public IP, Network Interface, Linux VM
- `variables.tf` - Module input variables
- `outputs.tf` - Module output values

**Creates**:
- Static Public IP
- Network Interface Card
- Ubuntu 22.04 LTS VM
- SSH key authentication

### Environment Configuration
Located in `/terraform/env/dev`:
- `dev.tfvars` - Development environment values

---

## 🔄 CI/CD Pipeline Files

### Main Pipeline
Located in `/pipelines`:
- `azure-pipelines.yml` - Main pipeline definition
  - **Stages**: Validate → Plan → Apply → VMHealthCheck
  - **Triggers**: Push to main/develop, PRs to main

### Pipeline Templates
Located in `/pipelines/templates`:
- `terraform-steps.yml` - Reusable Terraform steps
  - Setup Terraform
  - Download SSH key
  - Initialize backend
  - Format check
  - Validate
  - Plan
  - Apply
  - Export outputs

- `vm-health-check.yml` - Post-deployment health checks
  - SSH setup
  - Wait for VM readiness
  - Install Nginx
  - Verify services
  - Check port connectivity
  - Summary report

---

## 🔧 Scripts

Located in `/scripts`:
- `check_processes.sh` - Process verification utility
  - Check if processes are running
  - Colored output
  - Summary reporting
  - Exit codes for automation

---

## 📋 Quick Command Reference

### Initialize & Validate Locally
```bash
cd terraform
terraform init -backend=false
terraform fmt -recursive .
terraform validate
```

### Plan Deployment
```bash
terraform plan \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"
```

### Apply Infrastructure
```bash
terraform apply \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"
```

### Get VM Details
```bash
terraform output vm_public_ip
terraform output ssh_command
```

### SSH into VM
```bash
VM_IP=$(terraform output -raw vm_public_ip)
ssh -i ~/.ssh/id_rsa azureuser@$VM_IP
```

### Destroy Resources
```bash
terraform destroy -auto-approve \
  -var-file="env/dev/dev.tfvars" \
  -var="subscription_id=$(az account show --query id -o tsv)"
```

---

## 🔐 Important Variables

**Critical - Must Update Before Deploying:**
- `subscription_id` - Your Azure subscription ID
- `project_prefix` - Used in all resource names (keep it short!)
- `admin_source_ip` - YOUR IP for SSH access (critical for security!)
- `public_key_path` - Path to your SSH public key

**Optional - Already Have Defaults:**
- `environment` - Default: `dev`
- `location` - Default: `East US`
- `vm_size` - Default: `Standard_B2s`
- `enable_http` - Default: `true`

---

## 🆘 Troubleshooting Matrix

| Error | Quick Fix | Details |
|-------|-----------|---------|
| Format errors | `terraform fmt -recursive .` | See LOCAL_DEVELOPMENT.md |
| Validation errors | `terraform validate` | See README.md |
| SSH connection fails | Update `admin_source_ip` | See QUICK_REFERENCE.md |
| Storage not found | Check `BACKEND_STORAGE_ACCOUNT` | See SETUP_GUIDE.md |
| Azure auth fails | Run `az login` | See LOCAL_DEVELOPMENT.md |

---

## 📊 Architecture Quick Look

```
User/Pipeline
    ↓
Azure Resource Group
    ├─ Virtual Network (10.0.0.0/16)
    │  ├─ App Subnet (10.0.1.0/24)
    │  └─ Management Subnet (10.0.2.0/24)
    ├─ Network Security Group (SSH + HTTP/HTTPS)
    ├─ Public IP (Static)
    └─ Linux VM (Ubuntu 22.04)
       ├─ SSH Key Auth (Secure)
       └─ Nginx (Running)
```

---

## 🎯 Typical Workflow

### 1. Local Development
1. Clone repository
2. Update `terraform/env/dev/dev.tfvars`
3. Run `terraform init -backend=false`
4. Run `terraform plan`
5. Review output
6. Commit changes

### 2. Deploy via Pipeline
1. Push to main branch
2. Pipeline triggers automatically
3. Review plan in Azure DevOps
4. Pipeline continues to apply
5. Health checks verify deployment
6. SSH into VM

### 3. Iterate
1. Make infrastructure changes
2. Run `terraform plan` locally
3. Push to main
4. Pipeline re-deploys
5. Verify changes

---

## 📞 Getting Help

### Step 1: Check Documentation
- Is this about setup? → [SETUP_GUIDE.md](SETUP_GUIDE.md)
- Is this about commands? → [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- Is this about local dev? → [LOCAL_DEVELOPMENT.md](LOCAL_DEVELOPMENT.md)
- General question? → [README.md](README.md)

### Step 2: Enable Debug Logging
```bash
export TF_LOG=DEBUG
terraform plan
# Check logs at /tmp/terraform.log or TF_LOG_PATH
```

### Step 3: Check Terraform State
```bash
terraform state list
terraform state show <resource>
```

### Step 4: Check Azure Resources
```bash
az resource list --resource-group myapp-dev-rg
```

---

## ✅ Pre-Deployment Checklist

- [ ] Read PROJECT_SUMMARY.md
- [ ] Updated `admin_source_ip` in dev.tfvars
- [ ] Updated `project_prefix` in dev.tfvars
- [ ] Updated `subscription_id` in dev.tfvars
- [ ] SSH keys generated (`~/.ssh/id_rsa` exists)
- [ ] Ran `terraform validate` locally
- [ ] Azure CLI authenticated (`az login`)
- [ ] Azure DevOps service connection created (if using pipeline)
- [ ] SSH secure file uploaded (if using pipeline)
- [ ] Pipeline variables configured (if using pipeline)

---

## 📅 File Last Updated

- PROJECT_SUMMARY.md - 2024
- README.md - 2024
- SETUP_GUIDE.md - 2024
- LOCAL_DEVELOPMENT.md - 2024
- QUICK_REFERENCE.md - 2024
- Terraform files - 2024
- Pipeline files - 2024

---

## 🌟 Key Features at a Glance

✅ **Modular Terraform** - Separate network and compute modules  
✅ **Secure by Default** - SSH key-only, no passwords  
✅ **Highly Configurable** - All values via variables  
✅ **CI/CD Ready** - Full 4-stage Azure DevOps pipeline  
✅ **Health Checks** - Post-deployment verification  
✅ **Remote State** - Azure Storage for state management  
✅ **Well Documented** - 5 comprehensive guides  
✅ **Beginner Friendly** - Lots of examples and explanations  

---

**Ready to get started? → See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)**

**Questions? → Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md)**

**Need setup help? → Follow [SETUP_GUIDE.md](SETUP_GUIDE.md)**
