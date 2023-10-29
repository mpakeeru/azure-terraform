# Bastion Linux VM Input Variables Placeholder file.
variable "bastion_service_subnet_name" {
  description = "Bastion Service Subnet Name"
  default = "AzureBastionSubnet"
}
variable "bastion_service_address_prefixes" {
  description = "Bastion Service Address Prefixes"
  default = ["10.1.101.0/27"]
}

# Generic Input Variables
# Business Division
variable "business_divsion" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type = string
  default = "sap"
}
# Environment Variable
variable "environment" {
  description = "Environment Variable used as a prefix"
  type = string
  default = "dev"
}

# Azure Resource Group Name 
variable "resource_group_name" {
  description = "Resource Group Name"
  type = string
  default = "rg-default"  
}

# Azure Resources Location
variable "resource_group_location" {
  description = "Region in which Azure Resources to be created"
  type = string
  default = "eastus2"  
}