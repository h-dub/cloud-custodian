variable location { type = string }
variable suffix { type = string }

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "batch" {
  name     = "test_batch"
  location = var.location
}

resource "azurerm_batch_account" "batch" {
  name                 = "cctest${var.suffix}"
  location             = azurerm_resource_group.batch.location
  resource_group_name  = azurerm_resource_group.batch.name
  pool_allocation_mode = "BatchService"
  tags = {
    env = "cctest"
  }
}

