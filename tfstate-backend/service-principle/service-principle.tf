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

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-sp/terraform.tfstate"
  }
}

data "azuread_client_config" "current" {}

resource "azuread_application" "sp_data_lake" {
  display_name     = var.service_principal_name
  identifier_uris  = ["http://${var.service_principal_name}"]
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = var.sign_in_audience
}

resource "azuread_service_principal" "sp_data_lake" {
  application_id    = azuread_application.sp_data_lake.application_id
  owners            = [data.azuread_client_config.current.object_id]
  alternative_names = var.alternative_names
  description       = var.description
}

resource "azuread_service_principal_password" "sp_data_lake_passwd" {

  service_principal_id = azuread_service_principal.sp_data_lake.object_id
 
}