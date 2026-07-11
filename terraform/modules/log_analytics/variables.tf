variable "name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for workspace."
  type        = string
}

variable "retention_in_days" {
  description = "Retention period for workspace logs."
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily quota cap for ingestion."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags for workspace."
  type        = map(string)
  default     = {}
}