variable "environment" {
  description = "Deployment environment name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "region_short" {
  description = "Short region code for naming."
  type        = string
}

variable "project_name" {
  description = "Project short name."
  type        = string
  default     = "qotd"
}

variable "vnet_address_space" {
  description = "VNet address space."
  type        = list(string)
  default     = ["10.40.0.0/16"]
}

variable "app_subnet_prefix" {
  description = "App subnet prefix."
  type        = string
  default     = "10.40.1.0/24"
}

variable "privatelink_subnet_prefix" {
  description = "Private endpoint subnet prefix."
  type        = string
  default     = "10.40.2.0/24"
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
  default     = "interview"
}