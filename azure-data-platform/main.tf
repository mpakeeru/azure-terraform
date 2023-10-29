terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-azure-data/terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {
  
}

data "azuread_service_principal" "sp-data-lake" {
  display_name = "sp_data_lake"
}

data "azurerm_resource_group" "data-lake-rg" {
  name = "data-lake-rg"
}

data "azurerm_key_vault" "myKeyVault" {
  resource_group_name= data.azurerm_resource_group.data-lake-rg.name
  name = "myKeyVaultVenkat"
}

data "azurerm_key_vault_secret" "kvsecret" {
  name = "sp-data-lake-secret"
  key_vault_id = data.azurerm_key_vault.myKeyVault.id 
}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.dbws.id
  host  = azurerm_databricks_workspace.dbws.workspace_url
  azure_client_id             = data.azuread_service_principal.sp-data-lake.client_id
  azure_client_secret         = data.azurerm_key_vault_secret.kvsecret.value
  azure_tenant_id             = data.azurerm_client_config.current.tenant_id
}