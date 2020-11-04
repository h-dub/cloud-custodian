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

# windows normal app plan
resource "azurerm_resource_group" "appserviceplan" {
  name     = "test_appserviceplan"
  location = var.location
}

resource "azurerm_app_service_plan" "appserviceplan-win" {
  name                = "cctest-appserviceplan-win"
  location            = azurerm_resource_group.appserviceplan.location
  resource_group_name = azurerm_resource_group.appserviceplan.name

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = {
    sku = "B1"
    }
}

#windows consumption app plan
resource "azurerm_app_service_plan" "consumptionplan" {
  name                = "cctest-consumption-win"
  location            = azurerm_resource_group.appserviceplan.location
  resource_group_name = azurerm_resource_group.appserviceplan.name

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

#linux normal app plan, existing tests want to vary the rg name
resource "azurerm_resource_group" "appserviceplan2" {
  name     = "test_appserviceplan-linux"
  location = var.location
}

resource "azurerm_app_service_plan" "appserviceplan-lin" {
  name                = "cctest-appserviceplan-linux"
  location            = azurerm_resource_group.appserviceplan2.location
  resource_group_name = azurerm_resource_group.appserviceplan2.name
  kind = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
}

#linux consumption plan
#implemented as a function app and needs storage
resource "azurerm_storage_account" "storage-lin" {
  name                     = "cclastorage${var.suffix}"
  resource_group_name      = azurerm_resource_group.appserviceplan2.name
  location                 = azurerm_resource_group.appserviceplan2.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "consumptionplan-lin" {
  name                = "cclinuxappplan${var.suffix}"
  location            = azurerm_resource_group.appserviceplan2.location
  resource_group_name = azurerm_resource_group.appserviceplan2.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "functionapp-lin" {
  name                = "cclinuxappplan${var.suffix}"
  location                   = azurerm_resource_group.appserviceplan2.location
  resource_group_name        = azurerm_resource_group.appserviceplan2.name
  app_service_plan_id        = azurerm_app_service_plan.consumptionplan-lin.id
  storage_account_name       = azurerm_storage_account.storage-lin.name
  storage_account_access_key = azurerm_storage_account.storage-lin.primary_access_key
  os_type                    = "linux"
}
