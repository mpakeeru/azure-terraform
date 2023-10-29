terraform {
  required_version = ">=0.12"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    databricks = {
      source  = "databricks/databricks"
      #version = "~> 0.5"
    }
  }
}

provider "azuread"{}

provider "azurerm" {
  features {}
}
