# Log Analytics (KQL) cheat sheet - Portal > Log Analytics workspace > Logs

```kusto
// Pod restarts (probe failures / crash loops)
KubePodInventory | where Namespace startswith "shopsphere"
| summarize Restarts=max(ContainerRestartCount) by Name | order by Restarts desc

// Warnings from the cluster (failed probes, policy blocks, image pull errors)
KubeEvents | where Namespace startswith "shopsphere" and KubeEventType == "Warning"
| project TimeGenerated, Name, Reason, Message | order by TimeGenerated desc

// Container errors
ContainerLogV2 | where PodNamespace startswith "shopsphere" and LogMessage has_any ("error","ERROR")
| project TimeGenerated, PodName, LogMessage | take 100

// Node CPU/memory
Perf | where ObjectName == "K8SNode" and CounterName in ("cpuUsageNanoCores","memoryWorkingSetBytes")
| summarize avg(CounterValue) by Computer, CounterName, bin(TimeGenerated, 5m)

// Kubernetes audit style: who changed what in Azure
AzureActivity | where ResourceGroup startswith "rg-shopsphere" | project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue
```

## Suggested SLOs
| SLI | Target |
|---|---|
| Availability (ingress 2xx/3xx ratio) | 99.5% / 30d |
| p95 latency of /api/products | < 300 ms |
| Pod restart rate | < 3 / hour / pod |
