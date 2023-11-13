# password generator
resource "random_password" "dbhost_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1

}

# save to key vault
resource "azurerm_key_vault_secret" "dbhost_login" {
  name            = "db-host-pwd"
  value           = random_password.dbhost_password.result
  key_vault_id    = data.azurerm_key_vault.myKeyVault.id
  content_type    = "string"
  expiration_date = "2111-12-31T00:00:00Z"
}

#Create NIC for Jumphost
resource "azurerm_network_interface" "dbhost_nic" {
  name                = "nic-db-${local.basename}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  ip_configuration {
    name                          = "configuration"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.adb_plsubnet.id
  }
}

#Create security group for jumphost
resource "azurerm_network_security_group" "dbhost_nsg" {
  name                = "nsg-db-${local.basename}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  security_rule {
    name                       = "RDP"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 3389
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "syn_dbhost_nsg_association" {
  network_interface_id      = azurerm_network_interface.dbhost_nic.id
  network_security_group_id = azurerm_network_security_group.dbhost_nsg.id
}




#Create Jump Host Resource
resource "azurerm_virtual_machine" "dbhost" {
  name                  = "wvm-db-${local.basename}"
  location              = azurerm_resource_group.default.location
  resource_group_name   = azurerm_resource_group.default.name
  network_interface_ids = [azurerm_network_interface.dbhost_nic.id]
  vm_size               = "Standard_DS3_v2"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "dsvm-win-2019"
    sku       = "server-2019"
    version   = "latest"
  }

  os_profile {
    computer_name  = "dbhost"
    admin_username = var.dbhost_username
    admin_password = azurerm_key_vault_secret.dbhost_login.value
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name              = "disk-db-${local.basename}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
}

# Create automatic shutdown schedule

resource "azurerm_dev_test_global_vm_shutdown_schedule" "syn_dbhost_schedule" {
  virtual_machine_id = azurerm_virtual_machine.dbhost.id
  location           = azurerm_resource_group.default.location
  enabled            = true

  daily_recurrence_time = "2300"
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled = false
  }
}