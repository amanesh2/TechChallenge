locals {
  common_tags = {
    environment         = var.environment
    project             = "quote-of-the-day"
    managed-by          = "terraform"
    data-classification = "confidential-pii"
    cost-center         = var.cost_center
  }

  suffix = "${var.project_name}-${var.environment}-${var.region_short}"
}

module "platform_rg" {
  source   = "../modules/resource_group"
  name     = "rg-${local.suffix}-platform"
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source                    = "../modules/networking"
  resource_group_name       = module.platform_rg.name
  location                  = var.location
  vnet_name                 = "vnet-${local.suffix}"
  vnet_address_space        = var.vnet_address_space
  app_subnet_prefix         = var.app_subnet_prefix
  privatelink_subnet_prefix = var.privatelink_subnet_prefix
  tags                      = local.common_tags
}

module "log_analytics" {
  source              = "../modules/log_analytics"
  name                = "log-${local.suffix}"
  location            = var.location
  resource_group_name = module.platform_rg.name
  retention_in_days   = 30
  daily_quota_gb      = 1
  tags                = local.common_tags
}

module "app_insights" {
  source                     = "../modules/app_insights"
  name                       = "appi-${local.suffix}"
  location                   = var.location
  resource_group_name        = module.platform_rg.name
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

module "key_vault" {
  source                     = "../modules/key_vault"
  name                       = substr(replace("kv-${local.suffix}", "-", ""), 0, 24)
  location                   = var.location
  resource_group_name        = module.platform_rg.name
  private_endpoint_subnet_id = module.networking.privatelink_subnet_id
  virtual_network_id         = module.networking.vnet_id
  log_analytics_workspace_id = module.log_analytics.id
  tags                       = local.common_tags
}

resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "appinsights-connection-string"
  value        = module.app_insights.connection_string
  key_vault_id = module.key_vault.id
  content_type = "text/plain"
  depends_on   = [module.key_vault]
}

module "front_door" {
  source                     = "../modules/front_door"
  resource_group_name        = module.platform_rg.name
  profile_name               = "afd-${var.project_name}-${var.environment}"
  endpoint_name              = "afd-endpoint-${var.project_name}-${var.environment}"
  waf_policy_name            = "afd-waf-${var.project_name}-${var.environment}"
  log_analytics_workspace_id = module.log_analytics.id
  create_profile_resources   = true
  create_routing_resources   = false
  enable_diagnostics         = true
  tags                       = local.common_tags
}