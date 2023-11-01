resource "azurerm_synapse_private_link_hub" "default" {
  name                = "synplh${var.environment}"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  location            = data.azurerm_resource_group.data-lake-rg.location
}

# DNS Zones

resource "azurerm_private_dns_zone" "zone_web" {
  name                = "privatelink.azuresynapse.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "pe_web" {
  name                = "pe-${azurerm_synapse_private_link_hub.default.name}-web"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "psc-web-${local.basename}"
    private_connection_resource_id = azurerm_synapse_private_link_hub.default.id
    subresource_names              = ["web"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-syn-web"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone_web.id]
  }
}