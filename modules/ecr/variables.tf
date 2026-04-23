variable "repositories" {
  description = "Map of ECR repository configurations from the CSV data engine"
  type = map(object({
    project      = string
    environment  = string
    repo_name    = string
    mutability   = string
    scan_on_push = bool
    max_images   = number
  }))
}