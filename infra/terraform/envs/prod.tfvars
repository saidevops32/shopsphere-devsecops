# Example for a separate prod cluster (real MNC pattern). Not needed for the 1-cluster lab.
env                  = "prod"
alert_email          = "oncall@example.com"
namespaces           = ["shopsphere-prod"]
aks_min_nodes        = 3
aks_max_nodes        = 6
enable_postgres      = true
enable_defender      = true
