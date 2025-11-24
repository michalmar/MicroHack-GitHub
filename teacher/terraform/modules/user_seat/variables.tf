variable "user_index" {
  type        = number
  description = "Numeric user index (1..n)."
}

variable "location" {
  type        = string
  description = "Azure region for the resource group."
}

variable "user_object_id" {
  type        = string
  description = "Object ID of the user to assign Owner role."
}

variable "enable_test_deployment" {
  type        = bool
  default     = false
  description = "Enable deployment of test resources (Cosmos, ACA, ACR, MI) for validation."
}
