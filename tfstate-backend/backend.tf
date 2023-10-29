terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstatevenkat"
    container_name       = "tfstate"
    key                  = "tfstate-backend/terraform.tfstate"
  }
}