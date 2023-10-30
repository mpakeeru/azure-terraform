# password generator
resource "random_password" "synadmin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1

}

# save to key vault
resource "azurerm_key_vault_secret" "synadmin_password" {
  name            = "synadmin-pwd"
  value           = random_password.synadmin_password.result
  key_vault_id    = data.azurerm_key_vault.myKeyVault.id
  content_type    = "string"
  expiration_date = "2111-12-31T00:00:00Z"
}

resource "azurerm_synapse_workspace" "default" {
  name                                 = "syn-venkat-${var.environment}"
  resource_group_name                  = data.azurerm_resource_group.data-lake-rg.name
  location                             = data.azurerm_resource_group.data-lake-rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.default.id

  sql_administrator_login          = var.synadmin_username
  sql_administrator_login_password = azurerm_key_vault_secret.synadmin_password.value

  managed_virtual_network_enabled = true
  managed_resource_group_name     = "${data.azurerm_resource_group.data-lake-rg.name}-syn-managed"

  public_network_access_enabled = false

  aad_admin {
    login = var.aad_login.name
    object_id = var.aad_login.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }
}

# DNS Zones

resource "azurerm_private_dns_zone" "zone_dev" {
  name                = "privatelink.dev.azuresynapse.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

resource "azurerm_private_dns_zone" "zone_sql" {
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

# Linking of DNS zones to Virtual Network

resource "azurerm_private_dns_zone_virtual_network_link" "zone_dev_link" {
  name                  = "${local.basename}_link_dev"
  resource_group_name   = data.azurerm_resource_group.data-lake-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone_dev.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "zone_sql_link" {
  name                  = "${local.basename}_link_sql"
  resource_group_name   = data.azurerm_resource_group.data-lake-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.zone_sql.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

# Private Endpoint configuration

# Private Endpoint for Dev
resource "azurerm_private_endpoint" "pe_dev" {
  name                = "pe-${azurerm_synapse_workspace.default.name}-dev"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "psc-dev-${local.basename}"
    private_connection_resource_id = azurerm_synapse_workspace.default.id
    subresource_names              = ["dev"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-dev"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone_dev.id]
  }
}

# Private Endpoint for Serverless SQL
resource "azurerm_private_endpoint" "pe_sql" {
  name                = "pe-${azurerm_synapse_workspace.default.name}-sql"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "psc-sql-${local.basename}"
    private_connection_resource_id = azurerm_synapse_workspace.default.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-sql"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone_sql.id]
  }
}

# Private Endpoint for SQL on Demand
resource "azurerm_private_endpoint" "pe_sqlondemand" {
  name                = "pe-${azurerm_synapse_workspace.default.name}-sqlondemand"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "psc-sqlondemand-${local.basename}"
    private_connection_resource_id = azurerm_synapse_workspace.default.id
    subresource_names              = ["sqlondemand"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-sqlondemand"
    private_dns_zone_ids = [azurerm_private_dns_zone.zone_sql.id]
  }
}