locals {
  user_indices      = range(1, var.n + 1)
  region_count      = length(var.locations)
  user_location_map = { for i in local.user_indices : i => var.locations[(i - 1) % local.region_count] }
}

# Create Entra User group 
resource "azuread_group" "users" {
  display_name     = var.entra_user_group
  security_enabled = true
}

# Create Entra Users
module "entra_users" {
  source          = "./modules/entra_user"
  for_each        = { for i in local.user_indices : i => i }
  user_index      = each.value
  domain          = var.entra_user_domain
  password        = var.entra_user_password
  group_object_id = azuread_group.users.object_id
}

# Create User Seats (Resource Group + Role Assignment)
module "user_seats" {
  source                 = "./modules/user_seat"
  for_each               = { for i in local.user_indices : i => i }
  user_index             = each.value
  location               = local.user_location_map[each.value]
  user_object_id         = module.entra_users[each.value].object_id
  enable_test_deployment = var.enable_test_deployment
}

# Create Custom Role for Resource Provider Registration and assign to users group
module "all_users_subscription" {
  source          = "./modules/all_users_subscription"
  subscription_id = var.subscription_id
  group_object_id = azuread_group.users.object_id
}

