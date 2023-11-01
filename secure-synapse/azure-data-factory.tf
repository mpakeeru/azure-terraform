# Create Azure Data Factory
resource "azurerm_data_factory" "adf_transform" {
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  location            = data.azurerm_resource_group.data-lake-rg.location
  name = "vp-${var.environment}-adf01"
  public_network_enabled = false
  managed_virtual_network_enabled = true
  identity {
    type = "SystemAssigned"
  }
}

# Create Integration Runtime with virtual network enabled

resource "azurerm_data_factory_integration_runtime_azure" "adf_runtime_vnetwork" {
  name            = "vp-${var.environment}-runtime"
  data_factory_id = azurerm_data_factory.adf_transform.id
  location        = data.azurerm_resource_group.data-lake-rg.location
  virtual_network_enabled = true
}

# Create ADF Managenet Private Endpoint to blob storage
resource "azurerm_data_factory_managed_private_endpoint" "adf_manage_endpoint_blob" {
  name               = "vp-${var.environment}-managed-blob-pe"
  data_factory_id    = azurerm_data_factory.adf_transform.id
  target_resource_id = azurerm_storage_account.datalake.id
  subresource_name   = "blob"
}
/*
# Create ADF Managenet Private Endpoint to DFS storage
resource "azurerm_data_factory_managed_private_endpoint" "adf_manage_endpoint_dfs" {
  name               = "vp-${var.environment}-managed-dfs-pe"
  data_factory_id    = azurerm_data_factory.adf_transform.id
  target_resource_id = azurerm_storage_account.datalake.id
  subresource_name   = "dfs"
}
*/
# Retrieve the storage account details, including the private endpoint connections
data "azapi_resource" "datalake" {
  type                   = "Microsoft.Storage/storageAccounts@2022-09-01"
  resource_id            = azurerm_storage_account.datalake.id
  response_export_values = ["properties.privateEndpointConnections"]
}

# Retrieve the private endpoint connection name from the storage account based on the private endpoint name
locals {
  private_endpoint_connection_name_blob = element([
    for connection in jsondecode(data.azapi_resource.datalake.output).properties.privateEndpointConnections
    : connection.name
    if endswith(connection.properties.privateEndpoint.id, azurerm_data_factory_managed_private_endpoint.adf_manage_endpoint_blob.name)
  ], 0)
}

# Approve the private endpoint Blob
resource "azapi_update_resource" "approval_blob" {
  type      = "Microsoft.Storage/storageAccounts/privateEndpointConnections@2022-09-01"
  name      = local.private_endpoint_connection_name_blob
#  name = "${azurerm_data_factory.adf_transform.name}.${azurerm_data_factory_managed_private_endpoint.adf_manage_endpoint_blob.name}"
  parent_id = azurerm_storage_account.datalake.id

  body = jsonencode({
    properties = {
      privateLinkServiceConnectionState = {
        description = "Approved via Terraform"
        status      = "Approved"
      }
    }
  })
}

# ADF should have access to kv to read the service principal
resource "azurerm_key_vault_access_policy" "kv_adf_transform" {
  key_vault_id = data.azurerm_key_vault.myKeyVault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.adf_transform.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

# Create a linked service for Key Vault
resource "azurerm_data_factory_linked_service_key_vault" "adf_kv_ls" {
  name                = "ls_kv"
  data_factory_id   = azurerm_data_factory.adf_transform.id
  key_vault_id        = data.azurerm_key_vault.myKeyVault.id
  description         = " Used for retrieving sp information. "
}

# Create a linked service for storage

resource "azurerm_data_factory_linked_service_azure_blob_storage" "adf_adsl_ls" {
  name            = "adf_ads_ls"
  data_factory_id = azurerm_data_factory.adf_transform.id

  service_endpoint     = "https://${azurerm_storage_account.datalake.name}.blob.core.windows.net"
  service_principal_id = data.azuread_service_principal.sp-data-lake.client_id
  tenant_id            = data.azurerm_client_config.current.tenant_id
  service_principal_linked_key_vault_key {
    linked_service_name = azurerm_data_factory_linked_service_key_vault.adf_kv_ls.name
    secret_name         = data.azurerm_key_vault_secret.kvsecret.name
  }
}

# Create an Azure Private DNS Zone
resource "azurerm_private_dns_zone" "adf_dnszone" {
  name                = "adf-privatednszone.azuredatafactory.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

# Associate the Azure Private DNS Zone with the Azure Data Factory
resource "azurerm_private_dns_zone_virtual_network_link" "adf_dns_link" {
  name                = "adf-privatednszone-link"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  virtual_network_id  = data.azurerm_virtual_network.vnet.id
  private_dns_zone_name = azurerm_private_dns_zone.adf_dnszone.name
}

# Create a Private Endpoint for the Azure Data Factory
resource "azurerm_private_endpoint" "adf_pe" {
  name                = "adf-private-endpoint"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = data.azurerm_subnet.dbsubnet.id

  private_service_connection {
    name                           = "adf-private-service-connection"
    private_connection_resource_id = azurerm_data_factory.adf_transform.id
    subresource_names              = ["datafactory"]
    is_manual_connection           = false
  }

}