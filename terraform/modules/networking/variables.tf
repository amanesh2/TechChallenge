variable "resource_group_name" {
  description = "Resource group containing network resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "vnet_address_space" {
  description = "VNet CIDR blocks."
  type        = list(string)
}

variable "app_subnet_name" {
  description = "App integration subnet name."
  type        = string
  default     = "snet-app-integration"
}

variable "app_subnet_prefix" {
  description = "App subnet CIDR."
  type        = string
}

variable "privatelink_subnet_name" {
  description = "Private endpoint subnet name."
  type        = string
  default     = "snet-privatelink"
}

variable "privatelink_subnet_prefix" {
  description = "Private link subnet CIDR."
  type        = string
}

variable "tags" {
  description = "Tags for all resources."
  type        = map(string)
  default     = {}
}