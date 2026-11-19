# Interview Q&A (answer from what you actually built)
1. **Walk me through your pipeline.** Gitleaks, Semgrep, Hadolint in parallel -> tests + SCA -> build, Trivy (fail HIGH/CRITICAL), SBOM, push to ACR (OIDC service connection), commit tag to Git -> ArgoCD deploys.
2. **Why GitOps over kubectl in pipeline?** No cluster credentials in CI, drift correction, audit trail, easy rollback via revert.
3. **How are secrets handled?** Key Vault + CSI driver + workload identity; pods read files; nothing in YAML/pipelines; rotation enabled.
4. **No stored credentials to Azure from ADO?** Workload identity federation (OIDC) - short-lived tokens.
5. **Startup vs readiness vs liveness?** See `docs/runbooks/probes.md`.
6. **Why default-deny NetworkPolicy?** Limits lateral movement; Cilium enforces; DNS egress must be explicitly allowed.
7. **Kyverno vs Azure Policy vs PSS?** PSS = baseline pod hardening; Azure Policy = Azure-governed, audit/compliance at scale; Kyverno = flexible custom rules/mutation.
8. **Why distroless and non-root?** Smaller attack surface, no shell, fewer CVEs; non-root + read-only FS limits compromise impact.
9. **Pipeline failed on Trivy - what now?** Upgrade base/dep; if unfixable and risk-accepted, ignore with expiry and owner.
10. **How do you promote to prod?** Immutable tag, promote same artifact, approvals on environment, manual ArgoCD sync.
11. **Rollback?** Git revert of tag commit / ArgoCD history; zero-downtime strategy + PDB.
12. **Terraform state safety?** Remote backend, AAD auth only, versioning, locking via blob lease, plan->approve->apply.
13. **Private AKS and how pipelines reach it?** Self-hosted agents in VNet or `az aks command invoke`; GitOps avoids needing reach.
14. **How do you control cost?** Budgets, autoscaler, stop non-prod, spot pools, daily log cap, tags.
15. **Observability stack?** Container Insights + KQL, managed Prometheus/Grafana, alerts to action groups, SLOs.
16. **What would you change for production?** Private cluster, Firewall, WAF+TLS, per-env clusters, PIM, Premium ACR with signature verification, purge protection, DR region.
17. **SAST vs SCA vs DAST?** Code flaws vs vulnerable dependencies vs runtime black-box testing.
18. **What is an SBOM and why?** Inventory of components for vulnerability response and compliance.
19. **How do you secure AI-generated code/IaC?** Same gates: scanners, review, tests; verify packages exist/are trusted.
20. **HPA vs cluster autoscaler?** Pods vs nodes; HPA needs requests; autoscaler adds nodes for pending pods.
21. **What does maxUnavailable: 0 do?** New pod must be Ready before old removed.
22. **Why ResourceQuota + LimitRange?** Prevent noisy neighbors and enforce defaults per namespace.
