variable "project_code" { type = string }
variable "environment"  { type = string }
variable "account_id"   { type = string }

variable "buckets" {
  description = "Map of bucket configurations"
  type = map(object({
    versioning      = bool
    prevent_destroy = bool
    owner           = string
  }))
}

variable "common_tags" {
  type    = map(string)
  default = {}
}