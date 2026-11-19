resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.name}-cin-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-${local.name}-${local.suffix}"
  sku_tier            = "Free"
  tags                = local.tags

  # Hardening toggles. Real MNC: private_cluster_enabled = true + local_account_disabled = true
  local_account_disabled            = false
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  azure_policy_enabled              = true
  automatic_upgrade_channel         = "patch"
  node_os_upgrade_channel           = "NodeImage"
  role_based_access_control_enabled = true

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
  }

  default_node_pool {
    name                        = "system"
    vm_size                     = var.aks_vm_size
    auto_scaling_enabled        = true
    min_count                   = var.aks_min_nodes
    max_count                   = var.aks_max_nodes
    vnet_subnet_id              = azurerm_subnet.aks.id
    os_disk_size_gb             = 64
    temporary_name_for_rotation = "tmpsys"
    upgrade_settings {
      max_surge = "10%"
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium" # enforces K8s NetworkPolicy
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
    load_balancer_sku   = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.law.id
    msi_auth_for_monitoring_enabled = true
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_defender ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
    }
  }

  dynamic "api_server_access_profile" {
    for_each = length(var.authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }

  depends_on = [azurerm_subnet_network_security_group_association.aks]
}

# Human admin gets cluster-admin through Azure RBAC (no local kubeconfig admin)
resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.admin_object_id
}

resource "azurerm_role_assignment" "aks_user" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.admin_object_id
}
