# Create Storage account 
resource "azurerm_storage_account" "aksstorage" {
  name                     = "aksstorage${var.environment}venkat"
  resource_group_name      = azurerm_resource_group.rg-aks.name
  location                 = azurerm_resource_group.rg-aks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

# Create a storage container within storage account

resource "azurerm_storage_container" "akscontainer" { 
  name                  = "aksstorage"
  storage_account_name  = azurerm_storage_account.aksstorage.name
 
}
#Assign Role assignments

resource "azurerm_role_assignment" "aks_current_user" {
  scope                = azurerm_storage_account.aksstorage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_admin_user" {
   scope                = azurerm_storage_account.aksstorage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "6bb54f24-94fa-478f-a2f8-80a52224a736"
}
resource "azurerm_role_assignment" "aks_service_principal" {
    scope                = azurerm_storage_account.aksstorage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.sp_aks.object_id
}



# Virtual Network & Firewall configuration

resource "azurerm_storage_account_network_rules" "aksblob_firewall_rules" {
  storage_account_id = azurerm_storage_account.aksstorage.id

  default_action             = "Deny"
  ip_rules                   = [data.http.ip.response_body]
  virtual_network_subnet_ids = []
  bypass                     = ["None"]
/*  private_link_access {
    endpoint_resource_id = azurerm_kubernetes_cluster.aks_cluster.id
    endpoint_tenant_id = data.azurerm_client_config.current.tenant_id
  }*/
}



# Private Endpoint configuration

resource "azurerm_private_endpoint" "pe_aks_blob" {
  name                = "pe-${azurerm_storage_account.aksstorage.name}-blob"
  location            = azurerm_resource_group.rg-aks.location
  resource_group_name = azurerm_resource_group.rg-aks.name
  subnet_id           = azurerm_subnet.akspesubnet.id

  private_service_connection {
    name                           = "aks-blob-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.aksstorage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-blob-aks"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsblob.id]
  }
}



