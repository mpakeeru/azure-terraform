resource "azurerm_virtual_network_peering" "hub-adbvnet" {
  name                      = "hub-adbvnet"
  resource_group_name       = "NA-dev-rg"
  virtual_network_name      = data.azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.abd_vnet.id
}

resource "azurerm_virtual_network_peering" "adbvnet-hub" {
  name                      = "adbvnet-hub"
  resource_group_name       = data.azurerm_resource_group.data-lake-rg.name
  virtual_network_name      = azurerm_virtual_network.abd_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet.id
}