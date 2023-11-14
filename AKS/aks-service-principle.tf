

# Get Azure Tenant Data
data "azuread_client_config" "current" {}

# Get Azure Subscription Data
data "azurerm_subscription" "mysubscriptions" {}

# Create Application
resource "azuread_application" "sp_aks" {
  display_name     = "sp_aks"
  owners           = [data.azuread_client_config.current.object_id]
  sign_in_audience = var.sign_in_audience
  depends_on = [azurerm_resource_group.rg-aks]
}
# Create Service Principle
resource "azuread_service_principal" "sp_aks" {
  client_id = azuread_application.sp_aks.client_id
  owners            = [data.azuread_client_config.current.object_id]
  alternative_names = var.alternative_names
  description       = "AKS Service Principle"
  app_role_assignment_required = false
}

# create password for service principle
resource "azuread_service_principal_password" "sp_aks_passwd" {
  service_principal_id = azuread_service_principal.sp_aks.object_id
}

# Assign role to service prinicple
resource "azurerm_role_assignment" "sp_aks_role" {
  description          = "AKS SP Role"
  scope                = data.azurerm_subscription.mysubscriptions.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.sp_aks.object_id
}





# Create Key Vault Policy for Service Prinicple created above


# Policy for self
resource "azurerm_key_vault_access_policy" "myKeyVaultPolicy-aks" {
  key_vault_id = data.azurerm_key_vault.myKeyVault.id
   object_id    = azuread_application.sp_aks.object_id
  tenant_id    = data.azuread_client_config.current.tenant_id

  secret_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore","Set"]
  key_permissions = ["Backup","Delete","Get","List","Purge","Recover","Restore"]
}


# Store Service Prinicple client id and secret key in vault
resource "azurerm_key_vault_secret" "sp_aks" {
  name         = "sp-aks-client-id"
  value        = azuread_application.sp_aks.application_id
  key_vault_id = data.azurerm_key_vault.myKeyVault.id

  depends_on = [
    azurerm_key_vault_access_policy.myKeyVaultPolicy-aks
  ]
}

resource "azurerm_key_vault_secret" "sp_aks_secret" {
  name         = "sp-aks-secret"
  value        = azuread_service_principal_password.sp_aks_passwd.value
  key_vault_id = data.azurerm_key_vault.myKeyVault.id

  depends_on = [
    azurerm_key_vault_access_policy.myKeyVaultPolicy-aks
  ]
}