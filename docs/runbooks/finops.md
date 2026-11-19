# FinOps
- Budgets + alerts at subscription and RG; mandatory tags (project/env/owner/costcentr).
- Non-prod: autoscaler min nodes, `az aks stop` nights/weekends, spot node pools for batch/QA (add a `azurerm_kubernetes_cluster_node_pool` with `priority = "Spot"`).
- Right-size using Container Insights + HPA/VPA recommendations; set requests/limits (already enforced by Kyverno).
- Log Analytics daily cap and basic logs for noisy tables. Infracost in PRs (optional).
- Skip Azure Firewall / App Gateway WAF in practice (~$250-$900+/month); document the design instead.
