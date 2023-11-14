resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "${local.resource_name_prefix}-${var.resource_group_name}-aks"
  location            = azurerm_resource_group.rg-aks.location
  resource_group_name = azurerm_resource_group.rg-aks.name
  dns_prefix          = "${local.resource_name_prefix}-${var.resource_group_name}-k8s"
  kubernetes_version  = "1.26.3"

  default_node_pool {
    name            = "default"
    node_count      = 2
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = azuread_service_principal.sp_aks.client_id
    client_secret = azuread_service_principal_password.sp_aks_passwd.value
  }

  role_based_access_control_enabled = true

  tags = {
    environment = "dev"
  }
}
