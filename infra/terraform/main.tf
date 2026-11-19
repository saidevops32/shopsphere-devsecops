data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

locals {
  name   = "${var.prefix}-${var.env}"
  flat   = "${var.prefix}${var.env}"
  suffix = random_string.suffix.result
  tags = {
    project   = var.prefix
    env       = var.env
    owner     = "devsecops-practice"
    costcentr = "lab"
    managedby = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name}-cin-01"
  location = var.location
  tags     = local.tags
}
