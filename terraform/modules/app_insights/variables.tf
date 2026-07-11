variable "name" {
  description = "Application Insights name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for App Insights."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Workspace id to link Application Insights."
  type        = string
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}