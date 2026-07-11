variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "plan_name" {
  description = "App Service Plan name."
  type        = string
}

variable "app_name" {
  description = "Linux Web App name."
  type        = string
}

variable "plan_sku_name" {
  description = "App Service plan SKU."
  type        = string
  default     = "B2"
}

variable "zone_redundant" {
  description = "Enable zone-balanced plan when supported."
  type        = bool
  default     = false
}

variable "enable_autoscale" {
  description = "Enable autoscale for the App Service plan."
  type        = bool
  default     = false
}

variable "autoscale_default" {
  description = "Default App Service instance count."
  type        = number
  default     = 2
}

variable "autoscale_min" {
  description = "Minimum App Service instance count."
  type        = number
  default     = 2
}

variable "autoscale_max" {
  description = "Maximum App Service instance count."
  type        = number
  default     = 5
}

variable "app_subnet_id" {
  description = "Subnet id for app VNet integration."
  type        = string
}

variable "user_assigned_identity_id" {
  description = "User-assigned managed identity id for app runtime."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Workspace id for diagnostics."
  type        = string
}

variable "app_settings" {
  description = "Application settings."
  type        = map(string)
  default     = {}
}

variable "enable_front_door_lockdown" {
  description = "Enable Front Door only ingress restrictions."
  type        = bool
  default     = true
}

variable "front_door_profile_resource_guid" {
  description = "Front Door profile resource guid for FDID header check."
  type        = string
  default     = ""
}

variable "port" {
  description = "Container/application port."
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Tags for resources."
  type        = map(string)
  default     = {}
}