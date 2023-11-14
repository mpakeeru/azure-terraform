# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.30.0"
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-backend/aks/terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Define Local Values in Terraform
locals {
  owners = var.business_divsion
  environment = var.environment
  resource_name_prefix = "${var.business_divsion}-${var.environment}"
  #name = "${local.owners}-${local.environment}"
  common_tags = {
    owners = local.owners
    environment = local.environment
    
  }
} 

resource "azurerm_resource_group" "rg-aks" {
  name     = "${local.resource_name_prefix}-${var.resource_group_name}"
  location = var.resource_group_location
}

data "azurerm_virtual_network" "vnet" {
    name = "${local.owners}-${local.environment}-vnet"
    resource_group_name = "${local.owners}-${local.environment}-rg" 
}

data "azurerm_key_vault" "myKeyVault" {
  resource_group_name= "data-lake-rg"
  name = "myKeyVaultVenkat"
}

data "http" "ip" {
  url = "https://ifconfig.me"
}
data "azurerm_client_config" "current" {}