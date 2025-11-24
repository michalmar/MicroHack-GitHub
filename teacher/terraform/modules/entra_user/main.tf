resource "azuread_user" "this" {
  user_principal_name   = local.upn
  display_name          = local.display
  password              = var.password
  force_password_change = false
  mail_nickname         = local.mail_nick
}

resource "azuread_group_member" "this" {
  group_object_id  = var.group_object_id
  member_object_id = azuread_user.this.object_id
}
