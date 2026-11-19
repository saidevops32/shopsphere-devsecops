#!/usr/bin/env bash
# Run in Cloud Shell after dev is deployed. Expected results are in the echo lines.
NS=${1:-shopsphere-dev}
echo "1) frontend -> backend-api should WORK (expect JSON):"
kubectl -n $NS exec deploy/frontend -- wget -T3 -qO- http://backend-api:3000/health/live || echo FAIL
echo "2) frontend -> auth-service should be BLOCKED (expect timeout/FAIL):"
kubectl -n $NS exec deploy/frontend -- wget -T3 -qO- http://auth-service:8000/health/live && echo "UNEXPECTED: reachable" || echo "blocked (good)"
echo "3) random pod in another namespace -> backend-api should be BLOCKED:"
kubectl create ns lab --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n lab run t --image=busybox:1.36 --restart=Never --rm -i --command -- wget -T3 -qO- http://backend-api.$NS:3000/health/live && echo "UNEXPECTED: reachable" || echo "blocked (good)"
