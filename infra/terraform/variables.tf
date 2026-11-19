variable "prefix" {
  type    = string
  default = "shopsphere"
}
variable "env" {
  type    = string
  default = "dev"
}
variable "location" {
  type    = string
  default = "centralindia"
}
variable "admin_object_id" {
  type        = string
  description = "Entra object id of the human admin (az ad signed-in-user show --query id)"
}
variable "alert_email" {
  type    = string
  default = "you@example.com"
}
variable "namespaces" {
  type        = list(string)
  default     = ["shopsphere-dev", "shopsphere-qa", "shopsphere-prod"]
  description = "K8s namespaces allowed to use workload identity"
}
variable "aks_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}
variable "aks_min_nodes" {
  type    = number
  default = 2
}
variable "aks_max_nodes" {
  type    = number
  default = 3
}
variable "authorized_ip_ranges" {
  type        = list(string)
  default     = []
  description = "Restrict API server access. Empty = open (lab only). Real MNC = private cluster."
}
variable "enable_postgres" {
  type    = bool
  default = false
}
variable "enable_defender" {
  type    = bool
  default = false
}
