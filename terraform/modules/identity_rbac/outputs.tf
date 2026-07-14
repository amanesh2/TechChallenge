output "app_identity_id" {
  description = "App identity resource id."
  value       = azurerm_user_assigned_identity.app.id
}

output "app_identity_principal_id" {
  description = "App identity principal id."
  value       = azurerm_user_assigned_identity.app.principal_id
}

output "seeder_identity_id" {
  description = "Seeder identity resource id."
  value       = azurerm_user_assigned_identity.seeder.id
}

output "seeder_identity_principal_id" {
  description = "Seeder identity principal id."
  value       = azurerm_user_assigned_identity.seeder.principal_id
}

#output "umai_identity_id" {
#  description = "UMAI identity resource id."
#  value       = azurerm_user_assigned_identity.umai.id
#}
