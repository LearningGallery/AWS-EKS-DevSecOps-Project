variable "roles" {
  description = "Map of IAM roles and their configurations passed from the root module"
  type        = map(any)
}