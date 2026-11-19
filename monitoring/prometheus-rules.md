# Managed Prometheus + Grafana (optional, cost)
Enabled by `scripts/07-enable-prometheus-grafana.sh`. In Managed Grafana, open built-in dashboards:
*Kubernetes / Compute Resources / Namespace (Pods)* and *Node Exporter*.

Example alert rules (Portal > Monitor > Alerts > Prometheus rule groups):
```yaml
- alert: PodCrashLooping
  expr: increase(kube_pod_container_status_restarts_total{namespace=~"shopsphere-.*"}[15m]) > 3
  for: 5m
  labels: { severity: warning }
- alert: DeploymentUnavailable
  expr: kube_deployment_status_replicas_available{namespace=~"shopsphere-.*"} == 0
  for: 2m
  labels: { severity: critical }
- alert: HighMemory
  expr: sum by(pod)(container_memory_working_set_bytes{namespace=~"shopsphere-.*"}) / sum by(pod)(kube_pod_container_resource_limits{resource="memory",namespace=~"shopsphere-.*"}) > 0.9
  for: 10m
```
