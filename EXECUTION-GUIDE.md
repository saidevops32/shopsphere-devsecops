# Execution Guide (browser only, minimum billing)

## 0. Strategy
- Do the **free** work first (GitHub, Azure DevOps, reading) -> then create Azure resources -> finish in ONE focused session -> **teardown**.
- Billable while running: 2 AKS nodes (~$0.19/hr for 2x D2s_v5), ACR Standard (~$0.67/day), ingress public IP/LB (~$0.1-0.2/day), Log Analytics (daily cap 1 GB). A 6-8 hour session is roughly **$2-6**. Check the Azure Pricing Calculator; prices vary.
- Never leave it overnight: `scripts/stop-cluster.sh` (pauses nodes) or `scripts/teardown.sh` (zero).
- Use a **free account ($200 credit)** if you are eligible. If you hit vCPU quota errors in Central India, set `aks_vm_size = "Standard_B2s"` and `aks_min_nodes = 2` in `infra/terraform/envs/dev.tfvars`, or try region `southindia`/`eastus` (`LOCATION` + `location` var).

## 1. One-time setup (free, ~30 min)
1. **Azure Portal** -> Cost Management -> Budgets -> create budget (e.g. $20) with email alerts at 50/80/100%.
2. **Azure DevOps**: https://dev.azure.com -> New organization -> New project `ShopSphere` (Private).
3. **Free pipeline minutes**: Org settings -> Billing/Parallel jobs. New orgs often need to request free parallelism (https://aka.ms/azpipelines-parallelism-request, approval 2-3 days). **Plan B** (no waiting): self-hosted agent on a small VM (section 11).
4. **GitHub**: create an empty **public** repo `shopsphere-devsecops` (public = ArgoCD can read it with no credentials; the repo has no secrets). Create a **fine-grained PAT**: Settings -> Developer settings -> Fine-grained tokens -> only this repo -> Contents: Read & write. Save it (used as `GH_PAT`).
5. **Azure Cloud Shell** (portal top bar `>_`) -> Bash. First time it creates a small storage account (~$1/month; delete later).

## 2. Put the code on GitHub (from Cloud Shell, no laptop tools)
1. Cloud Shell toolbar -> **Upload** -> choose `shopsphere-devsecops.zip`.
2. ```bash
   unzip shopsphere-devsecops.zip && cd shopsphere-devsecops   # adjust folder name if different
   git init -b main && git add -A
   git -c user.name="you" -c user.email="you@example.com" commit -m "initial import"
   git remote add origin https://github.com/<OWNER>/shopsphere-devsecops.git
   git push -u origin main      # username = GitHub user, password = the PAT
   ```
   (Alternative without CLI: GitHub web -> Add file -> Upload files, after unzipping on your PC.)

## 3. Terraform state + infrastructure (Cloud Shell, ~20 min)
```bash
cd ~/shopsphere-devsecops/scripts
./00-bootstrap-tfstate.sh     # state storage (AAD auth only)
./01-terraform-apply.sh plan  # read the plan
./01-terraform-apply.sh       # type yes. AKS takes ~10 min
./02-connect-aks.sh           # kubeconfig + kubelogin, shows nodes
```
Portal check: Resource groups -> `rg-shopsphere-dev-cin-01` (AKS, ACR, Key Vault, Log Analytics, VNet, NSG, alerts). Policy -> Assignments -> `deny-privileged-containers`.
Common errors: *quota* (change VM size/region), *provider not registered* (`az provider register -n Microsoft.ContainerService` etc. for Microsoft.KeyVault, Microsoft.OperationalInsights, Microsoft.Network, Microsoft.Insights, Microsoft.PolicyInsights), *RBAC not propagated* (wait 2 min, re-run apply).

## 4. Platform add-ons + render config (Cloud Shell, ~10 min)
```bash
./03-install-platform.sh                          # ingress-nginx, ArgoCD, Kyverno. Prints ingress IP + ArgoCD password
./04-render-config.sh <OWNER>/shopsphere-devsecops  # fills placeholders (ACR, KV, IP, tenant...)
cd .. && git add -A && git commit -m "render config" && git push
```

## 5. Azure DevOps wiring (portal clicks, ~20 min)
1. **Service connection (no secrets)**: Project settings -> Service connections -> New -> Azure Resource Manager -> **Workload identity federation (automatic)** -> scope: Subscription + Resource group `rg-shopsphere-dev-cin-01` -> name exactly `sc-azure-shopsphere` -> save. Open it -> *Manage app registration* / copy the **Application (client) ID**.
2. In Cloud Shell: `./scripts/06-grant-pipeline-access.sh <client-id>` (least privilege: AcrPush only).
3. **Variable group**: Pipelines -> Library -> + Variable group `shopsphere-secrets` -> add `GH_PAT` (click the lock = secret) -> Pipeline permissions: allow all pipelines. (MNC upgrade: link the group to Key Vault.)
4. **Environments**: Pipelines -> Environments -> create `qa`, `prod`, `infra-dev`. On `prod` and `qa`: ... -> Approvals and checks -> Approvals -> add yourself.
5. **Pipelines**: Pipelines -> New pipeline -> GitHub -> your repo -> *Existing Azure Pipelines YAML file* -> create one each for: `pipelines/ci-backend-api.yml`, `ci-auth-service.yml`, `ci-frontend.yml`, `cd-gitops-promote.yml`, `dast-zap.yml`, `infra-terraform.yml` (rename each in the UI). Authorize the GitHub connection when asked.
6. Optional gate: GitHub repo -> Settings -> Branches -> require PR on `main`. If enabled, allow the PAT owner to bypass (the pipeline pushes tag bumps) - or leave unprotected for the lab.

## 6. First CI run -> images -> dev deploy
1. Run `ci-auth-service`, `ci-backend-api`, `ci-frontend` (Pipelines -> Run, branch main). Watch stages: Scan -> Test -> Build. Each pushes `shopsphere/<svc>:<buildid>-<sha>` to ACR and commits the tag to `values-dev.yaml` with `[skip ci]`.
   - First failures are normal learning: fix, commit, re-run (paste the log to Claude for help).
2. Portal: ACR -> Repositories shows images.
3. Cloud Shell:
   ```bash
   ./scripts/05-apply-policies-and-apps.sh dev      # Kyverno policies + ArgoCD app (dev)
   kubectl -n argocd get applications
   kubectl -n shopsphere-dev get pods,svc,ingress,hpa,pdb,networkpolicy
   ```
4. Browse `http://dev.<INGRESS_IP>.nip.io`. Demo login password: `az keyvault secret show --vault-name <kv> -n demo-password --query value -o tsv` (comes from Key Vault via CSI + workload identity).
5. ArgoCD UI: `kubectl -n argocd port-forward svc/argocd-server 8080:80` -> Cloud Shell **Web preview** -> port 8080. User `admin`, password printed by script 03.

## 7. Promote qa -> prod (GitOps + approvals)
Run `cd-gitops-promote` with `targetEnv=qa` (approve in the pipeline UI) -> `./scripts/05-apply-policies-and-apps.sh qa`. Repeat for `prod`; prod ArgoCD app is manual-sync (click SYNC) = second gate. Optionally run `dast-zap` with `http://qa.<IP>.nip.io`.
Rollback = `git revert` the GitOps commit (or ArgoCD history -> Rollback).

## 8. Break-it labs (this is the real learning) - see `docs/labs.md`
Trivy fail, Kyverno block, NetworkPolicy test (`labs/netpol-test.sh`), probe failure, kill a pod, alert fires.

## 9. Monitoring (Portal)
- Cluster -> Insights (Container Insights), Logs (`monitoring/kql-queries.md`), Alerts (3 rules created by Terraform; set a real email in `envs/dev.tfvars`).
- Optional Grafana/Prometheus: `./scripts/07-enable-prometheus-grafana.sh` (costs more; do last, then teardown).
- Security: Defender for Cloud -> Environment settings (enable Containers plan only for a quick look, then turn off), Activity log, `enable_defender` var.

## 10. FINISH: teardown (do not skip)
```bash
./scripts/teardown.sh --include-state
```
Then verify: Portal -> Resource groups (no `shopsphere`/`MC_` groups), Cost analysis next day. Delete the Cloud Shell storage account if you do not need it. Revoke the GitHub PAT.
Between sessions only: `./scripts/stop-cluster.sh` / `start-cluster.sh`.

## 11. Plan B: no free Microsoft-hosted parallelism
Create a tiny VM (B1s/B2s Ubuntu, no public inbound), install Docker (`curl -fsSL https://get.docker.com | sh`), then Azure DevOps -> Project settings -> Agent pools -> Default -> New agent -> follow the Linux download/config commands (needs a PAT with Agent Pools read/manage). Change `pool: { vmImage: ubuntu-latest }` to `pool: Default` in pipelines. **Deallocate the VM when idle.** Also install `yq` on it.

## 12. Timeline (one day)
| Block | Phases | Time |
|---|---|---|
| A | 1 (foundation), setup of sections 1-2 | 45 min |
| B | 2-4 Terraform + infra pipeline (plan only) | 40 min |
| C | 5-7 app, Docker, CI security gates | 60-90 min |
| D | 8-13 K8s, probes, netpol, secrets, GitOps, policies | 60 min |
| E | 14-16 monitoring, security, DAST | 45 min |
| F | 19 labs, then 17-18/20 docs + teardown | 45 min |

## 13. 20-phase map
| # | Phase | Where in repo |
|---|---|---|
| 1 | Azure foundation (naming, tags, RBAC, Policy) | `infra/terraform/main.tf, policy.tf` |
| 2 | Terraform infra | `infra/terraform/*` |
| 3 | Azure DevOps setup | section 5 |
| 4 | Infra pipeline (plan/scan/approval/apply) | `pipelines/infra-terraform.yml` |
| 5 | App code | `app/` |
| 6 | Docker best practices | `app/*/Dockerfile` |
| 7 | CI security gates | `pipelines/templates/ci-service.yml` |
| 8 | K8s manifests | `k8s/helm/shopsphere/templates/workloads.yaml, quota.yaml` |
| 9 | Probes | `workloads.yaml`, `docs/runbooks/probes.md` |
| 10 | Network policies | `templates/networkpolicies.yaml`, `labs/netpol-test.sh` |
| 11 | Secrets | `keyvault.tf`, `secretproviderclass.yaml` |
| 12 | CD / GitOps | `k8s/gitops/`, `cd-gitops-promote.yml` |
| 13 | Policy as code | `k8s/policies/kyverno/`, `policy.tf` |
| 14 | Observability | `monitoring.tf`, `monitoring/` |
| 15 | Security monitoring | Defender toggle, `docs/threat-model-stride.md` |
| 16 | DAST / release | `pipelines/dast-zap.yml` |
| 17 | Backup/DR | `docs/runbooks/backup-dr.md` |
| 18 | FinOps | budgets (section 1), spot/auto-stop in `docs/runbooks/finops.md` |
| 19 | Break-it labs | `docs/labs.md` |
| 20 | Docs + interview | `docs/` |

## 14. Troubleshooting quick table
| Symptom | Fix |
|---|---|
| Pipeline: "No hosted parallelism" | Request free grant or Plan B |
| Gitleaks fails | Real secret or false positive -> rotate or allowlist in `.gitleaks.toml` |
| Trivy fails HIGH/CRITICAL | Update base image/deps (that is the point); temporary exceptions in `security/trivyignore` with expiry comment |
| `npm audit` fails | `npm audit fix`, bump dependency |
| ImagePullBackOff | CI not yet pushed that tag (values still `0.0.0`) or AcrPull missing |
| Pod rejected by Kyverno | Read the message: tag/registry/limits/privileged. Fix manifest |
| Pod stuck ContainerCreating (auth-service) | CSI: check federated credential namespace/SA name, Key Vault role, `kubectl describe pod` |
| Site unreachable | Ingress IP in values host? NSG rule 80/443? `kubectl -n ingress-nginx get svc` |
| ArgoCD OutOfSync on prod | Expected: manual sync |
| `Forbidden` from kubectl | Role propagation or run `kubelogin convert-kubeconfig -l azurecli` |
