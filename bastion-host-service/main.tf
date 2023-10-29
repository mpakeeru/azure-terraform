# Terraform Block
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.0" 
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.0"
    }
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
    }     
  }
}

provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-bastion/terraform.tfstate"
  }
}

