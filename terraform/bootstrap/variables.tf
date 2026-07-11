variable "location" {
  description = "Azure region for state resources."
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group for Terraform state resources."
  type        = string
  default     = "rg-qotd-bootstrap-eastus2"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for tfstate."
  type        = string
}

variable "containers" {
  description = "State blob containers to create."
  type        = list(string)
  default = [
    "platform-dev",
    "application-dev",
    "platform-prod",
    "application-prod"
  ]
}

variable "tags" {
  description = "Bootstrap resource tags."
  type        = map(string)
  default = {
    environment         = "bootstrap"
    project             = "quote-of-the-day"
    managed-by          = "terraform"
    data-classification = "confidential-pii"
    cost-center         = "interview"
  }
}