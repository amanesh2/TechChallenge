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

variable "platform_state_resource_group_name" {
  description = "Resource group containing platform remote state storage."
  type        = string
}

variable "platform_state_storage_account_name" {
  description = "Storage account containing platform remote state."
  type        = string
}

variable "platform_state_container_name" {
  description = "Storage container containing platform remote state."
  type        = string
}

variable "platform_state_key" {
  description = "Blob key for platform remote state file."
  type        = string
}

variable "sql_admin_login" {
  description = "SQL admin login name required by Azure SQL provider."
  type        = string
}

variable "sql_admin_password" {
  description = "SQL admin login password required by provider."
  type        = string
  sensitive   = true
}

variable "entra_admin_login" {
  description = "Entra admin login/UPN for SQL server."
  type        = string
}

variable "entra_admin_object_id" {
  description = "Entra admin object id for SQL server."
  type        = string
}

variable "app_plan_sku_name" {
  description = "App Service plan SKU."
  type        = string
  default     = "B2"
}

variable "app_plan_zone_redundant" {
  description = "Enable zone redundancy for App Service plan."
  type        = bool
  default     = false
}

variable "app_plan_enable_autoscale" {
  description = "Enable autoscale for App Service plan."
  type        = bool
  default     = false
}

variable "sql_sku_name" {
  description = "SQL database SKU."
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "sql_zone_redundant" {
  description = "Enable SQL zone redundancy."
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email receiver for alert action group."
  type        = string
}

variable "cost_center" {
  description = "Cost center tag value."
  type        = string
  default     = "interview"
}