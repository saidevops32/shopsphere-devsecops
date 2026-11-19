# Break-it labs (write what you observed in your README = interview gold)
1. **Secret scan**: add `AKIA...`-style fake key or a password to a file, push, watch Gitleaks fail. Remove, rotate, explain why history matters.
2. **Vulnerable image**: copy `labs/vulnerable/Dockerfile` over `app/backend-api/Dockerfile` in a branch/PR -> Hadolint/Trivy fail. Revert.
3. **Admission control**: `kubectl -n shopsphere-dev apply -f labs/bad-pod.yaml` -> Kyverno denies with 4 reasons. Then try `--dry-run=server` on a compliant pod.
4. **Azure Policy**: same pod in a namespace outside `shopsphere-*` with `privileged: true` -> denied by Azure Policy add-on (wait ~15 min after apply).
5. **NetworkPolicy**: `./labs/netpol-test.sh` (frontend->backend works; frontend->auth blocked; other namespace blocked). Then delete `default-deny-all` in the dev namespace (ArgoCD self-heals it back - note why).
6. **Probes**: `kubectl -n shopsphere-dev set env deploy/backend-api ENABLE_FAULT_INJECTION=true` -> `kubectl -n shopsphere-dev port-forward deploy/backend-api 3000:3000` -> `curl -X POST localhost:3000/debug/unready` (pod leaves Service endpoints, no restart) then `/debug/unhealthy` (liveness fails, container restarts). `kubectl get events`. ArgoCD reverts the env var (drift) - discuss.
7. **Self-heal / resilience**: `kubectl -n shopsphere-dev delete pod -l app=backend-api` while refreshing the site (maxUnavailable 0 + PDB).
8. **HPA**: in prod values HPA is on; generate load `kubectl -n shopsphere-prod run load --image=busybox:1.36 --restart=Never -- sh -c 'while true; do wget -qO- http://frontend:8080/api/products; done'` (blocked by netpol! explain, then test from inside frontend pod instead).
9. **Alert**: crash a pod repeatedly -> `alert-pod-restarts` fires email within ~10 min.
10. **Secrets rotation**: change `demo-password` in Key Vault -> CSI rotation (~2 min) -> login with new value without redeploy.
11. **Rollback**: `git revert` a bad tag bump -> ArgoCD syncs back.
