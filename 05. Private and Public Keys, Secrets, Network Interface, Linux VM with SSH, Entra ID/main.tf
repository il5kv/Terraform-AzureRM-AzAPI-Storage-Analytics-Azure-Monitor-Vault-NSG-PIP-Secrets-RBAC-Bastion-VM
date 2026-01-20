resource "azurerm_resource_group" "main" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.primary_region
}

data "azurerm_subnet" "subnet_b" {
  name                 = "snet-b"
  virtual_network_name = "vnet-network-${var.environment_name}"
  resource_group_name  = "rg-network-${var.environment_name}"
}

/* LOCAL KEYS
resource "local_file" "private_key" {
  content         = tls_private_key.vm1pk.private_key_pem
  filename        = pathexpand("~/.ssh/vm1")
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content  = tls_private_key.vm1pk.public_key_openssh
  filename = pathexpand("~/.ssh/vm1.pub")
}*/

data "azurerm_key_vault" "main" {
  name                = "kv-devops-${var.environment_name}-scvq3d"
  resource_group_name = "rg-devops-${var.environment_name}"
}

resource "azurerm_key_vault_secret" "vm1_ssh_private_key" {
  name         = "vm1-ssh-private-key"
  value        = tls_private_key.vm1pk.private_key_pem
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "vm1_ssh_public_key" {
  name         = "vm1-ssh-public-key"
  value        = tls_private_key.vm1pk.public_key_openssh
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "tls_private_key" "vm1pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "vm1" {
  name                = "pip-${var.application_name}-${var.environment_name}-vm1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm1" {
  name                = "nic-${var.application_name}-${var.environment_name}-vm1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "public"
    subnet_id                     = data.azurerm_subnet.subnet_b.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1${var.application_name}${var.environment_name}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm1.id,
  ]

  identity {
    type = "SystemAssigned"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.vm1pk.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "entra_id_login" {
  name                       = "${azurerm_linux_virtual_machine.vm1.name}-AADSSHLogin"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm1.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "entra_id_user_login" {
  scope                = azurerm_linux_virtual_machine.vm1.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = azuread_group.remote-access-users.object_id
}
