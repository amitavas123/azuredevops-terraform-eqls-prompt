locals {
  common_tags = merge(
    var.tags,
    {
      environment = var.environment
      project     = var.project_prefix
      managed_by  = "terraform"
    }
  )

  resource_name_prefix = "${var.project_prefix}-${var.environment}"
}

# Create Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# Network Module
module "network" {
  source = "./modules/network"

  resource_group_name  = azurerm_resource_group.main.name
  resource_group_id    = azurerm_resource_group.main.id
  location             = azurerm_resource_group.main.location
  resource_name_prefix = local.resource_name_prefix

  vnet_cidr        = var.vnet_cidr
  app_subnet_cidr  = var.app_subnet_cidr
  mgmt_subnet_cidr = var.mgmt_subnet_cidr
  admin_source_ip  = var.admin_source_ip
  enable_http      = var.enable_http
  http_source_cidr = var.http_source_cidr

  tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  resource_group_name  = azurerm_resource_group.main.name
  resource_group_id    = azurerm_resource_group.main.id
  location             = azurerm_resource_group.main.location
  resource_name_prefix = local.resource_name_prefix

  mgmt_subnet_id            = module.network.mgmt_subnet_id
  network_security_group_id = module.network.nsg_id

  vm_admin_username = var.vm_admin_username
  vm_size           = var.vm_size

  vm_image_publisher = var.vm_image_publisher
  vm_image_offer     = var.vm_image_offer
  vm_image_sku       = var.vm_image_sku
  vm_image_version   = var.vm_image_version

  public_key_path = var.public_key_path
  ssh_key_name    = var.ssh_key_name

  tags = local.common_tags

  depends_on = [module.network]
}
