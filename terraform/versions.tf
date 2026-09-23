terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Configure a remote backend before running in production, e.g.:
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate"
  #   storage_account_name = "sttfstate<unique>"
  #   container_name       = "tfstate"
  #   key                  = "landing-zone.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {}

  # Null falls back to the ARM_SUBSCRIPTION_ID environment variable.
  subscription_id = var.subscription_id
}
