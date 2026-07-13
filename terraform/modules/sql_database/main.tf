resource "azurerm_mssql_server" "this" {
  name                          = var.server_name
  resource_group_name           = var.resource_group_name
  location                      = var.database_location
  version                       = "12.0"
  administrator_login           = var.administrator_login
  administrator_login_password  = var.administrator_login_password
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
  tags                          = var.tags

  azuread_administrator {
    login_username              = var.entra_admin_login
    object_id                   = var.entra_admin_object_id
    azuread_authentication_only = true
  }
}

resource "azurerm_mssql_database" "this" {
  name           = var.database_name
  server_id      = azurerm_mssql_server.this.id
  sku_name       = var.sku_name
  zone_redundant = var.zone_redundant

  auto_pause_delay_in_minutes = var.is_serverless ? var.auto_pause_delay_in_minutes : null
  min_capacity                = var.is_serverless ? var.serverless_min_capacity : null
  max_size_gb                 = var.max_size_gb

  short_term_retention_policy {
    retention_days = var.backup_retention_days
  }

  tags = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "pe-${var.server_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id_for_private_endpoint
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.server_name}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

resource "azurerm_monitor_diagnostic_setting" "sql_server" {
  name                       = "diag-${var.server_name}"
  target_resource_id         = azurerm_mssql_server.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}