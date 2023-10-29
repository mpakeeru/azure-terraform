# Create Data Factory Workspace
resource "azurerm_databricks_workspace" "dbws" {
  name                = "vp-${var.environment}-dbw01"
  resource_group_name = data.azurerm_resource_group.data-lake-rg.name
  location            = data.azurerm_resource_group.data-lake-rg.location
  sku                 = "standard"

  tags = {
    Environment = "dev"
  }
}

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
  name = "landing"
  cluster_id = databricks_cluster.dbcl.id
  uri = "abfss://${azurerm_storage_data_lake_gen2_filesystem.commonstorage.name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net"
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

resource "databricks_mount" "dbmountsyn" {
  name = "syn"
  cluster_id = databricks_cluster.dbcl.id
  uri = "abfss://${azurerm_storage_data_lake_gen2_filesystem.syn.name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net"
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