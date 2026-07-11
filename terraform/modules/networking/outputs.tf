output "vnet_id" {
  description = "Virtual network id."
  value       = azurerm_virtual_network.this.id
}

output "app_subnet_id" {
  description = "App integration subnet id."
  value       = azurerm_subnet.app.id
}

output "privatelink_subnet_id" {
  description = "Private endpoint subnet id."
  value       = azurerm_subnet.privatelink.id
}

output "private_dns_zone_sql_id" {
  description = "Private DNS zone id for SQL private endpoints."
  value       = azurerm_private_dns_zone.sql.id
}

output "private_dns_zone_sql_name" {
  description = "Private DNS zone name for SQL private endpoints."
  value       = azurerm_private_dns_zone.sql.name
}