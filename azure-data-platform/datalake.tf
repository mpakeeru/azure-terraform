
#Create data lake storage account with in the resource group

resource "azurerm_storage_account" "datalake" {
  name                      = "sadlvenkat${var.environment}"
    
  resource_group_name       = data.azurerm_resource_group.data-lake-rg.name
  location                  = data.azurerm_resource_group.data-lake-rg.location
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  access_tier               = "Hot"
  enable_https_traffic_only = true  
  is_hns_enabled            = true
  
  network_rules {
    default_action = "Allow"
    bypass                     = ["Metrics"]
  } 
  
  identity {
    type = "SystemAssigned"
  }
 
}

# Create a storage container within storage account

resource "azurerm_storage_container" "container" {
  for_each              = toset( ["landing","bronze", "silver", "gold"] )
  name                  = each.key
  storage_account_name  = azurerm_storage_account.datalake.name
 
}

resource "azurerm_role_assignment" "data_contributor_role" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.sp-data-lake.object_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "commonstorage" {
  name = "commonstorage" 
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "syn" {
  name = "syn" 
  storage_account_id = azurerm_storage_account.datalake.id
}