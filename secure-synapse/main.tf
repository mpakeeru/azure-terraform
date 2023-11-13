locals {
  basename      = "${var.name}-${var.environment}"
  safe_basename = replace(local.basename, "-", "")
  
  prefix = "adb-pl"
    tags = {
    Environment = "Demo"
   # Owner       = lookup(data.external.me.result, "name")
  }
}
/*
data "external" "me" {
  program = ["az", "account", "show", "--query", "user"]
}
*/
data "azurerm_client_config" "current" {}

data "http" "ip" {
  url = "https://ifconfig.me"
}

resource "azurerm_resource_group" "default" {
  name     = "rg-${local.basename}"
  location = var.location
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

data "azurerm_virtual_network" "vnet" {
    name = "${local.basename}-vnet"
    resource_group_name = "${local.basename}-rg" 
}

data "azurerm_subnet" "dbsubnet" {
    name = "${local.basename}-vnet-dbsubnet"
    virtual_network_name = "${local.basename}-vnet"
    resource_group_name = "${local.basename}-rg" 
  
}

/*data "databricks_service_principal" "dbservice" {
  application_id = data.azuread_service_principal.sp-data-lake.application_id
}
*/