# Define Local Values in Terraform
locals {
  owners = var.business_divsion
  environment = var.environment
  resource_name_prefix = "${var.business_divsion}-${var.environment}"
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    owners = local.owners
    environment = local.environment
    
  }
} 

data "azurerm_resource_group" "rg" {
    name = "NA-dev-rg"
  
}
data "azurerm_subnet" "bastionsubnet" {
    name = "NA-dev-vnet-bastionsubnet"
    resource_group_name = "NA-dev-rg"
    virtual_network_name = "NA-dev-vnet"
  
}

# Resource-1: Create Public IP Address
resource "azurerm_public_ip" "bastion_host_publicip" {
  name                = "${local.resource_name_prefix}-bastion-host-publicip"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku = "Standard"
}

# Resource-2: Create Network Interface
resource "azurerm_network_interface" "bastion_host_linuxvm_nic" {
  name                = "${local.resource_name_prefix}-bastion-host-linuxvm-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "bastion-host-ip-1"
    subnet_id                     = data.azurerm_subnet.bastionsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.bastion_host_publicip.id 
  }
}

# Resource-3: Azure Linux Virtual Machine - Bastion Host
resource "azurerm_linux_virtual_machine" "bastion_host_linuxvm" {
  name = "${local.resource_name_prefix}-bastion-linuxvm"
  #computer_name = "bastionlinux-vm"  # Hostname of the VM (Optional)
  resource_group_name = data.azurerm_resource_group.rg.name
  location = data.azurerm_resource_group.rg.location
  size = "Standard_DS1_v2"
  admin_username = "azureuser"
  network_interface_ids = [ azurerm_network_interface.bastion_host_linuxvm_nic.id ]
  admin_ssh_key {
    username = "azureuser"
    public_key = file("../ssh-keys/terraform-azure.pem.pub")
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "RedHat"
    offer = "RHEL"
    sku = "83-gen2"
    version = "latest"
  }
}

# Create a Null Resource and Provisioners
resource "null_resource" "name" {
  depends_on = [azurerm_linux_virtual_machine.bastion_host_linuxvm]
# Connection Block for Provisioners to connect to Azure VM Instance
  connection {
    type = "ssh"
    host = azurerm_linux_virtual_machine.bastion_host_linuxvm.public_ip_address
    user = azurerm_linux_virtual_machine.bastion_host_linuxvm.admin_username
    private_key = file("~/Documents/Azure/ssh-keys/terraform-azure.pem")
  }

## File Provisioner: Copies the terraform-key.pem file to /tmp/terraform-key.pem
  provisioner "file" {
    source      = "~/Documents/Azure/ssh-keys/terraform-azure.pem"
    destination = "/tmp/terraform-azure.pem"
  }
## Remote Exec Provisioner: Using remote-exec provisioner fix the private key permissions on Bastion Host
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/terraform-azure.pem"
    ]
  }
}

# Creation Time Provisioners - By default they are created during resource creations (terraform apply)
# Destory Time Provisioners - Will be executed during "terraform destroy" command (when = destroy)
