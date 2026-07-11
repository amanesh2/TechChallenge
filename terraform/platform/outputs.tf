output "platform_resource_group_name" {
  description = "Platform resource group name."
  value       = module.platform_rg.name
}

output "vnet_id" {
  description = "VNet id."
  value       = module.networking.vnet_id
}

output "app_subnet_id" {
  description = "App integration subnet id."
  value       = module.networking.app_subnet_id
}

output "privatelink_subnet_id" {
  description = "Private endpoint subnet id."
  value       = module.networking.privatelink_subnet_id
}

output "private_dns_zone_sql_id" {
  description = "Private SQL DNS zone id."
  value       = module.networking.private_dns_zone_sql_id
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace id."
  value       = module.log_analytics.id
}

output "key_vault_id" {
  description = "Key Vault id."
  value       = module.key_vault.id
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = module.key_vault.name
}

output "appinsights_secret_uri" {
  description = "Key Vault secret URI for Application Insights connection string."
  value       = azurerm_key_vault_secret.appinsights_connection_string.versionless_id
}

output "front_door_profile_id" {
  description = "Front Door profile id."
  value       = module.front_door.profile_id
}

output "front_door_endpoint_id" {
  description = "Front Door endpoint id."
  value       = module.front_door.endpoint_id
}

output "front_door_endpoint_hostname" {
  description = "Front Door endpoint hostname."
  value       = module.front_door.endpoint_hostname
}

output "front_door_profile_resource_guid" {
  description = "Front Door profile resource guid used by X-Azure-FDID checks."
  value       = module.front_door.profile_resource_guid
}