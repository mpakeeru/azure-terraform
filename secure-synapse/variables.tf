variable "name" {
  type        = string
  description = "Name of the deployment"
  default = "NA"
}

# Business Division
variable "business_divsion" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type = string
  default = "NA"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Location of the resources"
  default     = "East US"
}

variable "aad_login" {
  description = "AAD login"
  type = object({
    name      = string
    object_id = string
    tenant_id = string
  })
}

variable "jumphost_username" {
  type        = string
  description = "Admin username of the VM"
  default = "adminuser"
}

variable "dbhost_username" {
  type        = string
  description = "Admin username of the VM"
  default = "adminuser"
}
variable "jumphost_password" {
  type        = string
  description = "Password for the admin username of the VM"
}

variable "dbhost_password" {
  type        = string
  description = "Password for the admin username of the VM"
}
variable "synadmin_username" {
  type        = string
  description = "Specifies The login name of the SQL administrator"
}

variable "synadmin_password" {
  type        = string
  description = "The Password associated with the sql_administrator_login for the SQL administrator"
}

variable "enable_syn_sparkpool" {
  type        = bool
  description = "Variable to enable or disable Synapse Spark pool deployment"
  default     = false
}

variable "enable_syn_sqlpool" {
  type        = bool
  description = "Variable to enable or disable Synapse Dedicated SQL pool deployment"
  default     = false
}

variable "portal_user" {
    description = "Object id for portl user"
    default = "6bb54f24-94fa-478f-a2f8-80a52224a736"
  
}

variable "cidr" {
  type = string
  default = "172.0.0.0/16"
}

variable "workspace_prefix" {
  type = string
  default = "adbworkspace"
}