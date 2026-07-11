variable "resource_group_name" {
  description = "Resource group for monitor resources."
  type        = string
}

variable "action_group_name" {
  description = "Monitor action group name."
  type        = string
}

variable "action_group_short_name" {
  description = "Action group short name."
  type        = string
  default     = "qotdops"
}

variable "alert_email" {
  description = "Alert email receiver."
  type        = string
}

variable "app_service_id" {
  description = "App Service resource id for alerts."
  type        = string
}

variable "sql_database_id" {
  description = "SQL database id for alerts."
  type        = string
}

variable "tags" {
  description = "Tags for monitor resources."
  type        = map(string)
  default     = {}
}