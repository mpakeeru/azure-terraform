output "Databricks_Workspace_URL" {
  description = "Databricks Workspace URL"
  value = azurerm_databricks_workspace.dbws.workspace_url
}