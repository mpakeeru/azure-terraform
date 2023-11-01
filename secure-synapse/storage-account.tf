# Create Storage account 
resource "azurerm_storage_account" "datalake" {
  name                     = "dlvenkat${var.environment}"
  resource_group_name      = data.azurerm_resource_group.data-lake-rg.name
  location                 = data.azurerm_resource_group.data-lake-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

# Create a storage container within storage account

resource "azurerm_storage_container" "container" {
  for_each              = toset( ["landing","bronze", "silver", "gold"] )
  name                  = each.key
  storage_account_name  = azurerm_storage_account.datalake.name
 
}
#Assign Role assignments

resource "azurerm_role_assignment" "sbdc_current_user" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "sbdc_admin_user" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "6bb54f24-94fa-478f-a2f8-80a52224a736"
}
resource "azurerm_role_assignment" "sbdc_datalake_service_principal" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.sp-data-lake.object_id
}

resource "azurerm_role_assignment" "sbdc_syn_ws" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.default.identity[0].principal_id
}

resource "azurerm_role_assignment" "c_syn_ws" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.default.identity[0].principal_id
}

#Create ADSL
resource "azurerm_storage_data_lake_gen2_filesystem" "default" {
  name               = "default"
  storage_account_id = azurerm_storage_account.datalake.id

  depends_on = [
    azurerm_role_assignment.sbdc_current_user
  ]
}

# Virtual Network & Firewall configuration

resource "azurerm_storage_account_network_rules" "firewall_rules" {
  storage_account_id = azurerm_storage_account.datalake.id

  default_action             = "Deny"
  ip_rules                   = [data.http.ip.response_body]
  virtual_network_subnet_ids = []
  bypass                     = ["None"]
  private_link_access {
    endpoint_resource_id = azurerm_data_factory_managed_private_endpoint.adf_manage_endpoint_blob.id
    endpoint_tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

# DNS Zones

resource "azurerm_private_dns_zone" "zone_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

resource "azurerm_private_dns_zone" "zone_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "zone_blob_link" {
  name                  = "${local.basename}_link_blob"
  resource_group_name   = data.azurerm_resource_group.data-lake-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone_blob.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "zone_dfs_link" {
  name                  = "${local.basename}_link_dfs"
  resource_group_name   = data.azurerm_resource_group.data-lake-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone_dfs.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

# Private Endpoint configuration

resource "azurerm_private_endpoint" "pe_blob" {
  name                = "pe-${azurerm_storage_account.datalake.name}-blob"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "psc-blob-${local.basename}"
    private_connection_resource_id = azurerm_storage_account.datalake.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone_blob.id]
  }
}

resource "azurerm_private_endpoint" "pe_dfs" {
  name                = "pe-${azurerm_storage_account.datalake.name}-dfs"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "psc-dfs-${local.basename}"
    private_connection_resource_id = azurerm_storage_account.datalake.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dfs"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone_dfs.id]
  }
}