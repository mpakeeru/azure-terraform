terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.30.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.28.0"
    }
    azapi = {
      source = "azure/azapi"
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
provider "azapi"{

}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-secure-synapse/terraform.tfstate"
  }
}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.dbws.id
  host  = azurerm_databricks_workspace.dbws.workspace_url
  azure_client_id             = data.azuread_service_principal.sp-data-lake.client_id
  azure_client_secret         = data.azurerm_key_vault_secret.kvsecret.value
  azure_tenant_id             = data.azurerm_client_config.current.tenant_id
}