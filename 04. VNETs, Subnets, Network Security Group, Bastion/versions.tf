terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.54.0"
    }

  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = "abcc12e8-46f6-4fb0-ae1f-86a92dafdaa7"
}
