variable "resource_group_name" {
  description = "SQL resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "database_location" {
  description = "Azure region for the database."
  type        = string
}

variable "server_name" {
  description = "Azure SQL Server name."
  type        = string
}

variable "database_name" {
  description = "Azure SQL Database name."
  type        = string
}

variable "sku_name" {
  description = "SQL DB sku name."
  type        = string
  default     = "GP_S_Gen5_1"
}

variable "zone_redundant" {
  description = "Enable zone redundancy on database."
  type        = bool
  default     = false
}

variable "is_serverless" {
  description = "Whether selected SKU is serverless and supports auto pause settings."
  type        = bool
  default     = true
}

variable "administrator_login" {
  description = "SQL admin login required by provider, not used for auth mode."
  type        = string
}

variable "administrator_login_password" {
  description = "SQL admin login password required by provider."
  type        = string
  sensitive   = true
}

variable "entra_admin_object_id" {
  description = "Entra admin object id."
  type        = string
}

variable "entra_admin_login" {
  description = "Entra admin login UPN or display name."
  type        = string
}

variable "subnet_id_for_private_endpoint" {
  description = "Private endpoint subnet id."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone id for SQL."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace id."
  type        = string
}

variable "serverless_min_capacity" {
  description = "Minimum vCore for serverless SKU."
  type        = number
  default     = 0.5
}

variable "auto_pause_delay_in_minutes" {
  description = "Serverless auto pause delay."
  type        = number
  default     = 60
}

variable "max_size_gb" {
  description = "Maximum database size."
  type        = number
  default     = 32
}

variable "backup_retention_days" {
  description = "PITR short-term retention days."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags for resources."
  type        = map(string)
  default     = {}
}