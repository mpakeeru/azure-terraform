resource "azurerm_private_dns_zone" "dnsblob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg-aks.name
}

resource "azurerm_private_dns_zone" "dnsvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg-aks.name
}

resource "azurerm_private_dns_zone" "dnscr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.rg-aks.name
}

resource "azurerm_private_dns_zone" "dnsazmk8" {
  name                = "privatelink.region.azmk8s.io"
  resource_group_name = azurerm_resource_group.rg-aks.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "blobdnszonevnetlink" {
  name                  = "blobspokevnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsblob.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vaultdnszonevnetlink" {
  name                  = "vaultspokevnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsvault.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "crdnszonevnetlink" {
  name                  = "crspokevnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnscr.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "azmk8sdnszonevnetlink" {
  name                  = "azmk8sspokevnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsazmk8.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "blobdnszonevnetlink-hub" {
  name                  = "blobhubvnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsblob.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "vaultdnszonevnetlink-hub" {
  name                  = "vaulthubvnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsvault.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "crdnszonevnetlink-hub" {
  name                  = "crhubvnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnscr.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "azmk8sdnszonevnetlink-hub" {
  name                  = "azmk8shubvnetconnection-aks"
  resource_group_name   = azurerm_resource_group.rg-aks.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsazmk8.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}