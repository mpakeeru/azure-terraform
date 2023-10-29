# password generator
resource "random_password" "sql_administrator_login_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 1

}

# save to key vault
resource "azurerm_key_vault_secret" "sql_administrator_login" {
  name            = "synapseSQLpass"
  value           = random_password.sql_administrator_login_password.result
  key_vault_id    = data.azurerm_key_vault.myKeyVault.id
  content_type    = "string"
  expiration_date = "2111-12-31T00:00:00Z"

  
}

# Azure Synapse
resource "azurerm_synapse_workspace" "synapse-dev" {
  name = "vp${var.environment}syn001"
  resource_group_name                  = data.azurerm_resource_group.data-lake-rg.name
  location                             = data.azurerm_resource_group.data-lake-rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.syn.id
  sql_administrator_login              = "venkat"
  sql_administrator_login_password     = azurerm_key_vault_secret.sql_administrator_login.value

  #aad_admin {
  #  login = data.azuread_service_principal.sp-data-lake.display_name
  #  object_id = data.azuread_service_principal.sp-data-lake.object_id
  #  tenant_id = data.azurerm_client_config.current.tenant_id
  #}
 #   aad_admin {
 #   login = "vpakeeru_gmail.com#EXT#@vpakeerugmail.onmicrosoft.com"
 #   object_id = "6bb54f24-94fa-478f-a2f8-80a52224a736"
 #   tenant_id = data.azurerm_client_config.current.tenant_id
 # }
  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_storage_account.datalake,
    azurerm_key_vault_secret.sql_administrator_login
    ]

}
resource "azurerm_synapse_firewall_rule" "example" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapse-dev.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}