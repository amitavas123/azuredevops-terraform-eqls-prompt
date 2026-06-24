output "vm_id" {
  description = "ID of the Linux VM"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_name" {
  description = "Name of the Linux VM"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_public_ip" {
  description = "Public IP address of the Linux VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the Linux VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "nic_id" {
  description = "ID of the Network Interface Card"
  value       = azurerm_network_interface.main.id
}

output "public_ip_id" {
  description = "ID of the Public IP"
  value       = azurerm_public_ip.main.id
}

output "vm_admin_username" {
  description = "Admin username for the VM"
  value       = var.vm_admin_username
}
