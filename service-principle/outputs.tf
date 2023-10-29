output "service_principal_name" {
  description = "The object id of service principal. Can be used to assign roles to user."
  value       = azuread_service_principal.sp_data_lake.display_name
}

output "service_principal_object_id" {
  description = "The object id of service principal. Can be used to assign roles to user."
  value       = azuread_service_principal.sp_data_lake.object_id
}

output "service_principal_application_id" {
  description = "The object id of service principal. Can be used to assign roles to user."
  value       = azuread_service_principal.sp_data_lake.application_id
}

output "client_id" {
  description = "The application id of AzureAD application created."
  value       = azuread_application.sp_data_lake.application_id
}

output "client_secret" {
  description = "Password for service principal."
  value       = azuread_service_principal_password.sp_data_lake_passwd.value
  sensitive   = true
}

output "service_principal_password" {
  description = "Password for service principal."
  value       = azuread_service_principal_password.sp_data_lake_passwd.value
  sensitive   = true
}