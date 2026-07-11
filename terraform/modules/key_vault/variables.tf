variable "name" {
  description = "Key Vault name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days."
  type        = number
  default     = 90
}

variable "private_endpoint_subnet_id" {
  description = "Subnet id for Key Vault private endpoint."
  type        = string
}

variable "virtual_network_id" {
  description = "VNet id for private DNS zone linking."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace id."
  type        = string
}

variable "tags" {
  description = "Tags for resources."
  type        = map(string)
  default     = {}
}