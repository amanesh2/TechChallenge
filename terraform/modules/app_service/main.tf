resource "azurerm_service_plan" "this" {
  name                   = var.plan_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  os_type                = "Linux"
  sku_name               = var.plan_sku_name
  zone_balancing_enabled = var.zone_redundant
  tags                   = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                            = var.app_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  service_plan_id                 = azurerm_service_plan.this.id
  https_only                      = true
  key_vault_reference_identity_id = var.user_assigned_identity_id
  tags                            = var.tags

  virtual_network_subnet_id = var.app_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  site_config {
    always_on                         = true
    minimum_tls_version               = "1.2"
    ftps_state                        = "Disabled"
    health_check_path                 = "/health/ready"
    health_check_eviction_time_in_min = 5
    vnet_route_all_enabled            = true
    app_command_line                  = "node src/server.js"

    application_stack {
      node_version = "20-lts"
    }

    dynamic "ip_restriction" {
      for_each = var.enable_front_door_lockdown ? [1] : []
      content {
        name        = "Allow-Azure-Front-Door-Backend"
        priority    = 100
        action      = "Allow"
        service_tag = "AzureFrontDoor.Backend"
        headers {
          x_azure_fdid = [var.front_door_profile_resource_guid]
        }
      }
    }
  }

  app_settings = merge(var.app_settings, {
    WEBSITES_PORT                  = tostring(var.port)
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  })
}

resource "azurerm_linux_web_app_slot" "staging" {
  name                            = "staging"
  app_service_id                  = azurerm_linux_web_app.this.id
  https_only                      = true
  key_vault_reference_identity_id = var.user_assigned_identity_id
  tags                            = var.tags

  virtual_network_subnet_id = var.app_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  site_config {
    always_on                         = true
    minimum_tls_version               = "1.2"
    ftps_state                        = "Disabled"
    health_check_path                 = "/health/ready"
    health_check_eviction_time_in_min = 10
    vnet_route_all_enabled            = true
    app_command_line                  = "node src/server.js"

    application_stack {
      node_version = "20-lts"
    }

    dynamic "ip_restriction" {
      for_each = var.enable_front_door_lockdown ? [1] : []
      content {
        name        = "Allow-Azure-Front-Door-Backend"
        priority    = 100
        action      = "Allow"
        service_tag = "AzureFrontDoor.Backend"
        headers {
          x_azure_fdid = [var.front_door_profile_resource_guid]
        }
      }
    }
  }

  app_settings = merge(var.app_settings, {
    WEBSITES_PORT                  = tostring(var.port)
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  })
}

resource "azurerm_monitor_autoscale_setting" "plan" {
  count               = var.enable_autoscale ? 1 : 0
  name                = "autoscale-${var.plan_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.this.id
  tags                = var.tags

  profile {
    name = "cpu-based-profile"

    capacity {
      default = tostring(var.autoscale_default)
      minimum = tostring(var.autoscale_min)
      maximum = tostring(var.autoscale_max)
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "diag-${var.app_name}"
  target_resource_id         = azurerm_linux_web_app.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}