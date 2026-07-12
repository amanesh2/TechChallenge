variable "resource_group_name" {
  description = "Resource group name for Front Door resources."
  type        = string
}

variable "profile_name" {
  description = "Front Door profile name."
  type        = string
}

variable "endpoint_name" {
  description = "Front Door endpoint name."
  type        = string
}

variable "waf_policy_name" {
  description = "Front Door WAF policy name."
  type        = string
}

variable "sku_name" {
  description = "Front Door SKU."
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "waf_mode" {
  description = "WAF mode."
  type        = string
  default     = "Prevention"
}

variable "enable_managed_rules" {
  description = "Enable managed rule set (requires Premium SKU)."
  type        = bool
  default     = false
}

variable "create_profile_resources" {
  description = "Whether to create profile and endpoint resources."
  type        = bool
  default     = true
}

variable "create_routing_resources" {
  description = "Whether to create origin group, origin, and route resources."
  type        = bool
  default     = true
}

variable "existing_profile_id" {
  description = "Existing profile id used when profile creation is disabled."
  type        = string
  default     = ""
}

variable "existing_endpoint_id" {
  description = "Existing endpoint id used when endpoint creation is disabled."
  type        = string
  default     = ""
}

variable "origin_group_name" {
  description = "Origin group name."
  type        = string
  default     = "qotd-origin-group"
}

variable "origin_name" {
  description = "Origin name."
  type        = string
  default     = "qotd-app-origin"
}

variable "route_name" {
  description = "Route name."
  type        = string
  default     = "qotd-route"
}

variable "origin_hostname" {
  description = "App Service origin hostname."
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Workspace id for Front Door diagnostic settings."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for Front Door resources."
  type        = map(string)
  default     = {}
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings for Front Door."
  type        = bool
  default     = true
}