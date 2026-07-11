output "resource_group_name" {
  description = "Bootstrap resource group name."
  value       = azurerm_resource_group.bootstrap.name
}

output "storage_account_name" {
  description = "Terraform state storage account name."
  value       = azurerm_storage_account.tfstate.name
}

output "container_names" {
  description = "State container names."
  value       = keys(azurerm_storage_container.state)
}