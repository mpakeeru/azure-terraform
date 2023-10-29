variable "service_principal_name" {
  description = "The name of the service principal"
  default     = "sp_data_lake"
}

variable "sign_in_audience" {
  description = "The Microsoft account types that are supported for the current application. Must be one of `AzureADMyOrg`, `AzureADMultipleOrgs`, `AzureADandPersonalMicrosoftAccount` or `PersonalMicrosoftAccount`"
  default     = "AzureADMyOrg"
}

variable "alternative_names" {
  type        = list(string)
  description = "A set of alternative names, used to retrieve service principals by subscription, identify resource group and full resource ids for managed identities."
  default     = []
}

variable "description" {
  description = "A description of the service principal provided for internal end-users."
  default     = "Service Principle for Data Lake "
}

variable "azure_role_name" {
  description = "A unique UUID/GUID for this Role Assignment - one will be generated if not specified."
  default     = null
}

variable "azure_role_description" {
  description = "The description for this Role Assignment"
  default     = null
}

variable "role_scope" {
  description = "The scope for this service principal"
  default = ""
}

variable "role_definition" {
  description = "The scope for this service principal"
  default = "Contributor"
}