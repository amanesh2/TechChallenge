resource "azurerm_cdn_frontdoor_profile" "this" {
  count               = var.create_profile_resources ? 1 : 0
  name                = var.profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  response_timeout_seconds = 60
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  count                    = var.create_profile_resources ? 1 : 0
  name                     = var.endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  enabled                  = true
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  count               = var.create_profile_resources ? 1 : 0
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  enabled             = true
  mode                = var.waf_mode
  tags                = var.tags

  dynamic "managed_rule" {
    for_each = var.enable_managed_rules ? [1] : []
    content {
      type    = "Microsoft_DefaultRuleSet"
      version = "2.1"
      action  = "Block"
    }
  }

  custom_rule {
    name                           = "rate-limit-100-rpm"
    enabled                        = true
    priority                       = 1
    rate_limit_duration_in_minutes = 1
    rate_limit_threshold           = 100
    type                           = "RateLimitRule"
    action                         = "Block"

    match_condition {
      match_variable     = "RequestUri"
      operator           = "Contains"
      negation_condition = true
      match_values       = ["/health"]
      transforms         = []
    }
  }
}

locals {
  active_profile_id = var.create_profile_resources ? azurerm_cdn_frontdoor_profile.this[0].id : var.existing_profile_id
  active_endpoint_id = var.create_profile_resources ? azurerm_cdn_frontdoor_endpoint.this[0].id : var.existing_endpoint_id
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count                    = var.create_profile_resources ? 1 : 0
  name                     = "sp-${var.profile_name}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[0].id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this[0].id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  count                    = var.create_routing_resources ? 1 : 0
  name                     = var.origin_group_name
  cdn_frontdoor_profile_id = local.active_profile_id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 30
    path                = "/health"
    protocol            = "Https"
    request_type        = "GET"
  }

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 0
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  count                         = var.create_routing_resources ? 1 : 0
  name                          = var.origin_name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[0].id
  enabled                       = true
  host_name                     = var.origin_hostname
  origin_host_header            = var.origin_hostname
  http_port                     = 80
  https_port                    = 443
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "this" {
  count                         = var.create_routing_resources ? 1 : 0
  name                          = var.route_name
  cdn_frontdoor_endpoint_id     = local.active_endpoint_id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.this[0].id]
  enabled                       = true
  forwarding_protocol           = "HttpsOnly"
  https_redirect_enabled        = true
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]
  link_to_default_domain        = true
}

resource "azurerm_monitor_diagnostic_setting" "front_door" {
  count                      = var.create_profile_resources && var.log_analytics_workspace_id != "" ? 1 : 0
  name                       = "diag-${var.profile_name}"
  target_resource_id         = azurerm_cdn_frontdoor_profile.this[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FrontDoorAccessLog"
  }

  enabled_log {
    category = "FrontDoorWebApplicationFirewallLog"
  }

  enabled_log {
    category = "FrontDoorHealthProbeLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}