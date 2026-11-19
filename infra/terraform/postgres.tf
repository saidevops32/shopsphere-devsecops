# Optional (cost): set enable_postgres = true. Backend uses in-memory data unless you wire DB env vars.
resource "azurerm_private_dns_zone" "pg" {
  count               = var.enable_postgres ? 1 : 0
  name                = "${local.flat}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  count                 = var.enable_postgres ? 1 : 0
  name                  = "pg-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pg[0].name
  virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "random_password" "pg" {
  count   = var.enable_postgres ? 1 : 0
  length  = 24
  special = false
}

resource "azurerm_postgresql_flexible_server" "pg" {
  count                         = var.enable_postgres ? 1 : 0
  name                          = "psql-${local.name}-${local.suffix}"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "16"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  delegated_subnet_id           = azurerm_subnet.db.id
  private_dns_zone_id           = azurerm_private_dns_zone.pg[0].id
  public_network_access_enabled = false
  administrator_login           = "pgadmin"
  administrator_password        = random_password.pg[0].result
  backup_retention_days         = 7
  tags                          = local.tags
  depends_on                    = [azurerm_private_dns_zone_virtual_network_link.pg]
  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_key_vault_secret" "pg" {
  count        = var.enable_postgres ? 1 : 0
  name         = "pg-admin-password"
  value        = random_password.pg[0].result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}
