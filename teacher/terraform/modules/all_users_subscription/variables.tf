variable "subscription_id" {
  type        = string
  description = "The subscription ID where the role will be created and assigned."
}

variable "group_object_id" {
  type        = string
  description = "The object ID of the Entra group to assign the role to."
}
