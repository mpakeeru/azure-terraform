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