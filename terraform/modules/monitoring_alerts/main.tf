resource "azurerm_monitor_action_group" "this" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name
  tags                = var.tags

  email_receiver {
    name          = "primary"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_metric_alert" "app_5xx" {
  name                = "alert-app-5xx"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "App Service 5xx rate threshold exceeded"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

resource "azurerm_monitor_metric_alert" "app_latency" {
  name                = "alert-app-latency"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_id]
  description         = "App Service response time threshold exceeded"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "AverageResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

resource "azurerm_monitor_metric_alert" "sql_cpu" {
  name                = "alert-sql-cpu"
  resource_group_name = var.resource_group_name
  scopes              = [var.sql_database_id]
  description         = "SQL CPU threshold exceeded"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT10M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}