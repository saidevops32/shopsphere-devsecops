# Architecture notes
See the Mermaid in README. Design decisions: GitOps (pull-based, auditable, self-healing); workload identity federation (no secrets in Azure DevOps or pods); Cilium dataplane for NetworkPolicy; Kyverno for fine-grained admission + Azure Policy for subscription-level governance; Terraform remote state with Azure AD auth only.
## Practice vs MNC production
| Area | Practice (this repo) | MNC production |
|---|---|---|
| Network | single spoke VNet, public API server | hub-spoke, Azure Firewall + UDR, private cluster, private endpoints for ACR/KV/DB |
| Ingress | ingress-nginx, HTTP | App Gateway WAF/Front Door, TLS via cert-manager/Key Vault certs |
| Clusters | 1 cluster, 3 namespaces | cluster/subscription per environment |
| Identity | admin via Azure RBAC | PIM just-in-time, Conditional Access, groups only |
| Registry | Standard ACR | Premium, geo-replication, signed images, admission verification |
| Agents | Microsoft-hosted | self-hosted in VNet (VMSS/KEDA) |
| Secrets | Key Vault CSI | + rotation policies, purge protection, private endpoint |
