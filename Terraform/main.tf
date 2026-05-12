# Generate random resource group name
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  # Renamed from random_pet.rg_name.id to a static name for CI/CD pipeline stability
  name = "EADeployCA2-rg"
}

resource "random_pet" "azurerm_kubernetes_cluster_name" {
  prefix = "cluster"
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}



# Random suffix for Log Analytics Workspace name (must be globally unique)
# Based on Microsoft official Terraform pattern:
# https://learn.microsoft.com/en-us/azure/azure-linux/quickstart-terraform
resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

# Log Analytics Workspace for Container Insights monitoring
# Added as an additional feature for monitoring (Azure Monitor)
# Reference: https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-monitoring-enable
resource "azurerm_log_analytics_workspace" "logs" {
  location            = azurerm_resource_group.rg.location
  name                = "${var.log_analytics_workspace_name}-${random_id.log_analytics_workspace_name_suffix.dec}"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.log_analytics_workspace_sku
}

# Container Insights solution attached to the workspace
# Reference: https://learn.microsoft.com/en-us/azure/azure-linux/quickstart-terraform
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.logs.id
  workspace_name        = azurerm_log_analytics_workspace.logs.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_kubernetes_cluster" "k8s" {
  location = azurerm_resource_group.rg.location
  # Renamed from random_pet.azurerm_kubernetes_cluster_name.id to a static name for CI/CD pipeline stability
  name                = "EADeployCA2-aks"
  resource_group_name = azurerm_resource_group.rg.name
  # Renamed from random_pet.azurerm_kubernetes_cluster_dns_prefix.id to a static name for CI/CD pipeline stability
  dns_prefix = "EADeployCA2"

  # OIDC issuer cannot be disabled once enabled — keep set to true
  oidc_issuer_enabled = true

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name = "agentpool"
    # Changed from Standard_DS2_v2 to Standard_D2s_v3 — original not allowed on this subscription in northeurope
    vm_size    = "Standard_D2s_v3"
    node_count = var.node_count
  }

  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  # Container Insights monitoring add-on
  # Reference: https://learn.microsoft.com/en-us/azure/azure-monitor/containers/kubernetes-monitoring-enable
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.logs.id
    msi_auth_for_monitoring_enabled = true
  }
}