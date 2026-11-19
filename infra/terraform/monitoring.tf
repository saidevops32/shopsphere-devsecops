resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-${local.name}-cin-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 1 # cost guard-rail
  tags                = local.tags
}

resource "azurerm_monitor_action_group" "ops" {
  name                = "ag-${local.name}-ops"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "ops"
  email_receiver {
    name          = "oncall"
    email_address = var.alert_email
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_restarts" {
  name                 = "alert-pod-restarts-${local.name}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"
  scopes               = [azurerm_log_analytics_workspace.law.id]
  severity             = 2
  description          = "Container restarted more than 3 times (probe failures / crash loops)"
  criteria {
    query                   = <<-Q
      KubePodInventory
      | where Namespace startswith "shopsphere"
      | summarize Restarts = max(ContainerRestartCount) by Name
      | where Restarts > 3
    Q
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  action {
    action_groups = [azurerm_monitor_action_group.ops.id]
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_not_ready" {
  name                 = "alert-pods-not-running-${local.name}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"
  scopes               = [azurerm_log_analytics_workspace.law.id]
  severity             = 2
  description          = "Pods in shopsphere namespaces not Running"
  criteria {
    query                   = <<-Q
      KubePodInventory
      | where Namespace startswith "shopsphere" and PodStatus !in ("Running", "Succeeded")
      | summarize count() by Name, PodStatus
    Q
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }
  action {
    action_groups = [azurerm_monitor_action_group.ops.id]
  }
}

resource "azurerm_monitor_metric_alert" "node_cpu" {
  name                = "alert-node-cpu-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.aks.id]
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }
  action {
    action_group_id = azurerm_monitor_action_group.ops.id
  }
}
