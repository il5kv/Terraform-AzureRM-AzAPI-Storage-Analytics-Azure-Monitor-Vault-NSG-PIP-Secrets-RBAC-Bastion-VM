resource "azurerm_resource_group" "main" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.primary_region
}

resource "random_string" "keyvault_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.application_name}-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.base_address_space]
}

locals {
  bastion_address_space = cidrsubnet(var.base_address_space, 4, 0)
  b_address_space       = cidrsubnet(var.base_address_space, 2, 1)
  c_address_space       = cidrsubnet(var.base_address_space, 2, 2)
  d_address_space       = cidrsubnet(var.base_address_space, 2, 3)
}

/*# 10.23.0.0/26
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.bastion_address_space]
}*/

# 10.23.1.0/24
resource "azurerm_subnet" "b" {
  name                 = "snet-b"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.b_address_space]
}

# 10.23.2.0/24
resource "azurerm_subnet" "c" {
  name                 = "snet-c"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.c_address_space]
}

# 10.23.3.0/24
resource "azurerm_subnet" "d" {
  name                 = "snet-d"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [local.d_address_space]
}

/*resource "azurerm_network_security_group" "remote-access" {
  name                = "nsg-${var.application_name}-${var.environment_name}-remote-access"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = chomp(data.http.my_ip.body)
    destination_address_prefix = "*"
  }
}

data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

resource "azurerm_public_ip" "bastion" {
  name                = "pip-${var.application_name}-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "main" {
  name                = "bas-${var.application_name}-${var.environment_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}*/
