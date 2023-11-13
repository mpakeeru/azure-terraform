# Create Virtual Network
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${local.resource_name_prefix}-${var.vnet_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg-aks.location
  resource_group_name = azurerm_resource_group.rg-aks.name
  tags = local.common_tags
}

# Resource-1: Create AKS Subnet
resource "azurerm_subnet" "akssubnet" {
  name                 = "${azurerm_virtual_network.aks_vnet.name}-${var.aks_subnet_name}"
  resource_group_name  = azurerm_resource_group.rg-aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.aks_subnet_address  
}

# Resource-2: Create Network Security Group (NSG) for AKS Subnet
resource "azurerm_network_security_group" "aks_subnet_nsg" {
  name                = "${azurerm_subnet.akssubnet.name}-nsg"
  location            = azurerm_resource_group.rg-aks.location
  resource_group_name = azurerm_resource_group.rg-aks.name
}

# Resource-3: Associate NSG and Subnet for AKS Subnet
resource "azurerm_subnet_network_security_group_association" "aks_subnet_nsg_associate" {
 # depends_on = [ azurerm_network_security_rule.aks_nsg_rule_inbound]    
  subnet_id                 = azurerm_subnet.akssubnet.id
  network_security_group_id = azurerm_network_security_group.aks_subnet_nsg.id
}

# Resource-1: Create AKS PE Subnet
resource "azurerm_subnet" "akspesubnet" {
  name                 = "${azurerm_virtual_network.aks_vnet.name}-${var.akspe_subnet_name}"
  resource_group_name  = azurerm_resource_group.rg-aks.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = var.akspe_subnet_address  
}

# Resource-2: Create Network Security Group (NSG) for AKS PE Subnet
resource "azurerm_network_security_group" "akspe_subnet_nsg" {
  name                = "${azurerm_subnet.akspesubnet.name}-nsg"
  location            = azurerm_resource_group.rg-aks.location
  resource_group_name = azurerm_resource_group.rg-aks.name
}

# Resource-3: Associate NSG and Subnet for AKS PE Subnet
resource "azurerm_subnet_network_security_group_association" "akspe_subnet_nsg_associate" {
 # depends_on = [ azurerm_network_security_rule.aks_nsg_rule_inbound]    
  subnet_id                 = azurerm_subnet.akspesubnet.id
  network_security_group_id = azurerm_network_security_group.akspe_subnet_nsg.id
}