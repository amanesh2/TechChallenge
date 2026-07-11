output "sql_server_id" {
  description = "SQL server id."
  value       = azurerm_mssql_server.this.id
}

output "sql_server_fqdn" {
  description = "SQL server fqdn."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_id" {
  description = "SQL database id."
  value       = azurerm_mssql_database.this.id
}

output "sql_database_name" {
  description = "SQL database name."
  value       = azurerm_mssql_database.this.name
}