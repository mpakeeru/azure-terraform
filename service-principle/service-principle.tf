terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.30.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.28.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.1"
    }
  }
  required_version = ">= 1.1.9"
}
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-sp/terraform.tfstate"
  }
}
# Get Azure Tenant Data
data "azuread_client_config" "current" {}
# Get Azure Subscription Data
data "azurerm_subscription" "mysubscriptions" {}
data "azurerm_client_config" "current" {}
# Create Application
resource "azuread_application" "sp_data_lake" {
  display_name     = var.service_principal_name
  #identifier_uris  = ["http://${var.service_principal_name}"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = var.sign_in_audience
  depends_on = [ azurerm_resource_group.data-lake-rg ]
}
# Create Service Principle
resource "azuread_service_principal" "sp_data_lake" {
  client_id = azuread_application.sp_data_lake.client_id
  owners            = [data.azuread_client_config.current.object_id]
  alternative_names = var.alternative_names
  description       = var.description
  app_role_assignment_required = false
}

# create password for service principle
resource "azuread_service_principal_password" "sp_data_lake_passwd" {
  service_principal_id = azuread_service_principal.sp_data_lake.object_id
}

# Assign role to service prinicple
resource "azurerm_role_assignment" "sp_data_lake_role" {
  description          = var.azure_role_description
  scope                = data.azurerm_subscription.mysubscriptions.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp_data_lake.object_id
}

resource "azurerm_resource_group" "data-lake-rg" {
  name = "data-lake-rg"
  location = "eastus2"

}
# Create key vault

resource "azurerm_key_vault" "myKeyVault" {
  name                        = "myKeyVaultVenkat"
  location                    = azurerm_resource_group.data-lake-rg.location
  resource_group_name         = azurerm_resource_group.data-lake-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7     # minimum
  purge_protection_enabled    = false # so we can fully delete it
  sku_name                    = "standard"
}

# Create Key Vault Policy for Service Prinicple created above

resource "azurerm_key_vault_access_policy" "myKeyVaultPolicy" {
  key_vault_id = azurerm_key_vault.myKeyVault.id
  object_id    = data.azuread_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore","Set"]
  key_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore"]
}
# Policy for self
resource "azurerm_key_vault_access_policy" "myKeyVaultPolicy-self" {
  key_vault_id = azurerm_key_vault.myKeyVault.id
   object_id    = azuread_application.sp_data_lake.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore","Set"]
  key_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore"]
}
# Policy for user
resource "azurerm_key_vault_access_policy" "myKeyVaultPolicy-user" {
  key_vault_id = azurerm_key_vault.myKeyVault.id
  object_id    = "6bb54f24-94fa-478f-a2f8-80a52224a736"
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore","Set"]
  key_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore"]
}

# Store Service Prinicple client id and secret key in vault
resource "azurerm_key_vault_secret" "sp_data_lake" {
  name         = "sp-data-lake-client-id"
  value        = azuread_application.sp_data_lake.application_id
  key_vault_id = azurerm_key_vault.myKeyVault.id

  depends_on = [
    azurerm_key_vault_access_policy.myKeyVaultPolicy
  ]
}

resource "azurerm_key_vault_secret" "sp_data_lake_secret" {
  name         = "sp-data-lake-secret"
  value        = azuread_service_principal_password.sp_data_lake_passwd.value
  key_vault_id = azurerm_key_vault.myKeyVault.id

  depends_on = [
    azurerm_key_vault_access_policy.myKeyVaultPolicy
  ]
}