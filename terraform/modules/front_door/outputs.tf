output "profile_id" {
  description = "Front Door profile id."
  value       = local.active_profile_id
}

output "endpoint_id" {
  description = "Front Door endpoint id."
  value       = local.active_endpoint_id
}

output "endpoint_hostname" {
  description = "Front Door endpoint hostname."
  value       = var.create_profile_resources ? azurerm_cdn_frontdoor_endpoint.this[0].host_name : null
}

output "profile_resource_guid" {
  description = "Front Door profile resource guid for X-Azure-FDID checks."
  value       = var.create_profile_resources ? azurerm_cdn_frontdoor_profile.this[0].resource_guid : null
}