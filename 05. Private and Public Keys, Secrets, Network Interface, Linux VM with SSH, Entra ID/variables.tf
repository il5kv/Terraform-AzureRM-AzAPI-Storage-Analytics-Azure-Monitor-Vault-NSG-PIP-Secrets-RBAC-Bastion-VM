variable "application_name" {
  type = string
}
variable "environment_name" {
  type = string
}
variable "primary_region" {
  type = string
}
variable "base_address_space" {
  type = string
}
variable "remote_access_users" {
  type = list(string)
}
