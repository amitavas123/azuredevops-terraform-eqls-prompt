variable "subscription_id" {
  description = "The Azure Subscription ID"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for all resource names (e.g., 'myapp')"
  type        = string
  validation {
    condition     = length(var.project_prefix) <= 10 && can(regex("^[a-z][a-z0-9]*$", var.project_prefix))
    error_message = "Project prefix must be 1-10 lowercase alphanumeric characters and start with a letter."
  }
}

variable "environment" {
  description = "Environment name (e.g., 'dev', 'staging', 'prod')"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    terraform   = "true"
    created_by  = "terraform"
    environment = "dev"
  }
}

# Network variables
variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "app_subnet_cidr" {
  description = "CIDR block for the app subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "mgmt_subnet_cidr" {
  description = "CIDR block for the management subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "admin_source_ip" {
  description = "Source IP/CIDR for SSH access (e.g., '203.0.113.0/32' or your IP)"
  type        = string
  validation {
    condition     = can(cidrhost(var.admin_source_ip, 0))
    error_message = "Must be a valid CIDR block (e.g., '1.2.3.4/32' or '10.0.0.0/8')."
  }
}

variable "enable_http" {
  description = "Enable HTTP (port 80) access from anywhere"
  type        = bool
  default     = true
}

variable "http_source_cidr" {
  description = "CIDR block for HTTP access (only used if enable_http is true)"
  type        = string
  default     = "0.0.0.0/0"
}

# Compute variables
variable "vm_admin_username" {
  description = "Admin username for the Linux VM"
  type        = string
  default     = "azureuser"
  validation {
    condition     = length(var.vm_admin_username) >= 1 && length(var.vm_admin_username) <= 64
    error_message = "Admin username must be between 1 and 64 characters."
  }
}

variable "vm_size" {
  description = "Azure VM size (e.g., 'Standard_B2s', 'Standard_B1s')"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "vm_image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "vm_image_sku" {
  description = "SKU of the VM image (Ubuntu LTS versions)"
  type        = string
  default     = "22_04-lts-gen2"
}

variable "vm_image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

variable "public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "vm-ssh-key"
}
