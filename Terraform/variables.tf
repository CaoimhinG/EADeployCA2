variable "resource_group_location" {
  type        = string
  # Changed from eastus to northeurope (Dublin data centre — closer to Ireland)
  default     = "northeurope"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the cluster."
  default     = 3
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

# Variables for Log Analytics Workspace (Container Insights)
# Based on Microsoft official Terraform pattern:
# https://learn.microsoft.com/en-us/azure/azure-linux/quickstart-terraform
variable "log_analytics_workspace_name" {
  type        = string
  default     = "EADeployCA2-logs"
  description = "Name of the Log Analytics Workspace for Container Insights."
}

variable "log_analytics_workspace_sku" {
  type        = string
  default     = "PerGB2018"
  description = "SKU of the Log Analytics Workspace."
}