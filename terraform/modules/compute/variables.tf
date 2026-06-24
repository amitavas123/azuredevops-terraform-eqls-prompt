variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "mgmt_subnet_id" {
  description = "ID of the management subnet"
  type        = string
}

variable "network_security_group_id" {
  description = "ID of the Network Security Group"
  type        = string
}

variable "vm_admin_username" {
  description = "Admin username for the Linux VM"
  type        = string
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
}

variable "vm_image_publisher" {
  description = "Publisher of the VM image"
  type        = string
}

variable "vm_image_offer" {
  description = "Offer of the VM image"
  type        = string
}

variable "vm_image_sku" {
  description = "SKU of the VM image"
  type        = string
}

variable "vm_image_version" {
  description = "Version of the VM image"
  type        = string
}

variable "public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}
