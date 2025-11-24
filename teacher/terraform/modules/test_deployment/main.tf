resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_user_assigned_identity" "test" {
  name                = "id-test-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_container_registry" "test" {
  name                = "acrtest${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_cosmosdb_account" "test" {
  name                = "cosmos-test-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  capabilities {
    name = "EnableServerless"
  }
}

resource "azurerm_log_analytics_workspace" "test" {
  name                = "log-test-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "test" {
  name                       = "cae-test-${random_string.suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.test.id
}

resource "azurerm_container_app" "test" {
  name                         = "ca-test-${random_string.suffix.result}"
  container_app_environment_id = azurerm_container_app_environment.test.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "hello-world"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
  
  ingress {
    external_enabled = true 
    target_port      = 80
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}
