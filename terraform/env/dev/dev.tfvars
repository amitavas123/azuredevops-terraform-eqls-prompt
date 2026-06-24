# Development Environment Variables

subscription_id  = "ba4d7370-8df0-4392-b5b9-d99d93e39cd7"
project_prefix   = "ams-"
environment      = "dev"
location         = "East US"
admin_source_ip  = "192.168.20.18/32"  # Change this to your IP for production (e.g., "203.0.113.0/32")
enable_http      = true
http_source_cidr = "0.0.0.0/0"

# Network
vnet_cidr        = "10.0.0.0/16"
app_subnet_cidr  = "10.0.1.0/24"
mgmt_subnet_cidr = "10.0.2.0/24"

# Compute
vm_admin_username = "azureuser"
vm_size           = "Standard_B2s"

# Ubuntu 22.04 LTS
vm_image_publisher = "Canonical"
vm_image_offer     = "0001-com-ubuntu-server-jammy"
vm_image_sku       = "22_04-lts-gen2"
vm_image_version   = "latest"

# SSH Key
public_key_path = "~/.ssh/id_rsa.pub"
ssh_key_name    = "vm-ssh-key"

tags = {
  terraform   = "true"
  created_by  = "terraform"
  environment = "dev"
  project     = "eqls-prompt"
  team        = "devops"
}
