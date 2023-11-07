# Create Databricks VNET
resource "azurerm_virtual_network" "abd_vnet" {
  name                = "${local.prefix}-vnet"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  address_space       = [var.cidr]
  tags                = local.tags
}

resource "azurerm_network_security_group" "abd_vnet_sg" {
  name                = "${local.prefix}-nsg"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  tags                = local.tags
}

resource "azurerm_network_security_rule" "aad" {
  name                        = "AllowAAD"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureActiveDirectory"
  resource_group_name         = data.azurerm_resource_group.data-lake-rg.name
  network_security_group_name = azurerm_network_security_group.abd_vnet_sg.name
}

resource "azurerm_network_security_rule" "azfrontdoor" {
  name                        = "AllowAzureFrontDoor"
  priority                    = 201
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "AzureFrontDoor.Frontend"
  resource_group_name         = data.azurerm_resource_group.data-lake-rg.name
  network_security_group_name = azurerm_network_security_group.abd_vnet_sg.name
}

resource "azurerm_subnet" "adb_public" {
  name                 = "${local.prefix}-public"
  resource_group_name  = data.azurerm_resource_group.data-lake-rg.name
  virtual_network_name = azurerm_virtual_network.abd_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 3, 0)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.adb_public.id
  network_security_group_id = azurerm_network_security_group.abd_vnet_sg.id
}

variable "private_subnet_endpoints" {
  default = []
}

resource "azurerm_subnet" "adb_private" {
  name                 = "${local.prefix}-private"
  resource_group_name  = data.azurerm_resource_group.data-lake-rg.name
  virtual_network_name = azurerm_virtual_network.abd_vnet.name
  address_prefixes     = [cidrsubnet(var.cidr, 3, 1)]

  delegation {
    name = "databricks"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
    }
  }

  service_endpoints = var.private_subnet_endpoints
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.adb_private.id
  network_security_group_id = azurerm_network_security_group.abd_vnet_sg.id
}

resource "azurerm_subnet" "adb_plsubnet" {
  name                                           = "${local.prefix}-privatelink"
  resource_group_name                            = data.azurerm_resource_group.data-lake-rg.name
  virtual_network_name                           = azurerm_virtual_network.abd_vnet.name
  address_prefixes                               = [cidrsubnet(var.cidr, 3, 2)]
 
}

# Create Private End Point
resource "azurerm_private_endpoint" "uiapi" {
  name                = "uiapipvtendpoint"
  location            = data.azurerm_resource_group.data-lake-rg.location
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  subnet_id           = azurerm_subnet.adb_plsubnet.id

  private_service_connection {
    name                           = "ple-${var.workspace_prefix}-uiapi"
    private_connection_resource_id = azurerm_databricks_workspace.dbws.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-uiapi"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsuiapi.id]
  }
}

resource "azurerm_private_dns_zone" "dnsuiapi" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "uiapidnszonevnetlink" {
  name                  = "uiapispokevnetconnection"
  resource_group_name   = data.azurerm_resource_group.data-lake-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.dnsuiapi.name
  virtual_network_id    = azurerm_virtual_network.abd_vnet.id// connect to spoke vnet
}
# Create Data Factory Workspace
resource "azurerm_databricks_workspace" "dbws" {
  name                = "vp-${var.environment}-dbw01"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  location            = data.azurerm_resource_group.data-lake-rg.location
  sku                 = "premium"
  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"
  customer_managed_key_enabled          = true
  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = azurerm_virtual_network.abd_vnet.id
    private_subnet_name                                  = azurerm_subnet.adb_private.name
    public_subnet_name                                   = azurerm_subnet.adb_public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
    storage_account_name                                 = "adbdbfsvenkat"
  }

  tags = {
    Environment = "dev"
  }
  depends_on = [
    azurerm_subnet_network_security_group_association.public,
    azurerm_subnet_network_security_group_association.private
  ]
}
/*
data "databricks_node_type" "smallest" {
  local_disk = true
  depends_on = [
    azurerm_databricks_workspace.dbws
  ]
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
  depends_on = [
    azurerm_databricks_workspace.dbws
  ]
}

resource "databricks_cluster" "dbcl" {
  cluster_name            = "Single Node"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 15

  spark_conf = {
    # Single-node
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

#resource "databricks_notebook" "this" {
#  path     = "/Shared/test/test"
#  language = "PYTHON"
#  source   = "./test.py"
#}

resource "databricks_token" "pat" {
  #provider = databricks.created_workspace
  comment  = "Terraform Provisioning"
  // 100 day token
  lifetime_seconds = 8640000
}

resource "azurerm_key_vault_secret" "dbpattoken" {

  name         = "dbtoken"
  value        = databricks_token.pat.token_value
  key_vault_id = data.azurerm_key_vault.myKeyVault.id
  depends_on = [databricks_cluster.dbcl]
}

resource "databricks_mount" "dbmount" {
  name = "default"
  cluster_id = databricks_cluster.dbcl.id
  uri = "abfss://${azurerm_storage_data_lake_gen2_filesystem.default.name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net"
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : data.azuread_service_principal.sp-data-lake.client_id,
    "fs.azure.account.oauth2.client.secret" : "${data.azurerm_key_vault_secret.kvsecret.value}", # here should be secrete scoup
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }
  depends_on = [databricks_cluster.dbcl]

}
*/