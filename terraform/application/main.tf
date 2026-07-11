data "terraform_remote_state" "platform" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.platform_state_resource_group_name
    storage_account_name = var.platform_state_storage_account_name
    container_name       = var.platform_state_container_name
    key                  = var.platform_state_key
  }
}

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

module "app_rg" {
  source   = "../modules/resource_group"
  name     = "rg-${local.suffix}-app"
  location = var.location
  tags     = local.common_tags
}

module "data_rg" {
  source   = "../modules/resource_group"
  name     = "rg-${local.suffix}-data"
  location = var.location
  tags     = local.common_tags
}

module "identity" {
  source               = "../modules/identity_rbac"
  resource_group_name  = module.app_rg.name
  location             = var.location
  app_identity_name    = "uami-${local.suffix}-app"
  seeder_identity_name = "uami-${local.suffix}-seeder"
  key_vault_id         = data.terraform_remote_state.platform.outputs.key_vault_id
  tags                 = local.common_tags
}

module "sql" {
  source                         = "../modules/sql_database"
  resource_group_name            = module.data_rg.name
  location                       = var.location
  server_name                    = "sql-${local.suffix}"
  database_name                  = "sqldb-${local.suffix}"
  sku_name                       = var.sql_sku_name
  is_serverless                  = can(regex("_S_", var.sql_sku_name))
  zone_redundant                 = var.sql_zone_redundant
  administrator_login            = var.sql_admin_login
  administrator_login_password   = var.sql_admin_password
  entra_admin_login              = var.entra_admin_login
  entra_admin_object_id          = var.entra_admin_object_id
  subnet_id_for_private_endpoint = data.terraform_remote_state.platform.outputs.privatelink_subnet_id
  private_dns_zone_id            = data.terraform_remote_state.platform.outputs.private_dns_zone_sql_id
  log_analytics_workspace_id     = data.terraform_remote_state.platform.outputs.log_analytics_workspace_id
  tags                           = local.common_tags
}

module "app_service" {
  source                           = "../modules/app_service"
  resource_group_name              = module.app_rg.name
  location                         = var.location
  plan_name                        = "plan-${local.suffix}"
  app_name                         = "app-${local.suffix}"
  plan_sku_name                    = var.app_plan_sku_name
  zone_redundant                   = var.app_plan_zone_redundant
  enable_autoscale                 = var.app_plan_enable_autoscale
  app_subnet_id                    = data.terraform_remote_state.platform.outputs.app_subnet_id
  user_assigned_identity_id        = module.identity.app_identity_id
  log_analytics_workspace_id       = data.terraform_remote_state.platform.outputs.log_analytics_workspace_id
  front_door_profile_resource_guid = data.terraform_remote_state.platform.outputs.front_door_profile_resource_guid
  app_settings = {
    NODE_ENV                              = "production"
    LOG_LEVEL                             = "info"
    PORT                                  = "8080"
    SQL_SERVER_FQDN                       = module.sql.sql_server_fqdn
    SQL_DATABASE_NAME                     = module.sql.sql_database_name
    APPLICATIONINSIGHTS_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${data.terraform_remote_state.platform.outputs.appinsights_secret_uri})"
  }
  tags = local.common_tags
}

module "front_door_routing" {
  source                   = "../modules/front_door"
  resource_group_name      = data.terraform_remote_state.platform.outputs.platform_resource_group_name
  profile_name             = "unused-profile-name"
  endpoint_name            = "unused-endpoint-name"
  waf_policy_name          = "unused-waf-name"
  create_profile_resources = false
  create_routing_resources = true
  existing_profile_id      = data.terraform_remote_state.platform.outputs.front_door_profile_id
  existing_endpoint_id     = data.terraform_remote_state.platform.outputs.front_door_endpoint_id
  origin_hostname          = module.app_service.default_hostname
  origin_group_name        = "og-${local.suffix}"
  origin_name              = "origin-${local.suffix}"
  route_name               = "route-${local.suffix}"
  tags                     = local.common_tags
}

module "alerts" {
  source                  = "../modules/monitoring_alerts"
  resource_group_name     = module.app_rg.name
  action_group_name       = "ag-${local.suffix}"
  action_group_short_name = "qotdops"
  alert_email             = var.alert_email
  app_service_id          = module.app_service.id
  sql_database_id         = module.sql.sql_database_id
  tags                    = local.common_tags
}