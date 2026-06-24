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

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
}

variable "app_subnet_cidr" {
  description = "CIDR block for the app subnet"
  type        = string
}

variable "mgmt_subnet_cidr" {
  description = "CIDR block for the management subnet"
  type        = string
}

variable "admin_source_ip" {
  description = "Source IP/CIDR for SSH access"
  type        = string
}

variable "enable_http" {
  description = "Enable HTTP access"
  type        = bool
  default     = true
}

variable "http_source_cidr" {
  description = "CIDR block for HTTP access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}
