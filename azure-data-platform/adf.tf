# Create Azure Data Factory
resource "azurerm_data_factory" "adf_transform" {
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  location            = data.azurerm_resource_group.data-lake-rg.location
  name = "vp-${var.environment}-adf01"

  identity {
    type = "SystemAssigned"
  }
}

# ADF should have access to kv to read the service principal
resource "azurerm_key_vault_access_policy" "kv_adf_transform" {
  key_vault_id = data.azurerm_key_vault.myKeyVault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.adf_transform.identity[0].principal_id

  secret_permissions = ["Get", "List"]
}

resource "azurerm_data_factory_linked_service_key_vault" "adf_kv_ls" {
  name                = "ls_kv"
  data_factory_id   = azurerm_data_factory.adf_transform.id
  key_vault_id        = data.azurerm_key_vault.myKeyVault.id
  description         = " Used for retrieving sp information. "
}

# Link Azure Databricks
resource "azurerm_data_factory_linked_service_azure_databricks" "at_linked" {
  name                = "ADBLinkedServiceViaAccessToken"
  data_factory_id     = azurerm_data_factory.adf_transform.id
  description         = "ADB Linked Service via Access Token"
  existing_cluster_id = databricks_cluster.dbcl.id

  access_token = azurerm_key_vault_secret.dbpattoken.value
  adb_domain   = "https://${azurerm_databricks_workspace.dbws.workspace_url}"
  depends_on = [databricks_cluster.dbcl]
}