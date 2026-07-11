output "app_name" {
  description = "Web app name."
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Web app default hostname."
  value       = azurerm_linux_web_app.this.default_hostname
}

output "staging_slot_hostname" {
  description = "Staging slot hostname."
  value       = azurerm_linux_web_app_slot.staging.default_hostname
}

output "id" {
  description = "Web app resource id."
  value       = azurerm_linux_web_app.this.id
}