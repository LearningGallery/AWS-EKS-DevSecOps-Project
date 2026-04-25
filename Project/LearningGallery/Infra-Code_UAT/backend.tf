terraform {
  backend "s3" {
    bucket         = "st-cis-uat-tfstate-485950501937" # Replace with bootstrap output
    key            = "core-infra/terraform.tfstate"
    region         = "ap-southeast-1"
    use_lockfile   = true
    encrypt        = true
  }
}