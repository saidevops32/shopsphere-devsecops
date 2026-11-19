# RACI (R=Responsible, A=Accountable, C=Consulted, I=Informed)
| Activity | Dev | Platform/DevOps | Security | Product/Release mgr |
|---|---|---|---|---|
| App code and unit tests | R/A | I | C | I |
| Pipeline templates | C | R/A | C | I |
| Security gates and policies | C | R | A | I |
| Infra (Terraform) | I | R/A | C | I |
| Prod approval | C | R | C | A |
| Incident response | R | R/A | C | I |
| Vulnerability triage | R | C | A | I |
