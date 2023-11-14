resource "azurerm_virtual_network_peering" "hub-aksvnet" {
  name                      = "hub-aksvnet"
  resource_group_name       = "${local.owners}-${local.environment}-rg"
  virtual_network_name      = data.azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_virtual_network_peering" "aksvnet-hub" {
  name                      = "aksvnet-hub"
  resource_group_name       = azurerm_resource_group.rg-aks.name
  virtual_network_name      = azurerm_virtual_network.aks_vnet.name
  remote_virtual_network_id = data.azurerm_virtual_network.vnet.id
}