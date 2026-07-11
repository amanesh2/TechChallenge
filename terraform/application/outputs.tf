output "app_service_name" {
  description = "App Service name."
  value       = module.app_service.app_name
}

output "app_service_default_hostname" {
  description = "App Service hostname."
  value       = module.app_service.default_hostname
}

output "staging_slot_hostname" {
  description = "Staging slot hostname."
  value       = module.app_service.staging_slot_hostname
}

output "sql_server_fqdn" {
  description = "SQL server FQDN."
  value       = module.sql.sql_server_fqdn
}

output "sql_database_name" {
  description = "SQL database name."
  value       = module.sql.sql_database_name
}

output "front_door_hostname" {
  description = "Front Door public endpoint hostname."
  value       = data.terraform_remote_state.platform.outputs.front_door_endpoint_hostname
}

output "app_identity_principal_id" {
  description = "App managed identity principal id."
  value       = module.identity.app_identity_principal_id
}

output "seeder_identity_principal_id" {
  description = "Seeder managed identity principal id."
  value       = module.identity.seeder_identity_principal_id
}