locals {
  padded  = format("%03d", var.user_index)
  rg_name = "rg-user${local.padded}"
}

resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
}

resource "azurerm_role_assignment" "owner" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Owner"
  principal_id         = var.user_object_id
}

module "test_deployment" {
  source              = "../test_deployment"
  count               = var.enable_test_deployment ? 1 : 0
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
