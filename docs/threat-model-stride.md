# STRIDE threat model (summary)
| Threat | Example here | Control |
|---|---|---|
| Spoofing | Stolen JWT / pipeline identity | Short JWT TTL, Entra RBAC, workload identity federation (no long-lived SPN secrets) |
| Tampering | Modified image or manifest | Branch policy + PR review, Trivy, image signing (cosign), GitOps drift correction, Kyverno ACR-only |
| Repudiation | "Who changed prod?" | Git history, ADO audit, Azure Activity Log, K8s audit logs |
| Information disclosure | Secrets in repo/logs; lateral traffic | Gitleaks, Key Vault + CSI, NetworkPolicy default-deny, TLS (prod) |
| Denial of service | Pod overload, noisy neighbor | Resource limits/quotas, HPA, PDB, ingress rate limit |
| Elevation of privilege | Privileged pod, root container | PSS restricted, Kyverno + Azure Policy deny privileged, non-root, drop ALL caps, least-privilege RBAC |
Supply chain (AI era): pin dependencies, review AI-suggested packages (slopsquatting), SBOM per build, scan IaC, never paste secrets into AI tools.
