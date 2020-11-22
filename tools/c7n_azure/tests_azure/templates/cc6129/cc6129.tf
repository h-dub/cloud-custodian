variable location { type = string }


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

resource "azurerm_resource_group" "cc6129" {
  name     = "repro_cc6129"
  location = var.location

  tags = {
    environment = "repro"
  }
}

resource "azurerm_storage_account" "cc6129" {
  name                     = "cc6129"
  resource_group_name      = azurerm_resource_group.cc6129.name
  location                 = azurerm_resource_group.cc6129.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "repro"
  }
}

#public ip with diag set to true
resource "azurerm_public_ip" "cc6129_1" {
  name                = "cc6129_1"
  resource_group_name = azurerm_resource_group.cc6129.name
  location            = azurerm_resource_group.cc6129.location
  allocation_method   = "Static"

  tags = {
    environment = "repro"
  }
}

#public ip with diag set to false
resource "azurerm_public_ip" "cc6129_2" {
  name                = "cc6129_2"
  resource_group_name = azurerm_resource_group.cc6129.name
  location            = azurerm_resource_group.cc6129.location
  allocation_method   = "Static"

  tags = {
    environment = "repro"
  }
}

#public ip with diag missing
resource "azurerm_public_ip" "cc6129_3" {
  name                = "cc6129_3"
  resource_group_name = azurerm_resource_group.cc6129.name
  location            = azurerm_resource_group.cc6129.location
  allocation_method   = "Static"

  tags = {
    environment = "repro"
  }
}

#public ip with diag set to true
resource "azurerm_monitor_diagnostic_setting" "cc6129_1" {
  name               = "cc6129_1"
  target_resource_id = azurerm_public_ip.cc6129_1.id
  storage_account_id = azurerm_storage_account.cc6129.id

  log {
    category = "DDoSProtectionNotifications"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }
}

#public ip with diag set to false
resource "azurerm_monitor_diagnostic_setting" "cc6129_2" {
  name               = "cc6129_2"
  target_resource_id = azurerm_public_ip.cc6129_2.id
  storage_account_id = azurerm_storage_account.cc6129.id

  log {
    category = "DDoSProtectionNotifications"
    enabled  = false

    retention_policy {
      enabled = false
    }
  }

  #terraform needs something enabled or it won't try
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

