variable "resource_group_name" {
  description = "Resource group name for identities."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "app_identity_name" {
  description = "User-assigned identity for app runtime."
  type        = string
}

variable "seeder_identity_name" {
  description = "User-assigned identity for seed job runtime."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault id to assign Secrets User role."
  type        = string
}

variable "tags" {
  description = "Tags for identities."
  type        = map(string)
  default     = {}
}