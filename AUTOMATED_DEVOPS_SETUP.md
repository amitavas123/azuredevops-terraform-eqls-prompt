# Automated Azure DevOps Phase 2 Setup

This guide explains how to use the automated Phase 2 setup script instead of manual UI clicks.

## 📋 What Gets Automated

✅ **Service Connection Creation** - Creates `terraform-azure-connection`  
✅ **SSH Key Upload** - Uploads and authorizes secure file  
✅ **Environment Creation** - Creates `Azure-dev` environment  
ℹ️ **Pipeline Variables** - Instructions for manual creation (works better after pipeline exists)

---

## 📦 Prerequisites

Before running the script, ensure you have:

### Required Tools
```bash
# Azure CLI (v2.37+)
az --version

# Azure DevOps extension
az extension list | grep azure-devops

# jq (JSON processor)
jq --version

# SSH keys
ls ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
```

Install missing tools:
```bash
# macOS
brew install azure-cli jq

# Ubuntu/Debian
sudo apt-get install azure-cli jq

# Windows (using chocolatey)
choco install azure-cli jq
```

### Azure DevOps Personal Access Token (PAT)

1. Go to: https://dev.azure.com/YOUR_ORG/_usersSettings/tokens
2. Click **New Token**
3. Name: `Terraform Setup`
4. Organization: Select your org
5. Scopes: Select **Full access** (or custom: Read/Write - Secure Files, Environments, Service Connections, Variables)
6. Click **Create**
7. **Copy the token** (you'll use it in the script)

⚠️ **Store securely - you can't view it again after creating!**

### Phase 1 Outputs

You need these from Phase 1 (SETUP_GUIDE.md):
- `SUBSCRIPTION_ID` - Your Azure subscription ID
- `APP_ID` - Service Principal client ID
- `PASSWORD` - Service Principal client secret
- `TENANT_ID` - Azure tenant ID
- `STORAGE_ACCOUNT_NAME` - Name of storage account for Terraform state

---

## 🚀 Running the Script

### Step 1: Make Script Executable
```bash
cd /path/to/azuredevops-terraform-eqls-prompt
chmod +x scripts/setup-devops-phase2.sh
```

### Step 2: Run the Script
```bash
./scripts/setup-devops-phase2.sh
```

### Step 3: Provide Inputs When Prompted

The script will ask for:
```
Enter Azure DevOps Organization name: your-org
Enter Azure DevOps Project name: your-project
Enter Azure DevOps Personal Access Token: ***
Enter SUBSCRIPTION_ID: ba4d7370-8df0-4392-b5b9-d99d93e39cd7
Enter APP_ID (Client ID): xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Enter PASSWORD (Client Secret): ****
Enter TENANT_ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
Enter STORAGE_ACCOUNT_NAME (from Phase 1): tfstate1234567890
```

---

## ✅ What the Script Does

### 1. Validates Prerequisites
- ✓ Azure CLI installed
- ✓ Azure DevOps extension installed
- ✓ jq installed
- ✓ SSH keys exist

### 2. Collects Your Configuration
- Organization URL
- Project name
- Personal Access Token
- Service Principal details
- Storage account name

### 3. Creates Service Connection
```
Created: terraform-azure-connection
  - Service Principal authentication
  - All Azure resources accessible
```

### 4. Uploads SSH Key
```
Uploaded to: Secure Files > id_rsa
  - Authorized for all pipelines
  - Ready for pipeline use
```

### 5. Creates Environment
```
Created: Azure-dev
  - Ready for pipeline deployments
  - Ready for approval configuration
```

### 6. Outputs Summary
Shows links to verify everything in Azure DevOps UI

---

## 📊 Output Example

```
╔════════════════════════════════════════════════════════════╗
║ Azure DevOps Phase 2 Automated Setup                      ║
╚════════════════════════════════════════════════════════════╝

▶ Checking prerequisites...
✓ Azure CLI found: azure-cli 2.45.0
✓ Azure DevOps extension found
✓ jq found
✓ SSH keys found at ~/.ssh/

▶ Collecting configuration inputs...
Enter Azure DevOps Organization name: myorg
Enter Azure DevOps Project name: terraform-project
...

✓ All inputs collected

╔════════════════════════════════════════════════════════════╗
║ Configuring Azure DevOps CLI                              ║
╚════════════════════════════════════════════════════════════╝

✓ Azure DevOps CLI configured and authenticated

╔════════════════════════════════════════════════════════════╗
║ Creating Azure Resource Manager Service Connection         ║
╚════════════════════════════════════════════════════════════╝

▶ Creating service connection: terraform-azure-connection
✓ Service connection created: terraform-azure-connection

... [more steps] ...

╔════════════════════════════════════════════════════════════╗
║ Phase 2 Setup Summary                                      ║
╚════════════════════════════════════════════════════════════╝

Completed Actions:
  ✓ Azure DevOps CLI configured
  ✓ Service connection created: terraform-azure-connection
  ✓ SSH key uploaded to secure files (authorized)
  ✓ Environment created: Azure-dev

Next Steps:
  1. Create Pipeline Variables (best done after pipeline creation)
     Go to: Azure DevOps > Pipelines > Your Pipeline > Edit > Variables
  ...

✓ Phase 2 setup completed!
```

---

## 🔧 After the Script Runs

### 1. Create Pipeline Variables

The script recommends creating variables after the pipeline exists. Here's how:

1. Go to Azure DevOps
2. Go to **Pipelines** → Your pipeline
3. Click **Edit** (pencil icon)
4. Click **Variables** (top right)
5. Add non-secret variables:
   - `BACKEND_RESOURCE_GROUP` = `terraform-state-rg`
   - `BACKEND_STORAGE_ACCOUNT` = (Your storage account name)
   - `BACKEND_CONTAINER` = `tfstate`
   - `terraformVersion` = `1.5.0`
6. Add secret variables (click lock icon):
   - `ARM_SUBSCRIPTION_ID` = (Your subscription ID)
   - `ARM_CLIENT_ID` = (Your app ID)
   - `ARM_CLIENT_SECRET` = (Your password)
   - `ARM_TENANT_ID` = (Your tenant ID)
7. Click **Save**

### 2. Follow Phase 3 (Repository Setup)

Continue with Phase 3 from SETUP_GUIDE.md:
- Configure `dev.tfvars`
- Create the pipeline YAML
- Push to repository

---

## 🐛 Troubleshooting

### "Azure CLI not found"
```bash
# Install Azure CLI
# macOS: brew install azure-cli
# Ubuntu: sudo apt-get install azure-cli
# Windows: https://docs.microsoft.com/cli/azure/install-azure-cli-windows
```

### "jq not found"
```bash
# Install jq
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq
# Windows: https://stedolan.github.io/jq/download/
```

### "Personal Access Token invalid"
- Check token hasn't expired (tokens expire after 1 year by default)
- Regenerate token and try again
- Ensure token has scopes: Secure Files, Environments, Service Connections

### "Service connection creation failed"
- Verify Service Principal credentials are correct
- Ensure subscription ID is valid
- Try creating manually via UI: Project Settings → Service connections

### "SSH key upload failed"
- Try uploading manually: Pipelines → Library → Secure files
- Ensure SSH key file exists at `~/.ssh/id_rsa`
- Check PAT has "Secure Files" scope

### "Environment creation failed"
- Try creating manually: Pipelines → Environments → New environment
- Name it: `Azure-dev`

---

## 📝 Script Features

### Error Handling
- Validates all prerequisites before starting
- Checks for required tools
- Validates user inputs
- Clear error messages with solutions

### User-Friendly Output
- Colored output (green for success, yellow for steps, red for errors)
- Progress indicators
- Summary at the end
- Next steps clearly listed

### Security
- PAT entered hidden (doesn't echo to terminal)
- Client secret entered hidden
- No credentials logged to files
- Uses secure REST API calls

---

## 🔄 Manual Alternative

If the script doesn't work or you prefer manual setup, use SETUP_GUIDE.md Phase 2 steps.

---

## 📚 Next: Phase 3

After this automated setup completes, follow **Phase 3 (Repository Setup)** in SETUP_GUIDE.md:

1. Clone/update repository
2. Configure `dev.tfvars` with your values
3. Create pipeline YAML
4. Push to `main` branch
5. Pipeline runs automatically!

---

## 🎯 Time Savings

| Approach | Time | Effort |
|----------|------|--------|
| Manual UI clicks | ~10-15 min | High (many clicks) |
| Automated script | ~2-3 min | Low (one command) |

**Script saves ~10 minutes and eliminates click errors!** ✨

---

## 📞 Need Help?

1. Check Troubleshooting section above
2. Review SETUP_GUIDE.md for manual steps
3. Check Azure DevOps documentation
4. Verify all prerequisites are installed

---

**Ready to run the script?**

```bash
chmod +x scripts/setup-devops-phase2.sh
./scripts/setup-devops-phase2.sh
```

Happy automating! 🚀
