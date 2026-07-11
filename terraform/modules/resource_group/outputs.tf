output "name" {
  description = "Resource group name."
  value       = azurerm_resource_group.this.name
}

output "id" {
  description = "Resource group id."
  value       = azurerm_resource_group.this.id
}