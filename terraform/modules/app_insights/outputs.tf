output "id" {
  description = "Application Insights id."
  value       = azurerm_application_insights.this.id
}

output "connection_string" {
  description = "Application Insights connection string."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}