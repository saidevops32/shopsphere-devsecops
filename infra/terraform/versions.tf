terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.10" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
  }
  # Partial config: values are passed with -backend-config (scripts/01 and the pipeline)
  backend "azurerm" {
    use_azuread_auth = true
  }
}

# subscription_id comes from env ARM_SUBSCRIPTION_ID
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
