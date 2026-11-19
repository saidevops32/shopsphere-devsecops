resource "azurerm_key_vault" "kv" {
  name                       = "kv-${var.prefix}-${var.env}-${local.suffix}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # true in production
  tags                       = local.tags
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.admin_object_id
}

resource "random_password" "jwt" {
  length  = 48
  special = false
}
resource "random_password" "demo" {
  length  = 16
  special = false
}

resource "azurerm_key_vault_secret" "jwt" {
  name         = "jwt-secret"
  value        = random_password.jwt.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}
resource "azurerm_key_vault_secret" "demo" {
  name         = "demo-password"
  value        = random_password.demo.result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}

# Optional: signing key for cosign (azurekms://)
resource "azurerm_key_vault_key" "cosign" {
  name         = "cosign"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "EC"
  curve        = "P-256"
  key_opts     = ["sign", "verify"]
  depends_on   = [azurerm_role_assignment.kv_admin]
}

# Workload identity for auth-service pods (no secrets in the cluster)
resource "azurerm_user_assigned_identity" "auth" {
  name                = "id-auth-${local.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

# NOTE: apply with -parallelism=1 (Azure rejects concurrent federated credential writes on one identity)
resource "azurerm_federated_identity_credential" "auth" {
  for_each            = toset(var.namespaces)
  name                = "fic-${each.key}"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.auth.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${each.key}:auth-service-sa"
}

resource "azurerm_role_assignment" "auth_kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.auth.principal_id
}
