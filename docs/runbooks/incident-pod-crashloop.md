# Runbook: pod CrashLoopBackOff / alert-pod-restarts
1. `kubectl -n <ns> get pods` then `describe pod` (events: probe failures, OOMKilled, image pull).
2. `kubectl -n <ns> logs <pod> --previous`.
3. Check last GitOps change: `git log -5 -- k8s/helm/shopsphere/values-<env>.yaml`; if bad tag -> `git revert` (rollback).
4. OOMKilled -> raise memory limit in values; probe failures -> check endpoint and timing; secrets -> CSI/federated credential.
5. Record timeline + root cause (blameless postmortem).
