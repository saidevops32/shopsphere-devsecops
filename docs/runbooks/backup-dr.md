# Backup and DR (design for the lab; implement if time permits)
| Item | Approach | RPO | RTO |
|---|---|---|---|
| Cluster config | Everything is in Git (GitOps) -> rebuild with Terraform + ArgoCD | 0 | ~45 min |
| Images | ACR geo-replication (Premium) / re-run CI | 0 | 15 min |
| PostgreSQL | Flexible Server automated backups (7-35d, PITR), geo-redundant backup in prod | <5 min | 1-2 h |
| Persistent volumes | AKS Backup (Backup vault) or Velero | 24 h | 1 h |
| Secrets | Key Vault soft-delete + purge protection, backup of keys | 0 | 10 min |
| Region failure | Deploy `envs/prod.tfvars` in South India, Front Door/Traffic Manager | 5-15 min | 1 h |
Test: quarterly DR drill = `terraform apply` in secondary region + point ArgoCD at it.
