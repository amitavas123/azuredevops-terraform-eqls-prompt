output "resource_group_name" {
  description = "Name of the created Resource Group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created Resource Group"
  value       = azurerm_resource_group.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = module.network.vnet_name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.network.vnet_id
}

output "app_subnet_id" {
  description = "ID of the app subnet"
  value       = module.network.app_subnet_id
}

output "mgmt_subnet_id" {
  description = "ID of the management subnet"
  value       = module.network.mgmt_subnet_id
}

output "nsg_id" {
  description = "ID of the Network Security Group"
  value       = module.network.nsg_id
}

output "vm_public_ip" {
  description = "Public IP address of the Linux VM"
  value       = module.compute.vm_public_ip
}

output "vm_private_ip" {
  description = "Private IP address of the Linux VM"
  value       = module.compute.vm_private_ip
}

output "vm_name" {
  description = "Name of the Linux VM"
  value       = module.compute.vm_name
}

output "vm_id" {
  description = "ID of the Linux VM"
  value       = module.compute.vm_id
}

output "nic_id" {
  description = "ID of the Network Interface Card"
  value       = module.compute.nic_id
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh -i <path-to-private-key> ${module.compute.vm_admin_username}@${module.compute.vm_public_ip}"
}

output "vm_admin_username" {
  description = "Admin username for the VM"
  value       = module.compute.vm_admin_username
}
