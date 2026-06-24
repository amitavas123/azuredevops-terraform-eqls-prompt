# Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.resource_name_prefix}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interface Card
resource "azurerm_network_interface" "main" {
  name                = "${var.resource_name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = var.mgmt_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = var.network_security_group_id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = "${var.resource_name_prefix}-vm"
  location            = var.location
  resource_group_name = var.resource_group_name
  vm_size             = var.vm_size

  admin_username = var.vm_admin_username

  # Disable password authentication and use SSH keys only
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.public_key_path)
  }

  source_image_reference {
    publisher = var.vm_image_publisher
    offer     = var.vm_image_offer
    sku       = var.vm_image_sku
    version   = var.vm_image_version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      source_image_reference[0].version
    ]
  }
}
