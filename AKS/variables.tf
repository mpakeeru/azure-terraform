# Generic Input Variables
# Business Division
variable "business_divsion" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type = string
  default = "NA"
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
  default = "rg-aks"  
}

# Azure Resources Location
variable "resource_group_location" {
  description = "Region in which Azure Resources to be created"
  type = string
  default = "eastus2"  
}

# Virtual Network, Subnets and Subnet NSG's

## Virtual Network
variable "vnet_name" {
  description = "Virtual Network name"
  type = string
  default = "vnet-aks"
}
variable "vnet_address_space" {
  description = "Virtual Network address_space"
  type = list(string)
  default = ["192.168.0.0/16"]
}


# AKS Subnet Name
variable "aks_subnet_name" {
  description = "Virtual Network AKS Subnet Name"
  type = string
  default = "akssubnet"
}
# AKS Subnet Address Space
variable "aks_subnet_address" {
  description = "Virtual Network AKS Subnet Address Spaces"
  type = list(string)
  default = ["192.168.1.0/24"]
}

# AKS PE Subnet Name
variable "akspe_subnet_name" {
  description = "Virtual Network AKS PE Subnet Name"
  type = string
  default = "akspesubnet"
}
# AKS Subnet Address Space
variable "akspe_subnet_address" {
  description = "Virtual Network AKS PE Subnet Address Spaces"
  type = list(string)
  default = ["192.168.2.0/24"]
}